/**
 * Type definitions for Activities module
 */

export type ActivityStartInput = {
  startTime: string; // ISO 8601 format
  startLocation: {
    latitude: number;
    longitude: number;
  };
};

export type ActivityTrackInput = {
  points: Array<{
    latitude: number;
    longitude: number;
    timestamp: string; // ISO 8601 format
    accuracy?: number;
  }>;
};

export type ActivityEndInput = {
  endTime: string; // ISO 8601 format
  endLocation: {
    latitude: number;
    longitude: number;
  };
};

export type ActivityStartResponse = {
  success: true;
  data: {
    activityId: string;
    startTime: string;
    status: "in_progress";
  };
};

export type ActivityTrackResponse = {
  success: true;
  message: string;
  data: {
    pointsAdded: number;
    totalPoints: number;
  };
};

export type CollectedLocation = {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  area: string | null;
  coinsEarned: number;
};

export type ActivityNewBadge = {
  badgeId: string;
  name: string;
  imageUrl: string | null;
  unlockedAt: string;
};

export type ActivityEndResponse = {
  success: true;
  data: {
    activityId: string;
    startTime: string;
    endTime: string;
    distance: number;
    duration: number;
    averageSpeed: number;
    route: Array<{
      latitude: number;
      longitude: number;
      timestamp: string;
    }>;
    collectedLocations: CollectedLocation[];
    totalCoinsEarned: number;
    newBadges: ActivityNewBadge[];
  };
};

export type ActivityListItem = {
  activityId: string;
  date: string;
  distance: number;
  duration: number;
  averageSpeed: number;
  coinsEarned: number;
  collectedLocationsCount: number;
};

export type ActivityListQuery = {
  userId: string;
  page?: number;
  limit?: number;
  startDate?: string;
  endDate?: string;
};

export type ActivityListResponse = {
  success: true;
  data: {
    activities: ActivityListItem[];
    pagination: {
      currentPage: number;
      totalPages: number;
      totalRecords: number;
      limit: number;
    };
  };
};

export type ActivityDetailResponse = {
  success: true;
  data: {
    activityId: string;
    startTime: string;
    endTime: string;
    distance: number;
    duration: number;
    averageSpeed: number;
    route: Array<{
      latitude: number;
      longitude: number;
      timestamp: string;
    }>;
    collectedLocations: Array<{
      id: string;
      name: string;
      latitude: number;
      longitude: number;
      area: string | null;
      collectedAt: string;
    }>;
    coinsEarned: number;
  };
};

export type ActivityNfcCollectInput = {
  nfcId: string;
};

export type ActivityNfcCollectResponse = {
  success: true;
  data: {
    locationId: string;
    name: string;
    area: string | null;
    coinsEarned: number;
    totalCoins: number;
    isFirstCollection: boolean;
    badgeUnlocked: ActivityNewBadge | null;
  };
};

