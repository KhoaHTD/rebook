// Chốt chặn thật cho vùng khoá (hook Claude chỉ là lớp đầu). Chạy trong CI trên PR:
//   dart run tool/locked_check.dart --base origin/main --branch admin/users-page --labels core-change,foo
//
// Luật (xem tool/zones.txt, docs/TEAM_GUIDE.md):
//  - Nhánh `admin/...` hoặc `staff/...`: chỉ được sửa vùng của vai đó + vùng dùng chung + THÊM file mới ở vùng addable.
//  - Nhánh khác: file đã có trong vùng khoá không được sửa / xoá.
//  - File arb: không được đổi / xoá key cũ.
//  - PR có nhãn `core-change` (chủ repo gắn) thì bỏ qua các luật trên.
import 'dart:io';

import 'hooks/zones.dart';

Future<void> main(List<String> args) async {
  String arg(String name, [String fallback = '']) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : fallback;
  }

  final base = arg('base', 'origin/main');
  final branch = arg('branch');
  final labels = arg('labels')
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet();

  final repoRoot = (await _git(['rev-parse', '--show-toplevel'])).trim();
  final zones = Zones.load('$repoRoot/apps/frontend/tool/zones.txt');
  final role = switch (branch.split('/').first) {
    'admin' => Role.admin,
    'staff' => Role.staff,
    _ => null,
  };

  final diff = await _git([
    'diff',
    '--name-status',
    '--no-renames',
    '$base...HEAD',
  ]);
  final problems = <String>[];
  for (final line in diff.split('\n')) {
    if (line.trim().isEmpty) continue;
    final parts = line.split('\t');
    final status = parts[0];
    final path = parts[1];
    final existedBefore = status != 'A';

    if (role != null) {
      final why = zones.roleBlock(role, path, exists: existedBefore);
      if (why != null) problems.add('[${role.name}] $why');
    } else if (existedBefore && zones.lockedExistingChange(path)) {
      problems.add('$path nằm trong vùng khoá và đã bị ${_verb(status)}.');
    }

    if (status == 'M' && path.endsWith('.arb')) {
      final before = await _git(['show', '$base:$path']);
      final after = File('$repoRoot/$path').readAsStringSync();
      final bad = changedArbKeys(before, after);
      if (bad.isNotEmpty) {
        problems.add(
          '$path: đã đổi / xoá key cũ (${bad.take(8).join(', ')}). Chỉ được thêm key mới.',
        );
      }
    }
  }

  if (problems.isEmpty) {
    stdout.writeln('locked_check: OK');
    return;
  }
  if (labels.contains('core-change')) {
    stdout.writeln(
      'locked_check: ${problems.length} thay đổi vùng khoá, được bỏ qua nhờ nhãn core-change:',
    );
    for (final p in problems) {
      stdout.writeln('  - $p');
    }
    return;
  }
  stderr.writeln('locked_check: ${problems.length} vi phạm vùng khoá:\n');
  for (final p in problems) {
    stderr.writeln('  - $p');
  }
  stderr.writeln(
    '\nNếu thay đổi này là cần thiết, hãy nhờ chủ repo xem và gắn nhãn `core-change` cho PR. '
    'Xem docs/TEAM_GUIDE.md.',
  );
  exitCode = 1;
}

String _verb(String status) => switch (status) {
  'D' => 'xoá',
  _ => 'sửa',
};

Future<String> _git(List<String> args) async {
  final r = await Process.run('git', args, stdoutEncoding: systemEncoding);
  if (r.exitCode != 0) {
    stderr.writeln('git ${args.join(' ')} lỗi: ${r.stderr}');
    exit(2);
  }
  return r.stdout as String;
}
