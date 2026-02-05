import type { ZodError } from "zod";

export const formatZodError = (error: ZodError | Error): Array<{
  path: string;
  message: string;
}> => {
  // Translate Zod validation issues into a transport-friendly format.
  if ("issues" in error) {
    return error.issues.map((issue) => ({
      path: issue.path.join("."),
      message: issue.message
    }));
  }

  // Fall back to a generic error structure for unexpected exceptions.
  return [
    {
      path: "",
      message: error.message
    }
  ];
};

