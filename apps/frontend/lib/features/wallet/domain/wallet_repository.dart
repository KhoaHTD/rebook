import 'package:book_marketplace/shared/domain/commerce.dart';

/// Ví nội bộ: số dư, nạp qua VNPay, sổ giao dịch, rút tiền (SRS 8.1).
abstract interface class WalletRepository {
  Future<Wallet> wallet();

  Future<List<WalletTxn>> transactions();

  /// Tạo phiên nạp VNPay; app mở [Payment.paymentUrl].
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
}
