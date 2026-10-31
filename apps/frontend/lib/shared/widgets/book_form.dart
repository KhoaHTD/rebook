import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/network/upload_service.dart';
import 'package:book_marketplace/core/utils/input_rules.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/cover_scanner.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/form_widgets.dart';
import 'package:book_marketplace/shared/widgets/glass_menu.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';
import 'package:book_marketplace/shared/widgets/photo_picker.dart';

/// Phần nhập thông tin sách — dùng chung cho đăng bán và ký gửi.
///
/// Gọi [BookFormState.validate] / [BookFormState.draft] qua GlobalKey.
class BookForm extends ConsumerStatefulWidget {
  const BookForm({
    super.key,
    required this.categories,
    required this.photoFolder,
    this.initial,
    this.minPhotos = 3,
  });

  final List<Category> categories;
  final String photoFolder;
  final Book? initial;

  /// SRS 4.1: tối thiểu 3 ảnh (bìa trước, gáy, trang bên trong).
  final int minPhotos;

  @override
  ConsumerState<BookForm> createState() => BookFormState();
}

class BookFormState extends ConsumerState<BookForm> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _author = TextEditingController(text: widget.initial?.author);
  late final _publisher = TextEditingController(
    text: widget.initial?.publisher,
  );
  late final _year = TextEditingController(
    text: widget.initial?.publishYear?.toString(),
  );
  late final _isbn = TextEditingController(text: widget.initial?.isbn);
  late final _language = TextEditingController(text: widget.initial?.language);
  late final _pages = TextEditingController(
    text: widget.initial?.pages?.toString(),
  );
  late final _weight = TextEditingController(
    text: widget.initial?.weightGram?.toString(),
  );
  late final _description = TextEditingController(
    text: widget.initial?.description,
  );
  late var _photos = [
    for (final i in widget.initial?.images ?? const <BookImage>[]) i.url,
  ];
  late ConditionGrade? _condition = widget.initial?.condition;
  late String? _categoryId = widget.initial?.categoryId;
  var _showPhotoError = false;

  /// Ảnh bìa đại diện đã làm phẳng (đứng đầu danh sách ảnh); null = lấy ảnh thật đầu tiên như trước.
  String? _cover;
  var _coverBusy = false;

  /// Chọn / chụp ảnh bìa trước, cho người bán kéo 4 góc, làm phẳng rồi upload.
  Future<void> _pickCover(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2000,
    );
    if (file == null || !mounted) return;
    final photo = await file.readAsBytes();
    if (!mounted) return;
    final flat = await showCoverScanner(context, photo);
    if (flat == null || !mounted) return;
    setState(() => _coverBusy = true);
    try {
      final url = await ref
          .read(imageUploaderProvider)
          .upload(
            XFile.fromData(flat, name: 'cover.png', mimeType: 'image/png'),
            folder: widget.photoFolder,
          );
      if (mounted) setState(() => _cover = url);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _coverBusy = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _author,
      _publisher,
      _year,
      _isbn,
      _language,
      _pages,
      _weight,
      _description,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool validate() {
    final ok = _form.currentState!.validate();
    setState(() => _showPhotoError = _photos.length < widget.minPhotos);
    return ok && !_showPhotoError && _condition != null;
  }

  BookDraft draft() {
    String? text(InputRule r, TextEditingController c) =>
        r.value(c.text).isEmpty ? null : r.value(c.text);
    return BookDraft(
      title: Rules.bookTitle.value(_title.text),
      author: Rules.author.value(_author.text),
      condition: _condition!,
      imageUrls: [?_cover, ..._photos],
      publisher: text(Rules.publisher, _publisher),
      publishYear: int.tryParse(_year.text),
      isbn: text(Rules.isbn, _isbn),
      language: text(Rules.language, _language),
      pages: int.tryParse(_pages.text),
      categoryId: _categoryId,
      description: text(Rules.description, _description),
      weightGram: int.tryParse(_weight.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget field(
      TextEditingController c,
      String label,
      InputRule rule, {
      int lines = 1,
    }) => RuleField(
      controller: c,
      label: label,
      rule: rule,
      bottom: 0,
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 3,
      showCounter: lines > 1,
    );
    Widget pair(Widget a, Widget b) => Row(
      children: [
        Expanded(child: a),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: b),
      ],
    );
    const gap = SizedBox(height: AppSpacing.md);

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoPanel(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.coverTitle, style: context.textStyles.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.coverHint,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.appColors.secondaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_cover != null)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.md),
                        child: BookPoster(
                          title: _title.text,
                          author: _author.text,
                          coverUrl: _cover,
                          seed: _cover!,
                          width: 84,
                        ),
                      ),
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _coverBusy
                                ? null
                                : () => _pickCover(ImageSource.camera),
                            icon: const Icon(
                              Icons.photo_camera_outlined,
                              size: 18,
                            ),
                            label: Text(l10n.coverCamera),
                          ),
                          OutlinedButton.icon(
                            onPressed: _coverBusy
                                ? null
                                : () => _pickCover(ImageSource.gallery),
                            icon: const Icon(
                              Icons.photo_library_outlined,
                              size: 18,
                            ),
                            label: Text(
                              _cover == null ? l10n.coverPick : l10n.coverRedo,
                            ),
                          ),
                          if (_cover != null)
                            TextButton(
                              onPressed: () => setState(() => _cover = null),
                              child: Text(l10n.coverRemove),
                            ),
                          if (_coverBusy)
                            const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          gap,
          InfoPanel(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.photosRequired(widget.minPhotos),
                  style: context.textStyles.titleSmall?.copyWith(
                    color: _showPhotoError ? context.colors.error : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                PhotoPickerField(
                  folder: widget.photoFolder,
                  initial: _photos,
                  onChanged: (urls) => setState(() {
                    _photos = urls;
                    if (urls.length >= widget.minPhotos) {
                      _showPhotoError = false;
                    }
                  }),
                ),
              ],
            ),
          ),
          gap,
          InfoPanel(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                field(_title, l10n.bookTitle, Rules.bookTitle),
                gap,
                field(_author, l10n.author, Rules.author),
                gap,
                GlassDropdownField<String>(
                  value: _categoryId,
                  label: l10n.category,
                  hint: l10n.pickCategory,
                  items: [
                    for (final c in widget.categories)
                      GlassMenuItem(
                        value: c.id,
                        label: c.parentId == null ? c.name : '  ${c.name}',
                      ),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                  validator: (v) => v == null ? l10n.fieldRequired : null,
                ),
                gap,
                Text(l10n.pickCondition, style: context.textStyles.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final g in ConditionGrade.values.where(
                      (g) => g != ConditionGrade.unknown,
                    ))
                      ChoiceChip(
                        label: Text(g.label(l10n)),
                        selected: _condition == g,
                        onSelected: (_) => setState(() => _condition = g),
                      ),
                  ],
                ),
                if (_condition != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      _condition!.hint(l10n),
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.appColors.secondaryText,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          gap,
          InfoPanel(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                pair(
                  field(_publisher, l10n.publisher, Rules.publisher),
                  field(_year, l10n.publishYear, Rules.year),
                ),
                gap,
                pair(
                  field(_isbn, l10n.isbn, Rules.isbn),
                  field(_language, l10n.language, Rules.language),
                ),
                gap,
                pair(
                  field(_pages, l10n.pages, Rules.pages),
                  field(_weight, l10n.weight, Rules.weightGram),
                ),
                gap,
                field(
                  _description,
                  l10n.description,
                  Rules.description,
                  lines: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
