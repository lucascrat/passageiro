// Configurações do Sistema de Bingo
// URLs e credenciais para produção

const String kSupabaseUrl = 'https://yubztvbrgrldfueelxfh.supabase.co';
const String kSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl1Ynp0dmJyZ3JsZGZ1ZWVseGZoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3MDYwNzgsImV4cCI6MjA3NTI4MjA3OH0.2TrL_0LARjlNSctImwGMht7-hYxMNNSuhnGfLJMySU4';

// URL do painel admin em produção (deploy via Vercel)
const String kBingoAdminUrl =
    'https://bingo-admin-9c60fxc8o-lucas-projects-a375f211.vercel.app';

// Configurações de Realtime
const String kRealtimeChannelName = 'bingo_realtime';
const Duration kReconnectDelay = Duration(seconds: 3);
const Duration kConnectionTimeout = Duration(seconds: 10);

// Configurações de debug
const bool kEnableDebugLogs = true;

void debugLog(String message) {
  if (kEnableDebugLogs) {
    print('🎯 BINGO: $message');
  }
}
