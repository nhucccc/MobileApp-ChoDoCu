import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/home/services/listing_service.dart';
import '../../../features/home/widgets/listing_card.dart';
import '../../../models/listing_model.dart';

class PartnerProfileScreen extends StatefulWidget {
  final int userId;
  const PartnerProfileScreen({super.key, required this.userId});
  @override
  State<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends State<PartnerProfileScreen> {
  final _service = ListingService();
  bool _loading = true;
  _PartnerData? _data;
  List<ListingModel> _listings = [];
  bool _showAll = false;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final items = await _service.getUserListings(widget.userId);
      _PartnerData data;
      if (items.isNotEmpty) {
        final s = items.first.seller;
        data = _PartnerData(name: s.fullName, avatarUrl: s.avatarUrl, rating: s.rating, ratingCount: s.ratingCount, totalListings: items.length, soldCount: 0, joinYear: 2025);
      } else {
        data = _PartnerData(name: 'Nguoi dung', avatarUrl: null, rating: 0, ratingCount: 0, totalListings: 0, soldCount: 0, joinYear: 2025);
      }
      setState(() { _data = data; _listings = items; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.secondary)));
    final d = _data ?? _PartnerData(name: 'Nguoi dung', avatarUrl: null, rating: 0, ratingCount: 0, totalListings: 0, soldCount: 0, joinYear: 2025);
    final displayListings = _showAll ? _listings : _listings.take(4).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Stack(clipBehavior: Clip.none, children: [
          Container(height: 160,
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4DD0E1), Color(0xFF26C6DA)])),
            child: Stack(children: [
              Positioned(right: 20, top: 20, child: _Cloud(size: 80)),
              Positioned(right: 80, top: 10, child: _Cloud(size: 50)),
              Positioned(left: 30, top: 30, child: _Cloud(size: 60)),
              Positioned(top: 44, left: 12, child: SafeArea(child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(width: 36, height: 36,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
                  child: const Icon(Icons.chevron_left, color: Color(0xFF1A1A1A), size: 22))))),
            ])),
          Positioned(bottom: -40, left: 16, child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
            child: CircleAvatar(radius: 40, backgroundColor: const Color(0xFFE0E0E0),
              backgroundImage: d.avatarUrl != null ? CachedNetworkImageProvider(d.avatarUrl!) : null,
              child: d.avatarUrl == null ? Text(d.name[0].toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)) : null))),
          const SizedBox(height: 200),
        ])),
        SliverToBoxAdapter(child: Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(16, 48, 16, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.person_outline, size: 16, color: AppTheme.textSecondary), const SizedBox(width: 4), Text(d.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))]),
          const SizedBox(height: 4),
          Text('${d.totalListings} san pham  -  ${d.soldCount} da ban', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _InfoChip(icon: Icons.calendar_today_outlined, label: 'Tham gia ${d.joinYear}'),
            _InfoChip(icon: Icons.reply_outlined, label: 'Phan hoi nhanh'),
            _InfoChip(icon: Icons.local_shipping_outlined, label: 'Gui nhanh'),
            _InfoChip(icon: Icons.star_outline, label: '${d.rating.toStringAsFixed(1)} star', highlight: d.rating > 0),
          ]),
        ]))),
        SliverToBoxAdapter(child: Container(margin: const EdgeInsets.only(top: 8), color: Colors.white,
          child: InkWell(onTap: () => setState(() => _showAll = !_showAll),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(child: Text('Xem tat ca san pham (${d.totalListings})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))))))),
        if (displayListings.isNotEmpty)
          SliverPadding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((_, i) => ListingCard(listing: displayListings[i]), childCount: displayListings.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.68))),
        SliverToBoxAdapter(child: Container(margin: const EdgeInsets.only(top: 8), color: Colors.white, padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Danh gia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
            Row(children: List.generate(5, (i) => Icon(Icons.star, size: 20, color: i < d.rating.floor() ? Colors.amber : const Color(0xFFDDDDDD)))),
            const SizedBox(width: 8),
            Text('(${d.rating.toStringAsFixed(1)})', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const Spacer(),
            Text('Tong cong: ${d.ratingCount}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ]),
          const SizedBox(height: 12),
          ...List.generate(5, (i) { final star = 5 - i; return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
            SizedBox(width: 40, child: Text('$star sao', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
            const SizedBox(width: 8),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: const LinearProgressIndicator(value: 0, minHeight: 6, backgroundColor: Color(0xFFEEEEEE), valueColor: AlwaysStoppedAnimation(Colors.amber)))),
            const SizedBox(width: 8),
            const Text('(0)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ])); }),
        ]))),
        SliverToBoxAdapter(child: Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(children: [
            const Text('Danh gia', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(10)),
              child: Text('${d.ratingCount}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
          ]),
        )),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ]),
    );
  }
}

class _PartnerData {
  final String name; final String? avatarUrl; final double rating;
  final int ratingCount; final int totalListings; final int soldCount; final int joinYear;
  _PartnerData({required this.name, required this.avatarUrl, required this.rating, required this.ratingCount, required this.totalListings, required this.soldCount, required this.joinYear});
}

class _InfoChip extends StatelessWidget {
  final IconData icon; final String label; final bool highlight;
  const _InfoChip({required this.icon, required this.label, this.highlight = false});
  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, size: 20, color: highlight ? Colors.amber : AppTheme.textSecondary),
    const SizedBox(height: 4),
    Text(label, style: TextStyle(fontSize: 10, color: highlight ? Colors.amber : AppTheme.textSecondary)),
  ]);
}

class _Cloud extends StatelessWidget {
  final double size;
  const _Cloud({required this.size});
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(size, size * 0.6), painter: _CloudPainter());
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final w = size.width; final h = size.height;
    final path = Path()
      ..addOval(Rect.fromCenter(center: Offset(w * 0.3, h * 0.6), width: w * 0.5, height: h * 0.7))
      ..addOval(Rect.fromCenter(center: Offset(w * 0.55, h * 0.5), width: w * 0.55, height: h * 0.8))
      ..addOval(Rect.fromCenter(center: Offset(w * 0.75, h * 0.65), width: w * 0.4, height: h * 0.6))
      ..addRect(Rect.fromLTRB(w * 0.1, h * 0.6, w * 0.9, h));
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_) => false;
}
