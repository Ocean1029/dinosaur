import type { Request, Response } from "express";

import { nfcService } from "../services/nfc.service.js";

// 處理來自 URL 的 GET 請求（方法 A：NFC tag 寫入 URL）
const readNFCFromURL = async (req: Request, res: Response): Promise<void> => {
  const result = await nfcService.handleNFCRead({
    traceId: req.traceId || "unknown",
    data: {
      nfcId: req.query.id as string,
      tagType: req.query.tagType as string | undefined,
      timestamp: (req.query.timestamp as string | undefined) || new Date().toISOString(),
      deviceInfo: {
        platform: "iOS", // 從 URL 來的通常是 iPhone
        model: req.headers["user-agent"] || "Unknown"
      }
    }
  });

  // 返回簡單的 HTML 頁面，讓用戶知道 NFC 已成功讀取
  res.status(200).send(`
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>NFC 感應成功</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          display: flex;
          justify-content: center;
          align-items: center;
          min-height: 100vh;
          margin: 0;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
        }
        .container {
          text-align: center;
          padding: 2rem;
          background: rgba(255, 255, 255, 0.1);
          border-radius: 20px;
          backdrop-filter: blur(10px);
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }
        h1 { margin-top: 0; }
        .nfc-id {
          font-size: 1.5rem;
          font-weight: bold;
          margin: 1rem 0;
          padding: 1rem;
          background: rgba(255, 255, 255, 0.2);
          border-radius: 10px;
        }
        .message {
          margin-top: 1rem;
          opacity: 0.9;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>✅ NFC 感應成功</h1>
        <div class="nfc-id">NFC ID: ${result.data?.nfcId || req.query.id}</div>
        <div class="message">訊息已成功傳送到伺服器並顯示在終端機</div>
      </div>
    </body>
    </html>
  `);
};

// 處理來自 App 的 POST 請求（方法 B：Flutter App 發送）
const readNFC = async (req: Request, res: Response): Promise<void> => {
  const result = await nfcService.handleNFCRead({
    traceId: req.traceId || "unknown",
    data: req.body
  });

  res.status(200).json(result);
};

export const nfcController = {
  readNFCFromURL,
  readNFC
};

