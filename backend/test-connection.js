// Test Prisma connection string parsing
const testUrl = "postgresql://postgres:K9sVp2%29kmkBmEN%5D%7E@/run_city_db?host=/cloudsql/tung-tung-tung-sahur-477601:asia-east1:tung";
console.log("Testing URL:", testUrl);

try {
  const url = new URL(testUrl);
  console.log("Parsed URL:");
  console.log("  Protocol:", url.protocol);
  console.log("  Username:", url.username);
  console.log("  Password:", url.password);
  console.log("  Hostname:", url.hostname);
  console.log("  Pathname:", url.pathname);
  console.log("  Search:", url.search);
  console.log("  Host param:", url.searchParams.get('host'));
} catch (e) {
  console.error("Error parsing URL:", e.message);
}
