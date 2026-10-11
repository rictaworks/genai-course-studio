export type Health = {
  api: "online" | "offline";
  database: "ready" | "unavailable" | "unverified";
  worker: "unverified";
};

export function sanitizeHealth(input: unknown): Health {
  const data = input && typeof input === "object" ? input as Record<string, unknown> : {};
  return {
    api: "online",
    database: data.status === "ready" && data.database === "ready" ? "ready" : "unavailable",
    worker: "unverified",
  };
}

export function offlineHealth(): Health {
  return {api:"offline", database:"unverified", worker:"unverified"};
}
