import { Router } from "express";

import { activitiesController } from "../controllers/activities.controller.js";
import { requestValidator } from "../middlewares/requestValidator.js";
import {
  activityEndSchema,
  activityListParamsSchema,
  activityListQuerySchema,
  activityNfcCollectSchema,
  activityParamsSchema,
  activityStartSchema,
  activityTrackSchema
} from "../schemas/activities.schema.js";

/**
 * Routes for Activities module
 * Handles all activity tracking endpoints
 */
export const activitiesRouter = Router();

// POST /api/users/:userId/activities/start - Start a new activity
activitiesRouter.post(
  "/:userId/activities/start",
  requestValidator({
    params: activityListParamsSchema,
    body: activityStartSchema
  }),
  activitiesController.startActivity
);

// POST /api/users/:userId/activities/:activityId/track - Add track points to activity
activitiesRouter.post(
  "/:userId/activities/:activityId/track",
  requestValidator({
    params: activityParamsSchema,
    body: activityTrackSchema
  }),
  activitiesController.trackActivity
);

// POST /api/users/:userId/activities/:activityId/end - End an activity and calculate results
activitiesRouter.post(
  "/:userId/activities/:activityId/end",
  requestValidator({
    params: activityParamsSchema,
    body: activityEndSchema
  }),
  activitiesController.endActivity
);

// GET /api/users/:userId/activities - Get user's activity list
activitiesRouter.get(
  "/:userId/activities",
  requestValidator({
    params: activityListParamsSchema,
    query: activityListQuerySchema
  }),
  activitiesController.getActivities
);

// GET /api/users/:userId/activities/:activityId - Get activity details
activitiesRouter.get(
  "/:userId/activities/:activityId",
  requestValidator({
    params: activityParamsSchema
  }),
  activitiesController.getActivityDetail
);

// POST /api/users/:userId/activities/:activityId/collect/nfc - Collect location via NFC
activitiesRouter.post(
  "/:userId/activities/:activityId/collect/nfc",
  requestValidator({
    params: activityParamsSchema,
    body: activityNfcCollectSchema
  }),
  activitiesController.collectNfcLocation
);

