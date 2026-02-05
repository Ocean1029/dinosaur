import type { Request, Response } from "express";

import { activitiesService } from "../services/activities.service.js";
import type {
  ActivityEndInput,
  ActivityListQuery,
  ActivityNfcCollectInput,
  ActivityStartInput,
  ActivityTrackInput
} from "../types/activities.types.js";

/**
 * Controller layer for Activities module
 * Handles HTTP request/response for activity tracking endpoints
 */

const startActivity = async (req: Request, res: Response): Promise<void> => {
  const { userId } = req.params;
  const input = req.body as ActivityStartInput;
  const result = await activitiesService.startActivity(userId, input);
  res.status(201).json(result);
};

const trackActivity = async (req: Request, res: Response): Promise<void> => {
  const { userId, activityId } = req.params;
  const input = req.body as ActivityTrackInput;
  const result = await activitiesService.trackActivity(userId, activityId, input);
  res.status(200).json(result);
};

const endActivity = async (req: Request, res: Response): Promise<void> => {
  const { userId, activityId } = req.params;
  const input = req.body as ActivityEndInput;
  const result = await activitiesService.endActivity(userId, activityId, input);
  res.status(200).json(result);
};

const getActivities = async (req: Request, res: Response): Promise<void> => {
  const { userId } = req.params;
  const query = {
    userId,
    ...req.query
  } as unknown as ActivityListQuery;
  const result = await activitiesService.getActivities(query);
  res.status(200).json(result);
};

const getActivityDetail = async (req: Request, res: Response): Promise<void> => {
  const { userId, activityId } = req.params;
  const result = await activitiesService.getActivityDetail(userId, activityId);
  res.status(200).json(result);
};

const collectNfcLocation = async (req: Request, res: Response): Promise<void> => {
  const { userId, activityId } = req.params;
  const input = req.body as ActivityNfcCollectInput;
  const result = await activitiesService.collectNfcLocation(userId, activityId, input);
  res.status(200).json(result);
};

export const activitiesController = {
  startActivity,
  trackActivity,
  endActivity,
  collectNfcLocation,
  getActivities,
  getActivityDetail
};

