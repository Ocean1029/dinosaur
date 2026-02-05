import type { NextFunction, Request, Response } from "express";
import { ZodError, type ZodSchema } from "zod";

import { formatZodError } from "../utils/formatZodError.js";

type ValidationSchema = {
  body?: ZodSchema;
  query?: ZodSchema;
  params?: ZodSchema;
};

export const requestValidator =
  (schema: ValidationSchema) => (req: Request, res: Response, next: NextFunction) => {
    try {
      // Validate and coerce the request body if a schema is provided.
      if (schema.body) {
        req.body = schema.body.parse(req.body);
      }
      // Validate query parameters to ensure consistent formats.
      if (schema.query) {
        req.query = schema.query.parse(req.query);
      }
      // Validate URL parameters for routes that require typed identifiers.
      if (schema.params) {
        req.params = schema.params.parse(req.params);
      }
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        res.status(400).json({
          message: "Validation failed",
          details: formatZodError(error)
        });
        return;
      }
      next(error);
    }
  };

