import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';

/// Một cuốn đứng trên kệ tự chạy.
class ShelfBook {
  const ShelfBook({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    this.onTap,
  });

  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final VoidCallback? onTap;
}

/// Kệ sách ngang: các bìa đứng trên một tấm ván, tự trôi chậm **từ trái sang phải liên tục** và lặp vô tận.
/// Chạm / kéo thì dừng (kéo tay được), thả ra một lúc thì trôi tiếp; bấm vào một bìa gọi `onTap` của nó.
class AutoShelf extends StatefulWidget {
  const AutoShelf({
    super.key,
    required this.books,
    this.bookWidth = 92,
    this.height = 190,
    this.speed = 26,
  });

  final List<ShelfBook> books;
  final double bookWidth;

  /// Chiều cao vùng đặt sách (cao hơn cuốn cao nhất).
  final double height;

  /// Tốc độ trôi, điểm ảnh logic mỗi giây.
  final double speed;

  @override
  State<AutoShelf> createState() => _AutoShelfState();
}

class _AutoShelfState extends State<AutoShelf>
    with SingleTickerProviderStateMixin {
  final _controller = ScrollController();
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  bool _held = false;
  Timer? _resume;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (_held || !_controller.hasClients || widget.books.isEmpty) return;
    // Bỏ qua bước nhảy lớn (tab bị treo, quay lại từ nền) để sách không giật vọt.
    if (dt <= 0 || dt > 0.1) return;
    _controller.jumpTo(_controller.offset + widget.speed * dt);
  }

  void _hold() {
    _resume?.cancel();
    _held = true;
  }

  void _release() {
    _resume?.cancel();
    _resume = Timer(const Duration(milliseconds: 1500), () => _held = false);
  }

  @override
  void dispose() {
    _resume?.cancel();
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.books.length;
    final c = context.appColors;
    if (n == 0) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: Listener(
            onPointerDown: (_) => _hold(),
            onPointerUp: (_) => _release(),
            onPointerCancel: (_) => _release(),
            // reverse: tăng độ lệch cuộn = nội dung trôi sang phải.
            child: ListView.builder(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, i) {
                final b = widget.books[i % n];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: b.onTap,
                    child: SizedBox(
                      width: widget.bookWidth,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: BookPoster(
                          title: b.title,
                          author: b.author,
                          coverUrl: b.coverUrl,
                          seed: b.id,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Tấm ván kệ: sách đứng lên trên, đổ bóng nhẹ xuống dưới.
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.glassBorder, c.fill],
            ),
            boxShadow: [
              BoxShadow(
                color: c.glassShadow,
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
