part of tmark_flutter;

class _VideoMediaContent extends StatelessWidget {
  const _VideoMediaContent({required this.src, required this.preview});

  final String src;
  final String preview;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(src);
    final image = preview.isEmpty
        ? const AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(color: Color(0xff18181b)),
          )
        : _ResolvedImage(src: preview);
    return Stack(
      alignment: Alignment.center,
      children: [
        image,
        _TmarkIconButton(
          tooltip: 'Open video',
          icon: _TmarkIcon.play,
          size: 48,
          iconSize: 24,
          backgroundColor: _styleOf(context).linkColor,
          foregroundColor: const Color(0xffffffff),
          onPressed: uri == null || !uri.hasScheme
              ? null
              : () => launchUrl(uri, mode: LaunchMode.externalApplication),
        ),
      ],
    );
  }
}
