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
    _checkBashBackend(command);
    return;
  }

  final filePath = toolInput['file_path'] as String?;
  if (filePath == null) return;
  final rel = _rel(filePath);
  _checkBackendFile(filePath);

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

// ------------------------------------------------------- Luật cứng: backend

/// Gốc monorepo (hai cấp trên apps/frontend).
final String _repoRoot = Directory(_root).parent.parent.path;

/// Nhánh frontend: nhánh này VÀ mọi nhánh con cắt ra từ nó (nhánh có chứa commit của nó)
/// tuyệt đối không có code `apps/backend` (backend nằm ở `main`, do người khác làm).
/// Cùng luật có ở `.githooks/pre-push` và `.github/workflows/backend-guard.yml`.
/// (Khi nhánh này đã merge hết vào `main`, gỡ luật ở cả ba nơi.)
const _frontendBranch = 'design/apple-books';

const _backendHelp =
    'Nhánh design/apple-books và mọi nhánh con của nó chỉ chứa frontend: KHÔNG đưa code apps/backend lên. '
    'Cần backend thì làm ở nhánh cắt từ main, hoặc báo người dùng để họ nhờ người làm backend.';

String _git(List<String> args) {
  try {
    final r = Process.runSync('git', args, workingDirectory: _repoRoot);
    return r.exitCode == 0 ? (r.stdout as String).trim() : '';
  } catch (_) {
    return '';
  }
}

bool _gitOk(List<String> args) {
  try {
    return Process.runSync('git', args, workingDirectory: _repoRoot).exitCode ==
        0;
  } catch (_) {
    return false;
  }
}

/// Mốc để đo "nhánh này đã thêm gì so với nhánh frontend". `null` nếu đây không phải nhánh frontend
/// (vd. nhánh backend cắt từ main).
String? _frontendBase() {
  const remote = 'origin/$_frontendBranch';
  final hasRemote = _gitOk(['rev-parse', '--verify', '--quiet', remote]);
  if (_git(['rev-parse', '--abbrev-ref', 'HEAD']) == _frontendBranch) {
    return hasRemote ? remote : 'origin/main';
  }
  for (final ref in [remote, _frontendBranch]) {
    if (_gitOk(['merge-base', '--is-ancestor', ref, 'HEAD'])) return ref;
  }
  return null;
}

bool _onProtectedBranch() => _frontendBase() != null;

/// Đường dẫn tính từ gốc monorepo, `null` nếu nằm ngoài repo.
String? _repoRel(String path) {
  if (!File(path).isAbsolute && !path.startsWith('/')) {
    final projectDir =
        Platform.environment['CLAUDE_PROJECT_DIR'] ?? Directory.current.path;
    path = '$projectDir/$path';
  }
  final norm = path.replaceAll(r'\', '/');
  final root = _repoRoot.replaceAll(r'\', '/');
  final lower = norm.toLowerCase();
  if (lower.startsWith('${root.toLowerCase()}/')) {
    return norm.substring(root.length + 1);
  }
  // Git Bash có thể truyền dạng /d/... thay vì D:/...
  final drive = RegExp(r'^([a-zA-Z]):/').firstMatch(root);
  if (drive != null) {
    final bashRoot = '/${drive[1]!.toLowerCase()}/${root.substring(3)}'
        .toLowerCase();
    if (lower.startsWith('$bashRoot/')) {
      return norm.substring(bashRoot.length + 1);
    }
  }
  return null;
}

/// Sửa / tạo file trong apps/backend khi đang ở nhánh bảo vệ → chặn.
void _checkBackendFile(String filePath) {
  final rel = _repoRel(filePath);
  if (rel == null || !rel.startsWith('apps/backend/')) return;
  if (_onProtectedBranch()) {
    _block('BLOCKED: không sửa $rel trên nhánh bảo vệ. $_backendHelp');
  }
}

final _bashDangerRe = RegExp(
  r'--no-verify|push\s+.*--force|push\s+-f\b|reset\s+--hard',
);

/// Một dòng lệnh vừa có động từ ghi vừa trỏ vào apps/backend (xét từng dòng để không bắt nhầm
/// văn bản heredoc chỉ nhắc tới backend).
final _bashBackendWriteRe = RegExp(
  r'(\bsed\s+-i|\btee\b|\bmv\b|\bcp\b|\brm\b|\bgit\s+(checkout|restore|stash|apply|am|cherry-pick|add)\b|>>?(?!&)|'
  r'Set-Content|Add-Content|Out-File|Remove-Item|Copy-Item|Move-Item|New-Item|WriteAllText)'
  r'[^\n]*apps[/\\]backend',
);

/// Lệnh shell: chặn --no-verify / force push / reset --hard; chặn ghi vào apps/backend và
/// `git commit` / `git push` mang theo thay đổi apps/backend khi liên quan nhánh bảo vệ.
void _checkBashBackend(String command) {
  if (_bashDangerRe.hasMatch(command)) {
    _block(
      'BLOCKED: không dùng --no-verify / force push / reset --hard. '
      'Hook push và CI là lưới an toàn của team; nếu bị chặn hãy đọc lý do và sửa gốc.',
    );
  }
  final onProtected = _onProtectedBranch();
  // Bỏ nội dung `-m "..."` (thông điệp commit chỉ nhắc tới backend) và xét từng lệnh con riêng.
  final stripped = command.replaceAll(
    RegExp(r'''(-m|--message)\s+("[^"]*"|'[^']*')'''),
    '-m ""',
  );
  final writesBackend = stripped
      .split(RegExp(r'&&|\|\||;|\||\n'))
      .any(_bashBackendWriteRe.hasMatch);
  if (onProtected && writesBackend) {
    _block('BLOCKED: lệnh có vẻ ghi vào apps/backend. $_backendHelp');
  }

  if (RegExp(r'\bgit\s+commit\b').hasMatch(command) && onProtected) {
    final files = _git(['diff', 'HEAD', '--name-only', '--', 'apps/backend']);
    if (files.isNotEmpty) {
      _block(
        'BLOCKED: commit đang mang file apps/backend:\n$files\n$_backendHelp',
      );
    }
  }
  if (RegExp(r'\bgit\s+push\b').hasMatch(command)) {
    // Đẩy từ nhánh frontend / nhánh con, hoặc đẩy một nhánh khác thẳng lên design/apple-books.
    final base =
        _frontendBase() ??
        (command.contains(_frontendBranch) ? 'origin/main' : null);
    if (base == null) return;
    final mergeBase = _git(['merge-base', base, 'HEAD']);
    if (mergeBase.isEmpty) return;
    final files = _git([
      'diff',
      '--name-only',
      mergeBase,
      'HEAD',
      '--',
      'apps/backend',
    ]);
    if (files.isNotEmpty) {
      _block(
        'BLOCKED: push này mang code apps/backend:\n$files\n$_backendHelp',
      );
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
