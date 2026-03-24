import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

// ---- Model kết quả filter ----
class FilterResult {
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final String? condition;
  final String? location;
  final String? sortBy; // newest, oldest, price_asc, price_desc

  const FilterResult({
    this.category,
    this.minPrice,
    this.maxPrice,
    this.condition,
    this.location,
    this.sortBy,
  });
}

// ---- Hàm mở filter sheet ----
Future<FilterResult?> showFilterSheet(
  BuildContext context, {
  FilterResult? initial,
}) {
  return showModalBottomSheet<FilterResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FilterSheet(initial: initial),
  );
}

const _conditions = ['Mới', 'Như mới (99%)', 'Vẫn dùng tốt', 'Cũ'];

const _sortOptions = [
  _SortOpt('Mới nhất', 'newest', Icons.fiber_new_outlined),
  _SortOpt('Cũ nhất', 'oldest', Icons.history_outlined),
  _SortOpt('Giá thấp nhất', 'price_asc', Icons.arrow_upward),
  _SortOpt('Giá cao nhất', 'price_desc', Icons.arrow_downward),
];

class _SortOpt {
  final String label;
  final String value;
  final IconData icon;
  const _SortOpt(this.label, this.value, this.icon);
}

const _locations = [
  'Hà Nội', 'TP. Hồ Chí Minh', 'Đà Nẵng', 'Hải Phòng', 'Cần Thơ',
  'An Giang', 'Bắc Giang', 'Bắc Ninh', 'Bình Dương', 'Đồng Nai',
  'Khánh Hòa', 'Lâm Đồng', 'Long An', 'Nghệ An', 'Thanh Hóa', 'Toàn quốc',
];

class _FilterSheet extends StatefulWidget {
  final FilterResult? initial;
  const _FilterSheet({this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _category;
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  String? _condition;
  String? _location;
  String? _sortBy;
  bool _showAllCategories = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _category = init.category;
      _condition = init.condition;
      _location = init.location;
      _sortBy = init.sortBy;
      if (init.minPrice != null) _minCtrl.text = init.minPrice!.toStringAsFixed(0);
      if (init.maxPrice != null) _maxCtrl.text = init.maxPrice!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _category = null;
      _condition = null;
      _location = null;
      _sortBy = null;
      _minCtrl.clear();
      _maxCtrl.clear();
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      FilterResult(
        category: _category,
        minPrice: double.tryParse(_minCtrl.text.replaceAll(',', '')),
        maxPrice: double.tryParse(_maxCtrl.text.replaceAll(',', '')),
        condition: _condition,
        location: _location,
        sortBy: _sortBy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = _showAllCategories
        ? AppConstants.categories
        : AppConstants.categories.take(6).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
                    child: const Icon(Icons.chevron_left, color: Color(0xFF1A1A1A), size: 22),
                  ),
                ),
                const Expanded(
                  child: Text('Bộ lọc',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Sắp xếp theo ----
                  _sectionTitle('Sắp xếp theo'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3.2,
                    children: _sortOptions.map((s) => _SelectChip(
                      label: s.label,
                      icon: s.icon,
                      selected: _sortBy == s.value,
                      onTap: () => setState(() => _sortBy = _sortBy == s.value ? null : s.value),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 16),

                  // ---- Danh mục ----
                  _sectionTitle('Danh mục sản phẩm'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3.2,
                    children: cats.map((c) => _SelectChip(
                      label: c,
                      selected: _category == c,
                      onTap: () => setState(() => _category = _category == c ? null : c),
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(() => _showAllCategories = !_showAllCategories),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showAllCategories ? 'Thu gọn' : 'Xem thêm',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showAllCategories ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 18, color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 16),

                  // ---- Khoảng giá ----
                  _sectionTitle('Khoảng giá'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _PriceField(controller: _minCtrl, hint: 'Thấp nhất')),
                      const SizedBox(width: 12),
                      Expanded(child: _PriceField(controller: _maxCtrl, hint: 'Cao nhất')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 16),

                  // ---- Tình trạng ----
                  _sectionTitle('Tình trạng sản phẩm'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3.2,
                    children: _conditions.map((c) => _SelectChip(
                      label: c,
                      selected: _condition == c,
                      onTap: () => setState(() => _condition = _condition == c ? null : c),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 16),

                  // ---- Khu vực ----
                  _sectionTitle('Khu vực'),
                  const SizedBox(height: 12),
                  _LocationDropdown(
                    value: _location,
                    onChanged: (v) => setState(() => _location = v),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reset'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        foregroundColor: AppTheme.secondary,
                        side: const BorderSide(color: AppTheme.secondary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _apply,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        backgroundColor: AppTheme.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
  );
}

// ---- Chip chọn ----
class _SelectChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  const _SelectChip({required this.label, this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.secondary.withValues(alpha: 0.12) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.secondary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14,
                  color: selected ? AppTheme.secondary : AppTheme.textSecondary),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? AppTheme.secondary : AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Price field ----
class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _PriceField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.secondary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ---- Location dropdown ----
class _LocationDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  const _LocationDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: const Text('Chọn khu vực', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          items: _locations.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
