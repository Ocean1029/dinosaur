type LogLevel = "info" | "warn" | "error" | "debug";

const log = (level: LogLevel, context: string, message: string, meta?: unknown): void => {
  const timestamp = new Date().toISOString();
  if (meta) {
    console[level](`[${timestamp}] [${context}] ${message}`, meta);
    return;
  }
  console[level](`[${timestamp}] [${context}] ${message}`);
};

export const createLogger = (context: string) => ({
  // Info logs capture high-level application events.
  info: (message: string, meta?: unknown) => log("info", context, message, meta),
  // Warn logs flag soft failures that do not halt the process.
  warn: (message: string, meta?: unknown) => log("warn", context, message, meta),
  // Error logs record unexpected exceptions together with stack traces.
  error: (error: unknown, message?: string) => {
    const errorMessage = message ?? (error instanceof Error ? error.message : "Unknown error");
    log("error", context, errorMessage, error);
  },
  // Debug logs surface verbose diagnostics during development.
  debug: (message: string, meta?: unknown) => log("debug", context, message, meta)
});

