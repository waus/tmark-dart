import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tmark/tmark.dart' as tm;
import 'package:tmark_flutter/tmark_flutter.dart';
import 'package:video_player/video_player.dart';

/// Video preview and playback using loaders supplied by the application.
class TmarkVideoPlayer extends StatefulWidget {
  const TmarkVideoPlayer({
    super.key,
    required this.node,
    required this.getContent,
    required this.videoController,
  });
  final tm.VideoNode node;
  final TmarkContentLoader getContent;
  final FutureOr<VideoPlayerController> Function(String src) videoController;

  @override
  State<TmarkVideoPlayer> createState() => _TmarkVideoPlayerState();
}

class _TmarkVideoPlayerState extends State<TmarkVideoPlayer> {
  Future<Uint8List>? _preview;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  void _loadPreview() {
    _preview = widget.node.preview.isEmpty
        ? null
        : widget.getContent(widget.node.preview);
  }

  @override
  void didUpdateWidget(covariant TmarkVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.preview != widget.node.preview ||
        oldWidget.getContent != widget.getContent)
      _loadPreview();
    if (oldWidget.node.hasSpoiler != widget.node.hasSpoiler) _revealed = false;
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    if (preview == null) {
      return _buildVideo(
        context,
        const AspectRatio(
          aspectRatio: 16 / 9,
          child: ColoredBox(color: Colors.black),
        ),
        ready: true,
      );
    }
    return FutureBuilder<Uint8List>(
      future: preview,
      builder: (context, snapshot) => _buildVideo(
        context,
        snapshot.hasData
            ? Image.memory(snapshot.data!, fit: BoxFit.contain)
            : const AspectRatio(
                aspectRatio: 16 / 9,
                child: ColoredBox(color: Colors.black),
              ),
        ready: snapshot.hasData,
      ),
    );
  }

  Widget _buildVideo(
    BuildContext context,
    Widget image, {
    required bool ready,
  }) {
    final node = widget.node;
    return Stack(
      alignment: Alignment.center,
      children: [
        image,
        if (node.loop && (!node.hasSpoiler || _revealed) && ready)
          _VideoPlayback(
            key: ValueKey(node.src),
            src: node.src,
            videoController: widget.videoController,
            loop: true,
          ),
        if (!node.loop && (!node.hasSpoiler || _revealed))
          IconButton.filled(
            tooltip: 'Play video',
            icon: const Icon(Icons.play_arrow),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => Dialog.fullscreen(
                backgroundColor: Colors.black,
                child: SafeArea(
                  child: Stack(
                    children: [
                      Center(
                        child: _VideoPlayback(
                          src: node.src,
                          videoController: widget.videoController,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          tooltip: 'Close video',
                          color: Colors.white,
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (node.hasSpoiler && !_revealed)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _revealed = true),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Show video'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VideoPlayback extends StatefulWidget {
  const _VideoPlayback({
    super.key,
    required this.src,
    required this.videoController,
    this.loop = false,
  });
  final String src;
  final FutureOr<VideoPlayerController> Function(String src) videoController;
  final bool loop;

  @override
  State<_VideoPlayback> createState() => _VideoPlaybackState();
}

class _VideoPlaybackState extends State<_VideoPlayback> {
  VideoPlayerController? _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final controller = await widget.videoController(widget.src);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      if (widget.loop) {
        await controller.setLooping(true);
        await controller.setVolume(0);
      }
      await controller.play();
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Text('Video error: $_error');
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return widget.loop
          ? const SizedBox.shrink()
          : const CircularProgressIndicator();
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        if (!widget.loop)
          IconButton.filled(
            tooltip: controller.value.isPlaying ? 'Pause video' : 'Play video',
            icon: Icon(
              controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
            onPressed: () {
              setState(() {
                if (controller.value.isPlaying) {
                  controller.pause();
                } else {
                  controller.play();
                }
              });
            },
          ),
      ],
    );
  }
}
