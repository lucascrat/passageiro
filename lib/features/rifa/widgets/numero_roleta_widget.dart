// Widget para animação de roleta de números
import 'package:flutter/material.dart';
import 'dart:math';

class NumeroRoletaWidget extends StatefulWidget {
  final AnimationController animationController;
  final int? numeroFinal;
  final int numeroMin;
  final int numeroMax;

  const NumeroRoletaWidget({
    super.key,
    required this.animationController,
    this.numeroFinal,
    required this.numeroMin,
    required this.numeroMax,
  });

  @override
  State<NumeroRoletaWidget> createState() => _NumeroRoletaWidgetState();
}

class _NumeroRoletaWidgetState extends State<NumeroRoletaWidget> {
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  int _currentNumber = 1;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startNumberRotation();
  }

  void _setupAnimations() {
    // Animação de rotação da roleta
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0, // 8 voltas completas
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: Curves.easeOutCubic,
    ));

    // Animação de escala para efeito visual
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));
  }

  void _startNumberRotation() {
    widget.animationController.addListener(() {
      if (widget.animationController.isAnimating) {
        // Durante a animação, mostrar números aleatórios
        final random = Random();
        final newNumber = widget.numeroMin + 
            random.nextInt(widget.numeroMax - widget.numeroMin + 1);
        
        if (newNumber != _currentNumber) {
          setState(() {
            _currentNumber = newNumber;
          });
        }
      } else if (widget.animationController.isCompleted && widget.numeroFinal != null) {
        // No final, mostrar o número final
        setState(() {
          _currentNumber = widget.numeroFinal!;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 2 * pi,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEF4444),
                    const Color(0xFFDC2626),
                  ],
                  stops: const [0.0, 1.0],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
              ),
              child: Stack(
                children: [
                  // Círculos decorativos
                  ...List.generate(8, (index) {
                    final angle = (index * pi * 2) / 8;
                    return Positioned(
                      left: 60 + cos(angle) * 35 - 6,
                      top: 60 + sin(angle) * 35 - 6,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                  
                  // Número central
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 100),
                          child: Text(
                            '$_currentNumber',
                            key: ValueKey(_currentNumber),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}