const LEGACY_SSL_MODES = new Set(['prefer', 'require', 'verify-ca']);

export function normalizeDatabaseUrl(databaseUrl: string): string {
  const parsedUrl = new URL(databaseUrl);
  const sslMode = parsedUrl.searchParams.get('sslmode');

  if (sslMode && LEGACY_SSL_MODES.has(sslMode)) {
    parsedUrl.searchParams.set('sslmode', 'verify-full');
  }

  return parsedUrl.toString();
}

