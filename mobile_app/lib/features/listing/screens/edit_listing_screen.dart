import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/net_image.dart';
import '../../../features/home/services/listing_service.dart';

const _conditions = ['Mới', 'Như mới (99%)', 'Vẫn dùng tốt', 'Cũ'];

class EditListingScreen extends StatefulWidget {
  final int id;
  const EditListingScreen({super.key, required this.id});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _service = ListingService();
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _category;
  String? _condition;
  String _status = 'Active';
  int _quantity = 1;
  // existing network urls + new local paths mixed
  List<String> _imageUrls = [];   // network URLs từ server
  List<String> _newPaths = [];    // local paths mới thêm
  List<XFile> _newFiles = [];     // XFile để upload trên web
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final l = await _service.getListing(widget.id);
      setState(() {
        _titleCtrl.text = l.title;
        _priceCtrl.text = l.price.toStringAsFixed(0);
        _descCtrl.text = l.description;
        _category = l.category;
        _condition = l.condition.isNotEmpty ? l.condition : null;
        _status = l.status;
        _quantity = l.stock.clamp(1, 99);
        _imageUrls = List.from(l.imageUrls);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickMore() async {
    final total = _imageUrls.length + _newPaths.length;
    if (total >= 9) return;
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    final remaining = 9 - total;
    setState(() {
      for (final f in files.take(remaining)) {
        _newPaths.add(f.path);
        _newFiles.add(f);
      }
    });
  }

  void _removeExisting(int i) => setState(() => _imageUrls.removeAt(i));
  void _removeNew(int i) => setState(() {
    _newPaths.removeAt(i);
    if (i < _newFiles.length) _newFiles.removeAt(i);
  });

  void _changeQty(int delta) =>
      setState(() => _quantity = (_quantity + delta).clamp(1, 99));

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) { _snack('Nhập tên sản phẩm'); return; }
    if (_category == null) { _snack('Chọn loại sản phẩm'); return; }
    if (_condition == null) { _snack('Chọn tình trạng'); return; }

    setState(() => _saving = true);
    try {
      // Upload ảnh mới
      final uploaded = <String>[];
      for (int i = 0; i < _newPaths.length; i++) {
        try {
          String url;
          if (kIsWeb && i < _newFiles.length) {
            url = await _service.uploadImageXFile(_newFiles[i]);
          } else {
            url = await _service.uploadImage(_newPaths[i]);
          }
          uploaded.add(url);
        } catch (_) {}
      }
      final allUrls = [..._imageUrls, ...uploaded];

      await _service.updateListing(widget.id, {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0,
        'category': _category,
        'condition': _condition,
        'status': _status,
        'imageUrls': allUrls,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thành công'), backgroundColor: AppTheme.success));
      context.pop();
    } catch (e) {
      _snack('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa tin đăng'),
        content: const Text('Bạn có chắc muốn xóa tin này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _service.deleteListing(widget.id);
    if (!mounted) return;
    context.go('/my-listings');
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error));

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppTheme.secondary)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.close, size: 18, color: Color(0xFF1A1A1A)),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text('Chỉnh sửa sản phẩm',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 22),
            onPressed: _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Hình ảnh ----
            _Section(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hình ảnh sản phẩm',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Existing network images
                        ...List.generate(_imageUrls.length, (i) => _ImgThumb(
                          child: NetImage(
                            url: _imageUrls[i],
                            width: 80, height: 80,
                          ),
                          onRemove: () => _removeExisting(i),
                        )),
                        // New local images
                        ...List.generate(_newPaths.length, (i) => _ImgThumb(
                          child: kIsWeb
                              ? Image.network(_newPaths[i], width: 80, height: 80, fit: BoxFit.cover)
                              : Image.file(File(_newPaths[i]), width: 80, height: 80, fit: BoxFit.cover),
                          onRemove: () => _removeNew(i),
                        )),
                        // Add button
                        if (_imageUrls.length + _newPaths.length < 9)
                          GestureDetector(
                            onTap: _pickMore,
                            child: Container(
                              width: 80, height: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFDDDDDD)),
                              ),
                              child: const Icon(Icons.add_photo_alternate_outlined,
                                  size: 28, color: AppTheme.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ---- Thông tin cơ bản ----
            _Section(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông tin cơ bản',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),

                  // Tên sản phẩm
                  _fieldLabel('Tên sản phẩm'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleCtrl,
                    style: const TextStyle(fontSize: 14),
                    decoration: _inputDeco('Nhập tên sản phẩm'),
                  ),
                  const SizedBox(height: 14),

                  // Loại sản phẩm
                  _fieldLabel('Loại sản phẩm'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _category,
                        isExpanded: true,
                        hint: const Text('Chọn loại',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                        items: AppConstants.categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tình trạng — radio list
                  _fieldLabel('Tình trạng'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Column(
                      children: _conditions.map((c) {
                        final selected = _condition == c;
                        return InkWell(
                          onTap: () => setState(() => _condition = c),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            child: Row(
                              children: [
                                Container(
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
                                            decoration: const BoxDecoration(
                                                color: AppTheme.secondary, shape: BoxShape.circle),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Text(c,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                      color: const Color(0xFF1A1A1A),
                                    )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Số lượng
                  _fieldLabel('Số lượng'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _QtyBtn(icon: Icons.remove, onTap: () => _changeQty(-1)),
                      Container(
                        width: 48, height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                              horizontal: const BorderSide(color: Color(0xFFDDDDDD))),
                        ),
                        child: Text('$_quantity',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                      _QtyBtn(icon: Icons.add, onTap: () => _changeQty(1)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Giá
                  _fieldLabel('Giá (VNĐ)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 14),
                    decoration: _inputDeco('0').copyWith(
                      suffixText: 'đ',
                      suffixStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Trạng thái tin
                  _fieldLabel('Trạng thái tin'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _status,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                        items: const [
                          DropdownMenuItem(value: 'Active', child: Text('Đang bán')),
                          DropdownMenuItem(value: 'Hidden', child: Text('Ẩn tin')),
                          DropdownMenuItem(value: 'Sold', child: Text('Đã bán')),
                        ],
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ---- Mô tả chi tiết ----
            _Section(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mô tả chi tiết',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 14),
                    decoration: _inputDeco('Mô tả sản phẩm của bạn...'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ---- Bottom button ----
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        color: Colors.white,
        child: SafeArea(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Lưu Thay Đổi',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF555555)));

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.secondary, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}

// ---- Section card ----
class _Section extends StatelessWidget {
  final Widget child;
  const _Section({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
    ),
    child: child,
  );
}

// ---- Image thumbnail with remove ----
class _ImgThumb extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;
  const _ImgThumb({required this.child, required this.onRemove});
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(
        margin: const EdgeInsets.only(right: 8, top: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 80, height: 80, child: child),
        ),
      ),
      Positioned(
        top: 0, right: 2,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 20, height: 20,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            child: const Icon(Icons.close, size: 13, color: Colors.white),
          ),
        ),
      ),
    ],
  );
}

// ---- Qty button ----
class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 16, color: AppTheme.textPrimary),
    ),
  );
}
