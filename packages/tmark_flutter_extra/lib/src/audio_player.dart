import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Audio controls. The application supplies a source for each URL.
class TmarkAudioPlayer extends StatefulWidget {
  const TmarkAudioPlayer({
    super.key,
    required this.src,
    required this.audioSource,
  });
  final String src;
  final FutureOr<AudioSource> Function(String src) audioSource;

  @override
  State<TmarkAudioPlayer> createState() => _TmarkAudioPlayerState();
}

class _TmarkAudioPlayerState extends State<TmarkAudioPlayer> {
  AudioPlayer _player = AudioPlayer();
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(TmarkAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src) {
      unawaited(_player.dispose());
      _player = AudioPlayer();
      _error = null;
      _initialize();
    }
  }

  Future<void> _initialize() async {
    final player = _player;
    try {
      final source = await widget.audioSource(widget.src);
      if (!mounted || player != _player) return;
      await player.setAudioSource(source);
    } catch (error) {
      if (mounted && player == _player) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Text('Audio error: $_error');
    return Row(
      children: [
        StreamBuilder<PlayerState>(
          stream: _player.playerStateStream,
          builder: (context, snapshot) {
            final playing = snapshot.data?.playing ?? false;
            final completed =
                snapshot.data?.processingState == ProcessingState.completed;
            return IconButton.filled(
              tooltip: playing ? 'Pause audio' : 'Play audio',
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              onPressed: () async {
                if (playing && !completed) {
                  await _player.pause();
                } else {
                  if (completed) await _player.seek(Duration.zero);
                  await _player.play();
                }
              },
            );
          },
        ),
        Expanded(
          child: StreamBuilder<Duration?>(
            stream: _player.durationStream,
            builder: (context, durationSnapshot) => StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, positionSnapshot) {
                final duration = durationSnapshot.data ?? Duration.zero;
                final position = positionSnapshot.data ?? Duration.zero;
                final max = duration.inMilliseconds.toDouble();
                return Slider(
                  value: position.inMilliseconds.toDouble().clamp(0, max),
                  max: max > 0 ? max : 1,
                  onChanged: max > 0
                      ? (value) =>
                            _player.seek(Duration(milliseconds: value.round()))
                      : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
