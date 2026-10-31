import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/shared/domain/commerce.dart';

part 'withdraw_draft.g.dart';

/// Những gì người bán đã nhập qua các bước rút tiền (chọn ngân hàng → số tài khoản → số tiền).
class WithdrawDraft {
  const WithdrawDraft({
    this.bank,
    this.accountNumber = '',
    this.accountName = '',
    this.favorite = false,
    this.amount = 0,
    this.note,
    this.result,
  });

  final String? bank;
  final String accountNumber;
  final String accountName;

  /// Đã đánh dấu sao tài khoản này (lưu sau khi gửi yêu cầu).
  final bool favorite;
  final int amount;
  final String? note;

  /// Yêu cầu vừa tạo, cho màn kết quả.
  final Withdrawal? result;

  WithdrawDraft copyWith({
    String? bank,
    String? accountNumber,
    String? accountName,
    bool? favorite,
    int? amount,
    String? note,
    Withdrawal? result,
  }) => WithdrawDraft(
    bank: bank ?? this.bank,
    accountNumber: accountNumber ?? this.accountNumber,
    accountName: accountName ?? this.accountName,
    favorite: favorite ?? this.favorite,
    amount: amount ?? this.amount,
    note: note ?? this.note,
    result: result ?? this.result,
  );
}

@Riverpod(keepAlive: true)
class WithdrawDraftController extends _$WithdrawDraftController {
  @override
  WithdrawDraft build() => const WithdrawDraft();

  void reset() => state = const WithdrawDraft();

  /// Chọn ngân hàng; đổi sang ngân hàng khác thì xoá số tài khoản đã nhập.
  void selectBank(String bank) {
    state = state.bank == bank
        ? state
        : WithdrawDraft(bank: bank, amount: state.amount);
  }

  void setAccount(String number, String name, {bool? favorite}) {
    state = state.copyWith(
      accountNumber: number,
      accountName: name,
      favorite: favorite,
    );
  }

  void setFavorite(bool on) => state = state.copyWith(favorite: on);

  void setAmount(int amount) => state = state.copyWith(amount: amount);

  void setNote(String note) => state = state.copyWith(note: note);

  void setResult(Withdrawal w) => state = state.copyWith(result: w);
}
