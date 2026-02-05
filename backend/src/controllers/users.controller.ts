import type { NextFunction, Request, Response } from "express";

import { locationsService } from "../services/locations.service.js";
import { usersService } from "../services/users.service.js";
import type { UserMapQuery } from "../types/locations.types.js";
import type { UserListQuery } from "../types/users.types.js";

/**
 * Controller layer for User Profile module
 * Handles HTTP request/response for user profile endpoints
 */

const getUsers = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const query = req.query as unknown as UserListQuery;
    const result = await usersService.getUsers(query);
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

const getUserProfile = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { userId } = req.params;
    const result = await usersService.getUserProfile(userId);
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

const getUserMap = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { userId } = req.params;
    const query = {
      userId,
      ...req.query
    } as UserMapQuery;
    const result = await locationsService.getUserMap(query);
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

export const usersController = {
  getUsers,
  getUserProfile,
  getUserMap
};

