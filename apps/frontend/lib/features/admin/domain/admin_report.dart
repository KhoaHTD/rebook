import 'package:book_marketplace/shared/domain/enums.dart';

/// Số liệu của một ngày trong báo cáo.
class ReportDay {
  const ReportDay({
    required this.date,
    required this.gmv,
    required this.orders,
    required this.newUsers,
  });

  final DateTime date;

  /// Tổng giá trị đơn đặt trong ngày (không tính đơn huỷ / giao thất bại), đồng.
  final int gmv;
  final int orders;
  final int newUsers;
}

/// Một phần của biểu đồ cơ cấu theo thể loại.
class ReportCategory {
  const ReportCategory({required this.name, required this.amount});

  final String name;
  final int amount;
}

class ReportStatusCount {
  const ReportStatusCount({required this.status, required this.count});

  final OrderStatus status;
  final int count;
}

/// Báo cáo của Admin trong một khoảng ngày (cả hai đầu).
class AdminReport {
  const AdminReport({
    required this.from,
    required this.to,
    required this.gmv,
    required this.revenue,
    required this.platformFees,
    required this.orders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.auctionOrders,
    required this.newUsers,
    required this.days,
    required this.categories,
    required this.statuses,
  });

  final DateTime from;
  final DateTime to;

  /// Tổng giá trị đơn đặt; [revenue] chỉ tính đơn đã hoàn tất; [platformFees] là phí sàn thu được trên đơn đó.
  final int gmv;
  final int revenue;
  final int platformFees;
  final int orders;
  final int completedOrders;
  final int cancelledOrders;
  final int auctionOrders;
  final int newUsers;
  final List<ReportDay> days;
  final List<ReportCategory> categories;
  final List<ReportStatusCount> statuses;

  int get normalOrders => orders - auctionOrders;

  /// Tỷ lệ huỷ đơn (0–1).
  double get cancelRate => orders == 0 ? 0 : cancelledOrders / orders;

  /// Giá trị trung bình một đơn (đồng).
  int get averageOrder => orders == 0 ? 0 : (gmv / orders).round();

  /// Thay đổi của [pick] giữa nửa sau và nửa đầu của kỳ (0.12 = tăng 12%); null nếu nửa đầu bằng 0.
  double? trendOf(num Function(ReportDay) pick) {
    if (days.length < 2) return null;
    final mid = days.length ~/ 2;
    final first = days.take(mid).fold<num>(0, (a, d) => a + pick(d));
    final second = days.skip(mid).fold<num>(0, (a, d) => a + pick(d));
    if (first == 0) return null;
    return (second - first) / first;
  }
}
