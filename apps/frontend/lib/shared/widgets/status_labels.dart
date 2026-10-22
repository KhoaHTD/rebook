import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Nhãn hiển thị + màu cho các enum trạng thái — dùng chung cho mọi feature
/// để cùng một trạng thái luôn trông giống nhau.

extension OrderStatusL10n on OrderStatus {
  String label(AppLocalizations l) => switch (this) {
    OrderStatus.pendingPayment => l.osPendingPayment,
    OrderStatus.pendingConfirm => l.osPendingConfirm,
    OrderStatus.preparing => l.osPreparing,
    OrderStatus.shipping => l.osShipping,
    OrderStatus.delivered => l.osDelivered,
    OrderStatus.returnRequested => l.osReturnRequested,
    OrderStatus.completed => l.osCompleted,
    OrderStatus.cancelled => l.osCancelled,
    OrderStatus.returned => l.osReturned,
    OrderStatus.failedDelivery => l.osFailedDelivery,
  };

  StatusTone get tone => switch (this) {
    OrderStatus.pendingPayment ||
    OrderStatus.pendingConfirm => StatusTone.warning,
    OrderStatus.preparing || OrderStatus.shipping => StatusTone.info,
    OrderStatus.delivered || OrderStatus.completed => StatusTone.success,
    OrderStatus.returnRequested => StatusTone.warning,
    OrderStatus.cancelled ||
    OrderStatus.returned ||
    OrderStatus.failedDelivery => StatusTone.danger,
  };
}

extension PaymentMethodL10n on PaymentMethod {
  String label(AppLocalizations l) => switch (this) {
    PaymentMethod.cod => l.pmCod,
    PaymentMethod.wallet => l.pmWallet,
    PaymentMethod.vnpay => l.pmVnpay,
  };
}

extension ReturnStatusL10n on ReturnStatus {
  String label(AppLocalizations l) => switch (this) {
    ReturnStatus.pending => l.rsPending,
    ReturnStatus.accepted => l.rsAccepted,
    ReturnStatus.rejected => l.rsRejected,
    ReturnStatus.escalated => l.rsEscalated,
    ReturnStatus.resolvedRefund => l.rsResolvedRefund,
    ReturnStatus.resolvedNoRefund => l.rsResolvedNoRefund,
  };
}

extension WalletTxnTypeL10n on WalletTxnType {
  String label(AppLocalizations l) => switch (this) {
    WalletTxnType.topUp => l.txTopUp,
    WalletTxnType.payment => l.txPayment,
    WalletTxnType.refund => l.txRefund,
    WalletTxnType.depositHold => l.txDepositHold,
    WalletTxnType.depositRelease => l.txDepositRelease,
    WalletTxnType.depositForfeit => l.txDepositForfeit,
    WalletTxnType.salePending => l.txSalePending,
    WalletTxnType.saleRelease => l.txSaleRelease,
    WalletTxnType.fee => l.txFee,
    WalletTxnType.withdraw => l.txWithdraw,
  };
}

extension WithdrawalStatusL10n on WithdrawalStatus {
  String label(AppLocalizations l) => switch (this) {
    WithdrawalStatus.pending => l.wdPending,
    WithdrawalStatus.completed => l.wdCompleted,
    WithdrawalStatus.rejected => l.wdRejected,
  };

  StatusTone get tone => switch (this) {
    WithdrawalStatus.pending => StatusTone.warning,
    WithdrawalStatus.completed => StatusTone.success,
    WithdrawalStatus.rejected => StatusTone.danger,
  };
}

extension ConsignmentStatusL10n on ConsignmentStatus {
  String label(AppLocalizations l) => switch (this) {
    ConsignmentStatus.submitted => l.csSubmitted,
    ConsignmentStatus.preApproved => l.csPreApproved,
    ConsignmentStatus.preRejected => l.csPreRejected,
    ConsignmentStatus.appointmentBooked => l.csAppointmentBooked,
    ConsignmentStatus.expired => l.csExpired,
    ConsignmentStatus.received => l.csReceived,
    ConsignmentStatus.inspected => l.csInspected,
    ConsignmentStatus.inspectionFailed => l.csInspectionFailed,
    ConsignmentStatus.accepted => l.csAccepted,
    ConsignmentStatus.withdrawn => l.csWithdrawn,
    ConsignmentStatus.returned => l.csReturned,
  };

  StatusTone get tone => switch (this) {
    ConsignmentStatus.submitted ||
    ConsignmentStatus.appointmentBooked ||
    ConsignmentStatus.received => StatusTone.info,
    ConsignmentStatus.preApproved ||
    ConsignmentStatus.inspected => StatusTone.warning,
    ConsignmentStatus.accepted => StatusTone.success,
    ConsignmentStatus.preRejected ||
    ConsignmentStatus.expired ||
    ConsignmentStatus.inspectionFailed => StatusTone.danger,
    ConsignmentStatus.withdrawn ||
    ConsignmentStatus.returned => StatusTone.neutral,
  };
}

extension LotStatusL10n on LotStatus {
  String label(AppLocalizations l) => switch (this) {
    LotStatus.ready => l.lsReady,
    LotStatus.scheduled => l.lsScheduled,
    LotStatus.live => l.lsLive,
    LotStatus.sold => l.lsSold,
    LotStatus.unsold => l.lsUnsold,
    LotStatus.completed => l.lsCompleted,
    LotStatus.returned => l.lsReturned,
    LotStatus.cancelled => l.lsCancelled,
  };

  StatusTone get tone => switch (this) {
    LotStatus.ready || LotStatus.scheduled => StatusTone.info,
    LotStatus.live => StatusTone.danger,
    LotStatus.sold || LotStatus.completed => StatusTone.success,
    LotStatus.unsold || LotStatus.returned => StatusTone.warning,
    LotStatus.cancelled => StatusTone.neutral,
  };
}

extension SessionStatusL10n on SessionStatus {
  String label(AppLocalizations l) => switch (this) {
    SessionStatus.draft => l.ssDraft,
    SessionStatus.published => l.ssPublished,
    SessionStatus.postponed => l.ssPostponed,
    SessionStatus.confirmed => l.ssConfirmed,
    SessionStatus.live => l.ssLive,
    SessionStatus.paused => l.ssPaused,
    SessionStatus.ended => l.ssEnded,
    SessionStatus.cancelled => l.ssCancelled,
  };

  StatusTone get tone => switch (this) {
    SessionStatus.draft => StatusTone.neutral,
    SessionStatus.published || SessionStatus.confirmed => StatusTone.info,
    SessionStatus.live => StatusTone.danger,
    SessionStatus.paused || SessionStatus.postponed => StatusTone.warning,
    SessionStatus.ended => StatusTone.success,
    SessionStatus.cancelled => StatusTone.neutral,
  };
}

extension ListingStatusL10n on ListingStatus {
  String label(AppLocalizations l) => switch (this) {
    ListingStatus.pendingReview => l.lstPendingReview,
    ListingStatus.active => l.lstActive,
    ListingStatus.hidden => l.lstHidden,
    ListingStatus.outOfStock => l.lstOutOfStock,
    ListingStatus.rejected => l.lstRejected,
  };

  StatusTone get tone => switch (this) {
    ListingStatus.pendingReview => StatusTone.warning,
    ListingStatus.active => StatusTone.success,
    ListingStatus.hidden => StatusTone.neutral,
    ListingStatus.outOfStock => StatusTone.info,
    ListingStatus.rejected => StatusTone.danger,
  };
}

extension WarehouseStatusL10n on WarehouseStatus {
  String label(AppLocalizations l) => switch (this) {
    WarehouseStatus.inStock => l.whInStock,
    WarehouseStatus.reserved => l.whReserved,
    WarehouseStatus.shipped => l.whShipped,
    WarehouseStatus.returned => l.whReturned,
  };
}

/// Sắc thái của một trạng thái → màu chữ của [StatusPill].
enum StatusTone { neutral, info, success, warning, danger }

/// Nhãn trạng thái: chữ màu trên nền nhạt cùng tông, bo viên thuốc.
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.tone = StatusTone.neutral});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final color = switch (tone) {
      StatusTone.neutral => c.secondaryText,
      StatusTone.info => c.info,
      StatusTone.success => c.success,
      StatusTone.warning => c.warning,
      StatusTone.danger => c.live,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.12),
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: context.textStyles.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

extension ConditionGradeL10n on ConditionGrade {
  String label(AppLocalizations l) => switch (this) {
    ConditionGrade.brandNew => l.conditionNew,
    ConditionGrade.likeNew => l.conditionLikeNew,
    ConditionGrade.veryGood => l.conditionVeryGood,
    ConditionGrade.good => l.conditionGood,
    ConditionGrade.acceptable => l.conditionAcceptable,
    ConditionGrade.unknown => l.conditionUnknown,
  };

  String hint(AppLocalizations l) => switch (this) {
    ConditionGrade.brandNew => l.conditionNewHint,
    ConditionGrade.likeNew => l.conditionLikeNewHint,
    ConditionGrade.veryGood => l.conditionVeryGoodHint,
    ConditionGrade.good => l.conditionGoodHint,
    ConditionGrade.acceptable => l.conditionAcceptableHint,
    ConditionGrade.unknown => l.conditionUnknown,
  };

  StatusTone get tone => switch (this) {
    ConditionGrade.brandNew || ConditionGrade.likeNew => StatusTone.success,
    ConditionGrade.veryGood => StatusTone.info,
    ConditionGrade.good => StatusTone.neutral,
    ConditionGrade.acceptable || ConditionGrade.unknown => StatusTone.warning,
  };
}
