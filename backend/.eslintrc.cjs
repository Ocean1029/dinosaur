/* eslint-disable @typescript-eslint/no-var-requires */
const path = require("node:path");

module.exports = {
  root: true,
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: path.resolve(__dirname, "tsconfig.json"),
    sourceType: "module"
  },
  env: {
    node: true,
    es2022: true
  },
  plugins: ["@typescript-eslint", "import"],
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:import/recommended",
    "plugin:import/typescript",
    "prettier"
  ],
  rules: {
    "@typescript-eslint/explicit-function-return-type": "off",
    "@typescript-eslint/no-misused-promises": [
      "error",
      {
        "checksVoidReturn": false
      }
    ],
    "@typescript-eslint/no-unused-vars": [
      "error",
      {
        "argsIgnorePattern": "^_"
      }
    ],
    "import/no-default-export": "error",
    "import/no-unresolved": [
      "warn",
      {
        "ignore": ["^node:", "^dotenv/config", "\\.js$"]
      }
    ],
    "import/order": [
      "error",
      {
        "newlines-between": "always",
        "alphabetize": {
          "order": "asc",
          "caseInsensitive": true
        }
      }
    ]
  },
  settings: {
    "import/resolver": {
      node: {
        extensions: [".js", ".jsx", ".ts", ".tsx"]
      }
    },
    "import/extensions": [".js", ".jsx", ".ts", ".tsx"]
  },
  overrides: [
    {
      files: ["*.js", "*.cjs"],
      parserOptions: {
        project: null
      }
    },
    {
      files: ["*.d.ts"],
      rules: {
        "import/no-unresolved": "off"
      }
    }
  ]
};

