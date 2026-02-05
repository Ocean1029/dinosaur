import type { Request, Response } from "express";

import { healthService } from "../services/health.service.js";

const getStatus = async (req: Request, res: Response): Promise<void> => {
  // Delegate health report generation to the service layer.
  const report = await healthService.getStatus({
    traceId: req.traceId
  });

  // Respond with the aggregated service status payload.
  res.status(200).json(report);
};

export const healthController = {
  getStatus
};

