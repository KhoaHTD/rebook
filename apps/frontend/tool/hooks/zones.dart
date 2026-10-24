// Đọc tool/zones.txt và quyết định một file có được sửa hay không theo vai của người làm.
// Dùng chung cho hook Claude (claude_hook.dart) và CI (tool/locked_check.dart).
// Không import package ngoài SDK để khởi động nhanh.
import 'dart:convert';
import 'dart:io';

enum Role { owner, admin, staff, unknown }

/// Vai của người đang làm trên máy này. Thứ tự: biến môi trường `REBOOK_ROLE`,
/// rồi file `~/.rebook-role` (tạo bằng `dart run tool/set_role.dart <vai>`).
Role detectRole() {
  var raw = Platform.environment['REBOOK_ROLE']?.trim().toLowerCase();
  if (raw == null || raw.isEmpty) {
    final home =
        Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
    if (home != null) {
      final f = File('$home/.rebook-role');
      if (f.existsSync()) raw = f.readAsStringSync().trim().toLowerCase();
    }
  }
  return switch (raw) {
    'owner' => Role.owner,
    'admin' => Role.admin,
    'staff' => Role.staff,
    _ => Role.unknown,
  };
}

class Zones {
  Zones._(this.roleOwn, this.shared, this.addable, this.lock);

  final Map<String, List<String>> roleOwn;
  final List<String> shared;
  final List<String> addable;
  final List<String> lock;

  static Zones load(String zonesFile) {
    final roleOwn = <String, List<String>>{};
    final shared = <String>[];
    final addable = <String>[];
    final lock = <String>[];
    for (final raw in File(zonesFile).readAsLinesSync()) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final parts = line.split(RegExp(r'\s+'));
      switch (parts.first) {
        case 'role':
          roleOwn.putIfAbsent(parts[1], () => []).addAll(parts.skip(2));
        case 'shared':
          shared.addAll(parts.skip(1));
        case 'addable':
          addable.addAll(parts.skip(1));
        case 'lock':
          lock.addAll(parts.skip(1));
      }
    }
    return Zones._(roleOwn, shared, addable, lock);
  }

  static bool _in(String rel, List<String> prefixes) =>
      prefixes.any((p) => p.endsWith('/') ? rel.startsWith(p) : rel == p);

  /// Vai nào sở hữu file này (null nếu không vai nào).
  String? ownerRole(String rel) {
    for (final e in roleOwn.entries) {
      if (_in(rel, e.value)) return e.key;
    }
    return null;
  }

  bool isShared(String rel) => _in(rel, shared);
  bool isAddable(String rel) => _in(rel, addable);
  bool isLocked(String rel) => _in(rel, lock);

  /// Vai admin / staff có được sửa file [rel] (đường dẫn từ gốc monorepo) không?
  /// Trả về null nếu được, hoặc lý do chặn. [exists] = file đã tồn tại (sửa) hay chưa (tạo mới).
  String? roleBlock(Role role, String rel, {required bool exists}) {
    if (role == Role.owner) return null;
    if (role == Role.unknown) {
      return 'Chưa đặt vai làm việc trên máy này. Chạy `dart run tool/set_role.dart admin` '
          '(hoặc `staff`) trong apps/frontend rồi thử lại. Chủ repo dùng vai `owner`.';
    }
    final mine = role.name;
    final owner = ownerRole(rel);
    if (owner == mine) return null;
    if (owner != null) {
      return '$rel thuộc vùng của vai "$owner", không phải của bạn ("$mine"). '
          'Cần sửa thì nhờ người phụ trách vai "$owner" hoặc chủ repo.';
    }
    if (isShared(rel)) return null;
    if (isAddable(rel) && !exists) return null;
    if (isAddable(rel)) {
      return '$rel là widget dùng chung đã có sẵn nên khoá; bạn chỉ được THÊM file mới trong thư mục này. '
          'Cần thay đổi widget cũ thì báo chủ repo.';
    }
    return '$rel nằm ngoài vùng của bạn ("$mine"). Vùng của bạn: ${roleOwn[mine]?.join(', ')}; '
        'Ngoài ra bạn được sửa file dùng chung (zones.txt, mục shared). '
        'Đây là vùng khoá (giao diện chủ đạo / kiến trúc / cấu hình / feature của người khác): '
        'DỪNG LẠI, mô tả thay đổi cần thiết cho chủ repo và để họ quyết định. Không tìm cách lách.';
  }

  /// Dùng cho CI trên nhánh không có vai: file khoá đã tồn tại bị sửa / xoá?
  bool lockedExistingChange(String rel) {
    if (ownerRole(rel) != null || isShared(rel)) return false;
    return isLocked(rel) || isAddable(rel);
  }
}

/// Key có trong bản arb cũ nhưng bị đổi giá trị hoặc mất ở bản mới (thêm key mới thì không tính).
List<String> changedArbKeys(String before, String after) {
  try {
    final a = jsonDecode(before) as Map<String, dynamic>;
    final b = jsonDecode(after) as Map<String, dynamic>;
    return [
      for (final e in a.entries)
        if (!b.containsKey(e.key) ||
            jsonEncode(b[e.key]) != jsonEncode(e.value))
          e.key,
    ];
  } on FormatException {
    return const [];
  }
}

/// Đường dẫn [path] (tuyệt đối hoặc tương đối) → đường dẫn từ gốc monorepo, dấu `/`.
/// Null nếu nằm ngoài monorepo.
String? repoRelative(String path, String repoRoot) {
  var p = path.replaceAll(r'\', '/');
  final root = repoRoot.replaceAll(r'\', '/');
  if (!RegExp(r'^[A-Za-z]:/').hasMatch(p) && !p.startsWith('/')) {
    final base =
        Platform.environment['CLAUDE_PROJECT_DIR']?.replaceAll(r'\', '/') ??
        Directory.current.path.replaceAll(r'\', '/');
    p = '$base/$p';
  }
  final lower = p.toLowerCase();
  final rootLower = root.toLowerCase();
  if (lower.startsWith('$rootLower/')) return p.substring(root.length + 1);
  // Git Bash truyền dạng /d/... thay vì D:/...
  final drive = RegExp(r'^([A-Za-z]):/').firstMatch(root);
  if (drive != null) {
    final bashRoot = '/${drive[1]!.toLowerCase()}/${root.substring(3)}'
        .toLowerCase();
    if (lower.startsWith('$bashRoot/')) return p.substring(bashRoot.length + 1);
  }
  return null;
}
