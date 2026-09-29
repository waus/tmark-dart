import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:source_gen/source_gen.dart';

import 'generator.dart';

Future<void> main() async {
  final packageRoot = Directory.current.absolute;
  final targets = [
    ('lib/tmark.dart', 'lib/tmark.g.dart'),
    ('test/generated_models.dart', 'test/generated_models.g.dart'),
  ];
  final sources = [
    for (final (input, _) in targets) File('${packageRoot.path}/$input').absolute.path,
  ];
  final collection = AnalysisContextCollection(includedPaths: sources);
  try {
    for (final (input, output) in targets) {
      final sourcePath = File('${packageRoot.path}/$input').absolute.path;
      final result = await collection
          .contextFor(sourcePath)
          .currentSession
          .getResolvedLibrary(sourcePath);
      if (result is! ResolvedLibraryResult) {
        throw StateError('Could not resolve $input: $result');
      }
      final generated = TmarkGenerator().generate(LibraryReader(result.element));
      final partOf = input.substring(input.lastIndexOf('/') + 1);
      final content = '// GENERATED CODE - DO NOT MODIFY BY HAND\n\n'
          "part of '$partOf';\n\n"
          '// **************************************************************************\n'
          '// TmarkGenerator\n'
          '// **************************************************************************\n\n'
          '$generated\n';
      final outputPath = '${packageRoot.path}/$output';
      await File(outputPath).writeAsString(content);
      final formatted = await Process.run(Platform.resolvedExecutable, [
        'format',
        outputPath,
      ]);
      if (formatted.exitCode != 0) {
        throw StateError('Could not format $output: ${formatted.stderr}');
      }
      stdout.writeln('Generated $output');
    }
  } finally {
    await collection.dispose();
  }
}
