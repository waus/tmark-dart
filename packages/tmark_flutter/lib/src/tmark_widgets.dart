part of tmark_flutter;

class _TmarkDivider extends StatelessWidget {
  const _TmarkDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: ColoredBox(
        color: _styleOf(context).dividerColor ?? const Color(0xffe4e4e7),
      ),
    );
  }
}

class TmarkMediaPlaceholder extends StatelessWidget {
  const TmarkMediaPlaceholder({
    super.key,
    required this.kind,
    required this.src,
    this.error,
  });

  final String kind;
  final String src;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        width: double.infinity,
        height: constraints.hasBoundedHeight ? double.infinity : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: _styleOf(context).dividerColor ?? const Color(0xffe4e4e7),
            ),
            borderRadius: BorderRadius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(error == null ? '$kind: $src' : '$kind: $src\n$error'),
          ),
        ),
      ),
    );
  }
}
