import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BingoMainScreen extends StatelessWidget {
  const BingoMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bingo'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.purple.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.casino,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bem-vindo ao Bingo!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Escolha uma opção abaixo para começar',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Menu Options
            Expanded(
              child: Column(
                children: [
                  _buildMenuCard(
                    icon: Icons.play_circle_filled,
                    title: 'Jogo Ativo',
                    subtitle: 'Ver números sorteados e prêmio atual',
                    color: Colors.green,
                    onTap: () => Get.toNamed('/bingo-game'),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuCard(
                    icon: Icons.grid_view,
                    title: 'Minha Cartela',
                    subtitle: 'Jogar com sua cartela de bingo',
                    color: Colors.blue,
                    onTap: () => Get.toNamed('/bingo-client'),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuCard(
                    icon: Icons.history,
                    title: 'Histórico',
                    subtitle: 'Ver todos os números já sorteados',
                    color: Colors.orange,
                    onTap: () => Get.toNamed('/bingo-history'),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuCard(
                    icon: Icons.admin_panel_settings,
                    title: 'Painel Admin',
                    subtitle: 'Acesso para administradores',
                    color: Colors.red,
                    onTap: () => Get.toNamed('/bingo_admin'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}