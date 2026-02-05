import { z } from "zod";

/**
 * Zod schemas for Activities module validation
 */

export const activityStartSchema = z
  .object({
    startTime: z.string().datetime({ message: "Invalid datetime format" }),
    startLocation: z
      .object({
        latitude: z
          .number()
          .min(-90)
          .max(90),
        longitude: z
          .number()
          .min(-180)
          .max(180)
      })
      .strict()
  })
  .strict();

export const activityTrackSchema = z
  .object({
    points: z
      .array(
        z
          .object({
            latitude: z
              .number()
              .min(-90)
              .max(90),
            longitude: z
              .number()
              .min(-180)
              .max(180),
            timestamp: z.string().datetime({ message: "Invalid datetime format" }),
            accuracy: z.number().positive().optional()
          })
          .strict()
      )
      .min(1, { message: "At least one point is required" })
  })
  .strict();

export const activityEndSchema = z
  .object({
    endTime: z.string().datetime({ message: "Invalid datetime format" }),
    endLocation: z
      .object({
        latitude: z
          .number()
          .min(-90)
          .max(90),
        longitude: z
          .number()
          .min(-180)
          .max(180)
      })
      .strict()
  })
  .strict();

export const activityParamsSchema = z
  .object({
    userId: z.string().uuid({ message: "Invalid user ID format" }),
    activityId: z.string().uuid({ message: "Invalid activity ID format" })
  })
  .strict();

export const activityListParamsSchema = z
  .object({
    userId: z.string().uuid({ message: "Invalid user ID format" })
  })
  .strict();

export const activityListQuerySchema = z
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
      .default("20"),
    startDate: z.string().datetime().optional(),
    endDate: z.string().datetime().optional()
  })
  .strict();

export const activityNfcCollectSchema = z
  .object({
    nfcId: z.string().trim().min(1, { message: "NFC ID is required" })
  })
  .strict();

