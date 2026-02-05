/**
 * Custom error class for API errors
 * Follows the API specification error format
 */
export class ApiError extends Error {
  public readonly code: string;
  public readonly statusCode: number;

  constructor(code: string, message: string, statusCode = 400) {
    super(message);
    this.name = "ApiError";
    this.code = code;
    this.statusCode = statusCode;
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Common error codes according to API specification
 */
export const ErrorCodes = {
  INVALID_REQUEST: "INVALID_REQUEST",
  UNAUTHORIZED: "UNAUTHORIZED",
  NOT_FOUND: "NOT_FOUND",
  ALREADY_COLLECTED: "ALREADY_COLLECTED",
  SERVER_ERROR: "SERVER_ERROR"
} as const;

