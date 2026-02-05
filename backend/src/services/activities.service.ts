import type {
  ActivityDetailResponse,
  ActivityEndInput,
  ActivityEndResponse,
  ActivityListQuery,
  ActivityListResponse,
  ActivityNfcCollectInput,
  ActivityNfcCollectResponse,
  ActivityStartInput,
  ActivityStartResponse,
  ActivityTrackInput,
  ActivityTrackResponse
} from "../types/activities.types.js";
import { ApiError, ErrorCodes } from "../utils/errors.js";
import { prisma } from "../utils/prismaClient.js";

import { badgesService } from "./badges.service.js";
import { geocodingService } from "./geocoding.service.js";

/**
 * Service layer for Activities module
 * Handles all business logic related to activity tracking
 */

/**
 * Calculate distance between two coordinates using Haversine formula
 * Returns distance in kilometers
 */
const calculateDistance = (
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number => {
  const R = 6371; // Earth's radius in kilometers
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};

/**
 * Check if a location is near any point in the route
 * Uses a threshold of 50 meters (0.05 km)
 */
const isLocationNearRoute = (
  locationLat: number,
  locationLon: number,
  routePoints: Array<{ latitude: number; longitude: number }>,
  thresholdKm = 0.05
): boolean => {
  return routePoints.some((point) => {
    const distance = calculateDistance(
      locationLat,
      locationLon,
      point.latitude,
      point.longitude
    );
    return distance <= thresholdKm;
  });
};

const startActivity = async (
  userId: string,
  input: ActivityStartInput
): Promise<ActivityStartResponse> => {
  // Verify user exists
  const user = await prisma.user.findUnique({
    where: { id: userId }
  });

  if (!user) {
    throw new Error("User not found");
  }

  const startTime = new Date(input.startTime);

  // Create activity
  const activity = await prisma.activity.create({
    data: {
      userId,
      startTime
    }
  });

  // Create initial track point
  await prisma.activityTrackPoint.create({
    data: {
      activityId: activity.id,
      latitude: input.startLocation.latitude,
      longitude: input.startLocation.longitude,
      timestamp: startTime,
      accuracy: null
    }
  });

  return {
    success: true,
    data: {
      activityId: activity.id,
      startTime: input.startTime,
      status: "in_progress"
    }
  };
};

const trackActivity = async (
  userId: string,
  activityId: string,
  input: ActivityTrackInput
): Promise<ActivityTrackResponse> => {
  // Verify activity exists and belongs to user
  const activity = await prisma.activity.findFirst({
    where: {
      id: activityId,
      userId
    }
  });

  if (!activity) {
    throw new Error("Activity not found");
  }

  if (activity.endTime) {
    throw new Error("Activity has already ended");
  }

  // Create track points
  const trackPoints = input.points.map((point) => ({
    activityId,
    latitude: point.latitude,
    longitude: point.longitude,
    timestamp: new Date(point.timestamp),
    accuracy: point.accuracy || null
  }));

  await prisma.activityTrackPoint.createMany({
    data: trackPoints
  });

  // Get total points count
  const totalPoints = await prisma.activityTrackPoint.count({
    where: { activityId }
  });

  return {
    success: true,
    message: "路線已更新",
    data: {
      pointsAdded: input.points.length,
      totalPoints
    }
  };
};

const endActivity = async (
  userId: string,
  activityId: string,
  input: ActivityEndInput
): Promise<ActivityEndResponse> => {
  // Verify activity exists and belongs to user
  const activity = await prisma.activity.findFirst({
    where: {
      id: activityId,
      userId
    },
    include: {
      activityTrackPoints: {
        orderBy: {
          timestamp: "asc"
        }
      }
    }
  });

  if (!activity) {
    throw new Error("Activity not found");
  }

  if (activity.endTime) {
    throw new Error("Activity has already ended");
  }

  const endTime = new Date(input.endTime);
  const startTime = activity.startTime;

  // Add end location as final track point
  await prisma.activityTrackPoint.create({
    data: {
      activityId,
      latitude: input.endLocation.latitude,
      longitude: input.endLocation.longitude,
      timestamp: endTime,
      accuracy: null
    }
  });

  // Re-fetch track points including the end point
  const allTrackPoints = await prisma.activityTrackPoint.findMany({
    where: { activityId },
    orderBy: {
      timestamp: "asc"
    }
  });

  // Re-fetch collected locations (NFC collected)
  const nfcCollectedLocations = await prisma.activityCollectedLocation.findMany({
    where: { activityId },
    include: {
      location: true
    },
    orderBy: {
      collectedAt: "asc"
    }
  });

  // Calculate total distance
  // Priority: Use GPS track points if available (>= 2 points), otherwise use NFC collected locations
  let totalDistance = 0;
  
  if (allTrackPoints.length >= 2) {
    // Use GPS track points for distance calculation
    for (let i = 0; i < allTrackPoints.length - 1; i++) {
      const point1 = allTrackPoints[i];
      const point2 = allTrackPoints[i + 1];
      totalDistance += calculateDistance(
        point1.latitude,
        point1.longitude,
        point2.latitude,
        point2.longitude
      );
    }
  } else if (nfcCollectedLocations.length >= 2) {
    // Use NFC collected locations for distance calculation
    for (let i = 0; i < nfcCollectedLocations.length - 1; i++) {
      const loc1 = nfcCollectedLocations[i].location;
      const loc2 = nfcCollectedLocations[i + 1].location;
      totalDistance += calculateDistance(
        loc1.latitude,
        loc1.longitude,
        loc2.latitude,
        loc2.longitude
      );
    }
  }
  // If neither has enough points, totalDistance remains 0

  // Calculate duration in seconds
  const duration = Math.floor((endTime.getTime() - startTime.getTime()) / 1000);

  // Calculate average speed in km/h
  const averageSpeed = duration > 0 ? (totalDistance / duration) * 3600 : 0;

  // Find locations that overlap with the route
  const allLocations = await prisma.location.findMany();
  const routePoints = allTrackPoints.map((p) => ({
    latitude: p.latitude,
    longitude: p.longitude
  }));

  const collectedLocations: Array<{
    locationId: string;
    collectedAt: Date;
    coinsEarned: number;
  }> = [];

  // Check each location if it's near the route
  // Skip locations with NFC enabled (they must be collected via NFC)
  for (const location of allLocations) {
    if (location.isNfcEnabled) {
      continue; // Skip NFC-enabled locations, they must be collected via NFC endpoint
    }
    if (isLocationNearRoute(location.latitude, location.longitude, routePoints)) {
      // Check if user has already collected this location
      const existingCollection = await prisma.userLocationCollection.findUnique({
        where: {
          userId_locationId: {
            userId,
            locationId: location.id
          }
        }
      });

      // Find the closest track point timestamp for collection time
      let closestTimestamp = startTime;
      let minDistance = Infinity;

      for (const point of allTrackPoints) {
        const distance = calculateDistance(
          location.latitude,
          location.longitude,
          point.latitude,
          point.longitude
        );
        if (distance < minDistance) {
          minDistance = distance;
          closestTimestamp = point.timestamp;
        }
      }

      // Create or update user location collection
      if (!existingCollection) {
        await prisma.userLocationCollection.create({
          data: {
            userId,
            locationId: location.id,
            collectedAt: closestTimestamp
          }
        });
      }

      // Record in activity collected locations
      collectedLocations.push({
        locationId: location.id,
        collectedAt: closestTimestamp,
        coinsEarned: 1
      });

      await prisma.activityCollectedLocation.create({
        data: {
          activityId,
          locationId: location.id,
          collectedAt: closestTimestamp,
          coinsEarned: 1
        }
      });
    }
  }

  const totalCoinsEarned = collectedLocations.length;

  // Update activity with end time and calculated values
  await prisma.activity.update({
    where: { id: activityId },
    data: {
      endTime,
      distance: totalDistance,
      duration,
      averageSpeed,
      totalCoins: totalCoinsEarned
    }
  });

  // Get collected location details with areas from database
  const collectedLocationData = await Promise.all(
    collectedLocations.map(async (collected) => {
      const location = await prisma.location.findUnique({
        where: { id: collected.locationId }
      });
      return {
        location: location!,
        collected
      };
    })
  );

  // Separate locations that need area lookup (area is null in database)
  const locationsNeedingArea = collectedLocationData.filter(
    (data) => !data.location.area
  );

  // Batch fetch areas for locations that need them
  if (locationsNeedingArea.length > 0) {
    const areaMap = await geocodingService.getAreasFromCoordinates(
      locationsNeedingArea.map((data) => ({
        latitude: data.location.latitude,
        longitude: data.location.longitude
      }))
    );

    // Update locations in database
    await Promise.all(
      locationsNeedingArea.map(async (data) => {
        const area = areaMap.get(`${data.location.latitude},${data.location.longitude}`) || null;
        await prisma.location.update({
          where: { id: data.location.id },
          data: { area }
        });
        // Update the location object in memory
        data.location.area = area;
      })
    );
  }

  const collectedLocationDetails = collectedLocationData.map((data) => ({
    id: data.location.id,
    name: data.location.name,
    latitude: data.location.latitude,
    longitude: data.location.longitude,
    area: data.location.area,
    coinsEarned: data.collected.coinsEarned
  }));

  const badgeEvaluation = await badgesService.evaluateUserBadges(userId);
  const newBadges = badgeEvaluation.newBadges.map((badge) => ({
    badgeId: badge.badgeId,
    name: badge.name,
    imageUrl: badge.imageUrl,
    unlockedAt: badge.unlockedAt.toISOString()
  }));

  return {
    success: true,
    data: {
      activityId,
      startTime: startTime.toISOString(),
      endTime: endTime.toISOString(),
      distance: totalDistance,
      duration,
      averageSpeed,
      route: allTrackPoints.map((p) => ({
        latitude: p.latitude,
        longitude: p.longitude,
        timestamp: p.timestamp.toISOString()
      })),
      collectedLocations: collectedLocationDetails,
      totalCoinsEarned,
      newBadges
    }
  };
};

const getActivities = async (query: ActivityListQuery): Promise<ActivityListResponse> => {
  const { userId, page = 1, limit = 20, startDate, endDate } = query;
  const skip = (page - 1) * limit;

  // Verify user exists
  const user = await prisma.user.findUnique({
    where: { id: userId }
  });

  if (!user) {
    throw new Error("User not found");
  }

  // Build where clause
  const where: {
    userId: string;
    endTime?: { gte?: Date; lte?: Date };
  } = {
    userId
  };

  if (startDate || endDate) {
    where.endTime = {};
    if (startDate) {
      where.endTime.gte = new Date(startDate);
    }
    if (endDate) {
      where.endTime.lte = new Date(endDate);
    }
  }

  // Get activities
  const [activities, totalCount] = await Promise.all([
    prisma.activity.findMany({
      where,
      skip,
      take: limit,
      orderBy: {
        startTime: "desc"
      },
      include: {
        activityCollectedLocations: true
      }
    }),
    prisma.activity.count({ where })
  ]);

  const activityList = activities.map((activity) => ({
    activityId: activity.id,
    date: activity.startTime.toISOString(),
    distance: activity.distance || 0,
    duration: activity.duration || 0,
    averageSpeed: activity.averageSpeed || 0,
    coinsEarned: activity.totalCoins,
    collectedLocationsCount: activity.activityCollectedLocations.length
  }));

  const totalPages = Math.ceil(totalCount / limit);

  return {
    success: true,
    data: {
      activities: activityList,
      pagination: {
        currentPage: page,
        totalPages,
        totalRecords: totalCount,
        limit
      }
    }
  };
};

const getActivityDetail = async (
  userId: string,
  activityId: string
): Promise<ActivityDetailResponse> => {
  // Verify activity exists and belongs to user
  const activity = await prisma.activity.findFirst({
    where: {
      id: activityId,
      userId
    },
    include: {
      activityTrackPoints: {
        orderBy: {
          timestamp: "asc"
        }
      },
      activityCollectedLocations: {
        include: {
          location: true
        },
        orderBy: {
          collectedAt: "asc"
        }
      }
    }
  });

  if (!activity) {
    throw new Error("Activity not found");
  }

  const totalCoins = activity.activityCollectedLocations.reduce(
    (sum, collected) => sum + collected.coinsEarned,
    0
  );

  // Separate locations that need area lookup (area is null in database)
  const locationsNeedingArea = activity.activityCollectedLocations.filter(
    (collected) => !collected.location.area
  );

  // Batch fetch areas for locations that need them
  if (locationsNeedingArea.length > 0) {
    const areaMap = await geocodingService.getAreasFromCoordinates(
      locationsNeedingArea.map((collected) => ({
        latitude: collected.location.latitude,
        longitude: collected.location.longitude
      }))
    );

    // Update locations in database
    await Promise.all(
      locationsNeedingArea.map(async (collected) => {
        const area = areaMap.get(`${collected.location.latitude},${collected.location.longitude}`) || null;
        await prisma.location.update({
          where: { id: collected.location.id },
          data: { area }
        });
        // Update the location object in memory
        collected.location.area = area;
      })
    );
  }

  return {
    success: true,
    data: {
      activityId: activity.id,
      startTime: activity.startTime.toISOString(),
      endTime: activity.endTime?.toISOString() || "",
      distance: activity.distance || 0,
      duration: activity.duration || 0,
      averageSpeed: activity.averageSpeed || 0,
      route: activity.activityTrackPoints.map((p) => ({
        latitude: p.latitude,
        longitude: p.longitude,
        timestamp: p.timestamp.toISOString()
      })),
      collectedLocations: activity.activityCollectedLocations.map((collected) => ({
        id: collected.location.id,
        name: collected.location.name,
        latitude: collected.location.latitude,
        longitude: collected.location.longitude,
        area: collected.location.area,
        collectedAt: collected.collectedAt.toISOString()
      })),
      coinsEarned: totalCoins
    }
  };
};

/**
 * Collect a location via NFC during an activity
 * @param userId - User ID
 * @param activityId - Activity ID
 * @param input - NFC collection input (nfcId only)
 * @returns Collection result with coins earned and badge unlock status
 */
const collectNfcLocation = async (
  userId: string,
  activityId: string,
  input: ActivityNfcCollectInput
): Promise<ActivityNfcCollectResponse> => {
  // Verify activity exists and belongs to user
  const activity = await prisma.activity.findUnique({
    where: { id: activityId }
  });

  if (!activity) {
    throw new ApiError(ErrorCodes.NOT_FOUND, "Activity not found", 404);
  }

  if (activity.userId !== userId) {
    throw new ApiError(ErrorCodes.UNAUTHORIZED, "Activity does not belong to user", 401);
  }

  // Find location by NFC ID
  const location = await prisma.location.findUnique({
    where: { nfcId: input.nfcId }
  });

  if (!location) {
    throw new ApiError(ErrorCodes.NOT_FOUND, "Location with NFC ID not found", 404);
  }

  if (!location.isNfcEnabled) {
    throw new ApiError(
      ErrorCodes.INVALID_REQUEST,
      "Location NFC is not enabled",
      400
    );
  }

  // Check if location is already collected by user
  const existingCollection = await prisma.userLocationCollection.findUnique({
    where: {
      userId_locationId: {
        userId,
        locationId: location.id
      }
    }
  });

  const isFirstCollection = !existingCollection;
  // Use current time as collectedAt
  const collectedAt = new Date();

  // Create or update user location collection
  if (isFirstCollection) {
    await prisma.userLocationCollection.create({
      data: {
        userId,
        locationId: location.id,
        collectedAt
      }
    });
  }

  // Check if already collected in this activity
  const existingActivityCollection = await prisma.activityCollectedLocation.findFirst({
    where: {
      activityId,
      locationId: location.id
    }
  });

  if (!existingActivityCollection) {
    // Record in activity collected locations
    await prisma.activityCollectedLocation.create({
      data: {
        activityId,
        locationId: location.id,
        collectedAt,
        coinsEarned: 1
      }
    });
  }

  // Update activity total coins
  const activityCollectedCount = await prisma.activityCollectedLocation.count({
    where: { activityId }
  });

  await prisma.activity.update({
    where: { id: activityId },
    data: {
      totalCoins: activityCollectedCount
    }
  });

  // Get area for location if needed
  let area = location.area;
  if (!area) {
    const areaMap = await geocodingService.getAreasFromCoordinates([
      {
        latitude: location.latitude,
        longitude: location.longitude
      }
    ]);
    area = areaMap.get(`${location.latitude},${location.longitude}`) || null;

    if (area) {
      await prisma.location.update({
        where: { id: location.id },
        data: { area }
      });
    }
  }

  // Evaluate badges if this is first collection
  let badgeUnlocked = null;
  if (isFirstCollection) {
    const badgeEvaluation = await badgesService.evaluateUserBadges(userId);
    if (badgeEvaluation.newBadges.length > 0) {
      const firstBadge = badgeEvaluation.newBadges[0];
      badgeUnlocked = {
        badgeId: firstBadge.badgeId,
        name: firstBadge.name,
        imageUrl: firstBadge.imageUrl,
        unlockedAt: firstBadge.unlockedAt.toISOString()
      };
    }
  }

  // Get user's total coins from all activities
  const userActivities = await prisma.activity.findMany({
    where: { userId },
    select: { totalCoins: true }
  });
  const totalCoins = userActivities.reduce((sum, act) => sum + (act.totalCoins || 0), 0);

  return {
    success: true,
    data: {
      locationId: location.id,
      name: location.name,
      area,
      coinsEarned: 1,
      totalCoins,
      isFirstCollection,
      badgeUnlocked
    }
  };
};

export const activitiesService = {
  startActivity,
  trackActivity,
  endActivity,
  collectNfcLocation,
  getActivities,
  getActivityDetail
};

