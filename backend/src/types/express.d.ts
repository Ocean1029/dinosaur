import "express-serve-static-core";

declare module "express-serve-static-core" {
  interface Request {
    // Attach a trace identifier that is generated per incoming request.
    traceId?: string;
  }
}

