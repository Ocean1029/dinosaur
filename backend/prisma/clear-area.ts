import { PrismaClient } from "@prisma/client";
import { config } from "dotenv";

// Load environment variables from .env.dev
config({ path: "../.env.dev" });

// Fix DATABASE_URL for local execution (replace 'db:' with 'localhost:')
if (process.env.DATABASE_URL && process.env.DATABASE_URL.includes("db:")) {
  process.env.DATABASE_URL = process.env.DATABASE_URL.replace("db:", "localhost:");
}

const prisma = new PrismaClient();

/**
 * Script to clear all area fields in the locations table
 * This will set all area values to null so they can be re-fetched with the new format
 */
async function clearAreaFields() {
  try {
    console.log("Starting to clear area fields...");

    // Update all locations to set area to null
    const result = await prisma.location.updateMany({
      data: {
        area: null
      }
    });

    console.log(`Successfully cleared area fields for ${result.count} locations.`);
  } catch (error) {
    console.error("Error clearing area fields:", error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

clearAreaFields();

