// Kiểm tra luật kiến trúc. Chạy: `dart run tool/arch_check.dart`
// Được gọi bởi hook Stop của Claude Code và bởi CI. Thoát với mã 1 nếu có vi phạm.
//
// Bỏ qua một dòng có chủ đích: thêm comment `// arch-ignore: <lý do>` ở cuối dòng
// hoặc ở dòng ngay phía trên.
import 'dart:io';

import 'package:yaml/yaml.dart';

const _pkg = 'package:book_marketplace/';

final _importRe = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''');
final _hardcodedColorRe = RegExp(r'\bColor\(0x|\bColors\.(?!transparent\b)\w+');
final _hardcodedTextRe = RegExp(
  r'''\bText\(\s*['"][^'"$]*\p{L}''',
  unicode: true,
);
final _rawHttpRe = RegExp(r'''\.(get|post|put|patch|delete)\(\s*['"]/''');

class Violation {
  Violation(this.file, this.line, this.rule, this.message);
  final String file;
  final int line;
  final String rule;
  final String message;

  @override
  String toString() => '$file:$line  [$rule] $message';
}

void main() {
  final violations = <Violation>[..._checkSources(), ..._checkPubspec()];

  if (violations.isEmpty) {
    stdout.writeln('arch_check: OK');
    return;
  }
  stderr.writeln('arch_check: ${violations.length} vi phạm kiến trúc:\n');
  for (final v in violations) {
    stderr.writeln('  $v');
  }
  stderr.writeln('\nXem docs/ARCHITECTURE.md để biết cách sửa.');
  exitCode = 1;
}

bool _isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.startsWith('lib/api/generated/') ||
    path.startsWith('lib/app/l10n/generated/');

/// `lib/features/<feature>/<layer>/...` -> (feature, layer)
(String, String)? _featureLayer(String path) {
  final parts = path.split('/');
  if (parts.length < 4 || parts[0] != 'lib' || parts[1] != 'features') {
    return null;
  }
  return (parts[2], parts[3]);
}

Iterable<Violation> _checkSources() sync* {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) return;

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (_isGenerated(path)) continue;

    final lines = entity.readAsLinesSync();
    final location = _featureLayer(path);
    final inUi =
        path.startsWith('lib/features/') || path.startsWith('lib/shared/');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('arch-ignore') ||
          (i > 0 && lines[i - 1].contains('arch-ignore'))) {
        continue;
      }
      final n = i + 1;

      final match = _importRe.firstMatch(line);
      if (match != null) {
        final target = match.group(1)!;
        yield* _checkImport(path, n, target, location);
        continue;
      }

      final code = line.split('//').first;
      if (inUi &&
          !path.startsWith('lib/shared/data/') &&
          _hardcodedColorRe.hasMatch(code)) {
        yield Violation(
          path,
          n,
          'hardcoded-color',
          'Không hardcode màu. Dùng context.colors / context.appColors (app/theme/app_tokens.dart).',
        );
      }
      if (inUi && _hardcodedTextRe.hasMatch(code)) {
        yield Violation(
          path,
          n,
          'hardcoded-text',
          'Chuỗi hiển thị phải đi qua l10n: thêm key vào lib/app/l10n/arb/*.arb rồi dùng context.l10n.<key>.',
        );
      }
      if (location != null &&
          location.$2 == 'presentation' &&
          _rawHttpRe.hasMatch(code)) {
        yield Violation(
          path,
          n,
          'raw-http',
          'UI không gọi HTTP. Gọi qua repository.',
        );
      }
    }
  }
}

Iterable<Violation> _checkImport(
  String path,
  int line,
  String target,
  (String, String)? location,
) sync* {
  if (target.startsWith('../') ||
      target.startsWith('./') ||
      (!target.contains(':') && target.endsWith('.dart'))) {
    yield Violation(
      path,
      line,
      'relative-import',
      'Dùng package import: $_pkg...',
    );
    return;
  }

  final internal = target.startsWith(_pkg)
      ? 'lib/${target.substring(_pkg.length)}'
      : null;

  // core/ và shared/ không được phụ thuộc vào features/
  if ((path.startsWith('lib/core/') || path.startsWith('lib/shared/')) &&
      internal != null &&
      internal.startsWith('lib/features/')) {
    yield Violation(
      path,
      line,
      'layer',
      'core/ và shared/ không được import features/.',
    );
  }

  if (location == null) return;
  final (feature, layer) = location;

  if (internal != null) {
    final targetLoc = _featureLayer(internal);
    if (targetLoc != null && targetLoc.$1 != feature) {
      yield Violation(
        path,
        line,
        'cross-feature',
        'Feature "$feature" không được import feature "${targetLoc.$1}". '
            'Đưa phần dùng chung vào lib/shared/ (entity -> shared/domain, widget -> shared/widgets).',
      );
    }
    if (internal == 'lib/app/router/app_router.dart' ||
        internal == 'lib/app/app.dart') {
      yield Violation(
        path,
        line,
        'layer',
        'Feature chỉ được dùng app/router/routes.dart, không import app_router.dart / app.dart.',
      );
    }
  }

  switch (layer) {
    case 'domain':
      final forbidden =
          target.startsWith('package:flutter/') ||
          target.startsWith('package:dio/') ||
          target.startsWith('package:retrofit/') ||
          target.startsWith('package:flutter_riverpod/') ||
          target.startsWith('package:riverpod_annotation/') ||
          (internal != null &&
              (internal.startsWith('lib/api/') ||
                  internal.contains('/data/') ||
                  internal.contains('/presentation/')));
      if (forbidden) {
        yield Violation(
          path,
          line,
          'domain-purity',
          'domain/ là Dart thuần: không import Flutter, Dio, Riverpod, api/, data/, presentation/.',
        );
      }
    case 'presentation':
      final forbidden =
          target.startsWith('package:dio/') ||
          target.startsWith('package:web_socket_channel/') ||
          target.startsWith('package:flutter_secure_storage/') ||
          (internal != null && internal.startsWith('lib/api/'));
      if (forbidden) {
        yield Violation(
          path,
          line,
          'presentation-io',
          'presentation/ không dùng Dio/WebSocket/storage/DTO trực tiếp. Đi qua repository.',
        );
      }
      if (internal != null &&
          internal.startsWith('lib/features/$feature/data/') &&
          !internal.endsWith('_provider.dart')) {
        yield Violation(
          path,
          line,
          'presentation-data',
          'presentation/ chỉ import data/*_provider.dart, không import Api/Fake repository trực tiếp.',
        );
      }
    case 'data':
      if (internal != null && internal.contains('/presentation/')) {
        yield Violation(
          path,
          line,
          'layer',
          'data/ không được import presentation/.',
        );
      }
  }
}

Iterable<Violation> _checkPubspec() sync* {
  final allowFile = File('tool/allowed_packages.yaml');
  final pubspecFile = File('pubspec.yaml');
  if (!allowFile.existsSync() || !pubspecFile.existsSync()) return;

  final allow = loadYaml(allowFile.readAsStringSync()) as YamlMap;
  final pubspec = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;

  for (final section in ['dependencies', 'dev_dependencies']) {
    final allowed =
        (allow[section] as YamlMap?)?.keys.cast<String>().toSet() ?? {};
    final deps =
        (pubspec[section] as YamlMap?)?.keys.cast<String>() ?? const <String>[];
    for (final dep in deps) {
      if (!allowed.contains(dep)) {
        yield Violation(
          'pubspec.yaml',
          0,
          'unapproved-package',
          '"$dep" ($section) chưa có trong tool/allowed_packages.yaml.',
        );
      }
    }
  }
}
