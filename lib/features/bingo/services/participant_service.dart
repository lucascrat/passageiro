import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/participant_model.dart';

class ParticipantService {
  final SupabaseClient _client;
  static String? _cachedDeviceId;

  ParticipantService(this._client);

  /// Obtém o ID único do dispositivo
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    final deviceInfo = DeviceInfoPlugin();
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _cachedDeviceId = androidInfo.id; // Android ID único
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _cachedDeviceId = iosInfo.identifierForVendor ?? 'unknown_ios';
      } else {
        _cachedDeviceId = 'unknown_platform';
      }
    } catch (e) {
      _cachedDeviceId = 'device_id_error_${DateTime.now().millisecondsSinceEpoch}';
    }

    return _cachedDeviceId!;
  }

  /// Verifica se o participante atual está cadastrado e completo
  Future<bool> isParticipantRegistered() async {
    try {
      final deviceId = await getDeviceId();
      
      final response = await _client
          .rpc('is_participant_complete', params: {'device_uuid': deviceId});
      
      return response as bool? ?? false;
    } catch (e) {
      print('Erro ao verificar cadastro do participante: $e');
      return false;
    }
  }

  /// Busca o participante atual pelo device ID
  Future<Participant?> getCurrentParticipant() async {
    try {
      final deviceId = await getDeviceId();
      
      final response = await _client
          .rpc('get_participant_by_device', params: {'device_uuid': deviceId});
      
      if (response != null && response is List && response.isNotEmpty) {
        return Participant.fromJson(response.first as Map<String, dynamic>);
      }
      
      return null;
    } catch (e) {
      print('Erro ao buscar participante atual: $e');
      return null;
    }
  }

  /// Registra ou atualiza o participante atual
  Future<String?> registerParticipant(ParticipantForm form) async {
    try {
      final deviceId = await getDeviceId();
      
      final response = await _client.rpc('register_participant', params: {
        'p_name': form.name.trim(),
        'p_phone': form.phone.trim(),
        'p_pix_key': form.pixKey.trim(),
        'p_device_id': deviceId,
      });
      
      return response as String?;
    } catch (e) {
      print('Erro ao registrar participante: $e');
      throw Exception('Falha ao registrar participante: ${e.toString()}');
    }
  }

  /// Atualiza os dados do participante atual
  Future<bool> updateParticipant(ParticipantForm form) async {
    try {
      // Utiliza a mesma RPC de registro, que já faz upsert por device_id
      final deviceId = await getDeviceId();

      final response = await _client.rpc('register_participant', params: {
        'p_name': form.name.trim(),
        'p_phone': form.phone.trim(),
        'p_pix_key': form.pixKey.trim(),
        'p_device_id': deviceId,
      });

      return response != null;
    } catch (e) {
      print('Erro ao atualizar participante: $e');
      throw Exception('Falha ao atualizar participante: ${e.toString()}');
    }
  }

  /// Valida o formato do telefone brasileiro
  static bool isValidPhone(String phone) {
    // Remove espaços, parênteses e hífens
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\(\)\-]'), '');
    
    // Verifica se tem 10 ou 11 dígitos (com ou sem código do país)
    final phoneRegex = RegExp(r'^(\+?55)?[1-9]{2}9?[0-9]{8}$');
    return phoneRegex.hasMatch(cleanPhone);
  }

  /// Valida o formato da chave PIX
  static bool isValidPixKey(String pixKey) {
    final cleanKey = pixKey.trim();
    
    if (cleanKey.length < 5) return false;
    
    // CPF (11 dígitos)
    if (RegExp(r'^\d{11}$').hasMatch(cleanKey)) return true;
    
    // Telefone
    if (isValidPhone(cleanKey)) return true;
    
    // Email
    if (RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(cleanKey)) return true;
    
    // Chave aleatória (UUID ou similar)
    if (cleanKey.length >= 20) return true;
    
    return false;
  }

  /// Formata o telefone para exibição
  static String formatPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\(\)\-]'), '');
    
    if (cleanPhone.length == 11) {
      return '(${cleanPhone.substring(0, 2)}) ${cleanPhone.substring(2, 7)}-${cleanPhone.substring(7)}';
    } else if (cleanPhone.length == 10) {
      return '(${cleanPhone.substring(0, 2)}) ${cleanPhone.substring(2, 6)}-${cleanPhone.substring(6)}';
    }
    
    return phone;
  }

  /// Limpa o cache do device ID (útil para testes)
  static void clearDeviceIdCache() {
    _cachedDeviceId = null;
  }
}