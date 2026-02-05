import type { Express } from "express";
import { existsSync, readFileSync } from "fs";
import { join } from "path";
import swaggerJsdoc, { type OAS3Definition, type OAS3Options } from "swagger-jsdoc";
import swaggerUi from "swagger-ui-express";

const swaggerDefinition: OAS3Definition = {
  openapi: "3.1.0",
  info: {
    title: "Tung Tung Tung Sahur API",
    version: "0.1.0",
    description: "API documentation powered by Swagger UI."
  },
  servers: [
    {
      url: "/api",
      description: "Primary API entrypoint"
    }
  ]
};

// Determine the correct path for Swagger YAML files
// In development: src/docs/**/*.yaml
// In production: src/docs/**/*.yaml (copied to container)
const getSwaggerApiPaths = (): string[] => {
  const cwd = process.cwd();
  const srcPath = join(cwd, "src", "docs", "**", "*.yaml");
  const distPath = join(cwd, "dist", "docs", "**", "*.yaml");
  
  // Try both paths to support both development and production environments
  return [srcPath, distPath];
};

const swaggerOptions: OAS3Options = {
  definition: swaggerDefinition,
  // Support both development (src/docs) and production (dist/docs or src/docs) paths
  apis: getSwaggerApiPaths()
};

const swaggerSpec = (() => {
  try {
    // Precompute the OpenAPI specification so it can be reused across requests.
    return swaggerJsdoc(swaggerOptions);
  } catch (error) {
    console.error("Failed to initialize Swagger specification", error);
    throw error;
  }
})();

export const registerDocs = (app: Express): void => {
  // Mount Swagger UI under /docs to provide interactive API exploration.
  app.use("/docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
    customCss: '.swagger-ui .topbar { display: none }',
    customSiteTitle: "Tung Tung Tung Sahur API Docs"
  }));
  
  // Add a JSON endpoint to debug the swagger spec
  app.get("/docs.json", (req, res) => {
    res.json(swaggerSpec);
  });

  // Add a simple HTML documentation page
  app.get("/api-docs", (req, res) => {
    try {
      const cwd = process.cwd();
      // Try src/docs first (development), then dist/docs (production)
      const srcPath = join(cwd, "src", "docs", "api-docs.html");
      const distPath = join(cwd, "dist", "docs", "api-docs.html");
      
      const htmlPath = existsSync(srcPath) ? srcPath : distPath;
      const html = readFileSync(htmlPath, "utf-8");
      res.send(html);
    } catch (error) {
      res.status(500).send("無法載入文檔頁面");
    }
  });
};

