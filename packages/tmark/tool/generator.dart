import 'dart:convert';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

TypeChecker _annotation(String name) =>
    TypeChecker.fromUrl('package:tmark/tmark.dart#$name');

DartObject? _read(Element element, String name) =>
    _annotation(name).firstAnnotationOf(element, throwOnUnresolved: false);

class TmarkGenerator {
  String generate(LibraryReader library) {
    final output = <String>[];
    final tags = <String>{};
    for (final model in library.classes) {
      final node = _read(model, 'TmarkNode');
      final record = _read(model, 'TmarkRecord');
      if (node == null && record == null) continue;
      if (node != null && record != null)
        _fail(model, 'Choose TmarkNode or TmarkRecord, not both.');
      if (node != null) {
        final tag = node.getField('tag')!.toStringValue()!;
        if (!RegExp(r'^[a-z0-9_-]{1,32}$').hasMatch(tag))
          _fail(model, 'Invalid tmark tag: $tag');
        if (!tags.add(tag)) _fail(model, 'Duplicate tmark tag: $tag');
      }
      output.add(_ModelGenerator(library.element, model).generate(node));
    }
    return output.join('\n\n');
  }
}

String _literal(String value) => jsonEncode(value);

Never _fail(Element element, String message) =>
    throw InvalidGenerationSourceError(message, element: element);

class _ModelGenerator {
  _ModelGenerator(this.library, this.model);
  final LibraryElement library;
  final ClassElement model;

  String _ref(Element element) {
    final name = element.name!;
    if (element.library == library ||
        element.library?.uri.toString() == 'dart:core')
      return name;
    for (final fragment in library.fragments) {
      for (final import in fragment.libraryImports) {
        if (import.namespace.definedNames2[name] == element) {
          final prefix = import.prefix?.element.name;
          return prefix == null ? name : '$prefix.$name';
        }
      }
    }
    _fail(
      model,
      'Import ${element.library?.uri} so the generated schema can reference $name.',
    );
  }

  String _runtime(String name) {
    if (library.uri.toString() == 'package:tmark/tmark.dart') return name;
    for (final fragment in library.fragments) {
      for (final import in fragment.libraryImports) {
        final element =
            import.importedLibrary?.exportNamespace.definedNames2[name];
        if (element != null &&
            element.library?.uri.toString() == 'package:tmark/tmark.dart')
          return _ref(element);
      }
    }
    _fail(model, 'Import package:tmark/tmark.dart, including $name.');
  }

  String _type(DartType type, {bool includeNullability = true}) {
    if (type is! InterfaceType)
      _fail(
        model,
        'Unsupported field type $type. Use @TmarkUsing or a manual schema.',
      );
    final arguments = type.typeArguments.isEmpty
        ? ''
        : '<${type.typeArguments.map(_type).join(', ')}>';
    return '${_ref(type.element)}$arguments${includeNullability && type.nullabilitySuffix == NullabilitySuffix.question ? '?' : ''}';
  }

  bool _isNode(InterfaceType type) => const TypeChecker.fromUrl(
    'package:tmark/tmark.dart#TmarkValue',
  ).isAssignableFromType(type);

  String _codec(DartType type, FieldElement field, {bool nullable = true}) {
    if (type is! InterfaceType)
      _fail(
        field,
        'Unsupported field type $type. Supply @TmarkUsing(codecFactory).',
      );
    final types = _runtime('FieldTypes');
    if (nullable && type.nullabilitySuffix == NullabilitySuffix.question) {
      return '${_codec(type, field, nullable: false)}.optional()';
    }
    final name = type.element.name;
    if (type.element.library.uri.toString() == 'dart:core') {
      switch (name) {
        case 'String':
          return '$types.string';
        case 'int':
          return '$types.integer';
        case 'double':
          return '$types.doubleValue';
        case 'bool':
          return '$types.boolean';
        case 'List':
          final item = type.typeArguments.single;
          if (item is InterfaceType &&
              item.nullabilitySuffix != NullabilitySuffix.question) {
            if (item.element.name == 'RichNode' &&
                item.element.library.uri.toString() ==
                    'package:tmark/tmark.dart')
              return '$types.richText';
            if (_isNode(item)) return '$types.nodes<${_type(item)}>()';
          }
      }
    }
    if (type.element is EnumElement)
      return '$types.enumeration(${_ref(type.element)}.values)';
    if (_isNode(type))
      return '$types.node<${_type(type, includeNullability: false)}>()';
    if (_read(type.element, 'TmarkRecord') != null) {
      final ref = _ref(type.element);
      final dot = ref.lastIndexOf('.');
      final schema =
          '${dot < 0 ? '' : ref.substring(0, dot + 1)}\$${type.element.name}Schema';
      return '$types.record($schema)';
    }
    _fail(
      field,
      'Cannot infer a codec for $type. Use @TmarkRecord or @TmarkUsing(codecFactory).',
    );
  }

  String _custom(DartObject annotation, FieldElement field) {
    final function = annotation.getField('codec')?.toFunctionValue();
    if (function != null &&
        function.formalParameters.any((p) => p.isRequired)) {
      _fail(field, 'A codec factory must be callable without arguments.');
    }
    final returnType = function?.returnType;
    if (returnType is! InterfaceType ||
        returnType.element.name != 'FieldType' ||
        returnType.element.library.uri.toString() !=
            'package:tmark/tmark.dart' ||
        returnType.typeArguments.single != field.type) {
      _fail(field, 'A codec factory must return FieldType<${field.type}>.');
    }
    if (function is TopLevelFunctionElement) return '${_ref(function)}()';
    if (function is MethodElement && function.isStatic)
      return '${_ref(function.enclosingElement!)}.${function.name}()';
    _fail(field, 'TmarkUsing needs a top-level or static codec factory.');
  }

  String generate(DartObject? node) {
    if (model.isAbstract || model.typeParameters.isNotEmpty)
      _fail(model, 'Annotated models must be concrete, non-generic classes.');
    if (node != null && !_isNode(model.thisType))
      _fail(model, 'A TmarkNode must implement TmarkValue.');
    final constructor = model.unnamedConstructor;
    if (constructor == null || constructor.isFactory)
      _fail(model, 'Provide an unnamed generative constructor.');
    final fields = model.fields
        .where((field) => !field.isStatic && !field.isOriginGetterSetter)
        .toList();
    if (model.mixins.isNotEmpty ||
        (model.supertype?.element.name != 'Object' &&
            model.supertype?.element.name != 'TmarkValue')) {
      _fail(model, 'Inherited model fields need a manual schema.');
    }
    final parameters = {
      for (final p in constructor.formalParameters) p.name: p,
    };
    for (final parameter in parameters.values) {
      if (!fields.any((f) => f.name == parameter.name))
        _fail(parameter, 'Constructor parameter must match a declared field.');
    }
    final declarations = <String>[];
    final namedTokens = <String>[];
    String? bodyToken;
    final names = <String>{};
    final tokens = <String, String>{};
    for (var index = 0; index < fields.length; index++) {
      final field = fields[index];
      final parameter = parameters[field.name];
      if (parameter == null)
        _fail(
          field,
          'Every wire field must have a matching constructor parameter.',
        );
      final body = _read(field, 'TmarkBody') != null;
      final rename = _read(field, 'TmarkName');
      if (body && rename != null)
        _fail(field, 'A body cannot also have a wire name.');
      final wire = rename?.getField('name')?.toStringValue() ?? field.name!;
      if (!body &&
          (!RegExp(r'^[a-z0-9_-]{1,32}$').hasMatch(wire) || !names.add(wire)))
        _fail(field, 'Invalid or duplicate field name: $wire');
      final token = 'f$index';
      tokens[field.name!] = token;
      if (body) {
        if (bodyToken != null)
          _fail(field, 'Only one field can be the unnamed body.');
        bodyToken = token;
      } else {
        namedTokens.add(token);
      }
      final custom = _read(field, 'TmarkUsing');
      final codec = custom == null
          ? _codec(field.type, field)
          : _custom(custom, field);
      final defaultCode =
          parameter.defaultValueCode ?? (parameter.isOptional ? 'null' : null);
      declarations.add(
        'final $token = ${_runtime('TmarkField')}<${model.name}, ${_type(field.type)}>('
        '${body ? 'null' : _literal(wire)}, $codec, (v) => v.${field.name}'
        '${defaultCode == null ? '' : ', defaultValue: () => $defaultCode'});',
      );
    }
    final arguments = constructor.formalParameters
        .map((p) => '${p.isNamed ? '${p.name}: ' : ''}v.get(${tokens[p.name]})')
        .join(', ');
    final schemaType = _runtime(node == null ? 'RecordType' : 'NodeType');
    final tag = node?.getField('tag')?.toStringValue();
    final layoutIndex =
        node?.getField('layout')?.getField('index')?.toIntValue() ?? 0;
    final layout = ['compact', 'expanded', 'whenMultiple'][layoutIndex];
    return 'final \$${model.name}Schema = () {\n${declarations.join('\n')}\n'
        'return $schemaType<${model.name}>('
        '${node == null ? '' : '${_literal(tag!)}, layout: ${_runtime('TmarkLayout')}.$layout,'}'
        'fields: [${[...namedTokens, if (bodyToken != null) bodyToken].join(', ')}],'
        'create: (v) => ${model.name}($arguments));\n}();';
  }
}
