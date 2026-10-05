import 'dart:io';

import 'package:test/test.dart';
import 'package:tmark/tmark.dart';

void main() {
  test('marshal examples', () {
    expect(
      marshal(Header(size: 3, children: const [TText('x')])),
      '{h;#s{3}x}',
    );
    expect(marshal(const Paragraph([TText('x')])), '{p;x}');
    expect(
      marshal(const Link(href: 'https://example.com', children: [TText('x')])),
      '{a;#href{https://example.com}x}',
    );
    expect(
      marshal(
        const ListBlock([
          ListItem([
            Paragraph([TText('x')]),
          ], checked: false),
        ]),
      ),
      '{list;\n{#checked{f}{p;x}}\n}',
    );
    expect(
      marshal(
        const Table([
          TableRow([
            Cell([TText('x')]),
          ]),
        ]),
      ),
      '{table;\n{{x}}\n}',
    );
    expect(
      marshal(const Collage([ImageNode(src: 'a'), ImageNode(src: 'b')])),
      '{collage;\n{img;a}\n{img;b}\n}',
    );
    expect(
      marshal(const Slideshow([ImageNode(src: 'a'), VideoNode(src: 'b')])),
      '{slideshow;\n{img;a}\n{video;b}\n}',
    );
    expect(
      marshal(const ImageNode(src: '/file/x.jpg', hasSpoiler: true)),
      '{img;#has_spoiler{t}/file/x.jpg}',
    );
    expect(
      marshal(
        const VideoNode(src: 'clip.mp4', preview: 'cover.jpg', loop: true),
      ),
      '{video;#preview{cover.jpg}#loop{t}clip.mp4}',
    );
  });

  test('round trip', () {
    final values = <TmarkValue>[
      Header(size: 3, children: const [TText('x')]),
      const Paragraph([
        TText('plain ; '),
        Bold([TText('bold #{}')]),
      ]),
      const Link(href: 'https://example.com', children: [TText('x')]),
      const ImageNode(
        src: '/file/x.jpg',
        hasSpoiler: true,
        caption: Caption(credit: [TText('credit')], text: [TText('caption')]),
      ),
      const VideoNode(src: 'clip.mp4', preview: 'cover.jpg', loop: true),
      const DateTimeNode(unix: 1, timezone: 'UTC'),
      const Icon(src: '/file/x.png', alternativeText: 'x'),
      const ListBlock([
        ListItem([
          Paragraph([TText('x')]),
        ], checked: false),
      ]),
      const Collage([ImageNode(src: 'a'), ImageNode(src: 'b')]),
      const Slideshow([ImageNode(src: 'a'), VideoNode(src: 'b')]),
      const Table([
        TableRow([
          Cell([TText('A')], isHeader: true, align: TableCellAlign.left),
          Cell([TText('B')]),
        ]),
      ]),
      const Document(
        url: 'u',
        title: 't',
        content: [
          Paragraph([TText('x')]),
        ],
      ),
      const Document(
        url: 'u',
        title: 't',
        attachedMedia: [
          AttachedMedia(
            hash: 'h',
            content: [
              Paragraph([TText('attached')]),
            ],
          ),
        ],
        content: [
          Paragraph([TText('x')]),
        ],
      ),
      const Preformatted('a\nb', language: 'go'),
    ];

    for (final value in values) {
      final data = marshal(value);
      expect(marshal(unmarshal(data, soft: true)), data);
    }
  });

  test('repository examples parse', () {
    final files =
        Directory('test/examples')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.tmark'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(files, isNotEmpty);
    for (final file in files) {
      final source = file.readAsStringSync();
      expect(
        () => unmarshalDocument(source, soft: true),
        returnsNormally,
        reason: file.path,
      );
    }
  });

  test('valid fixtures round trip excluding trailing whitespace', () {
    final files =
        Directory('test/fixtures/valid')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.tmark'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(files, isNotEmpty);
    for (final file in files) {
      // The document codec does not preserve whitespace after the root node.
      final source = file.readAsStringSync().trimRight();
      expect(
        marshal(unmarshalDocument(source, soft: true)),
        source,
        reason: file.path,
      );
    }
  });

  test('valid node fixtures round trip byte for byte', () {
    final files =
        Directory('test/fixtures/valid')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.fixture'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(files, isNotEmpty);
    for (final file in files) {
      final source = file.readAsStringSync();
      expect(marshal(unmarshal(source)), source, reason: file.path);
    }
  });

  test('invalid fixtures are rejected', () {
    final files =
        Directory('test/fixtures/invalid')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.tmark'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(files, isNotEmpty);
    for (final file in files) {
      final source = file.readAsStringSync();
      expect(
        () => unmarshalDocument(source),
        throwsA(anything),
        reason: file.path,
      );
    }
  });
}
