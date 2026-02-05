import { Router } from "express";

import { badgesController } from "../controllers/badges.controller.js";
import { requestValidator } from "../middlewares/requestValidator.js";
import {
  badgeCreateSchema,
  badgeIdSchema,
  badgeListQuerySchema,
  badgeUpdateSchema,
  userBadgeListParamsSchema,
  userBadgeListQuerySchema,
  userBadgeParamsSchema
} from "../schemas/badges.schema.js";

/**
 * Routes for Badges module
 * Handles all badge management endpoints
 */
export const badgesRouter = Router();

// GET /api/badges - List all badges
badgesRouter.get(
  "/",
  requestValidator({
    query: badgeListQuerySchema
  }),
  badgesController.getBadges
);

// POST /api/badges - Create a new badge
badgesRouter.post(
  "/",
  requestValidator({
    body: badgeCreateSchema
  }),
  badgesController.createBadge
);

// PATCH /api/badges/:badgeId - Update an existing badge
badgesRouter.patch(
  "/:badgeId",
  requestValidator({
    params: badgeIdSchema,
    body: badgeUpdateSchema
  }),
  badgesController.updateBadge
);

// DELETE /api/badges/:badgeId - Delete a badge
badgesRouter.delete(
  "/:badgeId",
  requestValidator({
    params: badgeIdSchema
  }),
  badgesController.deleteBadge
);

/**
 * Routes for User Badges module
 * Handles user-specific badge endpoints
 */
export const userBadgesRouter = Router();

// GET /api/users/:userId/badges - Get user badge progress
userBadgesRouter.get(
  "/:userId/badges",
  requestValidator({
    params: userBadgeListParamsSchema,
    query: userBadgeListQuerySchema
  }),
  badgesController.getUserBadges
);

// GET /api/users/:userId/badges/:badgeId - Get user badge detail
userBadgesRouter.get(
  "/:userId/badges/:badgeId",
  requestValidator({
    params: userBadgeParamsSchema
  }),
  badgesController.getUserBadgeDetail
);
