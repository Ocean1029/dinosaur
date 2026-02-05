import { z } from "zod";

export const nfcReadBodySchema = z.object({
  nfcId: z.string().min(1, "NFC ID is required"),
  tagType: z.string().optional(),
  timestamp: z.string().optional(),
  deviceInfo: z
    .object({
      platform: z.string().optional(),
      model: z.string().optional(),
      osVersion: z.string().optional()
    })
    .optional()
});

// GET 請求的查詢參數 schema（用於 URL 方式，例如 ?id=station_001）
export const nfcReadQuerySchema = z.object({
  id: z.string().min(1, "NFC ID is required"),
  tagType: z.string().optional(),
  timestamp: z.string().optional()
});

