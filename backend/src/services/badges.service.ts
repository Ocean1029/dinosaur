import { UserBadgeStatus } from "@prisma/client";

import type {
  BadgeCreateInput,
  BadgeDeleteResponse,
  BadgeDetailResponse,
  BadgeEvaluationResult,
  BadgeListQuery,
  BadgeListResponse,
  BadgeSummary,
  BadgeUpdateInput,
  UserBadgeDetail,
  UserBadgeDetailResponse,
  UserBadgeListQuery,
  UserBadgeListResponse,
  UserBadgeSummary,
  UserBadgeStatusValue
} from "../types/badges.types.js";
import { prisma } from "../utils/prismaClient.js";
import { ApiError, ErrorCodes } from "../utils/errors.js";

/**
 * Helper to map Prisma badge entity to API summary format
 */
const mapBadgeToSummary = (badge: {
  id: string;
  name: string;
  description: string | null;
  imageUrl: string | null;
  color: string | null;
  createdAt: Date;
  updatedAt: Date;
  badgeLocationRequirements: Array<{
    locationId: string;
    location?: {
      area: string | null;
    } | null;
  }>;
}): BadgeSummary => {
  const requiredLocationIds = badge.badgeLocationRequirements.map((req) => req.locationId);
  const areaCandidates = badge.badgeLocationRequirements
    .map((req) => req.location?.area ?? null)
    .filter((value): value is string => Boolean(value));
  const uniqueAreas = Array.from(new Set(areaCandidates));
  const area = uniqueAreas.length === 1 ? uniqueAreas[0] : null;

  return {
    id: badge.id,
    name: badge.name,
    description: badge.description,
    imageUrl: badge.imageUrl,
    color: badge.color,
    area,
    totalLocations: badge.badgeLocationRequirements.length,
    requiredLocationIds,
    createdAt: badge.createdAt,
    updatedAt: badge.updatedAt
  };
};

const toPrismaStatus = (status: UserBadgeStatusValue): UserBadgeStatus => {
  switch (status) {
    case "collected":
      return UserBadgeStatus.Collected;
    case "in_progress":
      return UserBadgeStatus.InProgress;
    default:
      return UserBadgeStatus.Locked;
  }
};

const toApiStatus = (status: UserBadgeStatus | null | undefined): UserBadgeStatusValue => {
  switch (status) {
    case UserBadgeStatus.Collected:
      return "collected";
    case UserBadgeStatus.InProgress:
      return "in_progress";
    default:
      return "locked";
  }
};

const normalizePercentage = (collected: number, total: number): number => {
  if (total === 0) {
    return 100;
  }

  return Math.min(100, Math.round((collected / total) * 100));
};

const assertLocationsExist = async (locationIds: string[]): Promise<void> => {
  const uniqueIds = Array.from(new Set(locationIds));

  const locations = await prisma.location.findMany({
    where: {
      id: {
        in: uniqueIds
      }
    },
    select: {
      id: true
    }
  });

  const foundIds = new Set(locations.map((location) => location.id));
  const missingIds = uniqueIds.filter((id) => !foundIds.has(id));

  if (missingIds.length > 0) {
    throw new ApiError(
      ErrorCodes.INVALID_REQUEST,
      `Some locations do not exist: ${missingIds.join(", ")}`
    );
  }
};

const getBadges = async (query?: BadgeListQuery): Promise<BadgeListResponse> => {
  const { search, page, limit } = query ?? {};
  const pageNumber = page && page > 0 ? page : 1;
  const pageSize = limit && limit > 0 && limit <= 100 ? limit : undefined;
  const skip = pageSize ? (pageNumber - 1) * pageSize : undefined;

  const whereClause = search
    ? {
        name: {
          contains: search,
          mode: "insensitive" as const
        }
      }
    : undefined;

  const [badges, totalCount] = await Promise.all([
    prisma.badge.findMany({
      where: whereClause,
      include: {
        badgeLocationRequirements: {
          include: {
            location: {
              select: {
                area: true
              }
            }
          }
        }
      },
      orderBy: {
        createdAt: "desc"
      },
      skip,
      take: pageSize
    }),
    prisma.badge.count({ where: whereClause })
  ]);

  return {
    success: true,
    count: totalCount,
    data: badges.map(mapBadgeToSummary)
  };
};

const createBadge = async (input: BadgeCreateInput): Promise<BadgeDetailResponse> => {
  const requiredLocationIds = Array.from(new Set(input.requiredLocationIds));

  await assertLocationsExist(requiredLocationIds);

  const badge = await prisma.badge.create({
    data: {
      name: input.name,
      description: input.description ?? null,
      imageUrl: input.imageUrl ?? null,
      color: input.color ?? null,
      badgeLocationRequirements: {
        createMany: {
          data: requiredLocationIds.map((locationId) => ({
            locationId
          }))
        }
      }
    },
    include: {
      badgeLocationRequirements: {
        include: {
          location: {
            select: {
              area: true
            }
          }
        }
      }
    }
  });

  return {
    success: true,
    data: mapBadgeToSummary(badge)
  };
};

const updateBadge = async (
  badgeId: string,
  input: BadgeUpdateInput
): Promise<BadgeDetailResponse> => {
  const existingBadge = await prisma.badge.findUnique({
    where: { id: badgeId },
    include: {
      badgeLocationRequirements: true
    }
  });

  if (!existingBadge) {
    throw new ApiError(ErrorCodes.NOT_FOUND, "Badge not found", 404);
  }

  const { requiredLocationIds, ...rest } = input;

  if (requiredLocationIds) {
    await assertLocationsExist(requiredLocationIds);
  }

  const updateData = {
    ...(rest.name !== undefined && { name: rest.name }),
    ...(rest.description !== undefined && { description: rest.description ?? null }),
    ...(rest.imageUrl !== undefined && { imageUrl: rest.imageUrl ?? null }),
    ...(rest.color !== undefined && { color: rest.color ?? null })
  };

  await prisma.$transaction(async (tx) => {
    if (Object.keys(updateData).length > 0) {
      await tx.badge.update({
        where: { id: badgeId },
        data: updateData
      });
    }

    if (requiredLocationIds) {
      await tx.badgeLocationRequirement.deleteMany({
        where: {
          badgeId
        }
      });

      const uniqueIds = Array.from(new Set(requiredLocationIds));
      await tx.badgeLocationRequirement.createMany({
        data: uniqueIds.map((locationId) => ({
          badgeId,
          locationId
        }))
      });
    }
  });

  const updatedBadge = await prisma.badge.findUnique({
    where: { id: badgeId },
    include: {
      badgeLocationRequirements: {
        include: {
          location: {
            select: {
              area: true
            }
          }
        }
      }
    }
  });

  if (!updatedBadge) {
    throw new ApiError(ErrorCodes.SERVER_ERROR, "Failed to retrieve updated badge", 500);
  }

  return {
    success: true,
    data: mapBadgeToSummary(updatedBadge)
  };
};

const deleteBadge = async (badgeId: string): Promise<BadgeDeleteResponse> => {
  try {
    await prisma.badge.delete({
      where: { id: badgeId }
    });
  } catch (error) {
    throw new ApiError(ErrorCodes.NOT_FOUND, "Badge not found", 404);
  }

  return {
    success: true,
    message: "徽章已成功刪除"
  };
};

const getUserBadges = async (
  query: UserBadgeListQuery
): Promise<UserBadgeListResponse> => {
  const { userId, status } = query;

  const user = await prisma.user.findUnique({
    where: { id: userId }
  });

  if (!user) {
    throw new ApiError(ErrorCodes.NOT_FOUND, "User not found", 404);
  }

  const [badges, userBadgeRecords, userCollections] = await Promise.all([
    prisma.badge.findMany({
      include: {
        badgeLocationRequirements: {
          include: {
            location: {
              select: {
                area: true
              }
            }
          }
        }
      },
      orderBy: {
        createdAt: "asc"
      }
    }),
    prisma.userBadge.findMany({
      where: { userId }
    }),
    prisma.userLocationCollection.findMany({
      where: { userId },
      select: {
        locationId: true
      }
    })
  ]);

  const userBadgeMap = new Map(
    userBadgeRecords.map((record) => [record.badgeId, record])
  );
  const collectedLocationIds = new Set(
    userCollections.map((collection) => collection.locationId)
  );

  // 調試：記錄從數據庫查詢到的徽章顏色
  console.log('========== 數據庫徽章顏色檢查 ==========');
  badges.forEach((badge, index) => {
    console.log(`徽章[${index}]: ${badge.name} - color: ${badge.color} (類型: ${typeof badge.color})`);
  });
  console.log('========================================');

  const badgeSummaries: UserBadgeSummary[] = badges.map((badge) => {
    const areaCandidates = badge.badgeLocationRequirements
      .map((req) => req.location?.area ?? null)
      .filter((value): value is string => Boolean(value));
    const uniqueAreas = Array.from(new Set(areaCandidates));
    const area = uniqueAreas.length === 1 ? uniqueAreas[0] : null;

    const total = badge.badgeLocationRequirements.length;
    const collected = badge.badgeLocationRequirements.filter((req) =>
      collectedLocationIds.has(req.locationId)
    ).length;
    const percentage = normalizePercentage(collected, total);

    let finalStatus: UserBadgeStatusValue;
    if (total === 0 || collected >= total) {
      finalStatus = "collected";
    } else if (collected > 0) {
      finalStatus = "in_progress";
    } else {
      finalStatus = "locked";
    }

    const existingRecord = userBadgeMap.get(badge.id);
    const unlockedAt = existingRecord?.unlockedAt ?? null;

    const apiStatus =
      finalStatus === "collected"
        ? "collected"
        : finalStatus === "in_progress"
        ? "in_progress"
        : "locked";

    const badgeSummary = {
      badgeId: badge.id,
      name: badge.name,
      description: badge.description,
      imageUrl: badge.imageUrl,
      color: badge.color,
      area,
      totalLocations: total,
      status: apiStatus,
      unlockedAt,
      progress: {
        collected,
        total,
        percentage
      }
    };
    
    // 調試：記錄徽章顏色資訊
    if (badge.name === '溫室雜草' || badge.name.includes('溫室')) {
      console.log('========== 徽章顏色調試 ==========');
      console.log(`徽章名稱: ${badge.name}`);
      console.log(`數據庫中的 color: ${badge.color}`);
      console.log(`返回的 color: ${badgeSummary.color}`);
      console.log(`完整 badge 對象:`, JSON.stringify(badge, null, 2));
      console.log('================================');
    }
    
    return badgeSummary;
  });

  const filteredBadges = status
    ? badgeSummaries.filter((badge) => badge.status === status)
    : badgeSummaries;

  const collectedCount = badgeSummaries.filter(
    (badge) => badge.status === "collected"
  ).length;
  const inProgressCount = badgeSummaries.filter(
    (badge) => badge.status === "in_progress"
  ).length;
  const lockedCount = badgeSummaries.filter(
    (badge) => badge.status === "locked"
  ).length;

  return {
    success: true,
    data: {
      totalBadges: badgeSummaries.length,
      collectedCount,
      inProgressCount,
      lockedCount,
      badges: filteredBadges
    }
  };
};

const getUserBadgeDetail = async (
  userId: string,
  badgeId: string
): Promise<UserBadgeDetailResponse> => {
  const [user, badge, userCollections, userBadgeRecord] = await Promise.all([
    prisma.user.findUnique({
      where: { id: userId }
    }),
    prisma.badge.findUnique({
      where: { id: badgeId },
      include: {
        badgeLocationRequirements: {
          include: {
            location: true
          }
        }
      }
    }),
    prisma.userLocationCollection.findMany({
      where: { userId },
      select: {
        locationId: true,
        collectedAt: true
      }
    }),
    prisma.userBadge.findUnique({
      where: {
        userId_badgeId: {
          userId,
          badgeId
        }
      }
    })
  ]);

  if (!user) {
    throw new ApiError(ErrorCodes.NOT_FOUND, "User not found", 404);
  }

  if (!badge) {
    throw new ApiError(ErrorCodes.NOT_FOUND, "Badge not found", 404);
  }

  const collectionMap = new Map(
    userCollections.map((collection) => [collection.locationId, collection.collectedAt])
  );

  const total = badge.badgeLocationRequirements.length;
  const collected = badge.badgeLocationRequirements.filter((req) =>
    collectionMap.has(req.locationId)
  ).length;
  const percentage = normalizePercentage(collected, total);

  let status: UserBadgeStatusValue;
  if (total === 0 || collected >= total) {
    status = "collected";
  } else if (collected > 0) {
    status = "in_progress";
  } else {
    status = "locked";
  }

  const requiredLocations = badge.badgeLocationRequirements.map((req) => {
    const location = req.location;
    return {
      locationId: req.locationId,
      name: location?.name ?? "Unknown location",
      latitude: location?.latitude ?? 0,
      longitude: location?.longitude ?? 0,
      area: location?.area ?? null,
      isCollected: collectionMap.has(req.locationId),
      collectedAt: collectionMap.get(req.locationId) ?? null
    };
  });

  const detail: UserBadgeDetail = {
    badgeId: badge.id,
    name: badge.name,
    description: badge.description,
    imageUrl: badge.imageUrl,
    color: badge.color,
    area: (() => {
      const candidates = badge.badgeLocationRequirements
        .map((req) => req.location?.area ?? null)
        .filter((value): value is string => Boolean(value));
      const areas = Array.from(new Set(candidates));
      return areas.length === 1 ? areas[0] : null;
    })(),
    totalLocations: total,
    status,
    unlockedAt: userBadgeRecord?.unlockedAt ?? null,
    progress: {
      collected,
      total,
      percentage
    },
    requiredLocations
  };

  return {
    success: true,
    data: detail
  };
};

const evaluateUserBadges = async (userId: string): Promise<BadgeEvaluationResult> => {
  const [badges, userCollections, existingRecords] = await Promise.all([
    prisma.badge.findMany({
      include: {
        badgeLocationRequirements: true
      }
    }),
    prisma.userLocationCollection.findMany({
      where: { userId },
      select: {
        locationId: true,
        collectedAt: true
      }
    }),
    prisma.userBadge.findMany({
      where: { userId }
    })
  ]);

  const collectedLocationSet = new Set(
    userCollections.map((collection) => collection.locationId)
  );
  const userBadgeMap = new Map(
    existingRecords.map((record) => [record.badgeId, record])
  );

  const newBadges: BadgeEvaluationResult["newBadges"] = [];
  const operations: Array<ReturnType<typeof prisma.userBadge.create>> = [];

  for (const badge of badges) {
    const total = badge.badgeLocationRequirements.length;
    const collected = badge.badgeLocationRequirements.filter((req) =>
      collectedLocationSet.has(req.locationId)
    ).length;

    let status: UserBadgeStatusValue;
    if (total === 0 || collected >= total) {
      status = "collected";
    } else if (collected > 0) {
      status = "in_progress";
    } else {
      status = "locked";
    }

    const prismaStatus = toPrismaStatus(status);
    const existingRecord = userBadgeMap.get(badge.id);
    const isNewlyCollected =
      status === "collected" &&
      (!existingRecord || existingRecord.status !== UserBadgeStatus.Collected);

    let targetUnlockedAt: Date | null = null;
    if (prismaStatus === UserBadgeStatus.Collected) {
      targetUnlockedAt = existingRecord?.unlockedAt ?? new Date();
    }

    if (existingRecord) {
      const shouldUpdate =
        existingRecord.status !== prismaStatus ||
        (prismaStatus === UserBadgeStatus.Collected &&
          !existingRecord.unlockedAt &&
          targetUnlockedAt !== null) ||
        (prismaStatus !== UserBadgeStatus.Collected && existingRecord.unlockedAt !== null);

      if (shouldUpdate) {
        operations.push(
          prisma.userBadge.update({
            where: { id: existingRecord.id },
            data: {
              status: prismaStatus,
              unlockedAt: prismaStatus === UserBadgeStatus.Collected ? targetUnlockedAt : null
            }
          })
        );
      }
    } else {
      operations.push(
        prisma.userBadge.create({
          data: {
            userId,
            badgeId: badge.id,
            status: prismaStatus,
            unlockedAt: prismaStatus === UserBadgeStatus.Collected ? targetUnlockedAt : null
          }
        })
      );
    }

    if (isNewlyCollected && targetUnlockedAt) {
      newBadges.push({
        badgeId: badge.id,
        name: badge.name,
        imageUrl: badge.imageUrl,
        color: badge.color,
        unlockedAt: targetUnlockedAt
      });
    }
  }

  if (operations.length > 0) {
    await prisma.$transaction(operations);
  }

  return {
    newBadges
  };
};

export const badgesService = {
  getBadges,
  createBadge,
  updateBadge,
  deleteBadge,
  getUserBadges,
  getUserBadgeDetail,
  evaluateUserBadges
};


