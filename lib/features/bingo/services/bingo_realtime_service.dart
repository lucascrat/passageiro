import 'dart:async';
import '../models/bingo_models.dart';

abstract class BingoRealtimeService {
  Stream<BingoEvent> get events;
  Stream<bool> get connected;
  Future<void> connect();
  Future<void> sendEvent(BingoEvent event);
  Future<void> disconnect();
  Future<void> close();
}