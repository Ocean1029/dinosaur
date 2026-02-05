/**
 * Type definitions for Badges module
 */

export type BadgeSummary = {
  id: string;
  name: string;
  description: string | null;
  imageUrl: string | null;
  color: string | null;
  area: string | null;
  totalLocations: number;
  requiredLocationIds: string[];
  createdAt: Date;
  updatedAt: Date;
};

export type BadgeListQuery = {
  search?: string;
  page?: number;
  limit?: number;
};

export type BadgeCreateInput = {
  name: string;
  description?: string;
  imageUrl?: string;
  color?: string;
  requiredLocationIds: string[];
};

export type BadgeUpdateInput = {
  name?: string;
  description?: string;
  imageUrl?: string;
  color?: string;
  requiredLocationIds?: string[];
};

export type BadgeListResponse = {
  success: true;
  count: number;
  data: BadgeSummary[];
};

export type BadgeDetailResponse = {
  success: true;
  data: BadgeSummary;
};

export type BadgeDeleteResponse = {
  success: true;
  message: string;
};

export type BadgeRequirementDetail = {
  locationId: string;
  name: string;
  latitude: number;
  longitude: number;
  area: string | null;
  isCollected?: boolean;
  collectedAt?: Date | null;
};

export type UserBadgeStatusValue = "locked" | "in_progress" | "collected";

export type UserBadgeProgress = {
  collected: number;
  total: number;
  percentage: number;
};

export type UserBadgeSummary = {
  badgeId: string;
  name: string;
  description: string | null;
  imageUrl: string | null;
  color: string | null;
  area: string | null;
  totalLocations: number;
  status: UserBadgeStatusValue;
  unlockedAt: Date | null;
  progress: UserBadgeProgress;
};

export type UserBadgeDetail = UserBadgeSummary & {
  requiredLocations: BadgeRequirementDetail[];
};

export type UserBadgeListQuery = {
  userId: string;
  status?: UserBadgeStatusValue;
};

export type UserBadgeListResponse = {
  success: true;
  data: {
    totalBadges: number;
    collectedCount: number;
    inProgressCount: number;
    lockedCount: number;
    badges: UserBadgeSummary[];
  };
};

export type UserBadgeDetailResponse = {
  success: true;
  data: UserBadgeDetail;
};

export type BadgeEvaluationResult = {
  newBadges: Array<{
    badgeId: string;
    name: string;
    imageUrl: string | null;
    color: string | null;
    unlockedAt: Date;
  }>;
};


