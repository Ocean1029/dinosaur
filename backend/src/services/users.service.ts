import type {
  UserListQuery,
  UserListResponse,
  UserProfileResponse
} from "../types/users.types.js";
import { prisma } from "../utils/prismaClient.js";

/**
 * Service layer for User Profile module
 * Handles all business logic related to user profile and statistics
 */

const getUsers = async (query: UserListQuery): Promise<UserListResponse> => {
  const { page = 1, limit = 100 } = query;
  const skip = (page - 1) * limit;

  const [users, totalCount] = await Promise.all([
    prisma.user.findMany({
      skip,
      take: limit,
      orderBy: {
        createdAt: "desc"
      },
      select: {
        id: true,
        name: true,
        email: true,
        avatarUrl: true,
        createdAt: true,
        updatedAt: true
      }
    }),
    prisma.user.count()
  ]);

  return {
    success: true,
    count: totalCount,
    data: users.map((user) => ({
      userId: user.id,
      name: user.name,
      email: user.email,
      avatar: user.avatarUrl,
      createdAt: user.createdAt.toISOString(),
      updatedAt: user.updatedAt.toISOString()
    }))
  };
};

const getUserProfile = async (userId: string): Promise<UserProfileResponse> => {
  // Get user with aggregated statistics
  const user = await prisma.user.findUnique({
    where: { id: userId },
    include: {
      activities: {
        where: {
          endTime: { not: null }
        }
      },
      userLocationCollections: true
    }
  });

  if (!user) {
    throw new Error("User not found");
  }

  // Calculate total distance from completed activities
  const totalDistance =
    user.activities.reduce((sum, activity) => sum + (activity.distance || 0), 0) || 0;

  // Calculate total time from completed activities (duration in seconds)
  const totalTime =
    user.activities.reduce((sum, activity) => sum + (activity.duration || 0), 0) || 0;

  // Calculate total coins from activities
  const totalCoins =
    user.activities.reduce((sum, activity) => sum + activity.totalCoins, 0) || 0;

  return {
    success: true,
    data: {
      userId: user.id,
      name: user.name,
      email: user.email,
      avatar: user.avatarUrl,
      totalDistance,
      totalTime,
      totalCoins,
      createdAt: user.createdAt.toISOString(),
      updatedAt: user.updatedAt.toISOString()
    }
  };
};

export const usersService = {
  getUsers,
  getUserProfile
};

