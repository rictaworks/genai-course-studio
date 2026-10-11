import { afterEach, describe, expect, it, vi } from "vitest";
import { GET } from "../../app/api/health/route";
import { sanitizeHealth } from "../../lib/health";

afterEach(() => vi.unstubAllGlobals());
describe("public health boundary", () => {
  it("allowlists readiness fields without disclosing upstream details", () => {
    expect(sanitizeHealth({ status: "ready", database: "ready", worker: "unverified", secret: "internal" }))
      .toEqual({ api: "online", database: "ready", worker: "unverified" });
  });
  it("fails closed for malformed or contradictory health", () => {
    for (const input of [null, {}, { status: "unavailable", database: "ready" }]) {
      expect(sanitizeHealth(input)).toEqual({ api: "online", database: "unavailable", worker: "unverified" });
    }
  });
  it("fetches only the fixed readiness endpoint with no forwarded input", async () => {
    const upstream = vi.fn().mockResolvedValue(new Response(JSON.stringify({status:"ready",database:"ready",worker:"unverified"})));
    vi.stubGlobal("fetch", upstream);
    const response = await GET();
    expect(response.status).toBe(200);
    expect(upstream).toHaveBeenCalledWith("http://127.0.0.1:3001/health", expect.objectContaining({ cache:"no-store", redirect:"error", signal:expect.any(AbortSignal) }));
    expect(await response.json()).toEqual({api:"online",database:"ready",worker:"unverified"});
  });
  it("preserves DB unavailable as 503", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(new Response(JSON.stringify({status:"unavailable",database:"unavailable",worker:"unverified"}), {status:503})));
    const response = await GET();
    expect(response.status).toBe(503);
    expect(await response.json()).toEqual({api:"online",database:"unavailable",worker:"unverified"});
  });
  it("does not treat upstream errors as healthy", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(new Response(JSON.stringify({status:"ready",database:"ready"}), {status:500})));
    expect((await GET()).status).toBe(503);
  });
  it("returns safe API offline state on network failure without exception details", async () => {
    vi.stubGlobal("fetch", vi.fn().mockRejectedValue(new Error("sensitive connection details")));
    const response = await GET();
    expect(response.status).toBe(503);
    expect(response.headers.get("cache-control")).toBe("no-store");
    expect(await response.json()).toEqual({api:"offline",database:"unverified",worker:"unverified"});
  });
});
