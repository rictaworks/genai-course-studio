"use client";

import { useEffect, useState } from "react";
import { healthConfig } from "../lib/config";
import { offlineHealth, type Health } from "../lib/health";
import { ja } from "../lib/ja";

export default function HealthPanel() {
  const [health, setHealth] = useState<Health | null>(null);
  const [busy, setBusy] = useState(false);

  async function refresh() {
    setBusy(true);
    try {
      const response = await fetch(healthConfig.endpoint, { cache:"no-store", signal:AbortSignal.timeout(healthConfig.timeoutMs) });
      setHealth(await response.json());
    } catch {
      setHealth(offlineHealth());
    } finally {
      setBusy(false);
    }
  }

  useEffect(() => {
    const controller = new AbortController();
    fetch(healthConfig.endpoint, { cache: "no-store", signal: AbortSignal.any([controller.signal, AbortSignal.timeout(healthConfig.timeoutMs)]) })
      .then(response => response.json())
      .then(data => { if (!controller.signal.aborted) setHealth(data); })
      .catch(() => { if (!controller.signal.aborted) setHealth(offlineHealth()); });
    return () => controller.abort();
  }, []);
  const message = !health ? ja.checking : health.api === "offline" ? ja.offline : health.database === "ready" ? ja.ready : ja.unavailable;

  return <section aria-labelledby="health-heading">
    <h2 id="health-heading">{ja.heading}</h2>
    <p role="status" aria-live="polite">{message}</p>
    <p>{ja.worker}</p>
    <p>{ja.jobs}</p>
    <button type="button" disabled={busy} onClick={() => void refresh()}>{ja.refresh}</button>
  </section>;
}
