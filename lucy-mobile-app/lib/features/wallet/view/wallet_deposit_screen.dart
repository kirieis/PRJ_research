// lib/features/wallet/view/wallet_deposit_screen.dart
// ============================================================
// Project LUCY — Wallet Deposit & VietQR Screen
//
// Matches Web client `/wallet` page functionality:
//   - Balance display
//   - Package selection (10k -> 500k VND)
//   - VietQR code rendering via VietQR API (MB Bank 3399377355)
//   - Account info & transfer memo copying
//   - BLoC real-time balance integration
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';

class WalletDepositScreen extends StatefulWidget {
  final String userId;

  const WalletDepositScreen({
    super.key,
    this.userId = '2',
  });

  @override
  State<WalletDepositScreen> createState() => _WalletDepositScreenState();
}

class _WalletDepositScreenState extends State<WalletDepositScreen> {
  final NumberFormat _fmt = NumberFormat('#,###', 'vi_VN');

  // Bank Info (matching Web)
  static const String myBankBin = '970422'; // MB Bank
  static const String myAccountNo = '3399377355';
  static const String myAccountName = 'NGUYEN TRI THIEN';

  // Packages (matching Web)
  static const List<Map<String, dynamic>> _packages = [
    {'amount': 10000, 'coins': 100},
    {'amount': 20000, 'coins': 200},
    {'amount': 50000, 'coins': 500},
    {'amount': 100000, 'coins': 1000},
    {'amount': 500000, 'coins': 5000},
  ];

  int _selectedAmount = 10000;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(const WalletBalanceFetched());
  }

  String get _transferContent => 'LUCY ${widget.userId}';

  String get _qrUrl {
    final encodedInfo = Uri.encodeComponent(_transferContent);
    final encodedName = Uri.encodeComponent(myAccountName);
    return 'https://img.vietqr.io/image/$myBankBin-$myAccountNo-compact2.png?amount=$_selectedAmount&addInfo=$encodedInfo&accountName=$encodedName';
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
          SizedBox(width: 8),
          Text('Đã sao chép vào bộ nhớ tạm'),
        ]),
        backgroundColor: AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Nạp Xu (VietQR)'),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Balance Card
            _buildBalanceCard(),
            const SizedBox(height: 24),

            // Package Selector
            const Text(
              'Chọn gói nạp xu',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildPackageGrid(),
            const SizedBox(height: 24),

            // VietQR Card
            _buildQrCard(),
            const SizedBox(height: 24),

            // Bank Details Card
            _buildBankDetailsCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Số dư hiện tại',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${_fmt.format(state.balance)} Xu',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '🪙',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPackageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _packages.length,
      itemBuilder: (context, index) {
        final pkg = _packages[index];
        final amount = pkg['amount'] as int;
        final coins = pkg['coins'] as int;
        final isSelected = amount == _selectedAmount;

        return InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedAmount = amount);
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.accent
                    : AppColors.textHint.withValues(alpha: 0.2),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_fmt.format(coins)} Xu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color:
                        isSelected ? AppColors.accent : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmt.format(amount)}đ',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQrCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Mã VietQR Thanh Toán',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mở app ngân hàng quét mã QR bên dưới để nạp tự động',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // QR Image from VietQR API
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.network(
              _qrUrl,
              height: 220,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  height: 220,
                  width: 220,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                height: 220,
                width: 220,
                child: Center(
                  child: Text(
                    'Không thể tải QR\nVui lòng thử lại',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Selected amount badge
          Text(
            'Số tiền: ${_fmt.format(_selectedAmount)} VNĐ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin chuyển khoản thủ công',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Ngân hàng', 'MB Bank (Ngân hàng Quân Đội)'),
          const SizedBox(height: 8),
          _buildInfoRow('Chủ tài khoản', myAccountName),
          const SizedBox(height: 8),
          _buildCopyRow('Số tài khoản', myAccountNo),
          const SizedBox(height: 8),
          _buildCopyRow('Nội dung CK', _transferContent, highlight: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCopyRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () => _copyToClipboard(value),
          child: Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: highlight ? AppColors.accent : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
                size: 14,
                color: _copied
                    ? AppColors.success
                    : (highlight ? AppColors.accent : AppColors.textHint),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
