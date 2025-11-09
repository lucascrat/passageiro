import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bingo_config.dart';
import 'bingo_admin_panel_screen.dart';

class BingoAdminLoginScreen extends StatefulWidget {
  const BingoAdminLoginScreen({super.key});
  @override
  State<BingoAdminLoginScreen> createState() => _BingoAdminLoginScreenState();
}

class _BingoAdminLoginScreenState extends State<BingoAdminLoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pré-preencher com as credenciais do admin para teste
    _user.text = 'lrlucasrafael11@gmail.com';
    _pass.text = '01Deus02@';
  }

  void _login() {
    final user = _user.text.trim();
    final pass = _pass.text;

    if (kSupabaseUrl.isNotEmpty && kSupabaseAnonKey.isNotEmpty) {
      _loginWithSupabase(user, pass);
      return;
    }
    // Modo local (sem Supabase): credenciais fixas
    if (user == 'holanda' && pass == 'holanda2025@') {
      Get.off(() => const BingoAdminPanelScreen());
    } else {
      setState(() { _error = 'Login ou senha inválidos'; });
    }
  }

  Future<void> _loginWithSupabase(String user, String pass) async {
    try {
      // print('DEBUG: Iniciando login com Supabase');
      // print('DEBUG: URL: $kSupabaseUrl');
      // print('DEBUG: Email: $user');
      // print('DEBUG: USE_SUPABASE: $kUseSupabase');
      
      // Inicializa se necessário
      try {
        await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
        // print('DEBUG: Supabase inicializado com sucesso');
      } catch (e) {
        // print('DEBUG: Erro ao inicializar Supabase: $e');
      }
      final client = Supabase.instance.client;

      if (!user.contains('@')) {
        setState(() { _error = 'Use seu e-mail para login (Supabase)'; });
        return;
      }

      // print('DEBUG: Tentando fazer login...');
      final res = await client.auth.signInWithPassword(email: user, password: pass);
      // print('DEBUG: Resposta do login: ${res.session != null ? "Sucesso" : "Falha"}');
      // print('DEBUG: User ID: ${res.user?.id}');
      
      if (res.session == null || res.user == null) {
        setState(() { _error = 'Falha no login. Verifique e-mail/senha.'; });
        return;
      }

      // Verificar se o usuário é admin
      // print('DEBUG: Verificando se usuário é admin...');
      try {
        final adminCheck = await client
            .from('admin_users')
            .select('user_id')
            .eq('user_id', res.user!.id)
            .maybeSingle();
        
        // print('DEBUG: Resultado da verificação admin: $adminCheck');
        
        if (adminCheck == null) {
          // Tentar promover o usuário a admin
          // print('DEBUG: Tentando promover usuário a admin...');
          await client.from('admin_users').upsert({'user_id': res.user!.id});
          // print('DEBUG: Usuário promovido a admin com sucesso');
        }
      } catch (e) {
        // print('DEBUG: Erro ao verificar/promover admin: $e');
      }

      // print('DEBUG: Login bem-sucedido, navegando para painel admin');
      Get.off(() => const BingoAdminPanelScreen());
    } catch (e) {
      // print('DEBUG: Erro geral no login: $e');
      setState(() { _error = 'Erro: ${e.toString()}'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Bingo - Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _user, decoration: const InputDecoration(labelText: 'Usuário')), 
            const SizedBox(height: 12),
            TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Senha'), obscureText: true),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _login, child: const Text('Entrar')),
            ),
          ],
        ),
      ),
    );
  }
}