import { readFileSync } from "fs";
import { join } from "path";

import { PrismaClient, UserBadgeStatus } from "@prisma/client";

// Fix DATABASE_URL for local execution (replace 'db:5432' with 'localhost:5432')
// This allows the seed script to work both locally and inside Docker containers
if (process.env.DATABASE_URL && process.env.DATABASE_URL.includes("db:")) {
  // Replace db:5432 with localhost:5432 (the mapped port in docker-compose)
  process.env.DATABASE_URL = process.env.DATABASE_URL.replace("db:5432", "localhost:5432");
}

const prisma = new PrismaClient();

// Interface for location data from JSON file
interface LocationData {
  name: string;
  latitude: number;
  longitude: number;
  description: string;
  isNFCEnabled: boolean;
  nfcId: string | null;
}

// Helper function to generate random date within a range
const randomDate = (start: Date, end: Date): Date => {
  return new Date(
    start.getTime() + Math.random() * (end.getTime() - start.getTime())
  );
};

// Helper function to shuffle array
const shuffle = <T>(array: T[]): T[] => {
  const shuffled = [...array];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
};

// Helper function to calculate distance between two coordinates (Haversine formula)
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

const seed = async () => {
  console.log("Starting seed process...");

  // Clear existing data
  console.log("Clearing existing data...");
  await prisma.userBadge.deleteMany();
  await prisma.badgeLocationRequirement.deleteMany();
  await prisma.badge.deleteMany();
  await prisma.activityCollectedLocation.deleteMany();
  await prisma.activityTrackPoint.deleteMany();
  await prisma.activity.deleteMany();
  await prisma.userLocationCollection.deleteMany();
  await prisma.location.deleteMany();
  await prisma.user.deleteMany();

  // Load locations from JSON file
  console.log("Loading locations from JSON file...");
  // Try multiple possible paths for locations.json
  const possiblePaths = [
    join(process.cwd(), "..", "data", "locations.json"), // If running from backend/
    join(process.cwd(), "data", "locations.json"), // If running from project root
  ];
  
  let locationsPath: string | null = null;
  for (const path of possiblePaths) {
    try {
      readFileSync(path, "utf-8");
      locationsPath = path;
      break;
    } catch {
      // Continue to next path
    }
  }
  
  if (!locationsPath) {
    throw new Error(
      `Could not find locations.json. Tried paths: ${possiblePaths.join(", ")}`
    );
  }
  
  const locationsData: LocationData[] = JSON.parse(
    readFileSync(locationsPath, "utf-8")
  );

  // Create locations
  console.log(`Creating ${locationsData.length} locations...`);
  const locations = await Promise.all(
    locationsData.map((loc) =>
      prisma.location.create({
        data: {
          name: loc.name,
          description: loc.description || null,
          latitude: loc.latitude,
          longitude: loc.longitude,
          nfcId: loc.nfcId || null,
          isNfcEnabled: false, // All locations have NFC disabled as per requirement
        },
      })
    )
  );
  console.log(`Created ${locations.length} locations`);

  // Create users
  console.log("Creating users...");
  // Create the specific user from frontend mock data first
  const frontendUser = await prisma.user.upsert({
    where: { id: "7f3562f4-bb3f-4ec7-89b9-da3b4b5ff250" },
    update: {
      avatarUrl: "https://api.dicebear.com/7.x/avataaars/svg?seed=Wesley",
    },
    create: {
      id: "7f3562f4-bb3f-4ec7-89b9-da3b4b5ff250",
      name: "金大森",
      email: "ist83903@bcaoo.com",
      avatarUrl: "https://api.dicebear.com/7.x/avataaars/svg?seed=Wesley",
    },
  });
  
  const userNames = [
    "Alice Chen",
    "Bob Wang",
    "Carol Lin",
    "David Liu",
    "Emma Zhang",
    "Frank Huang",
    "Grace Wu",
    "Henry Chen",
  ];
  const baseUsers = await Promise.all(
    userNames.map((name, index) =>
      prisma.user.create({
        data: {
          name,
          email: `user${index + 1}@example.com`,
          avatarUrl: `https://api.dicebear.com/7.x/avataaars/svg?seed=${name}`,
        },
      })
    )
  );
  const users = [frontendUser, ...baseUsers];
  console.log(`Created ${users.length} users`);

  // Create user location collections
  console.log("Creating user location collections...");
  let collectionCount = 0;
  for (const user of users) {
    // Each user collects 10-30 random locations
    const numCollections = Math.floor(Math.random() * 21) + 10;
    const shuffledLocations = shuffle(locations);
    const userLocations = shuffledLocations.slice(0, numCollections);

    const collections = await Promise.all(
      userLocations.map((location) =>
        prisma.userLocationCollection.create({
          data: {
            userId: user.id,
            locationId: location.id,
            collectedAt: randomDate(
              new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // 30 days ago
              new Date()
            ),
          },
        })
      )
    );
    collectionCount += collections.length;
  }
  console.log(`Created ${collectionCount} user location collections`);

  // Create activities
  console.log("Creating activities...");
  const activities = [];
  for (const user of users) {
    // Each user has 3-5 activities
    const numActivities = Math.floor(Math.random() * 3) + 3;
    const userCollections = await prisma.userLocationCollection.findMany({
      where: { userId: user.id },
      include: { location: true },
    });

    for (let i = 0; i < numActivities; i++) {
      const startTime = randomDate(
        new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
        new Date()
      );
      const duration = Math.floor(Math.random() * 3600) + 1800; // 30-90 minutes in seconds
      const endTime = new Date(startTime.getTime() + duration * 1000);

      // Select 2-5 locations for this activity
      const activityLocations = shuffle(userCollections).slice(
        0,
        Math.floor(Math.random() * 4) + 2
      );

      // Calculate total distance based on locations
      let totalDistance = 0;
      for (let j = 0; j < activityLocations.length - 1; j++) {
        const loc1 = activityLocations[j].location;
        const loc2 = activityLocations[j + 1].location;
        totalDistance += calculateDistance(
          loc1.latitude,
          loc1.longitude,
          loc2.latitude,
          loc2.longitude
        );
      }

      const averageSpeed = totalDistance / (duration / 3600); // km/h
      const totalCoins = activityLocations.length * (Math.floor(Math.random() * 3) + 1);

      const activity = await prisma.activity.create({
        data: {
          userId: user.id,
          startTime,
          endTime,
          distance: totalDistance,
          duration,
          averageSpeed,
          totalCoins,
        },
      });
      activities.push(activity);

      // Create track points for this activity
      const numTrackPoints = Math.floor(Math.random() * 31) + 20; // 20-50 points
      const trackPoints = [];
      for (let j = 0; j < numTrackPoints; j++) {
        const progress = j / (numTrackPoints - 1);
        const pointTime = new Date(
          startTime.getTime() + progress * duration * 1000
        );

        // Interpolate between activity locations
        const segmentIndex = Math.floor(
          progress * (activityLocations.length - 1)
        );
        const segmentProgress =
          (progress * (activityLocations.length - 1)) % 1;
        const loc1 = activityLocations[segmentIndex].location;
        const loc2 =
          activityLocations[Math.min(segmentIndex + 1, activityLocations.length - 1)]
            .location;

        const lat =
          loc1.latitude +
          (loc2.latitude - loc1.latitude) * segmentProgress +
          (Math.random() - 0.5) * 0.001; // Add small random variation
        const lon =
          loc1.longitude +
          (loc2.longitude - loc1.longitude) * segmentProgress +
          (Math.random() - 0.5) * 0.001;

        trackPoints.push({
          activityId: activity.id,
          latitude: lat,
          longitude: lon,
          timestamp: pointTime,
          accuracy: Math.random() * 10 + 5, // 5-15 meters
        });
      }

      await prisma.activityTrackPoint.createMany({
        data: trackPoints,
      });

      // Create activity collected locations
      const collectedLocations = activityLocations.map((collection, idx) => ({
        activityId: activity.id,
        locationId: collection.locationId,
        collectedAt: new Date(
          startTime.getTime() + (idx / activityLocations.length) * duration * 1000
        ),
        coinsEarned: Math.floor(Math.random() * 3) + 1,
      }));

      await prisma.activityCollectedLocation.createMany({
        data: collectedLocations,
      });
    }
  }
  console.log(`Created ${activities.length} activities`);

  // Create badges
  console.log("Creating badges...");
  const badgeData = [
    {
      name: "NTU Explorer",
      description: "Collect all locations in National Taiwan University area",
      imageUrl: "https://example.com/badges/ntu-explorer.png",
    },
    {
      name: "Night Market Master",
      description: "Visit all major night markets in Taipei",
      imageUrl: "https://example.com/badges/night-market-master.png",
    },
    {
      name: "Mountain Hiker",
      description: "Complete all hiking trails in Taipei",
      imageUrl: "https://example.com/badges/mountain-hiker.png",
    },
    {
      name: "Temple Pilgrim",
      description: "Visit all temples and religious sites",
      imageUrl: "https://example.com/badges/temple-pilgrim.png",
    },
    {
      name: "Museum Enthusiast",
      description: "Explore all museums and cultural sites",
      imageUrl: "https://example.com/badges/museum-enthusiast.png",
    },
    {
      name: "Park Wanderer",
      description: "Visit all parks and green spaces",
      imageUrl: "https://example.com/badges/park-wanderer.png",
    },
    {
      name: "Historic Sites Collector",
      description: "Discover all historic landmarks",
      imageUrl: "https://example.com/badges/historic-sites-collector.png",
    },
    {
      name: "Complete Explorer",
      description: "Collect all locations in the system",
      imageUrl: "https://example.com/badges/complete-explorer.png",
    },
  ];

  // 定義徽章顏色（循環使用4種顏色）
  const badgeColors = [
    '#76a732', // 綠色
    '#F5BA4B', // 黃色
    '#FD853A', // 橙色
    '#5ab4c5', // 青色
  ];

  const badges = await Promise.all(
    badgeData.map((badge, index) =>
      prisma.badge.create({
        data: {
          name: badge.name,
          description: badge.description,
          imageUrl: badge.imageUrl,
          color: badgeColors[index % badgeColors.length], // 循環分配顏色
        },
      })
    )
  );
  console.log(`Created ${badges.length} badges`);

  // Create badge location requirements
  console.log("Creating badge location requirements...");
  const ntuLocations = locations.filter((loc) =>
    loc.name.includes("國立臺灣大學") || loc.name.includes("台大")
  );
  const nightMarketLocations = locations.filter((loc) =>
    loc.name.includes("夜市")
  );
  const hikingLocations = locations.filter((loc) =>
    loc.name.includes("步道") || loc.name.includes("山")
  );
  const templeLocations = locations.filter((loc) =>
    loc.name.includes("寺") || loc.name.includes("廟") || loc.name.includes("宮")
  );
  const museumLocations = locations.filter((loc) =>
    loc.name.includes("博物館") || loc.name.includes("美術館") || loc.name.includes("館")
  );
  const parkLocations = locations.filter((loc) =>
    loc.name.includes("公園") || loc.name.includes("園區")
  );
  const historicLocations = locations.filter((loc) =>
    loc.name.includes("古蹟") ||
    loc.name.includes("紀念") ||
    loc.name.includes("歷史")
  );

  const badgeRequirements = [
    { badge: badges[0], locations: ntuLocations.slice(0, 5) }, // NTU Explorer
    { badge: badges[1], locations: nightMarketLocations.slice(0, 5) }, // Night Market Master
    { badge: badges[2], locations: hikingLocations.slice(0, 5) }, // Mountain Hiker
    { badge: badges[3], locations: templeLocations.slice(0, 5) }, // Temple Pilgrim
    { badge: badges[4], locations: museumLocations.slice(0, 5) }, // Museum Enthusiast
    { badge: badges[5], locations: parkLocations.slice(0, 5) }, // Park Wanderer
    { badge: badges[6], locations: historicLocations.slice(0, 5) }, // Historic Sites Collector
    { badge: badges[7], locations: locations.slice(0, 10) }, // Complete Explorer
  ];

  let requirementCount = 0;
  for (const requirement of badgeRequirements) {
    const requirements = await Promise.all(
      requirement.locations.map((location) =>
        prisma.badgeLocationRequirement.create({
          data: {
            badgeId: requirement.badge.id,
            locationId: location.id,
          },
        })
      )
    );
    requirementCount += requirements.length;
  }
  console.log(`Created ${requirementCount} badge location requirements`);

  // Create user badges
  console.log("Creating user badges...");
  let userBadgeCount = 0;
  for (const user of users) {
    const userCollections = await prisma.userLocationCollection.findMany({
      where: { userId: user.id },
      select: { locationId: true },
    });
    const collectedLocationIds = new Set(
      userCollections.map((c) => c.locationId)
    );

    for (const badge of badges) {
      const requirements = await prisma.badgeLocationRequirement.findMany({
        where: { badgeId: badge.id },
        select: { locationId: true },
      });

      const collectedRequirements = requirements.filter((req) =>
        collectedLocationIds.has(req.locationId)
      );
      const progress =
        requirements.length > 0
          ? collectedRequirements.length / requirements.length
          : 0;

      let status: UserBadgeStatus;
      let unlockedAt: Date | null = null;

      if (progress === 0) {
        status = UserBadgeStatus.Locked;
      } else if (progress === 1) {
        status = UserBadgeStatus.Collected;
        unlockedAt = randomDate(
          new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
          new Date()
        );
      } else {
        status = UserBadgeStatus.InProgress;
      }

      await prisma.userBadge.create({
        data: {
          userId: user.id,
          badgeId: badge.id,
          status,
          unlockedAt,
        },
      });
      userBadgeCount++;
    }
  }
  console.log(`Created ${userBadgeCount} user badges`);

  console.log("Seed completed successfully!");
};

seed()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error("Seeding failed", error);
    await prisma.$disconnect();
    process.exit(1);
  });