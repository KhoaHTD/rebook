package com.rebook.wallet;

public enum WalletTxType {
    TOP_UP, PAYMENT, REFUND, DEPOSIT_HOLD, DEPOSIT_RELEASE, DEPOSIT_FORFEIT, SALE_PENDING, SALE_RELEASE, FEE, WITHDRAW,
    /** Sàn nhận tiền COD đối soát từ hãng vận chuyển / sàn trả tiền COD cho shop. */
    COD_RECEIPT, COD_PAYOUT,
    /** Tiền phạt người thắng bỏ thanh toán lô đấu giá (ngoài phần tiền cọc). */
    AUCTION_PENALTY,
    /** Sàn bồi thường: kho làm mất / hỏng sách, hoặc bù chênh cho người bán khi lô bị bỏ rồi bán lại thấp hơn. */
    COMPENSATION
}
