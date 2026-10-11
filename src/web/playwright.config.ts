import { defineConfig } from "@playwright/test";
export default defineConfig({
  testDir: "./test/pr002", testMatch: "**/*.spec.ts", timeout: 30_000, workers: 1,
  use: { baseURL: "http://127.0.0.1:3000", browserName: "chromium", launchOptions: { executablePath: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH } },
  webServer: { command: "npm run dev -- --hostname 127.0.0.1 --port 3000", url: "http://127.0.0.1:3000", reuseExistingServer: false, timeout: 120_000 },
});
