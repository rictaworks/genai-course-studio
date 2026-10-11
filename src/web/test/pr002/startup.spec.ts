import { expect, test } from "@playwright/test";

test("Japanese startup page remains usable with actual backend state", async ({ page, request }) => {
  const response = await request.get("/api/health");
  expect([200, 503]).toContain(response.status());
  const health = await response.json();
  await page.goto("/");
  await expect(page.getByRole("heading", {name:"講座開発スタジオ"})).toBeVisible();
  await expect(page.getByText("外部AIへの送信は無効です。")).toBeVisible();
  await expect(page.getByText(health.api === "offline" ? "APIに接続できません" : health.database === "ready" ? "DB接続を確認しました" : "DBが未設定、または接続できません")).toBeVisible();
  await expect(page.getByText("ワーカーの実行は未検証です。")).toBeVisible();
});

for (const scenario of [
  { name:"API offline", payload:{api:"offline",database:"unverified",worker:"unverified"}, text:"APIに接続できません" },
  { name:"database missing", payload:{api:"online",database:"unavailable",worker:"unverified"}, text:"DBが未設定、または接続できません" },
  { name:"database ready", payload:{api:"online",database:"ready",worker:"unverified"}, text:"DB接続を確認しました" },
]) {
  test(`display boundary with simulated ${scenario.name}`, async ({ page }) => {
    await page.route("**/api/health", route => route.fulfill({status:scenario.payload.database === "ready" ? 200 : 503, json:scenario.payload}));
    await page.goto("/");
    await expect(page.getByText(scenario.text)).toBeVisible();
    await page.getByRole("button",{name:"状態を再確認"}).click();
    await expect(page.getByText(scenario.text)).toBeVisible();
  });
}
