import { Router } from "express";

import { nfcController } from "../controllers/nfc.controller.js";
import { requestValidator } from "../middlewares/requestValidator.js";
import { nfcReadBodySchema, nfcReadQuerySchema } from "../schemas/nfc.schema.js";

export const nfcRouter = Router();

// GET 端點：用於 URL 方式（例如 NFC tag 寫入 https://your-server.com/api/nfc?id=station_001）
// 當 iPhone 感應到 NFC tag 時，會自動打開瀏覽器並發送 GET 請求
nfcRouter.get(
  "/",
  requestValidator({
    query: nfcReadQuerySchema
  }),
  nfcController.readNFCFromURL
);

// POST 端點：接收來自 Flutter App 的 NFC 數據
nfcRouter.post(
  "/read",
  requestValidator({
    body: nfcReadBodySchema
  }),
  nfcController.readNFC
);

