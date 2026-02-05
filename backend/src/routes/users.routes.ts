import { Router } from "express";

import { usersController } from "../controllers/users.controller.js";
import { requestValidator } from "../middlewares/requestValidator.js";
import { userMapParamsSchema, userMapQuerySchema } from "../schemas/locations.schema.js";
import {
  userListQuerySchema,
  userParamsSchema
} from "../schemas/users.schema.js";

/**
 * Routes for User Profile module
 * Handles all user profile and map endpoints
 */
export const usersRouter = Router();

// GET /api/users - Get all users with pagination
// This route must be defined before /:userId routes to avoid path conflicts
usersRouter.get(
  "/",
  requestValidator({
    query: userListQuerySchema
  }),
  usersController.getUsers
);

// GET /api/users/:userId/profile - Get user profile with statistics
usersRouter.get(
  "/:userId/profile",
  requestValidator({
    params: userParamsSchema
  }),
  usersController.getUserProfile
);

// GET /api/users/:userId/map - Get user's map view with collection status
usersRouter.get(
  "/:userId/map",
  requestValidator({
    params: userMapParamsSchema,
    query: userMapQuerySchema
  }),
  usersController.getUserMap
);

