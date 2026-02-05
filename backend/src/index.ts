import "dotenv/config";

import cors from "cors";
import express from "express";
import helmet from "helmet";
import os from "os";

import { registerDocs } from "./docs/swagger.js";
import { errorHandler } from "./middlewares/errorHandler.js";
import { notFoundHandler } from "./middlewares/notFoundHandler.js";
import { requestContext } from "./middlewares/requestContext.js";
import { registerRoutes } from "./routes/index.js";
import { createLogger } from "./utils/logger.js";

const app = express();
const logger = createLogger("bootstrap");

// Register global middlewares that make the application safer and easier to debug.
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors());

// Configure Helmet with relaxed CSP for Swagger UI
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'"],
        imgSrc: ["'self'", "data:", "https:"],
      },
    },
  })
);

app.use(requestContext);

// Root endpoint with built-in documentation
app.get("/", (req, res) => {
  res.json({
    name: "Tung Tung Tung Sahur API",
    version: "0.1.0",
    status: "running",
    documentation: {
      api: "/api/docs",
      html: "/api-docs",
      openapi: "/docs.json"
    },
    endpoints: {
      health: "/api/health",
      docs: "/api/docs"
    }
  });
});

// Attach documentation and API routes.
registerDocs(app);
registerRoutes(app);

// Fallback middleware chain to handle unmatched routes and runtime errors.
app.use(notFoundHandler);
app.use(errorHandler);

const port = Number(process.env.PORT ?? 3000);
const host = process.env.HOST ?? "0.0.0.0"; // 監聽所有網路介面，允許外部訪問

// 獲取本機 IP 地址（用於顯示）
const getLocalIP = (): string => {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    const nets = interfaces[name];
    if (nets) {
      for (const net of nets) {
        // 跳過內部（loopback）和 IPv6 地址
        if (net.family === "IPv4" && !net.internal) {
          return net.address;
        }
      }
    }
  }
  return "localhost";
};

app.listen(port, host, () => {
  // Use the shared logger utility to print startup information.
  const localIP = getLocalIP();
  logger.info(`Server listening on ${host}:${port}`);
  logger.info(`Local access: http://localhost:${port}`);
  logger.info(`Network access: http://${localIP}:${port}`);
});

