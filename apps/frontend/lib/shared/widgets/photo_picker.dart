import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/network/upload_service.dart';
import 'package:book_marketplace/shared/widgets/app_image.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';

/// Chọn nhiều ảnh, upload ngay, trả về danh sách URL qua [onChanged].
/// Dùng cho đăng bán (≥ 3 ảnh), ký gửi, phiếu kiểm định, yêu cầu trả hàng.
class PhotoPickerField extends ConsumerStatefulWidget {
  const PhotoPickerField({
    super.key,
    required this.folder,
    required this.onChanged,
    this.initial = const [],
    this.max = 8,
  });

  final String folder;
  final ValueChanged<List<String>> onChanged;
  final List<String> initial;
  final int max;

  @override
  ConsumerState<PhotoPickerField> createState() => _PhotoPickerFieldState();
}

class _PhotoPickerFieldState extends ConsumerState<PhotoPickerField> {
  late final _urls = [...widget.initial];
  var _uploading = 0;

  Future<void> _pick() async {
    final files = await ImagePicker().pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );
    final room = widget.max - _urls.length - _uploading;
    final chosen = files.take(room).toList();
    if (chosen.isEmpty) return;
    setState(() => _uploading += chosen.length);
    final uploader = ref.read(imageUploaderProvider);
    for (final f in chosen) {
      try {
        final url = await uploader.upload(f, folder: widget.folder);
        if (!mounted) return;
        setState(() => _urls.add(url));
        widget.onChanged(List.unmodifiable(_urls));
      } catch (e) {
        if (mounted) showErrorSnack(context, e);
      } finally {
        if (mounted) setState(() => _uploading--);
      }
    }
  }

  void _remove(String url) {
    setState(() => _urls.remove(url));
    widget.onChanged(List.unmodifiable(_urls));
  }

  @override
  Widget build(BuildContext context) {
    const size = 92.0;
    final tile = BorderRadius.circular(10);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final url in _urls)
          SizedBox.square(
            dimension: size,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(borderRadius: tile, child: AppImage(url)),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _remove(url),
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: CoverPalette.scrim,
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: context.colors.surface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        for (var i = 0; i < _uploading; i++)
          SizedBox.square(
            dimension: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.appColors.fill,
                borderRadius: tile,
              ),
              child: const Center(
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        if (_urls.length + _uploading < widget.max)
          InkWell(
            onTap: _pick,
            borderRadius: tile,
            child: Ink(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: context.appColors.fill,
                borderRadius: tile,
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                color: context.appColors.secondaryText,
              ),
            ),
          ),
      ],
    );
  }
}
