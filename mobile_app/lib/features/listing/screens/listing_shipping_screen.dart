import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../models/address_model.dart';
import '../../home/services/listing_service.dart';

enum _ShippingPayer { seller, buyer, free }

class ListingShippingScreen extends StatefulWidget {
  final double price;
  final Map<String, dynamic> listingData;
  const ListingShippingScreen({
    super.key,
    required this.price,
    required this.listingData,
  });

  @override
  State<ListingShippingScreen> createState() => _ListingShippingScreenState();
}

class _ListingShippingScreenState extends State<ListingShippingScreen> {
  _ShippingPayer _payer = _ShippingPayer.seller;
  bool _agreed = false;
  AddressModel? _selectedAddress;
  bool _submitting = false;
  final _service = ListingService();

  static const double _platformFeeRate = 0.05;

  double get _platformFee => widget.price * _platformFeeRate;
  double get _sellerReceives => widget.price - _platformFee;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn địa chỉ bán hàng'), backgroundColor: AppTheme.error),
      );
      return;
    }
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đồng ý điều khoản'), backgroundColor: AppTheme.error),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final data = widget.listingData;
      final paths = (data['mediaPaths'] as List?)?.cast<String>() ?? [];
      final xfiles = (data['mediaFiles'] as List?)?.cast<XFile>() ?? [];
      final videoFile = data['videoFile'] as XFile?;

      // Upload ảnh
      final imageUrls = <String>[];
      for (int i = 0; i < paths.length; i++) {
        try {
          String url;
          if (kIsWeb && i < xfiles.length) {
            url = await _service.uploadImageXFile(xfiles[i]);
          } else {
            url = await _service.uploadImage(paths[i]);
          }
          imageUrls.add(url);
        } catch (_) {}
      }

      // Upload video nếu có
      String? videoUrl;
      if (videoFile != null) {
        try {
          final result = await _service.uploadVideo(videoFile);
          videoUrl = result['url'];
        } catch (_) {}
      }

      final listing = await _service.createListing(
        title: data['title'] as String,
        description: data['description'] as String? ?? '',
        price: (data['price'] as num).toDouble(),
        category: data['category'] as String,
        condition: data['condition'] as String? ?? '',
        imageUrls: imageUrls,
        stock: (data['quantity'] as int?) ?? 1,
        location: _selectedAddress?.city,
        videoUrl: videoUrl,
      );
      if (!mounted) return;
      context.go('/listing-success?id=${listing.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.chevron_left, color: Color(0xFF1A1A1A), size: 22),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text('Đăng tin',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Địa điểm bán ----
            _sectionTitle('Địa điểm bán'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final result = await context.push<AddressModel>('/address');
                if (result != null) {
                  setState(() => _selectedAddress = result);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedAddress == null
                        ? const Color(0xFFDDDDDD)
                        : AppTheme.secondary,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: _selectedAddress == null
                          ? AppTheme.textSecondary
                          : AppTheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _selectedAddress == null
                          ? const Text(
                              'Chọn địa chỉ bán hàng',
                              style: TextStyle(
                                  fontSize: 14, color: AppTheme.textSecondary),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_selectedAddress!.fullName} · ${_selectedAddress!.phoneNumber}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedAddress!.fullAddress,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ---- Phí vận chuyển ----
            _sectionTitle('Phí vận chuyển'),
            const SizedBox(height: 12),
            _RadioOption(
              label: 'Người bán trả',
              value: _ShippingPayer.seller,
              groupValue: _payer,
              onChanged: (v) => setState(() => _payer = v),
            ),
            const SizedBox(height: 10),
            _RadioOption(
              label: 'Người mua trả',
              value: _ShippingPayer.buyer,
              groupValue: _payer,
              onChanged: (v) => setState(() => _payer = v),
            ),
            const SizedBox(height: 10),
            _RadioOption(
              label: 'Miễn phí ship',
              value: _ShippingPayer.free,
              groupValue: _payer,
              onChanged: (v) => setState(() => _payer = v),
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFEEEEEE)),
            const SizedBox(height: 16),

            // ---- Tóm tắt giá ----
            _PriceSummaryRow(
              label: 'Giá bán',
              value: FormatUtils.formatPrice(widget.price),
              bold: false,
            ),
            const SizedBox(height: 8),
            _PriceSummaryRow(
              label: 'Phí nền tảng (5%)',
              value: FormatUtils.formatPrice(_platformFee),
              bold: false,
            ),
            const SizedBox(height: 12),
            _PriceSummaryRow(
              label: 'Người bán nhận',
              value: FormatUtils.formatPrice(_sellerReceives),
              bold: true,
            ),
            const SizedBox(height: 16),

            // ---- Checkbox đồng ý ----
            Row(
              children: [
                SizedBox(
                  width: 22, height: 22,
                  child: Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    activeColor: AppTheme.secondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    side: const BorderSide(color: Color(0xFFBBBBBB), width: 1.5),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Tôi đồng ý lưu chọn',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
      ),

      // ---- Bottom buttons ----
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: const BoxDecoration(
          color: AppTheme.secondary,
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Hủy bỏ
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Hủy bỏ',
                      style: TextStyle(color: AppTheme.textPrimary)),
                ),
              ),
              const SizedBox(width: 12),
              // Tiếp tục
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    backgroundColor: const Color(0xFF66BB6A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Tiếp tục'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A)),
      );
}

// ---- Radio option ----
class _RadioOption extends StatelessWidget {
  final String label;
  final _ShippingPayer value;
  final _ShippingPayer groupValue;
  final ValueChanged<_ShippingPayer> onChanged;

  const _RadioOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Container(
            width: 22, height: 22,
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
                      width: 10, height: 10,
                      decoration: const BoxDecoration(
                          color: AppTheme.secondary, shape: BoxShape.circle),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: const Color(0xFF1A1A1A),
              )),
        ],
      ),
    );
  }
}

// ---- Price summary row ----
class _PriceSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _PriceSummaryRow({
    required this.label,
    required this.value,
    required this.bold,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold ? const Color(0xFF1A1A1A) : AppTheme.textSecondary,
            )),
        Text(value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold ? const Color(0xFF1A1A1A) : AppTheme.textSecondary,
            )),
      ],
    );
  }
}
