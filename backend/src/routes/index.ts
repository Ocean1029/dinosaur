import type { Express } from "express";
import { Router } from "express";

import { activitiesRouter } from "./activities.routes.js";
import { docsRouter } from "./docs.routes.js";
import { badgesRouter, userBadgesRouter } from "./badges.routes.js";
import { healthRouter } from "./health.routes.js";
import { locationsRouter } from "./locations.routes.js";
import { nfcRouter } from "./nfc.routes.js";
import { usersRouter } from "./users.routes.js";

export const registerRoutes = (app: Express): void => {
  // Aggregate feature routers under a single API namespace for clarity.
  const apiRouter = Router();

  // Built-in API documentation endpoint
  apiRouter.use("/docs", docsRouter);
  apiRouter.use("/health", healthRouter);
  apiRouter.use("/locations", locationsRouter);
  apiRouter.use("/nfc", nfcRouter);
  apiRouter.use("/badges", badgesRouter);
  // Activities routes must be registered before users routes to avoid path conflicts
  apiRouter.use("/users", activitiesRouter);
  // User badges routes should come before generic user routes to avoid conflicts
  apiRouter.use("/users", userBadgesRouter);
  apiRouter.use("/users", usersRouter);

  app.use("/api", apiRouter);
};

