import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient({
  log: ["warn", "error"]
});

// Export a shared PrismaClient instance so connections can be reused across modules.
export { prisma };

