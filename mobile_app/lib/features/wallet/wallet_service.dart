import '../../core/network/api_client.dart';

class BankAccountModel {
  final int id;
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final bool isDefault;

  BankAccountModel({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    required this.isDefault,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> j) => BankAccountModel(
        id: j['id'],
        bankName: j['bankName'],
        accountNumber: j['accountNumber'],
        accountHolder: j['accountHolder'],
        isDefault: j['isDefault'] ?? false,
      );
}

class WalletTransactionModel {
  final int id;
  final double amount;
  final String type;
  final String status;
  final String? note;
  final int? relatedOrderId;
  final DateTime createdAt;

  WalletTransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.status,
    this.note,
    this.relatedOrderId,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> j) =>
      WalletTransactionModel(
        id: j['id'],
        amount: (j['amount'] as num).toDouble(),
        type: j['type'],
        status: j['status'],
        note: j['note'],
        relatedOrderId: j['relatedOrderId'],
        createdAt: DateTime.parse(j['createdAt']).toUtc(),
      );

  String get typeLabel {
    switch (type) {
      case 'OrderIncome': return 'Thu nhập đơn hàng';
      case 'Withdrawal': return 'Rút tiền';
      case 'Refund': return 'Hoàn tiền';
      case 'Deposit': return 'Nạp tiền';
      default: return type;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'Completed': return 'Thành công';
      case 'Pending': return 'Đang xử lý';
      case 'Failed': return 'Thất bại';
      case 'Rejected': return 'Bị từ chối';
      default: return status;
    }
  }

  bool get isIncome => type == 'OrderIncome' || type == 'Refund' || type == 'Deposit';
}

class WalletService {
  final _api = ApiClient();

  Future<double> getBalance() async {
    final res = await _api.dio.get('/wallet/balance');
    return (res.data['balance'] as num).toDouble();
  }

  Future<List<WalletTransactionModel>> getTransactions() async {
    final res = await _api.dio.get('/wallet/transactions');
    return (res.data as List)
        .map((j) => WalletTransactionModel.fromJson(j))
        .toList();
  }

  Future<List<BankAccountModel>> getBankAccounts() async {
    final res = await _api.dio.get('/wallet/bank-accounts');
    return (res.data as List)
        .map((j) => BankAccountModel.fromJson(j))
        .toList();
  }

  Future<BankAccountModel> addBankAccount({
    required String bankName,
    required String accountNumber,
    required String accountHolder,
  }) async {
    final res = await _api.dio.post('/wallet/bank-accounts', data: {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolder': accountHolder,
    });
    return BankAccountModel.fromJson(res.data);
  }

  Future<void> deleteBankAccount(int id) async {
    await _api.dio.delete('/wallet/bank-accounts/$id');
  }

  Future<void> setDefaultBankAccount(int id) async {
    await _api.dio.patch('/wallet/bank-accounts/$id/set-default');
  }

  Future<WalletTransactionModel> withdraw({
    required double amount,
    required int bankAccountId,
  }) async {
    final res = await _api.dio.post('/wallet/withdraw', data: {
      'amount': amount,
      'bankAccountId': bankAccountId,
    });
    return WalletTransactionModel.fromJson(res.data);
  }
}
