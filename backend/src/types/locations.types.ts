/**
 * Type definitions for Locations module
 */

export type LocationResponse = {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  description: string | null;
  nfcId: string | null;
  isNfcEnabled: boolean;
  area: string | null;
  createdAt: Date;
  updatedAt: Date;
};

export type LocationWithCollectionStatus = LocationResponse & {
  isCollected: boolean;
  collectedAt: Date | null;
};

export type LocationCreateInput = {
  name: string;
  latitude: number;
  longitude: number;
  description?: string;
  isNfcEnabled?: boolean;
  nfcId?: string;
};

export type LocationUpdateInput = {
  name?: string;
  latitude?: number;
  longitude?: number;
  description?: string;
  isNfcEnabled?: boolean;
  nfcId?: string;
};

export type LocationListQuery = {
  page?: number;
  limit?: number;
  badge?: string;
};

export type LocationListResponse = {
  success: true;
  count: number;
  data: LocationResponse[];
};

export type LocationDetailResponse = {
  success: true;
  data: LocationResponse;
};

export type LocationDeleteResponse = {
  success: true;
  message: string;
};

export type UserMapQuery = {
  userId: string;
  badge?: string;
  bounds?: string;
};

export type UserMapResponse = {
  success: true;
  count: number;
  data: {
    locations: LocationWithCollectionStatus[];
  };
};

export type LocationEnableNfcResponse = {
  success: true;
  data: LocationResponse;
};

