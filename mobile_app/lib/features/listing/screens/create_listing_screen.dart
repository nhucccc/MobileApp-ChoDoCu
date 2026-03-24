import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

const _conditions = ['Mới', 'Như mới (99%)', 'Vẫn dùng tốt', 'Cũ'];

class CreateListingScreen extends StatefulWidget {
  final List<String> initialPaths;
  final List<XFile> initialXFiles;
  final XFile? initialVideoFile;
  const CreateListingScreen({
    super.key,
    this.initialPaths = const [],
    this.initialXFiles = const [],
    this.initialVideoFile,
  });

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '0');
  final _descCtrl = TextEditingController();

  String? _category;
  String? _condition;
  int _quantity = 1;
  List<String> _mediaPaths = [];
  List<XFile> _mediaFiles = [];
  XFile? _videoFile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _mediaPaths = List.from(widget.initialPaths);
    _mediaFiles = List.from(widget.initialXFiles);
    _videoFile = widget.initialVideoFile;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMore() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    final remaining = 9 - _mediaPaths.length;
    setState(() {
      for (final f in files.take(remaining)) {
        _mediaPaths.add(f.path);
        _mediaFiles.add(f);
      }
    });
  }

  void _removeMedia(int index) => setState(() {
    _mediaPaths.removeAt(index);
    if (index < _mediaFiles.length) _mediaFiles.removeAt(index);
  });

  void _changeQty(int delta) {
    setState(() => _quantity = (_quantity + delta).clamp(1, 99));
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Nhập tiêu đề sản phẩm');
      return;
    }
    if (_category == null) {
      _snack('Chọn loại sản phẩm');
      return;
    }
    if (_condition == null) {
      _snack('Chọn tình trạng sản phẩm');
      return;
    }

    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0;

    // Navigate sang màn hình shipping với data
    context.push('/listing-shipping', extra: {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'price': price,
      'category': _category,
      'condition': _condition,
      'quantity': _quantity,
      'mediaPaths': _mediaPaths,
      'mediaFiles': _mediaFiles,
      'videoFile': _videoFile,
    });
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppTheme.success : AppTheme.error,
    ));
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
            decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.chevron_left, color: Color(0xFF1A1A1A), size: 22),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text('Đăng tin',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Ảnh / video sản phẩm ----
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ảnh / video sản phẩm',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                if (_mediaPaths.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _mediaPaths.clear()),
                    child: const Icon(Icons.delete_outline,
                        size: 20, color: AppTheme.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Hàng ảnh đã chọn
            if (_mediaPaths.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _mediaPaths.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(
                                _mediaPaths[i],
                                width: 80, height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80, height: 80,
                                  color: const Color(0xFFEEEEEE),
                                  child: const Icon(Icons.broken_image,
                                      color: AppTheme.textSecondary),
                                ),
                              )
                            : Image.file(
                                File(_mediaPaths[i]),
                                width: 80, height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80, height: 80,
                                  color: const Color(0xFFEEEEEE),
                                  child: const Icon(Icons.broken_image,
                                      color: AppTheme.textSecondary),
                                ),
                              ),
                      ),
                      Positioned(
                        top: 2, right: 2,
                        child: GestureDetector(
                          onTap: () => _removeMedia(i),
                          child: Container(
                            width: 18, height: 18,
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Video đã chọn
            if (_videoFile != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.videocam, color: AppTheme.secondary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _videoFile!.name.isNotEmpty ? _videoFile!.name : 'video.mp4',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _videoFile = null),
                      child: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Nút thêm ảnh/video
            GestureDetector(
              onTap: _pickMore,
              child: Container(
                width: 80, height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library_outlined,
                        size: 22, color: AppTheme.textSecondary),
                    SizedBox(height: 2),
                    Text('Thêm ảnh /\nvideo',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ---- Chọn loại sản phẩm ----
            _label('Chọn loại sản phẩm'),
            const SizedBox(height: 8),
            _CategoryDropdown(
              value: _category,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 16),

            // ---- Tiêu đề sản phẩm ----
            _label('Tiêu đề sản phẩm'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 14),
              decoration: _inputDeco('Thêm tiêu đề'),
            ),
            const SizedBox(height: 16),

            // ---- Tình trạng sản phẩm ----
            _label('Tình trạng sản phẩm'),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3.5,
              children: _conditions.map((c) => _ConditionChip(
                label: c,
                selected: _condition == c,
                onTap: () => setState(() => _condition = _condition == c ? null : c),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // ---- Số lượng ----
            Row(
              children: [
                const Text('Số lượng',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                _QtyBtn(icon: Icons.remove, onTap: () => _changeQty(-1)),
                Container(
                  width: 40, height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                        horizontal: const BorderSide(color: Color(0xFFDDDDDD))),
                  ),
                  child: Text('$_quantity',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                _QtyBtn(icon: Icons.add, onTap: () => _changeQty(1)),
              ],
            ),
            const SizedBox(height: 16),

            // ---- Giá sản phẩm ----
            _label('Giá sản phẩm'),
            const SizedBox(height: 8),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 14),
              decoration: _inputDeco('').copyWith(
                suffixText: 'đ',
                suffixStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
            ),
            const SizedBox(height: 16),

            // ---- Mô tả chi tiết ----
            _label('Mô tả chi tiết'),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 5,
              style: const TextStyle(fontSize: 14),
              decoration: _inputDeco('Thêm mô tả'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Tiếp tục'),          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppTheme.secondary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}

// ---- Category dropdown ----
class _CategoryDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  const _CategoryDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: const Text('Chọn danh mục',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          items: AppConstants.categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ---- Condition chip ----
class _ConditionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ConditionChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.secondary.withValues(alpha: 0.1) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.secondary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? AppTheme.secondary : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ---- Qty button ----
class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: AppTheme.textPrimary),
      ),
    );
  }
}
