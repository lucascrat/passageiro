import 'dart:async';
import 'bingo_realtime_service.dart';
import 'bingo_supabase_service.dart';

/// Factory simplificado que retorna apenas o BingoSupabaseService
/// Removemos a complexidade de múltiplos serviços para focar na estabilidade
Future<BingoRealtimeService> createBingoService() async {
  return BingoSupabaseService.create();
}