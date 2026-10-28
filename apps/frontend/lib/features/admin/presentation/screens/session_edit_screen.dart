import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/glass_picker.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Tạo / sửa phiên, xếp lô, công bố (SRS 5.3, 7.2).
class SessionEditScreen extends ConsumerWidget {
  const SessionEditScreen({super.key, this.sessionId});

  final String? sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (sessionId == null) {
      return AppPage(
        title: l10n.newSession,
        showBack: true,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: const _SessionForm(),
            ),
          ),
        ],
      );
    }
    final data = ref.watch(adminSessionProvider(sessionId!));
    final s = data.value?.$1;
    final busy = ref.watch(adminActionsProvider).isLoading;
    return AppPage(
      title: s?.title ?? l10n.editSession,
      subtitle: s?.status.label(l10n),
      showBack: true,
      actions: [
        if (s != null && s.status == SessionStatus.draft)
          HeaderAction(
            icon: Icons.campaign_outlined,
            label: l10n.publish,
            onPressed: busy
                ? null
                : () async {
                    final r = await ref.read(adminActionsProvider.notifier).run(
                      (r) => r.publish(s.id),
                      [DataArea.auctions],
                    );
                    if (r == null && context.mounted) {
                      showErrorSnack(
                        context,
                        ref.read(adminActionsProvider).error!,
                      );
                    }
                  },
          ),
        if (s != null && s.isLive)
          HeaderAction(
            icon: Icons.monitor_heart_outlined,
            label: l10n.monitor,
            onPressed: () => context.go(AdminRoutes.monitor(s.id)),
          ),
      ],
      children: [
        AsyncValueView(
          value: data,
          onRetry: () => ref.invalidate(adminSessionProvider(sessionId!)),
          data: (d) {
            final editable =
                d.$1.status == SessionStatus.draft ||
                d.$1.status == SessionStatus.postponed;
            final form = _SessionForm(initial: d.$1, enabled: editable);
            final lots = _LotsPanel(
              session: d.$1,
              lots: d.$2,
              editable: editable,
            );
            if (context.windowSize == WindowSize.expanded) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 420, child: form),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(child: lots),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                form,
                const SizedBox(height: AppSpacing.lg),
                lots,
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SessionForm extends ConsumerStatefulWidget {
  const _SessionForm({this.initial, this.enabled = true});

  final AuctionSession? initial;
  final bool enabled;

  @override
  ConsumerState<_SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends ConsumerState<_SessionForm> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _desc = TextEditingController(text: widget.initial?.description);
  late final _min = TextEditingController(
    text: '${widget.initial?.minParticipants ?? 5}',
  );
  late final _deposit = TextEditingController(
    text: '${widget.initial?.depositAmount ?? 500000}',
  );
  late final _lot = TextEditingController(
    text: '${widget.initial?.lotDurationSec ?? 60}',
  );
  late final _soft = TextEditingController(
    text: '${widget.initial?.softCloseSec ?? 15}',
  );
  late DateTime _start =
      widget.initial?.startAt ??
      DateTime.now()
          .add(const Duration(days: 7))
          .copyWith(
            hour: 20,
            minute: 0,
            second: 0,
            millisecond: 0,
            microsecond: 0,
          );
  late DateTime _deadline =
      widget.initial?.registrationDeadline ??
      _start.subtract(const Duration(hours: 24));

  @override
  void dispose() {
    for (final c in [_title, _desc, _min, _deposit, _lot, _soft]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial, String title) {
    final now = DateTime.now();
    return showGlassDateTimePicker(
      context,
      initial: initial,
      min: now,
      max: now.add(const Duration(days: 365)),
      title: title,
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final draft = AuctionSession(
      id: widget.initial?.id ?? '',
      title: _title.text.trim(),
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      startAt: _start,
      registrationDeadline: _deadline,
      minParticipants: int.parse(_min.text),
      depositAmount: int.parse(_deposit.text),
      lotDurationSec: int.parse(_lot.text),
      softCloseSec: int.parse(_soft.text),
      status: widget.initial?.status ?? SessionStatus.draft,
      lotCount: widget.initial?.lotCount ?? 0,
      registeredCount: widget.initial?.registeredCount ?? 0,
    );
    final s = await ref.read(adminActionsProvider.notifier).run(
      (r) => r.saveSession(widget.initial?.id, draft),
      [DataArea.auctions],
    );
    if (!mounted) return;
    if (s == null) {
      showErrorSnack(context, ref.read(adminActionsProvider).error!);
      return;
    }
    showInfoSnack(context, context.l10n.saved);
    if (widget.initial == null) context.go(AdminRoutes.session(s.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = ref.watch(adminActionsProvider).isLoading;
    String? positive(String? v) =>
        (int.tryParse(v ?? '') ?? 0) > 0 ? null : l10n.invalidNumber;
    Widget number(TextEditingController c, String label) => Expanded(
      child: TextFormField(
        controller: c,
        enabled: widget.enabled,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label),
        validator: positive,
      ),
    );
    Widget when(String label, DateTime at, IconData icon, VoidCallback pick) =>
        ListTile(
          contentPadding: EdgeInsets.zero,
          enabled: widget.enabled,
          title: Text(label),
          subtitle: Text(formatDateTime(at)),
          trailing: Icon(icon),
          onTap: pick,
        );

    return Form(
      key: _form,
      child: InfoPanel(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _title,
              enabled: widget.enabled,
              decoration: InputDecoration(labelText: l10n.sessionTitle),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _desc,
              enabled: widget.enabled,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(labelText: l10n.description),
            ),
            const SizedBox(height: AppSpacing.md),
            when(l10n.sessionStart, _start, Icons.event_outlined, () async {
              final d = await _pick(_start, l10n.sessionStart);
              if (d != null) setState(() => _start = d);
            }),
            when(
              l10n.sessionDeadline,
              _deadline,
              Icons.event_busy_outlined,
              () async {
                final d = await _pick(_deadline, l10n.sessionDeadline);
                if (d != null) setState(() => _deadline = d);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                number(_deposit, l10n.depositAmount),
                const SizedBox(width: AppSpacing.sm),
                number(_min, l10n.minParticipants),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                number(_lot, l10n.lotDuration),
                const SizedBox(width: AppSpacing.sm),
                number(_soft, l10n.softClose),
              ],
            ),
            if (widget.enabled) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: busy ? null : _save,
                child: Text(l10n.save),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Xếp lô vào phiên: chọn từ các lô sẵn sàng, thứ tự theo lần chọn.
class _LotsPanel extends ConsumerStatefulWidget {
  const _LotsPanel({
    required this.session,
    required this.lots,
    required this.editable,
  });

  final AuctionSession session;
  final List<Lot> lots;
  final bool editable;

  @override
  ConsumerState<_LotsPanel> createState() => _LotsPanelState();
}

class _LotsPanelState extends ConsumerState<_LotsPanel> {
  late final _chosen = [for (final l in widget.lots) l.id];

  Future<void> _assign() async {
    final l10n = context.l10n;
    final r = await ref.read(adminActionsProvider.notifier).run(
      (r) => r.setLots(widget.session.id, _chosen),
      [DataArea.auctions],
    );
    if (!mounted) return;
    if (r == null) {
      showErrorSnack(context, ref.read(adminActionsProvider).error!);
    } else {
      showInfoSnack(context, l10n.saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ready = ref.watch(readyLotsProvider).value ?? const <Lot>[];
    final byId = {
      for (final l in [...widget.lots, ...ready]) l.id: l,
    };
    final busy = ref.watch(adminActionsProvider).isLoading;

    Widget tile(Lot l, {required bool inSession}) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: BookPoster(
        title: l.book.title,
        author: '',
        coverUrl: l.book.coverUrl,
        seed: l.book.id,
        width: 36,
        shadow: false,
      ),
      title: Text(l.book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${formatVnd(l.startPrice)} · ${l.status.label(l10n)}'),
      trailing: widget.editable
          ? IconButton(
              tooltip: inSession ? l10n.delete : l10n.assignLots,
              icon: Icon(
                inSession
                    ? Icons.remove_circle_outline_rounded
                    : Icons.add_circle_outline_rounded,
              ),
              onPressed: () => setState(
                () => inSession ? _chosen.remove(l.id) : _chosen.add(l.id),
              ),
            )
          : (l.status == LotStatus.live || l.status == LotStatus.scheduled)
          ? null
          : StatusPill(l.status.label(l10n), tone: l.status.tone),
    );

    return InfoPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${l10n.inSession} (${_chosen.length})',
            style: context.textStyles.titleMedium,
          ),
          for (final id in _chosen)
            if (byId[id] != null) tile(byId[id]!, inSession: true),
          if (widget.editable) ...[
            Divider(height: AppSpacing.xl, color: context.appColors.separator),
            Text(l10n.readyLots, style: context.textStyles.titleMedium),
            for (final l in ready.where((l) => !_chosen.contains(l.id)))
              tile(l, inSession: false),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: busy ? null : _assign,
              child: Text(l10n.assignLots),
            ),
          ],
        ],
      ),
    );
  }
}
