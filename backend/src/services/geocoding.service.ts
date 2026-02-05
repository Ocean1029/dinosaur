import { createLogger } from "../utils/logger.js";

const logger = createLogger("geocoding-service");

/**
 * Geocoding service to get administrative area from coordinates
 * Uses Google Maps Geocoding API to reverse geocode coordinates
 */

// Track if API key warning has been logged to avoid spam
let apiKeyWarningLogged = false;

// Track API errors to avoid spam logging
const errorCounts = new Map<string, number>();
const MAX_ERROR_LOG_COUNT = 5;

/**
 * Check if Google Maps API key is available
 * Logs a warning only once if the key is missing
 * @returns true if API key is available, false otherwise
 */
const checkApiKey = (): boolean => {
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;
  if (!apiKey && !apiKeyWarningLogged) {
    logger.warn("GOOGLE_MAPS_API_KEY not set, geocoding service will return null for area");
    apiKeyWarningLogged = true;
  }
  return !!apiKey;
};

/**
 * Log API error with rate limiting to avoid spam
 * @param errorType - Type of error (e.g., "REQUEST_DENIED", "OVER_QUERY_LIMIT")
 * @param details - Additional error details
 */
const logApiError = (errorType: string, details?: string): void => {
  const count = errorCounts.get(errorType) || 0;
  if (count < MAX_ERROR_LOG_COUNT) {
    const message = details
      ? `Geocoding API error [${errorType}]: ${details}`
      : `Geocoding API error [${errorType}]`;
    logger.error(message);
    errorCounts.set(errorType, count + 1);
  } else if (count === MAX_ERROR_LOG_COUNT) {
    logger.warn(
      `Geocoding API error [${errorType}] has occurred ${MAX_ERROR_LOG_COUNT} times. Further occurrences will be suppressed.`
    );
    errorCounts.set(errorType, count + 1);
  }
};

/**
 * Get administrative area (city and district) from latitude and longitude
 * Uses Google Maps Geocoding API reverse geocoding
 * @param latitude - Latitude coordinate
 * @param longitude - Longitude coordinate
 * @returns Administrative area name in format "XX市XX區" (e.g., "台北市大安區", "新北市板橋區") or null if not found
 */
const getAreaFromCoordinates = async (
  latitude: number,
  longitude: number
): Promise<string | null> => {
  if (!checkApiKey()) {
    return null;
  }

  const apiKey = process.env.GOOGLE_MAPS_API_KEY!;

  try {
    const url = new URL("https://maps.googleapis.com/maps/api/geocode/json");
    url.searchParams.set("latlng", `${latitude},${longitude}`);
    url.searchParams.set("key", apiKey);
    url.searchParams.set("language", "zh-TW");
    url.searchParams.set("region", "tw");

    const response = await fetch(url.toString());

    if (!response.ok) {
      logApiError(
        "HTTP_ERROR",
        `HTTP ${response.status} ${response.statusText} for coordinates (${latitude}, ${longitude})`
      );
      return null;
    }

    const data = (await response.json()) as {
      status: string;
      error_message?: string;
      results?: Array<{
        address_components?: Array<{
          types: string[];
          long_name: string;
          short_name: string;
        }>;
        formatted_address?: string;
      }>;
    };

    // Handle different API status codes
    if (data.status === "OK") {
      // Success case, continue processing
    } else if (data.status === "ZERO_RESULTS") {
      // No results found for this coordinate, this is normal
      return null;
    } else if (data.status === "REQUEST_DENIED") {
      logApiError(
        "REQUEST_DENIED",
        `API key may be invalid or Geocoding API not enabled. Error: ${data.error_message || "Unknown"}. Coordinates: (${latitude}, ${longitude})`
      );
      return null;
    } else if (data.status === "OVER_QUERY_LIMIT") {
      logApiError(
        "OVER_QUERY_LIMIT",
        `API quota exceeded. Coordinates: (${latitude}, ${longitude})`
      );
      return null;
    } else if (data.status === "INVALID_REQUEST") {
      logApiError(
        "INVALID_REQUEST",
        `Invalid request parameters. Coordinates: (${latitude}, ${longitude})`
      );
      return null;
    } else {
      logApiError(
        data.status,
        `Unexpected API status. Error: ${data.error_message || "Unknown"}. Coordinates: (${latitude}, ${longitude})`
      );
      return null;
    }

    if (!data.results || data.results.length === 0) {
      return null;
    }

    // Extract city (administrative_area_level_1) and district (administrative_area_level_3)
    // Format: "XX市XX區" (e.g., "台北市大安區", "新北市板橋區")
    for (const result of data.results) {
      if (result.address_components) {
        let city: string | null = null;
        let district: string | null = null;

        // Extract city and district from address components
        for (const component of result.address_components) {
          // Extract city (administrative_area_level_1) - e.g., "台北市", "新北市"
          if (
            component.types.includes("administrative_area_level_1") &&
            !city
          ) {
            city = component.long_name || component.short_name;
            // Ensure it ends with "市" or "縣"
            if (city && !city.endsWith("市") && !city.endsWith("縣")) {
              // Try to add appropriate suffix based on context
              if (city.includes("台北") || city.includes("新北") || city.includes("桃園") || 
                  city.includes("台中") || city.includes("台南") || city.includes("高雄")) {
                city = `${city}市`;
              } else {
                city = `${city}縣`;
              }
            }
          }

          if (
            (component.types.includes("administrative_area_level_2") ||
              component.types.includes("sublocality_level_1")) &&
            !district
          ) {
            district = component.long_name || component.short_name;
            
          }
        }

        // Return combined format "XX市XX區" if both city and district are found
        if (city && district) {
          return `${city}${district}`;
        }

        // If only district is found, try to extract city from formatted address
        if (district && !city) {
          const formattedAddress = result.formatted_address;
          if (formattedAddress) {
            // Try to match city pattern like "台北市", "新北市"
            const cityMatch = formattedAddress.match(/([^縣]+[市縣])/);
            if (cityMatch) {
              return `${cityMatch[1]}${district}`;
            }
            // Fallback: return only district if city cannot be determined
            return district;
          }
        }
      }
    }

    // Fallback: try to extract from formatted address
    const formattedAddress = data.results[0]?.formatted_address;
    if (formattedAddress) {
      // Try to match pattern like "台北市大安區", "新北市板橋區"
      const areaMatch = formattedAddress.match(/([^縣]+[市縣])([^市縣]+區)/);
      if (areaMatch) {
        return `${areaMatch[1]}${areaMatch[2]}`;
      }
      // Try to match district pattern like "大安區", "中正區"
      const districtMatch = formattedAddress.match(/([^市縣]+區)/);
      if (districtMatch) {
        // Try to find city before district
        const cityMatch = formattedAddress.match(/([^縣]+[市縣])/);
        if (cityMatch) {
          return `${cityMatch[1]}${districtMatch[1]}`;
        }
        return districtMatch[1];
      }
    }

    return null;
  } catch (error) {
    logger.error(error, "Error calling Geocoding API");
    return null;
  }
};

/**
 * Batch get areas for multiple coordinates
 * Uses caching to avoid duplicate API calls for nearby coordinates
 * Adds rate limiting to avoid hitting API quotas and REQUEST_DENIED errors
 */
const getAreasFromCoordinates = async (
  coordinates: Array<{ latitude: number; longitude: number }>
): Promise<Map<string, string | null>> => {
  const results = new Map<string, string | null>();
  const coordinateKey = (lat: number, lng: number) => `${lat.toFixed(6)},${lng.toFixed(6)}`;

  // Group coordinates by rounded values to reduce API calls
  const coordinateMap = new Map<string, { latitude: number; longitude: number; originalKeys: string[] }>();
  for (const coord of coordinates) {
    const key = coordinateKey(coord.latitude, coord.longitude);
    const originalKey = `${coord.latitude},${coord.longitude}`;
    
    if (coordinateMap.has(key)) {
      coordinateMap.get(key)!.originalKeys.push(originalKey);
    } else {
      coordinateMap.set(key, {
        latitude: coord.latitude,
        longitude: coord.longitude,
        originalKeys: [originalKey]
      });
    }
  }

  // Process coordinates in batches with delays to avoid rate limiting
  // Google Maps Geocoding API has a rate limit of 50 requests per second
  // We'll process 10 requests at a time with 200ms delay between batches
  const uniqueCoordinates = Array.from(coordinateMap.values());
  const BATCH_SIZE = 10; // Process 10 coordinates at a time
  const DELAY_MS = 200; // 200ms delay between batches (allows ~5 requests per second, well under limit)

  for (let i = 0; i < uniqueCoordinates.length; i += BATCH_SIZE) {
    const batch = uniqueCoordinates.slice(i, i + BATCH_SIZE);
    
    // Process batch in parallel
    const batchPromises = batch.map(async (coord) => {
      const area = await getAreaFromCoordinates(coord.latitude, coord.longitude);
      return { coord, area };
    });

    const batchResults = await Promise.all(batchPromises);

    // Map results back to all original coordinates
    for (const { coord, area } of batchResults) {
      for (const originalKey of coord.originalKeys) {
        results.set(originalKey, area);
      }
    }

    // Add delay between batches (except for the last batch)
    if (i + BATCH_SIZE < uniqueCoordinates.length) {
      await new Promise((resolve) => setTimeout(resolve, DELAY_MS));
    }
  }

  return results;
};

export const geocodingService = {
  getAreaFromCoordinates,
  getAreasFromCoordinates
};

