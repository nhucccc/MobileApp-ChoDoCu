import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/address_model.dart';
import '../services/address_service.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _service = AddressService();
  List<AddressModel> _addresses = [];
  bool _loading = true;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _service.getAll();
      setState(() {
        _addresses = list;
        _selectedId = list.firstWhere((a) => a.isDefault, orElse: () => list.isNotEmpty ? list.first : AddressModel(id: -1, fullName: '', phoneNumber: '', street: '', district: '', city: '', isDefault: false)).id;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _select(AddressModel addr) {
    setState(() => _selectedId = addr.id);
    context.pop(addr);
  }

  Future<void> _delete(AddressModel addr) async {
    try {
      await _service.delete(addr.id);
      setState(() => _addresses.removeWhere((a) => a.id == addr.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _addAddress() async {
    final result = await context.push<AddressModel>('/add-address');
    if (result == null) return;
    setState(() {
      if (result.isDefault) {
        _addresses = _addresses.map((a) => AddressModel(
          id: a.id, fullName: a.fullName, phoneNumber: a.phoneNumber,
          street: a.street, district: a.district, city: a.city, isDefault: false,
        )).toList();
      }
      _addresses.add(result);
      if (result.isDefault) _selectedId = result.id;
    });
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
        title: const Text('Địa chỉ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.secondary))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Địa chỉ của bạn',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 12),
                        if (_addresses.isEmpty)
                          const Text('Chưa có địa chỉ nào',
                              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))
                        else
                          ..._addresses.map((addr) => _AddressItem(
                                address: addr,
                                selected: addr.id == _selectedId,
                                onTap: () => _select(addr),
                                onDelete: _addresses.length > 1 ? () => _delete(addr) : null,
                              )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _addAddress,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: const Text('Thêm địa chỉ',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AddressItem extends StatelessWidget {
  final AddressModel address;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _AddressItem({
    required this.address,
    required this.selected,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppTheme.secondary : const Color(0xFFBBBBBB),
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 9, height: 9,
                          decoration: const BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address.fullName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 2),
                  Text(address.phoneNumber,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 2),
                  Text(address.fullAddress,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  if (address.isDefault)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Mặc định',
                          style: TextStyle(fontSize: 11, color: AppTheme.secondary, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.delete_outline, size: 18, color: AppTheme.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
