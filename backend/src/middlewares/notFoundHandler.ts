import type { RequestHandler } from "express";

export const notFoundHandler: RequestHandler = (_req, res) => {
  // Provide a consistent JSON payload for missing resources.
  res.status(404).json({
    message: "Resource not found"
  });
};

