import type { Request, Response } from "express";

import { locationsService } from "../services/locations.service.js";
import type {
  LocationCreateInput,
  LocationListQuery,
  LocationUpdateInput,
  UserMapQuery
} from "../types/locations.types.js";

/**
 * Controller layer for Locations module
 * Handles HTTP request/response for location management endpoints
 */

const getLocations = async (req: Request, res: Response): Promise<void> => {
  const query = req.query as unknown as LocationListQuery;
  const result = await locationsService.getLocations(query);
  res.status(200).json(result);
};

const createLocation = async (req: Request, res: Response): Promise<void> => {
  const input = req.body as LocationCreateInput;
  const result = await locationsService.createLocation(input);
  res.status(201).json(result);
};

const updateLocation = async (req: Request, res: Response): Promise<void> => {
  const { locationId } = req.params;
  const input = req.body as LocationUpdateInput;
  const result = await locationsService.updateLocation(locationId, input);
  res.status(200).json(result);
};

const deleteLocation = async (req: Request, res: Response): Promise<void> => {
  const { locationId } = req.params;
  const result = await locationsService.deleteLocation(locationId);
  res.status(200).json(result);
};

const getUserMap = async (req: Request, res: Response): Promise<void> => {
  const { userId } = req.params;
  const query = {
    userId,
    ...req.query
  } as UserMapQuery;
  const result = await locationsService.getUserMap(query);
  res.status(200).json(result);
};

const enableNfc = async (req: Request, res: Response): Promise<void> => {
  const { locationId } = req.params;
  const result = await locationsService.enableNfc(locationId);
  res.status(200).json(result);
};

export const locationsController = {
  getLocations,
  createLocation,
  updateLocation,
  deleteLocation,
  getUserMap,
  enableNfc
};

