import { z } from "zod";

/**
 * Zod schemas for Badges module validation
 */

export const badgeIdSchema = z
  .object({
    badgeId: z.string().uuid({ message: "Invalid badge ID format" })
  })
  .strict();

export const badgeCreateSchema = z
  .object({
    name: z.string().trim().min(1, { message: "Name is required" }),
    description: z.string().trim().optional(),
    imageUrl: z.string().url().optional().nullable(),
    color: z
      .string()
      .regex(/^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$/, {
        message: "Color must be a valid hex color code (e.g., #FF5733 or #FF5733AA)"
      })
      .optional()
      .nullable(),
    requiredLocationIds: z
      .array(z.string().uuid({ message: "Invalid location ID format" }))
      .min(1, { message: "At least one location is required" })
  })
  .strict();

export const badgeUpdateSchema = z
  .object({
    name: z.string().trim().min(1).optional(),
    description: z.string().trim().optional(),
    imageUrl: z.string().url().optional().nullable(),
    color: z
      .string()
      .regex(/^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$/, {
        message: "Color must be a valid hex color code (e.g., #FF5733 or #FF5733AA)"
      })
      .optional()
      .nullable(),
    requiredLocationIds: z
      .array(z.string().uuid({ message: "Invalid location ID format" }))
      .min(1)
      .optional()
  })
  .strict();

export const badgeListQuerySchema = z
  .object({
    search: z.string().trim().optional(),
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

export const userBadgeListQuerySchema = z
  .object({
    status: z.enum(["locked", "in_progress", "collected"]).optional()
  })
  .strict();

export const userBadgeParamsSchema = z
  .object({
    userId: z.string().uuid({ message: "Invalid user ID format" }),
    badgeId: z.string().uuid({ message: "Invalid badge ID format" })
  })
  .strict();

export const userBadgeListParamsSchema = z
  .object({
    userId: z.string().uuid({ message: "Invalid user ID format" })
  })
  .strict();
