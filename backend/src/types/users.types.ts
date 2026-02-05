/**
 * Type definitions for User Profile module
 */

export type UserProfileResponse = {
  success: true;
  data: {
    userId: string;
    name: string;
    email: string;
    avatar: string | null;
    totalDistance: number;
    totalTime: number; // Duration in seconds
    totalCoins: number;
    createdAt: string;
    updatedAt: string;
  };
};

export type UserListItem = {
  userId: string;
  name: string;
  email: string;
  avatar: string | null;
  createdAt: string;
  updatedAt: string;
};

export type UserListQuery = {
  page?: number;
  limit?: number;
};

export type UserListResponse = {
  success: true;
  count: number;
  data: UserListItem[];
};

