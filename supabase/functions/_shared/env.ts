// Environment access that never throws (missing permission / variable → undefined).

export function readEnv(name: string): string | undefined {
  try {
    const value = Deno.env.get(name);
    return value === undefined || value.trim() === "" ? undefined : value;
  } catch {
    return undefined;
  }
}

/** Secret API key: new `sb_secret_…` key first, legacy service_role JWT as a fallback. */
export function serviceKey(): string | undefined {
  return readEnv("SUPABASE_SECRET_KEY") ?? readEnv("SUPABASE_SERVICE_ROLE_KEY");
}
