import { z } from "zod";

export const healthQuerySchema = z
  .object({
    traceId: z
      .string()
      .trim()
      .min(1, { message: "traceId must not be empty" })
      .optional()
  })
  // Enforce strict mode to prevent unknown query parameters from slipping through.
  .strict();

