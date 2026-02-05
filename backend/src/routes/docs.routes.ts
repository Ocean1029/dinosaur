import type { Request, Response } from "express";
import { Router } from "express";

export const docsRouter = Router();

// Simple built-in API documentation endpoint
docsRouter.get("/", (req: Request, res: Response): void => {
  res.json({
    name: "Tung Tung Tung Sahur API",
    version: "0.1.0",
    description: "API 文檔與端點列表",
    endpoints: {
      health: {
        method: "GET",
        path: "/api/health",
        description: "健康檢查端點 - 檢查應用程式運行狀態",
        example: "/api/health",
        response: {
          status: "ok",
          timestamp: "2025-11-08T09:00:00.000Z",
          uptime: 12345,
          environment: "development"
        }
      }
    },
    documentation: {
      html: "/api-docs",
      json: "/docs.json",
      openapi: "/docs.json"
    },
    database: {
      studio: "http://localhost:5555 (run: make prisma-studio)"
    }
  });
});

