import 'package:flutter/material.dart';
import '../models/bingo_models.dart';

class BingoCardWidget extends StatelessWidget {
  final BingoCard card;
  const BingoCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardSize = screenWidth - 56; // Margens (32px) + padding (4px) + border (3px) + buffer extra (17px)
    final cellSize = (cardSize - 25) / 5; // Reduzir ainda mais para evitar overflow
    
    return Container(
      width: cardSize,
      padding: const EdgeInsets.all(1), // Padding ainda menor
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // Border radius menor
        border: Border.all(
          color: Colors.purple.shade300,
          width: 1.5, // Borda mais fina
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título "BINGO" mais compacto
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4), // Padding reduzido
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade500, Colors.purple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'BINGO',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14, // Fonte menor
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          
          const SizedBox(height: 2), // Espaçamento mínimo
          
          // Grid da cartela otimizado
          Column(
            children: List.generate(5, (row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 0.5), // Espaçamento mínimo entre linhas
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (col) {
                    final number = card.numbers[row][col];
                    final isMarked = card.marked[row][col];
                    final isCenter = row == 2 && col == 2;
                    
                    return Container(
                      width: cellSize,
                      height: cellSize,
                      margin: const EdgeInsets.all(0.1), // Margem ainda menor
                      decoration: BoxDecoration(
                        gradient: isCenter 
                          ? LinearGradient(
                              colors: [Colors.purple.shade200, Colors.purple.shade300],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : isMarked 
                            ? LinearGradient(
                                colors: [Colors.green.shade200, Colors.green.shade300],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [Colors.grey.shade100, Colors.grey.shade200],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(4), // Border radius menor
                        border: Border.all(
                          color: isCenter 
                            ? Colors.purple.shade400
                            : isMarked 
                              ? Colors.green.shade400 
                              : Colors.grey.shade400,
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Número ou estrela
                          Center(
                            child: isCenter
                              ? Icon(
                                  Icons.star,
                                  color: Colors.purple.shade700,
                                  size: (cellSize * 0.4).clamp(14.0, 20.0), // Estrela proporcional
                                )
                              : Text(
                                  number?.toString() ?? '',
                                  style: TextStyle(
                                    fontSize: (cellSize * 0.25).clamp(8.0, 14.0), // Fonte proporcional ao tamanho da célula
                                    fontWeight: FontWeight.bold,
                                    color: isMarked 
                                      ? Colors.green.shade800 
                                      : Colors.black87,
                                  ),
                                ),
                          ),
                          
                          // Checkmark se marcado
                          if (isMarked && !isCenter)
                            Positioned(
                              top: 1,
                              right: 1,
                              child: Container(
                                width: (cellSize * 0.2).clamp(10.0, 14.0),
                                height: (cellSize * 0.2).clamp(10.0, 14.0),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: (cellSize * 0.15).clamp(6.0, 10.0),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
