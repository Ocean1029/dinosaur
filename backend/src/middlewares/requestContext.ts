import crypto from "node:crypto";

import type { RequestHandler } from "express";

export const requestContext: RequestHandler = (req, _res, next) => {
  // Generate a trace identifier so logs across layers can be correlated.
  req.traceId = crypto.randomUUID();
  next();
};

