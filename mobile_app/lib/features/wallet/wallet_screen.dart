import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format_utils.dart';
import 'wallet_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _service = WalletService();
  double _balance = 0;
  List<BankAccountModel> _banks = [];
  List<WalletTransactionModel> _recentTxs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getBalance(),
        _service.getBankAccounts(),
        _service.getTransactions(),
      ]);
      if (mounted) {
        setState(() {
          _balance = results[0] as double;
          _banks = results[1] as List<BankAccountModel>;
          final txs = results[2] as List<WalletTransactionModel>;
          _recentTxs = txs.take(3).toList();
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addBank() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddBankSheet(
        onAdd: (bankName, number, holder) async {
          Navigator.pop(context);
          try {
            await _service.addBankAccount(
                bankName: bankName,
                accountNumber: number,
                accountHolder: holder);
            _load();
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Không thể thêm tài khoản')));
            }
          }
        },
      ),
    );
  }

  void _deleteBank(BankAccountModel bank) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: Text('Xóa ${bank.bankName} - ${bank.accountNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.deleteBankAccount(bank.id);
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể xóa tài khoản')));
      }
    }
  }

  void _withdraw() {
    if (_banks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng thêm tài khoản ngân hàng trước')));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _WithdrawSheet(
        balance: _balance,
        banks: _banks,
        onWithdraw: (amount, bankId) async {
          Navigator.pop(context);
          try {
            await _service.withdraw(amount: amount, bankAccountId: bankId);
            _load();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Yêu cầu rút tiền đã được gửi')));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().contains('Số dư') ? 'Số dư không đủ' : 'Không thể rút tiền')));
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.chevron_left, color: Color(0xFF1A1A1A), size: 22),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text('Ví của tôi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1A)), onPressed: _load),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.secondary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.secondary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Balance card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4F5D4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Số dư ví:',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        const Text('VNĐ',
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(FormatUtils.formatPrice(_balance),
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w800)),
                            const Spacer(),
                            OutlinedButton.icon(
                              onPressed: _withdraw,
                              icon: const Icon(Icons.currency_exchange, size: 16),
                              label: const Text('Rút Tiền', style: TextStyle(fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1A1A1A),
                                side: const BorderSide(color: Color(0xFF1A1A1A)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bank accounts
                  const Text('Tài khoản ngân hàng',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),

                  ..._banks.map((b) => _BankTile(
                        bank: b,
                        onDelete: () => _deleteBank(b),
                        onSetDefault: b.isDefault
                            ? null
                            : () async {
                                await _service.setDefaultBankAccount(b.id);
                                _load();
                              },
                      )),

                  GestureDetector(
                    onTap: _addBank,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 18, color: AppTheme.textSecondary),
                          SizedBox(width: 6),
                          Text('Thêm tài khoản ngân hàng',
                              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),

                  // Recent transactions
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text('Lịch sử giao dịch',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push('/wallet/history'),
                        child: const Text('Xem tất cả',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.secondary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_recentTxs.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                        child: Text('Chưa có giao dịch nào',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ),
                    )
                  else
                    ..._recentTxs.map((tx) => _TxTile(tx: tx)),
                ],
              ),
            ),
    );
  }
}

// ---- Bank tile ----
class _BankTile extends StatelessWidget {
  final BankAccountModel bank;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;
  const _BankTile({required this.bank, required this.onDelete, this.onSetDefault});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: bank.isDefault
                ? AppTheme.secondary.withValues(alpha: 0.5)
                : const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_balance, color: AppTheme.secondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(bank.bankName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    if (bank.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Mặc định',
                            style: TextStyle(fontSize: 10, color: AppTheme.secondary)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(bank.accountNumber,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                Text(bank.accountHolder,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          if (onSetDefault != null)
            TextButton(
              onPressed: onSetDefault,
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero, minimumSize: const Size(40, 32)),
              child: const Text('Mặc định',
                  style: TextStyle(fontSize: 11, color: AppTheme.secondary)),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ---- Transaction tile ----
class _TxTile extends StatelessWidget {
  final WalletTransactionModel tx;
  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.isIncome;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: (isIncome ? AppTheme.secondary : AppTheme.primary)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              size: 18,
              color: isIncome ? AppTheme.secondary : AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.typeLabel,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if (tx.note != null)
                  Text(tx.note!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${FormatUtils.formatPrice(tx.amount)}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isIncome ? AppTheme.secondary : AppTheme.primary),
              ),
              Text(tx.statusLabel,
                  style: TextStyle(
                      fontSize: 11,
                      color: tx.status == 'Completed'
                          ? AppTheme.secondary
                          : tx.status == 'Rejected'
                              ? AppTheme.error
                              : tx.status == 'Failed'
                                  ? AppTheme.error
                                  : Colors.orange)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- Add bank sheet ----
class _AddBankSheet extends StatefulWidget {
  final void Function(String bankName, String number, String holder) onAdd;
  const _AddBankSheet({required this.onAdd});

  @override
  State<_AddBankSheet> createState() => _AddBankSheetState();
}

class _AddBankSheetState extends State<_AddBankSheet> {
  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String? _selectedBank;

  static const _banks = [
    'Vietcombank', 'BIDV', 'Agribank', 'Techcombank',
    'MB Bank', 'VPBank', 'ACB', 'Sacombank', 'TPBank', 'VietinBank',
  ];

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Thêm tài khoản ngân hàng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedBank,
                decoration: _inputDeco('Chọn ngân hàng'),
                items: _banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (v) => setState(() => _selectedBank = v),
                validator: (v) => v == null ? 'Vui lòng chọn ngân hàng' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numberCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDeco('Số tài khoản'),
                validator: (v) => v == null || v.isEmpty ? 'Nhập số tài khoản' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDeco('Tên chủ tài khoản'),
                validator: (v) => v == null || v.isEmpty ? 'Nhập tên chủ tài khoản' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.onAdd(_selectedBank!, _numberCtrl.text.trim(),
                          _nameCtrl.text.trim());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Lưu',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

// ---- Withdraw sheet ----
class _WithdrawSheet extends StatefulWidget {
  final double balance;
  final List<BankAccountModel> banks;
  final void Function(double amount, int bankId) onWithdraw;
  const _WithdrawSheet(
      {required this.balance, required this.banks, required this.onWithdraw});

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  int? _selectedBankId;

  @override
  void initState() {
    super.initState();
    final def = widget.banks.where((b) => b.isDefault).firstOrNull;
    _selectedBankId = def?.id ?? widget.banks.first.id;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Rút tiền',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Số dư: ${FormatUtils.formatPrice(widget.balance)}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDeco('Số tiền muốn rút'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Nhập số tiền';
                  final amount = double.tryParse(v.replaceAll(',', ''));
                  if (amount == null || amount <= 0) return 'Số tiền không hợp lệ';
                  if (amount > widget.balance) return 'Số dư không đủ';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedBankId,
                decoration: _inputDeco('Chọn tài khoản ngân hàng'),
                items: widget.banks
                    .map((b) => DropdownMenuItem(
                          value: b.id,
                          child: Text('${b.bankName} - ${b.accountNumber}',
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedBankId = v),
                validator: (v) => v == null ? 'Chọn tài khoản' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final amount = double.parse(
                          _amountCtrl.text.trim().replaceAll(',', ''));
                      widget.onWithdraw(amount, _selectedBankId!);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Xác nhận rút tiền',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
