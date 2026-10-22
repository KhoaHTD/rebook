import 'package:book_marketplace/shared/domain/commerce.dart';

/// Ví nội bộ: số dư, nạp qua VNPay, sổ giao dịch, rút tiền (SRS 8.1).
abstract interface class WalletRepository {
  Future<Wallet> wallet();

  Future<List<WalletTxn>> transactions();

  /// Tạo phiên nạp VNPay; app mở [Payment.paymentUrl].
  Future<Payment> topUp(int amount);

  Future<List<Withdrawal>> withdrawals();

  Future<Withdrawal> requestWithdrawal(int amount);
}
