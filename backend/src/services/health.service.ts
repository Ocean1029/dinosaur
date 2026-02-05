import os from "node:os";

import { prisma } from "../utils/prismaClient.js";

type HealthStatusInput = {
  traceId?: string;
};

type HealthStatus = {
  status: "ok";
  uptime: number;
  hostname: string;
  database: {
    connected: boolean;
  };
  traceId?: string;
};

const getStatus = async ({ traceId }: HealthStatusInput): Promise<HealthStatus> => {
  // Try to verify database connectivity, but don't fail if database is not available.
  // This allows the server to run without a database (useful for NFC testing).
  let databaseConnected = false;
  
  try {
    // Check if DATABASE_URL is set
    if (process.env.DATABASE_URL) {
  await prisma.$queryRaw`SELECT 1`;
      databaseConnected = true;
    }
  } catch (error) {
    // Database is not available or not configured - this is OK for NFC testing
    databaseConnected = false;
  }

  return {
    status: "ok",
    uptime: process.uptime(),
    hostname: os.hostname(),
    database: {
      connected: databaseConnected
    },
    traceId
  };
};

export const healthService = {
  getStatus
};

