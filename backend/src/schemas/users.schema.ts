import { z } from "zod";

/**
 * Zod schemas for User Profile module validation
 */

export const userParamsSchema = z
  .object({
    userId: z.string().uuid({ message: "Invalid user ID format" })
  })
  .strict();

export const userListQuerySchema = z
  .object({
    page: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().int().positive())
      .optional()
      .default("1"),
    limit: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().int().positive().max(100))
      .optional()
      .default("100")
  })
  .strict();

