import 'package:book_marketplace/features/wallet/domain/debt.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';

/// Ví nội bộ: số dư, nạp qua ZaloPay, sổ giao dịch, rút tiền (SRS 8.1).
abstract interface class WalletRepository {
  Future<Wallet> wallet();

  Future<List<WalletTxn>> transactions();

  /// Tạo phiên nạp ZaloPay; app mở [Payment.paymentUrl].
  Future<Payment> topUp(int amount);

  Future<List<Withdrawal>> withdrawals();

  /// Tạo yêu cầu rút tiền kèm thông tin nhận tiền. Số dư khả dụng phải đủ; ví chỉ bị trừ khi Admin duyệt (SRS 8.1).
  /// Tài khoản ngân hàng đã dùng, yêu thích đứng đầu rồi tới lần dùng mới nhất.
  Future<List<BankAccount>> bankAccounts();

  Future<BankAccount> setBankAccountFavorite(String id, {required bool on});

  Future<Withdrawal> requestWithdrawal(
    int amount, {
    required String bankName,
    required String accountNumber,
    required String accountName,
    String? note,
  });

  /// Nợ còn phải trả (phạt bỏ thanh toán, phí kho).
  Future<List<Debt>> debts();

  /// Thu nợ ngay từ số dư dùng được của ví, cũ nhất trước.
  Future<DebtCollectResult> collectDebts();
}
