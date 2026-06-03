// lib/features/wallet/view/wallet_deposit_screen.dart
// ============================================================
// Project LUCY — Wallet Deposit Screen (BLoC-driven)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';

class WalletDepositScreen extends StatefulWidget {
  const WalletDepositScreen({super.key});

  @override
  State<WalletDepositScreen> createState() => _WalletDepositScreenState();
}

class _WalletDepositScreenState extends State<WalletDepositScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final NumberFormat _fmt = NumberFormat('#,###', 'vi_VN');
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  int _selectedPreset = 0;

  static const List<int> _presets = [50000, 100000, 200000, 500000];

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOutBack),
    );
    context.read<WalletBloc>().add(const WalletBalanceFetched());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  int _parseAmount() {
    final raw = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return raw.isEmpty ? 0 : (int.tryParse(raw) ?? 0);
  }

  void _setPreset(int amount) {
    setState(() => _selectedPreset = amount);
    _amountController.text = _fmt.format(amount);
    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _amountController.text.length),
    );
  }

  void _deposit() {
    final amount = _parseAmount();
    if (amount <= 0) return;
    context.read<WalletBloc>().add(WalletDepositRequested(amount: amount));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Nạp Tiền'),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
      ),
      body: BlocListener<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state.status == WalletStatus.success) {
            _bounceCtrl.forward().then((_) => _bounceCtrl.reverse());
            _amountController.clear();
            setState(() => _selectedPreset = 0);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 20),
                SizedBox(width: 8),
                Text('Nạp tiền thành công!'),
              ]),
              backgroundColor: AppColors.surfaceDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          } else if (state.status == WalletStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(state.errorMessage ?? 'Lỗi nạp tiền')),
              ]),
              backgroundColor: AppColors.surfaceDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 32),
              _buildAmountInput(),
              const SizedBox(height: 20),
              _buildPresetRow(),
              const SizedBox(height: 40),
              _buildDepositButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return BlocBuilder<WalletBloc, WalletState>(
      buildWhen: (p, c) => p.balance != c.balance,
      builder: (context, state) {
        return ScaleTransition(
          scale: _bounceAnim,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.accent.withValues(alpha: 0.08),
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(children: [
              const Text('Số dư hiện tại',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(_fmt.format(state.balance),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 36, fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('VND', style: TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildAmountInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          TextInputFormatter.withFunction((oldValue, newValue) {
            if (newValue.text.isEmpty) return newValue;
            final int value = int.parse(newValue.text);
            final String formatted = _fmt.format(value);
            return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
          }),
        ],
        decoration: InputDecoration(
          labelText: 'Số tiền cần nạp',
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          suffixText: 'VND',
          suffixStyle: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
            ),
          ),
        ),
        onChanged: (_) {
          if (_selectedPreset != 0) setState(() => _selectedPreset = 0);
        },
      ),
    );
  }

  Widget _buildPresetRow() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.only(left: 4, bottom: 12),
        child: Text('Chọn nhanh',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
      ),
      Row(
        children: _presets.map((amount) {
          final isSelected = _selectedPreset == amount;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: amount == _presets.last ? 0 : 8),
              child: _presetChip(amount, isSelected),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _presetChip(int amount, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _setPreset(amount),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: AppColors.primaryGradient, begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: isSelected ? null : AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.transparent : AppColors.textHint.withValues(alpha: 0.3)),
            boxShadow: isSelected
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Center(
            child: Text('${_fmt.format(amount)}đ',
                style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
          ),
        ),
      ),
    );
  }

  Widget _buildDepositButton() {
    return BlocBuilder<WalletBloc, WalletState>(
      buildWhen: (p, c) => p.isDepositing != c.isDepositing,
      builder: (context, state) {
        return PrimaryButton(
          label: 'Nạp tiền',
          icon: Icons.add_card_rounded,
          isLoading: state.isDepositing,
          isDisabled: state.isDepositing,
          onPressed: _deposit,
        );
      },
    );
  }
}
