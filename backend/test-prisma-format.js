// Test different Prisma connection string formats for Unix socket
const formats = [
  "postgresql://postgres:K9sVp2%29kmkBmEN%5D%7E@/run_city_db?host=/cloudsql/tung-tung-tung-sahur-477601:asia-east1:tung",
  "postgresql://postgres:K9sVp2%29kmkBmEN%5D%7E@localhost/run_city_db?host=/cloudsql/tung-tung-tung-sahur-477601:asia-east1:tung",
  "postgresql://postgres:K9sVp2%29kmkBmEN%5D%7E@unix/run_city_db?host=/cloudsql/tung-tung-tung-sahur-477601:asia-east1:tung",
];

formats.forEach((url, i) => {
  console.log(`\nFormat ${i + 1}:`);
  console.log(url);
  try {
    // Try to parse as URL
    const parsed = new URL(url);
    console.log("  ✓ URL parsed successfully");
    console.log("  Hostname:", parsed.hostname || "(empty)");
    console.log("  Host param:", parsed.searchParams.get('host'));
  } catch (e) {
    console.log("  ✗ URL parse error:", e.message);
  }
});
