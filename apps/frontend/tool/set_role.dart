// Đặt vai làm việc trên máy này: `dart run tool/set_role.dart admin|staff|owner`
// Ghi vào ~/.rebook-role. Hook Claude và CI dùng vai này để biết bạn được sửa vùng nào
// (xem tool/zones.txt và docs/TEAM_GUIDE.md). Chủ repo dùng `owner`.
import 'dart:io';

void main(List<String> args) {
  const roles = ['admin', 'staff', 'owner'];
  if (args.length != 1 || !roles.contains(args.first)) {
    stderr.writeln('Dùng: dart run tool/set_role.dart <${roles.join('|')}>');
    exitCode = 64;
    return;
  }
  final home =
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
  if (home == null) {
    stderr.writeln('Không tìm thấy thư mục home.');
    exitCode = 1;
    return;
  }
  File('$home/.rebook-role').writeAsStringSync('${args.first}\n');
  stdout.writeln('Đã đặt vai "${args.first}" (file: $home/.rebook-role).');
  if (args.first == 'admin') {
    stdout.writeln('Bạn sở hữu: features/admin/** và test/features/admin/**.');
  } else if (args.first == 'staff') {
    stdout.writeln('Bạn sở hữu: features/staff/** và test/features/staff/**.');
  }
  stdout.writeln(
    'Tạo nhánh theo vai: ${args.first}/<tên-việc>. Đọc docs/TEAM_GUIDE.md.',
  );
}
