import 'package:flutter/widgets.dart';
import 'package:flutter_math_fork/flutter_math.dart' as fm;

/// Renders a TeX expression inline or as a display block.
class TmarkMath extends StatelessWidget {
  const TmarkMath({super.key, required this.expression, this.display = false});

  final String expression;
  final bool display;

  @override
  Widget build(BuildContext context) {
    final textStyle = DefaultTextStyle.of(context).style;
    final math = fm.Math.tex(
      expression,
      mathStyle: display ? fm.MathStyle.display : fm.MathStyle.text,
      textStyle: display
          ? textStyle.copyWith(fontSize: (textStyle.fontSize ?? 14) * 1.2)
          : textStyle,
    );
    return display
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Center(child: math),
          )
        : math;
  }
}
