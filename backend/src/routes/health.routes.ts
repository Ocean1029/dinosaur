import { Router } from "express";

import { healthController } from "../controllers/health.controller.js";
import { requestValidator } from "../middlewares/requestValidator.js";
import { healthQuerySchema } from "../schemas/health.schema.js";

export const healthRouter = Router();

// Expose a simple liveness endpoint to monitor service health.
healthRouter.get(
  "/",
  requestValidator({
    query: healthQuerySchema
  }),
  healthController.getStatus
);

