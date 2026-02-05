import type { Request, Response } from "express";

import { badgesService } from "../services/badges.service.js";
import type {
  BadgeCreateInput,
  BadgeListQuery,
  BadgeUpdateInput,
  UserBadgeListQuery
} from "../types/badges.types.js";

/**
 * Controller layer for Badges module
 * Handles HTTP request/response for badge management endpoints
 */

const getBadges = async (req: Request, res: Response): Promise<void> => {
  const query = req.query as unknown as BadgeListQuery;
  const result = await badgesService.getBadges(query);
  res.status(200).json(result);
};

const createBadge = async (req: Request, res: Response): Promise<void> => {
  const input = req.body as BadgeCreateInput;
  const result = await badgesService.createBadge(input);
  res.status(201).json(result);
};

const updateBadge = async (req: Request, res: Response): Promise<void> => {
  const { badgeId } = req.params;
  const input = req.body as BadgeUpdateInput;
  const result = await badgesService.updateBadge(badgeId, input);
  res.status(200).json(result);
};

const deleteBadge = async (req: Request, res: Response): Promise<void> => {
  const { badgeId } = req.params;
  const result = await badgesService.deleteBadge(badgeId);
  res.status(200).json(result);
};

const getUserBadges = async (req: Request, res: Response): Promise<void> => {
  const { userId } = req.params;
  const query = {
    userId,
    ...req.query
  } as unknown as UserBadgeListQuery;
  const result = await badgesService.getUserBadges(query);
  res.status(200).json(result);
};

const getUserBadgeDetail = async (req: Request, res: Response): Promise<void> => {
  const { userId, badgeId } = req.params;
  const result = await badgesService.getUserBadgeDetail(userId, badgeId);
  res.status(200).json(result);
};

export const badgesController = {
  getBadges,
  createBadge,
  updateBadge,
  deleteBadge,
  getUserBadges,
  getUserBadgeDetail
};
