import { Router } from "express";

import { locationsController } from "../controllers/locations.controller.js";
import { requestValidator } from "../middlewares/requestValidator.js";
import {
  locationCreateSchema,
  locationListQuerySchema,
  locationParamsSchema,
  locationUpdateSchema
} from "../schemas/locations.schema.js";

/**
 * Routes for Locations module
 * Handles all location management endpoints
 */
export const locationsRouter = Router();

// GET /api/locations - List all locations with pagination and optional badge filter
locationsRouter.get(
  "/",
  requestValidator({
    query: locationListQuerySchema
  }),
  locationsController.getLocations
);

// POST /api/locations - Create a new location
locationsRouter.post(
  "/",
  requestValidator({
    body: locationCreateSchema
  }),
  locationsController.createLocation
);

// PATCH /api/locations/:locationId - Update an existing location
locationsRouter.patch(
  "/:locationId",
  requestValidator({
    params: locationParamsSchema,
    body: locationUpdateSchema
  }),
  locationsController.updateLocation
);

// DELETE /api/locations/:locationId - Delete a location
locationsRouter.delete(
  "/:locationId",
  requestValidator({
    params: locationParamsSchema
  }),
  locationsController.deleteLocation
);

// POST /api/locations/:locationId/enable-nfc - Enable NFC for a location
locationsRouter.post(
  "/:locationId/enable-nfc",
  requestValidator({
    params: locationParamsSchema
  }),
  locationsController.enableNfc
);

