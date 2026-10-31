// So hợp đồng API của frontend với spec của backend, in ra những gì backend còn thiếu hoặc lệch.
//
//   dart run tool/api_gap.dart                              # backend mặc định: ../backend/openapi.yaml
//   dart run tool/api_gap.dart --backend path/openapi.yaml  # chỉ định file khác
//   dart run tool/api_gap.dart --all-fields                 # thêm: mọi field của frontend backend chưa có (nhiều nhiễu)
//
// Mã thoát 0 = backend đã đủ những gì frontend cần; 1 = còn thiếu / lệch (CI dùng được).
//
// Cách đọc: openapi/openapi.yaml của frontend đánh dấu mọi thứ frontend tự đặt thêm bằng
//   x-origin: frontend           (endpoint / schema / field / tham số mới)
//   x-frontend-change: "..."     (endpoint đã có nhưng frontend cần thêm / đổi hành vi)
//   x-frontend-added: [A, B]     (giá trị enum mới)
// Chi tiết nghiệp vụ nằm ở docs/BACKEND_HANDOFF.md.
import 'dart:io';

import 'package:yaml/yaml.dart';

const _methods = ['get', 'post', 'put', 'patch', 'delete'];

void main(List<String> args) {
  var backendPath = '../backend/openapi.yaml';
  final allFields = args.contains('--all-fields');
  final i = args.indexOf('--backend');
  if (i >= 0 && i + 1 < args.length) backendPath = args[i + 1];
  const frontendPath = 'openapi/openapi.yaml';

  if (!File(frontendPath).existsSync()) {
    stderr.writeln('Không thấy $frontendPath, chạy lệnh trong apps/frontend.');
    exit(64);
  }
  if (!File(backendPath).existsSync()) {
    stderr.writeln(
      'Không thấy spec backend: $backendPath (dùng --backend <file>).',
    );
    exit(64);
  }
  final report = compare(_load(frontendPath), _load(backendPath));
  stdout.write(report.render(allFields: allFields));
  exit(report.hasGaps ? 1 : 0);
}

Map<String, dynamic> _load(String path) =>
    _plain(loadYaml(File(path).readAsStringSync())) as Map<String, dynamic>;

Object? _plain(Object? v) => switch (v) {
  YamlMap() => {for (final e in v.entries) '${e.key}': _plain(e.value)},
  YamlList() => [for (final e in v) _plain(e)],
  _ => v,
};

/// "GET /listings/{id}" thành "GET /listings/{}" (tên tham số đường dẫn mỗi bên đặt một kiểu).
String _opKey(String method, String path) =>
    '${method.toUpperCase()} ${path.replaceAll(RegExp(r'\{[^}]+\}'), '{}')}';

class Op {
  Op(this.key, this.path, this.data);

  final String key;
  final String path;
  final Map<String, dynamic> data;

  String get id => '${data['operationId'] ?? ''}';
  String get summary =>
      '${data['summary'] ?? data['description'] ?? ''}'.trim();
  bool get frontendOrigin => data['x-origin'] == 'frontend';
  String? get change => data['x-frontend-change'] as String?;

  List<Map<String, dynamic>> get params => [
    for (final p in (data['parameters'] as List? ?? const []))
      if (p is Map<String, dynamic>) p,
  ];
}

Map<String, Op> _ops(Map<String, dynamic> spec) {
  final out = <String, Op>{};
  final paths = spec['paths'] as Map<String, dynamic>? ?? {};
  for (final p in paths.entries) {
    final item = p.value as Map<String, dynamic>;
    for (final m in _methods) {
      final op = item[m];
      if (op is Map<String, dynamic>) {
        final key = _opKey(m, p.key);
        out[key] = Op(key, p.key, op);
      }
    }
  }
  return out;
}

Map<String, dynamic> _schemas(Map<String, dynamic> spec) =>
    ((spec['components'] as Map<String, dynamic>?)?['schemas']
        as Map<String, dynamic>?) ??
    {};

/// Mọi tên field xuất hiện ở bất kỳ schema nào của spec (backend đặt tên schema khác nên so theo tên field).
Set<String> _allPropertyNames(Map<String, dynamic> spec) => {
  for (final s in _schemas(spec).values)
    if (s is Map<String, dynamic>)
      ...((s['properties'] as Map<String, dynamic>?)?.keys ?? const <String>[]),
};

Set<String> _allEnumValues(Map<String, dynamic> spec) {
  final out = <String>{};
  void walk(Object? n) {
    if (n is Map<String, dynamic>) {
      final e = n['enum'];
      if (e is List) out.addAll(e.map((x) => '$x'));
      n.values.forEach(walk);
    } else if (n is List) {
      n.forEach(walk);
    }
  }

  walk(spec);
  return out;
}

class GapReport {
  /// Endpoint frontend tự đặt mà backend chưa có.
  final missingOps = <String>[];

  /// Endpoint đã có nhưng cần đổi / thêm.
  final changedOps = <String>[];
  final missingFields = <String>[];
  final missingEnumValues = <String>[];
  final missingParams = <String>[];

  /// Frontend gọi mà backend không có, không đánh dấu (lệch từ trước).
  final unmarkedMismatch = <String>[];
  final allFieldsMissing = <String>[];

  bool get hasGaps =>
      missingOps.isNotEmpty ||
      changedOps.isNotEmpty ||
      missingFields.isNotEmpty ||
      missingEnumValues.isNotEmpty ||
      missingParams.isNotEmpty ||
      unmarkedMismatch.isNotEmpty;

  String render({bool allFields = false}) {
    final b = StringBuffer('# Backend còn thiếu / lệch so với frontend\n\n');
    void section(String title, List<String> items, {String? hint}) {
      b.writeln('## $title (${items.length})');
      if (hint != null) b.writeln('_${hint}_');
      if (items.isEmpty) {
        b.writeln('- (không có)');
      } else {
        for (final s in items) {
          b.writeln('- $s');
        }
      }
      b.writeln();
    }

    section(
      'Endpoint frontend đặt thêm, backend chưa có',
      missingOps,
      hint: 'x-origin: frontend, làm theo docs/BACKEND_HANDOFF.md',
    );
    section(
      'Endpoint đã có nhưng frontend cần thêm / đổi hành vi',
      changedOps,
      hint: 'x-frontend-change',
    );
    section('Tham số frontend đặt thêm, backend chưa có', missingParams);
    section('Field frontend đặt thêm, backend chưa có', missingFields);
    section(
      'Giá trị enum frontend đặt thêm, backend chưa có',
      missingEnumValues,
    );
    section(
      'Frontend gọi nhưng backend không có endpoint (không đánh dấu: lệch từ trước)',
      unmarkedMismatch,
      hint: 'cùng method + đường dẫn; kiểm tra backend đặt đường dẫn khác hay chưa làm',
    );
    if (allFields) {
      section(
        'Mọi field của frontend backend chưa có (theo tên)',
        allFieldsMissing,
      );
    }
    b.writeln(
      'Lưu ý: field và enum so theo TÊN trên toàn spec backend (schema hai bên đặt tên khác nhau), nên một field trùng tên ở schema khác sẽ bị bỏ sót; đối chiếu thêm với docs/BACKEND_HANDOFF.md.\n',
    );
    b.writeln(
      hasGaps
          ? 'KẾT LUẬN: còn thiếu / lệch. Backend làm theo spec frontend; không đồng ý thì sửa spec rồi báo frontend.'
          : 'KẾT LUẬN: backend đã đủ những gì frontend đặt thêm.',
    );
    return b.toString();
  }
}

GapReport compare(Map<String, dynamic> front, Map<String, dynamic> back) {
  final r = GapReport();
  final fOps = _ops(front);
  final bOps = _ops(back);
  final bFields = _allPropertyNames(back);
  final bEnums = _allEnumValues(back);

  for (final op in fOps.values) {
    final inBackend = bOps[op.key];
    final note = op.summary.isEmpty ? '' : ' - ${op.summary}';
    final label = '`${op.key}` (${op.id})$note';
    if (inBackend == null) {
      if (op.frontendOrigin) {
        r.missingOps.add(label);
      } else {
        r.unmarkedMismatch.add(label);
      }
    } else if (op.change != null) {
      r.changedOps.add('`${op.key}` (${op.id}): ${op.change}');
    }
    for (final p in op.params) {
      if (p['x-origin'] != 'frontend') continue;
      final name = '${p['name']}';
      final has = inBackend?.params.any((x) => x['name'] == name) ?? false;
      if (!has) {
        r.missingParams.add('`${op.key}` thiếu tham số `$name` (${p['in']})');
      }
    }
  }

  for (final e in _schemas(front).entries) {
    final s = e.value;
    if (s is! Map<String, dynamic>) continue;
    final wholeSchema = s['x-origin'] == 'frontend';
    final props = (s['properties'] as Map<String, dynamic>?) ?? {};
    for (final p in props.entries) {
      final marked =
          wholeSchema ||
          (p.value is Map && (p.value as Map)['x-origin'] == 'frontend');
      if (!bFields.contains(p.key)) {
        if (marked) r.missingFields.add('`${e.key}.${p.key}`');
        r.allFieldsMissing.add('`${e.key}.${p.key}`');
      }
    }
    final added = s['x-frontend-added'];
    if (added is List) {
      for (final v in added) {
        if (!bEnums.contains('$v')) r.missingEnumValues.add('`${e.key}`: $v');
      }
    }
    if (wholeSchema && s['enum'] is List) {
      for (final v in s['enum'] as List) {
        if (!bEnums.contains('$v')) r.missingEnumValues.add('`${e.key}`: $v');
      }
    }
  }
  return r;
}
