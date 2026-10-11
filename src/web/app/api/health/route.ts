import { serverConfig } from "../../../lib/server-config";
import { offlineHealth, sanitizeHealth } from "../../../lib/health";

export const dynamic = "force-dynamic";

export async function GET() {
  const headers = { "Cache-Control": "no-store" };
  try {
    const response = await fetch(serverConfig.upstream, {
      cache: "no-store", redirect: "error", signal: AbortSignal.timeout(serverConfig.timeoutMs),
    });
    const health = sanitizeHealth(await response.json());
    if (!response.ok) health.database = "unavailable";
    return Response.json(health, { status: health.database === "ready" ? 200 : 503, headers });
  } catch {
    return Response.json(offlineHealth(), { status: 503, headers });
  }
}
