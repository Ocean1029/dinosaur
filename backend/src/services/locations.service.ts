import type {
  LocationCreateInput,
  LocationDeleteResponse,
  LocationDetailResponse,
  LocationEnableNfcResponse,
  LocationListQuery,
  LocationListResponse,
  LocationUpdateInput,
  UserMapQuery,
  UserMapResponse
} from "../types/locations.types.js";
import { ApiError, ErrorCodes } from "../utils/errors.js";
import { prisma } from "../utils/prismaClient.js";

import { geocodingService } from "./geocoding.service.js";

/**
 * Service layer for Locations module
 * Handles all business logic related to location management
 */

/**
 * Batch ensure areas for multiple locations
 * Fetches areas only for locations that don't have area in database
 * @param locations - Array of locations with id, latitude, longitude, and optional area
 * @returns Map of location ID to area
 */
const batchEnsureLocationAreas = async (
  locations: Array<{ id: string; latitude: number; longitude: number; area: string | null }>
): Promise<Map<string, string | null>> => {
  const results = new Map<string, string | null>();

  // Separate locations that need area lookup
  const locationsNeedingArea = locations.filter((loc) => !loc.area);

  if (locationsNeedingArea.length === 0) {
    // All locations already have area, return them
    locations.forEach((loc) => {
      results.set(loc.id, loc.area);
    });
    return results;
  }

  // Batch fetch areas for locations that need them
  const areaMap = await geocodingService.getAreasFromCoordinates(
    locationsNeedingArea.map((loc) => ({
      latitude: loc.latitude,
      longitude: loc.longitude
    }))
  );

  // Update locations in database and build result map
  const updatePromises = locationsNeedingArea.map(async (loc) => {
    const area = areaMap.get(`${loc.latitude},${loc.longitude}`) || null;

    // Update location in database
    await prisma.location.update({
      where: { id: loc.id },
      data: { area }
    });

    return { id: loc.id, area };
  });

  const updatedAreas = await Promise.all(updatePromises);

  // Build result map
  locations.forEach((loc) => {
    if (loc.area) {
      results.set(loc.id, loc.area);
    } else {
      const updated = updatedAreas.find((u) => u.id === loc.id);
      results.set(loc.id, updated?.area || null);
    }
  });

  return results;
};

const getLocations = async (
  query: LocationListQuery
): Promise<LocationListResponse> => {
  const { page = 1, limit = 100, badge } = query;
  const skip = (page - 1) * limit;

  // Build where clause for badge filtering
  const where: {
    badgeLocationRequirements?: { badgeId: string };
  } = {};

  if (badge) {
    where.badgeLocationRequirements = {
      badgeId: badge
    };
  }

  // Get locations with optional badge filter
  const [locations, totalCount] = await Promise.all([
    prisma.location.findMany({
      where: badge
        ? {
            badgeLocationRequirements: {
              some: {
                badgeId: badge
              }
            }
          }
        : undefined,
      skip,
      take: limit,
      orderBy: {
        createdAt: "desc"
      }
    }),
    prisma.location.count({
      where: badge
        ? {
            badgeLocationRequirements: {
              some: {
                badgeId: badge
              }
            }
          }
        : undefined
    })
  ]);

  // Ensure all locations have area in database
  const areaMap = await batchEnsureLocationAreas(
    locations.map((loc) => ({
      id: loc.id,
      latitude: loc.latitude,
      longitude: loc.longitude,
      area: loc.area
    }))
  );

  return {
    success: true,
    count: totalCount,
    data: locations.map((loc) => {
      const area = areaMap.get(loc.id) || null;

      return {
        id: loc.id,
        name: loc.name,
        latitude: loc.latitude,
        longitude: loc.longitude,
        description: loc.description,
        nfcId: loc.nfcId,
        isNfcEnabled: loc.isNfcEnabled,
        area,
        createdAt: loc.createdAt,
        updatedAt: loc.updatedAt
      };
    })
  };
};

const createLocation = async (
  input: LocationCreateInput
): Promise<LocationDetailResponse> => {
  // Check if nfcId is already taken if provided
  if (input.nfcId) {
    const existingLocation = await prisma.location.findUnique({
      where: { nfcId: input.nfcId }
    });

    if (existingLocation) {
      throw new Error("NFC ID already exists");
    }
  }

  // Get area for the new location before creating
  const area = await geocodingService.getAreaFromCoordinates(
    input.latitude,
    input.longitude
  );

  const location = await prisma.location.create({
    data: {
      name: input.name,
      latitude: input.latitude,
      longitude: input.longitude,
      description: input.description || null,
      area,
      isNfcEnabled: input.isNfcEnabled ?? false,
      nfcId: input.nfcId || null
    }
  });

  return {
    success: true,
    data: {
      id: location.id,
      name: location.name,
      latitude: location.latitude,
      longitude: location.longitude,
      description: location.description,
      nfcId: location.nfcId,
      isNfcEnabled: location.isNfcEnabled,
      area: location.area,
      createdAt: location.createdAt,
      updatedAt: location.updatedAt
    }
  };
};

const updateLocation = async (
  locationId: string,
  input: LocationUpdateInput
): Promise<LocationDetailResponse> => {
  // Check if location exists
  const existingLocation = await prisma.location.findUnique({
    where: { id: locationId }
  });

  if (!existingLocation) {
    throw new Error("Location not found");
  }

  // Check if nfcId is already taken by another location
  if (input.nfcId && input.nfcId !== existingLocation.nfcId) {
    const locationWithNfcId = await prisma.location.findUnique({
      where: { nfcId: input.nfcId }
    });

    if (locationWithNfcId) {
      throw new Error("NFC ID already exists");
    }
  }

  // Determine final coordinates after update
  const finalLat = input.latitude !== undefined ? input.latitude : existingLocation.latitude;
  const finalLng = input.longitude !== undefined ? input.longitude : existingLocation.longitude;

  // Recalculate area if coordinates changed
  let area = existingLocation.area;
  if (
    input.latitude !== undefined ||
    input.longitude !== undefined ||
    (finalLat !== existingLocation.latitude || finalLng !== existingLocation.longitude)
  ) {
    area = await geocodingService.getAreaFromCoordinates(finalLat, finalLng);
  }

  const location = await prisma.location.update({
    where: { id: locationId },
    data: {
      ...(input.name && { name: input.name }),
      ...(input.latitude !== undefined && { latitude: input.latitude }),
      ...(input.longitude !== undefined && { longitude: input.longitude }),
      ...(input.description !== undefined && { description: input.description }),
      ...(input.isNfcEnabled !== undefined && { isNfcEnabled: input.isNfcEnabled }),
      ...(input.nfcId !== undefined && { nfcId: input.nfcId }),
      ...(area !== undefined && { area })
    }
  });

  return {
    success: true,
    data: {
      id: location.id,
      name: location.name,
      latitude: location.latitude,
      longitude: location.longitude,
      description: location.description,
      nfcId: location.nfcId,
      isNfcEnabled: location.isNfcEnabled,
      area: location.area,
      createdAt: location.createdAt,
      updatedAt: location.updatedAt
    }
  };
};

const deleteLocation = async (locationId: string): Promise<LocationDeleteResponse> => {
  // Check if location exists
  const existingLocation = await prisma.location.findUnique({
    where: { id: locationId }
  });

  if (!existingLocation) {
    throw new Error("Location not found");
  }

  await prisma.location.delete({
    where: { id: locationId }
  });

  return {
    success: true,
    message: "點位已成功刪除"
  };
};

const getUserMap = async (query: UserMapQuery): Promise<UserMapResponse> => {
  const { userId, badge, bounds } = query;

  // Verify user exists
  const user = await prisma.user.findUnique({
    where: { id: userId }
  });

  if (!user) {
    throw new Error("User not found");
  }

  // Parse bounds if provided (format: lat1,lng1,lat2,lng2)
  let boundsFilter:
    | {
        latitude?: { gte?: number; lte?: number };
        longitude?: { gte?: number; lte?: number };
      }
    | undefined;

  if (bounds) {
    const [lat1, lng1, lat2, lng2] = bounds.split(",").map(Number);
    const minLat = Math.min(lat1, lat2);
    const maxLat = Math.max(lat1, lat2);
    const minLng = Math.min(lng1, lng2);
    const maxLng = Math.max(lng1, lng2);

    boundsFilter = {
      latitude: {
        gte: minLat,
        lte: maxLat
      },
      longitude: {
        gte: minLng,
        lte: maxLng
      }
    };
  }

  // Get all locations with filters
  const locations = await prisma.location.findMany({
    where: {
      ...(badge && {
        badgeLocationRequirements: {
          some: {
            badgeId: badge
          }
        }
      }),
      ...boundsFilter
    },
    include: {
      userLocationCollections: {
        where: {
          userId
        },
        take: 1,
        orderBy: {
          collectedAt: "desc"
        }
      }
    },
    orderBy: {
      createdAt: "desc"
    }
  });

  // Get user's collected location IDs for quick lookup
  const collectedLocationIds = new Set(
    (
      await prisma.userLocationCollection.findMany({
        where: { userId },
        select: { locationId: true }
      })
    ).map((c) => c.locationId)
  );

  // Ensure all locations have area in database
  const areaMap = await batchEnsureLocationAreas(
    locations.map((loc) => ({
      id: loc.id,
      latitude: loc.latitude,
      longitude: loc.longitude,
      area: loc.area
    }))
  );

  const locationsWithStatus = locations.map((loc) => {
    const isCollected = collectedLocationIds.has(loc.id);
    const collection = loc.userLocationCollections[0];
    const area = areaMap.get(loc.id) || null;

    return {
      id: loc.id,
      name: loc.name,
      latitude: loc.latitude,
      longitude: loc.longitude,
      description: loc.description,
      nfcId: loc.nfcId,
      isNfcEnabled: loc.isNfcEnabled,
      area,
      createdAt: loc.createdAt,
      updatedAt: loc.updatedAt,
      isCollected,
      collectedAt: collection?.collectedAt || null
    };
  });

  return {
    success: true,
    count: locationsWithStatus.length,
    data: {
      locations: locationsWithStatus
    }
  };
};

/**
 * Enable NFC for a location
 * Sets isNfcEnabled to true and automatically generates an NFC ID if not already set
 * NFC ID format: nfc-001, nfc-002, etc.
 * @param locationId - Location ID
 * @returns Updated location with NFC enabled and NFC ID set
 */
const enableNfc = async (locationId: string): Promise<LocationEnableNfcResponse> => {
  // Check if location exists
  const existingLocation = await prisma.location.findUnique({
    where: { id: locationId }
  });

  if (!existingLocation) {
    throw new ApiError(ErrorCodes.NOT_FOUND, "Location not found", 404);
  }

  // If location already has an NFC ID, just enable NFC
  if (existingLocation.nfcId) {
    const location = await prisma.location.update({
      where: { id: locationId },
      data: {
        isNfcEnabled: true
      }
    });

    return {
      success: true,
      data: {
        id: location.id,
        name: location.name,
        latitude: location.latitude,
        longitude: location.longitude,
        description: location.description,
        nfcId: location.nfcId,
        isNfcEnabled: location.isNfcEnabled,
        area: location.area,
        createdAt: location.createdAt,
        updatedAt: location.updatedAt
      }
    };
  }

  // Generate a new NFC ID in format nfc-001, nfc-002, etc.
  // Find the highest existing NFC ID number
  const locationsWithNfcId = await prisma.location.findMany({
    where: {
      nfcId: {
        not: null,
        startsWith: "nfc-"
      }
    },
    select: {
      nfcId: true
    }
  });

  // Extract numbers from existing NFC IDs and find the maximum
  let maxNumber = 0;
  for (const loc of locationsWithNfcId) {
    if (loc.nfcId) {
      const match = loc.nfcId.match(/^nfc-(\d+)$/);
      if (match) {
        const number = parseInt(match[1], 10);
        if (number > maxNumber) {
          maxNumber = number;
        }
      }
    }
  }

  // Generate next NFC ID
  const nextNumber = maxNumber + 1;
  const newNfcId = `nfc-${String(nextNumber).padStart(3, "0")}`;

  // Update location to enable NFC and set NFC ID
  const location = await prisma.location.update({
    where: { id: locationId },
    data: {
      isNfcEnabled: true,
      nfcId: newNfcId
    }
  });

  return {
    success: true,
    data: {
      id: location.id,
      name: location.name,
      latitude: location.latitude,
      longitude: location.longitude,
      description: location.description,
      nfcId: location.nfcId,
      isNfcEnabled: location.isNfcEnabled,
      area: location.area,
      createdAt: location.createdAt,
      updatedAt: location.updatedAt
    }
  };
};

export const locationsService = {
  getLocations,
  createLocation,
  updateLocation,
  deleteLocation,
  getUserMap,
  enableNfc
};

