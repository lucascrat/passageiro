// Widget personalizado para player de vídeo da rifa
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerWidget extends StatefulWidget {
  final YoutubePlayerController controller;
  final VoidCallback? onVideoEnded;
  final String? videoTitle;

  const VideoPlayerWidget({
    super.key,
    required this.controller,
    this.onVideoEnded,
    this.videoTitle,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool _isVideoEnded = false;

  @override
  void initState() {
    super.initState();
    _setupVideoListener();
  }

  void _setupVideoListener() {
    widget.controller.addListener(() {
      final isEnded = widget.controller.value.playerState == PlayerState.ended;
      
      if (isEnded && !_isVideoEnded) {
        setState(() {
          _isVideoEnded = true;
        });
        widget.onVideoEnded?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Player de vídeo
            YoutubePlayer(
              controller: widget.controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: const Color(0xFF8B5CF6),
              progressColors: const ProgressBarColors(
                playedColor: Color(0xFF8B5CF6),
                handleColor: Color(0xFF7C3AED),
              ),
              onReady: () {
                // Vídeo pronto para reprodução
              },
              onEnded: (metaData) {
                setState(() {
                  _isVideoEnded = true;
                });
                widget.onVideoEnded?.call();
              },
            ),
            
            // Overlay com título do vídeo
            if (widget.videoTitle != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    widget.videoTitle!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            
            // Indicador de vídeo assistido
            if (_isVideoEnded)
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Assistido',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}