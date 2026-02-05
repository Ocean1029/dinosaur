import { z } from "zod";

/**
 * Zod schemas for Locations module validation
 */

export const locationCreateSchema = z
  .object({
    name: z.string().trim().min(1, { message: "Name is required" }),
    latitude: z
      .number()
      .min(-90, { message: "Latitude must be between -90 and 90" })
      .max(90, { message: "Latitude must be between -90 and 90" }),
    longitude: z
      .number()
      .min(-180, { message: "Longitude must be between -180 and 180" })
      .max(180, { message: "Longitude must be between -180 and 180" }),
    description: z.string().trim().optional(),
    isNfcEnabled: z.boolean().optional().default(false),
    nfcId: z.string().trim().optional().nullable()
  })
  .strict();

export const locationUpdateSchema = z
  .object({
    name: z.string().trim().min(1).optional(),
    latitude: z
      .number()
      .min(-90)
      .max(90)
      .optional(),
    longitude: z
      .number()
      .min(-180)
      .max(180)
      .optional(),
    description: z.string().trim().optional(),
    isNfcEnabled: z.boolean().optional(),
    nfcId: z.string().trim().optional().nullable()
  })
  .strict();

export const locationListQuerySchema = z
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
      .default("100"),
    badge: z.string().uuid().optional()
  })
  .strict();

export const locationParamsSchema = z
  .object({
    locationId: z.string().uuid({ message: "Invalid location ID format" })
  })
  .strict();

export const userMapQuerySchema = z
  .object({
    badge: z.string().uuid().optional(),
    bounds: z
      .string()
      .regex(
        /^-?\d+\.?\d*,-?\d+\.?\d*,-?\d+\.?\d*,-?\d+\.?\d*$/,
        { message: "Bounds must be in format: lat1,lng1,lat2,lng2" }
      )
      .optional()
  })
  .strict();

export const userMapParamsSchema = z
  .object({
    userId: z.string().uuid({ message: "Invalid user ID format" })
  })
  .strict();

