import type { ErrorRequestHandler } from "express";
import { ZodError } from "zod";

import { ApiError, ErrorCodes } from "../utils/errors.js";
import { formatZodError } from "../utils/formatZodError.js";
import { createLogger } from "../utils/logger.js";

const logger = createLogger("error-handler");

export const errorHandler: ErrorRequestHandler = (error, _req, res, _next) => {
  // Check if response has already been sent
  if (res.headersSent) {
    return;
  }

  if (error instanceof ZodError) {
    // Respond with structured validation error feedback for clients.
    res.status(400).json({
      success: false,
      error: {
        code: ErrorCodes.INVALID_REQUEST,
      message: "Validation failed",
      details: formatZodError(error)
      }
    });
    return;
  }

  if (error instanceof ApiError) {
    // Handle custom API errors with proper format
    res.status(error.statusCode).json({
      success: false,
      error: {
        code: error.code,
        message: error.message
      }
    });
    return;
  }

  // Map common error messages to error codes
  if (error?.message === "User not found" || error?.message === "Activity not found" || error?.message === "Location not found") {
    res.status(404).json({
      success: false,
      error: {
        code: ErrorCodes.NOT_FOUND,
        message: error.message
      }
    });
    return;
  }

  if (error?.message === "NFC ID already exists" || error?.message === "Activity has already ended") {
    res.status(400).json({
      success: false,
      error: {
        code: ErrorCodes.INVALID_REQUEST,
        message: error.message
      }
    });
    return;
  }

  // Log unexpected failures while shielding consumers from implementation details.
  logger.error(error, "Unhandled error");

  res.status(500).json({
    success: false,
    error: {
      code: ErrorCodes.SERVER_ERROR,
    message: "Internal server error"
    }
  });
};

