// Widget para exibir números com animação
import 'package:flutter/material.dart';

class NumeroAnimadoWidget extends StatefulWidget {
  final int numero;
  final AnimationController animationController;
  final Color? backgroundColor;
  final Color? textColor;
  final double? size;

  const NumeroAnimadoWidget({
    super.key,
    required this.numero,
    required this.animationController,
    this.backgroundColor,
    this.textColor,
    this.size,
  });

  @override
  State<NumeroAnimadoWidget> createState() => _NumeroAnimadoWidgetState();
}

class _NumeroAnimadoWidgetState extends State<NumeroAnimadoWidget>
    with SingleTickerProviderStateMixin {
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Animação de escala (bounce effect)
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    // Animação de rotação
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    ));

    // Animação de opacidade
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? 80.0;
    final backgroundColor = widget.backgroundColor ?? Colors.white;
    final textColor = widget.textColor ?? Colors.black87;

    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 0.5, // Rotação sutil
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: backgroundColor.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 0),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${widget.numero}',
                    style: TextStyle(
                      fontSize: size * 0.35,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}