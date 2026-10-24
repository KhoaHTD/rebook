// Hook của Claude Code (cấu hình trong .claude/settings.json ở gốc repo và ở apps/frontend).
//
//   dart tool/hooks/claude_hook.dart pre   — PreToolUse: chặn sửa file sinh tự động,
//                                            chặn package ngoài allowlist.
//   dart tool/hooks/claude_hook.dart post  — PostToolUse: dart format, gen-l10n khi sửa .arb.
//   dart tool/hooks/claude_hook.dart stop  — Stop: dart analyze + arch_check nếu code đã đổi.
//
// Quy ước của Claude Code: exit 2 + stderr = chặn hành động và báo lý do cho Claude.
// Không import package ngoài SDK để hook khởi động nhanh.
import 'dart:convert';
import 'dart:io';

import 'zones.dart';

Future<void> main(List<String> args) async {
  final input = await _readInput();
  switch (args.firstOrNull) {
    case 'pre':
      _pre(input);
    case 'post':
      await _post(input);
    case 'stop':
      await _stop(input);
  }
}

Future<Map<String, dynamic>> _readInput() async {
  final raw = await stdin.transform(utf8.decoder).join();
  if (raw.trim().isEmpty) return {};
  return jsonDecode(raw) as Map<String, dynamic>;
}

/// Gốc app Flutter (apps/frontend), suy ra từ vị trí file này (`<gốc>/tool/hooks/`).
/// Nhờ vậy hook chạy đúng dù Claude được mở ở gốc monorepo hay trong apps/frontend.
final String _root = File.fromUri(Platform.script).parent.parent.parent.path;

String _rel(String path) {
  if (!File(path).isAbsolute && !path.startsWith('/')) {
    final projectDir =
        Platform.environment['CLAUDE_PROJECT_DIR'] ?? Directory.current.path;
    path = '$projectDir/$path';
  }
  final norm = path.replaceAll(r'\', '/');
  final root = _root.replaceAll(r'\', '/');
  final lower = norm.toLowerCase();
  final rootLower = root.toLowerCase();
  if (lower.startsWith('$rootLower/')) return norm.substring(root.length + 1);
  // Git Bash có thể truyền dạng /d/... thay vì D:/...
  final drive = RegExp(r'^([a-zA-Z]):/').firstMatch(root);
  if (drive != null) {
    final bashRoot = '/${drive[1]!.toLowerCase()}/${root.substring(3)}'
        .toLowerCase();
    if (lower.startsWith('$bashRoot/')) {
      return norm.substring(bashRoot.length + 1);
    }
  }
  return norm;
}

Never _block(String message) {
  stderr.writeln(message);
  exit(2);
}

// ---------------------------------------------------------------- PreToolUse

bool _isGenerated(String rel) =>
    rel.endsWith('.g.dart') ||
    rel.endsWith('.freezed.dart') ||
    rel.startsWith('lib/api/generated/') ||
    rel.startsWith('lib/app/l10n/generated/');

void _pre(Map<String, dynamic> input) {
  final tool = input['tool_name'] as String? ?? '';
  final toolInput =
      (input['tool_input'] as Map?)?.cast<String, dynamic>() ?? {};

  if (tool == 'Bash' || tool == 'PowerShell') {
    final command = toolInput['command'] as String? ?? '';
    _checkPubAdd(command);
    _checkBashZones(command);
    return;
  }

  final filePath = toolInput['file_path'] as String?;
  if (filePath == null) return;
  final rel = _rel(filePath);
  _checkZones(tool, toolInput, filePath);

  if (_isGenerated(rel)) {
    _block(
      'BLOCKED: $rel là file sinh tự động, không sửa tay.\n'
      '- *.g.dart / *.freezed.dart: sửa file nguồn rồi chạy `dart run build_runner build`.\n'
      '- lib/api/generated/: sửa openapi/openapi.yaml rồi chạy /sync-api.\n'
      '- lib/app/l10n/generated/: sửa lib/app/l10n/arb/*.arb rồi chạy `flutter gen-l10n`.',
    );
  }

  if (rel == 'tool/allowed_packages.yaml') {
    _block(
      'BLOCKED: tool/allowed_packages.yaml chỉ do con người sửa sau khi team thống nhất.\n'
      'Hãy giải thích cho người dùng vì sao cần package đó và để họ tự quyết định.',
    );
  }

  if (rel == 'pubspec.yaml') {
    final newContent = _simulateEdit(
      tool,
      toolInput,
      File('$_root/pubspec.yaml'),
    );
    if (newContent == null) return;
    final allowed = _allowedPackages();
    final deps = _parseDeps(newContent);
    final bad = deps.where((d) => !allowed.contains(d)).toList();
    if (bad.isNotEmpty) _blockPackages(bad);
  }
}

// ------------------------------------------------------------ Phân vùng làm việc

/// Gốc monorepo (hai cấp trên apps/frontend).
final String _repoRoot = Directory(_root).parent.parent.path;

Zones? _zonesCache;
Zones get _zones => _zonesCache ??= Zones.load('$_root/tool/zones.txt');

const _roleHelp =
    'Xem apps/frontend/docs/TEAM_GUIDE.md (mục "Vùng khoá"). '
    'Nếu việc này thật sự cần, dừng lại và báo người dùng để họ nhờ chủ repo.';

/// Chặn sửa file ngoài vùng của vai hiện tại (xem tool/zones.txt).
void _checkZones(String tool, Map<String, dynamic> toolInput, String filePath) {
  final role = detectRole();
  if (role == Role.owner) return;
  final repoRel = repoRelative(filePath, _repoRoot);
  if (repoRel == null) return;
  final exists = File(filePath).existsSync();
  final why = _zones.roleBlock(role, repoRel, exists: exists);
  if (why != null) _block('BLOCKED (vùng khoá): $why\n$_roleHelp');

  // File arb dùng chung: chỉ được thêm key mới, không đổi / xoá key cũ.
  if (repoRel.endsWith('.arb') && exists) {
    final next = _simulateEdit(tool, toolInput, File(filePath));
    if (next != null) {
      final bad = changedArbKeys(File(filePath).readAsStringSync(), next);
      if (bad.isNotEmpty) {
        _block(
          'BLOCKED: $repoRel chỉ được THÊM key mới. Bạn đang đổi / xoá key cũ: '
          '${bad.take(8).join(", ")}. Dùng `node tool/l10n_add.mjs <file.json>` để thêm key; '
          'muốn sửa chuỗi cũ thì báo chủ repo.',
        );
      }
    }
  }
}

final _bashWriteRe = RegExp(
  r'(\bsed\s+-i|\btee\b|\bmv\b|\bcp\b|\brm\b|\bgit\s+(checkout|restore|stash|apply|am|cherry-pick)\b|>>?\s*\S|'
  r'Set-Content|Add-Content|Out-File|Remove-Item|Copy-Item|Move-Item|New-Item|WriteAllText)',
);
final _bashPathRe = RegExp(r'[A-Za-z0-9_./:~\\-]+');
final _bashDangerRe = RegExp(
  r'--no-verify|push\s+.*--force|push\s+-f\b|reset\s+--hard',
);

/// Lệnh shell có vẻ ghi vào vùng khoá → chặn. Chỉ là lớp phụ; CI (locked_check) mới là chốt chặn thật.
void _checkBashZones(String command) {
  final role = detectRole();
  if (role == Role.owner) return;
  if (_bashDangerRe.hasMatch(command)) {
    _block(
      'BLOCKED: không dùng --no-verify / force push / reset --hard. $_roleHelp',
    );
  }
  if (!_bashWriteRe.hasMatch(command)) return;
  for (final m in _bashPathRe.allMatches(command)) {
    final token = m[0]!;
    if (!token.contains('/') && !token.contains(r'\')) continue;
    // Token tương đối có thể tính từ gốc monorepo, gốc app hoặc thư mục đang chạy.
    final isAbs = RegExp(r'^([A-Za-z]:)?[/\\]').hasMatch(token);
    final bases = isAbs
        ? ['']
        : [
            '$_repoRoot/',
            '$_root/',
            '${Platform.environment['CLAUDE_PROJECT_DIR'] ?? Directory.current.path}/',
          ];
    for (final base in bases) {
      final full = '$base$token';
      final repoRel = repoRelative(full, _repoRoot);
      if (repoRel == null) continue;
      final onDisk = '$_repoRoot/$repoRel';
      final exists =
          File(onDisk).existsSync() || Directory(onDisk).existsSync();
      // Chuỗi kiểu `s/a/b/` (sed) không phải đường dẫn: bỏ qua nếu cả thư mục cha cũng không có.
      if (!exists && !Directory(File(onDisk).parent.path).existsSync()) {
        continue;
      }
      final asDir = Directory(onDisk).existsSync() && !repoRel.endsWith('/');
      final why = _zones.roleBlock(
        role,
        asDir ? '$repoRel/' : repoRel,
        exists: exists,
      );
      if (why != null) {
        _block('BLOCKED (vùng khoá, lệnh shell): $why\n$_roleHelp');
      }
    }
  }
}

String? _simulateEdit(String tool, Map<String, dynamic> toolInput, File file) {
  if (tool == 'Write') return toolInput['content'] as String?;
  if (!file.existsSync()) return null;
  var content = file.readAsStringSync();

  void apply(Map<String, dynamic> e) {
    final oldStr = e['old_string'] as String? ?? '';
    final newStr = e['new_string'] as String? ?? '';
    if (oldStr.isEmpty) return;
    content = e['replace_all'] == true
        ? content.replaceAll(oldStr, newStr)
        : content.replaceFirst(oldStr, newStr);
  }

  if (tool == 'Edit') apply(toolInput);
  if (tool == 'MultiEdit') {
    for (final e in (toolInput['edits'] as List? ?? const [])) {
      apply((e as Map).cast<String, dynamic>());
    }
  }
  return content;
}

/// Đọc tên package trong `dependencies:` và `dev_dependencies:` (key thụt 2 dấu cách).
Set<String> _parseDeps(String yaml) {
  final deps = <String>{};
  var inDeps = false;
  final topKey = RegExp(r'^([A-Za-z_]+):');
  final depKey = RegExp(r'^  ([A-Za-z0-9_]+):');
  for (final line in const LineSplitter().convert(yaml)) {
    final top = topKey.firstMatch(line);
    if (top != null) {
      inDeps = top[1] == 'dependencies' || top[1] == 'dev_dependencies';
      continue;
    }
    if (!inDeps) continue;
    final m = depKey.firstMatch(line);
    if (m != null) deps.add(m[1]!);
  }
  return deps;
}

Set<String> _allowedPackages() {
  final file = File('$_root/tool/allowed_packages.yaml');
  if (!file.existsSync()) return {};
  return _parseDeps(file.readAsStringSync());
}

void _checkPubAdd(String command) {
  final m = RegExp(r'\b(?:flutter|dart)\s+pub\s+add\s+(.+)')
      .firstMatch(command);
  if (m == null) return;
  final names = <String>[];
  for (var token in m[1]!.split(RegExp(r'\s+'))) {
    if (RegExp(r'^(&&|\|\||;|\|)').hasMatch(token)) break;
    token = token.replaceAll(RegExp(r'''['"]'''), '');
    if (token.isEmpty || token.startsWith('-')) continue;
    if (token.startsWith('dev:') || token.startsWith('override:')) {
      token = token.substring(token.indexOf(':') + 1);
    }
    final name = token.split(':').first;
    if (RegExp(r'^[a-z0-9_]+$').hasMatch(name)) names.add(name);
  }
  final allowed = _allowedPackages();
  final bad = names.where((n) => !allowed.contains(n)).toList();
  if (bad.isNotEmpty) _blockPackages(bad);
}

Never _blockPackages(List<String> bad) => _block(
  'BLOCKED: package chưa được duyệt: ${bad.join(', ')}.\n'
  'Dự án chỉ dùng các package trong tool/allowed_packages.yaml (xem bảng stack trong CLAUDE.md).\n'
  'Hãy làm bằng package/stack sẵn có. Nếu thật sự không thể, DỪNG lại và giải thích cho người dùng '
  'lý do cần package này để họ thống nhất với team.',
);

// --------------------------------------------------------------- PostToolUse

Future<void> _post(Map<String, dynamic> input) async {
  final toolInput =
      (input['tool_input'] as Map?)?.cast<String, dynamic>() ?? {};
  final filePath = toolInput['file_path'] as String?;
  if (filePath == null) return;
  final rel = _rel(filePath);

  if (rel.endsWith('.dart') && !_isGenerated(rel)) {
    await Process.run(
      'dart',
      ['format', rel],
      workingDirectory: _root,
      runInShell: true,
    );
  } else if (rel.startsWith('lib/app/l10n/arb/') && rel.endsWith('.arb')) {
    final r = await Process.run(
      'flutter',
      ['gen-l10n'],
      workingDirectory: _root,
      runInShell: true,
    );
    if (r.exitCode != 0) {
      stderr.writeln(
        'flutter gen-l10n lỗi sau khi sửa $rel:\n${r.stdout}\n${r.stderr}',
      );
      exit(2);
    }
  }
}

// ---------------------------------------------------------------------- Stop

Future<void> _stop(Map<String, dynamic> input) async {
  // Đã chặn một lần trong lượt này rồi -> cho dừng, tránh vòng lặp vô hạn.
  if (input['stop_hook_active'] == true) return;

  final stamp = File('$_root/.dart_tool/claude_last_check');
  final lastCheck = stamp.existsSync()
      ? stamp.lastModifiedSync()
      : DateTime(2000);
  if (!_hasChangesSince(lastCheck)) return;

  final analyze = await Process.run(
    'dart',
    ['analyze', '--fatal-infos'],
    workingDirectory: _root,
    runInShell: true,
  );
  final arch = await Process.run(
    'dart',
    ['run', 'tool/arch_check.dart'],
    workingDirectory: _root,
    runInShell: true,
  );

  if (analyze.exitCode == 0 && arch.exitCode == 0) {
    stamp
      ..createSync(recursive: true)
      ..setLastModifiedSync(DateTime.now());
    return;
  }

  final out = StringBuffer(
    'Chưa xong: còn lỗi analyze / vi phạm kiến trúc. Sửa hết rồi mới kết thúc.\n',
  );
  if (analyze.exitCode != 0) {
    out
      ..writeln('\n== dart analyze ==')
      ..writeln(_tail('${analyze.stdout}${analyze.stderr}', 60))
      ..writeln(
        '(Thiếu file .g.dart/.freezed.dart? chạy `dart run build_runner build`.)',
      );
  }
  if (arch.exitCode != 0) {
    out
      ..writeln('\n== tool/arch_check.dart ==')
      ..writeln(_tail('${arch.stdout}${arch.stderr}', 60));
  }
  _block(out.toString());
}

bool _hasChangesSince(DateTime since) {
  for (final dir in ['lib', 'test', 'tool']) {
    final d = Directory('$_root/$dir');
    if (!d.existsSync()) continue;
    for (final f in d.listSync(recursive: true)) {
      if (f is File &&
          (f.path.endsWith('.dart') ||
              f.path.endsWith('.arb') ||
              f.path.endsWith('.yaml')) &&
          f.lastModifiedSync().isAfter(since)) {
        return true;
      }
    }
  }
  final pubspec = File('$_root/pubspec.yaml');
  return pubspec.existsSync() && pubspec.lastModifiedSync().isAfter(since);
}

String _tail(String text, int lines) {
  final all = const LineSplitter()
      .convert(text)
      .where((l) => l.trim().isNotEmpty)
      .toList();
  return all.length <= lines
      ? all.join('\n')
      : all.sublist(all.length - lines).join('\n');
}
