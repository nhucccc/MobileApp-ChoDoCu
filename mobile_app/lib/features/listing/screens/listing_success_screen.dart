import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class ListingSuccessScreen extends StatelessWidget {
  final int? listingId;
  const ListingSuccessScreen({super.key, this.listingId});

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
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // ---- Banner congratulations ----
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _CongratsBanner(),
            ),

            // ---- Check icon ----
            Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppTheme.secondary, size: 30),
              ),
            ),

            // ---- Text ----
            const SizedBox(height: 4),
            const Text(
              'Thành công',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bạn đăng tin thành công',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tin của bạn vừa được hiển thị.\nChúng tôi sẽ thông báo cho bạn\nnếu có bất cứ vấn đề gì xảy ra.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppTheme.textSecondary),
            ),

            const Spacer(),

            // ---- Buttons ----
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Row(
                children: [
                  // Xem tin
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (listingId != null) {
                          context.go('/listing/$listingId');
                        } else {
                          context.go('/');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Xem tin',
                          style: TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Về trang chủ
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.go('/'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        backgroundColor: AppTheme.secondary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Về trang chủ',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Banner vẽ bằng CustomPaint (không cần asset) ----
class _CongratsBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
        ),
      ),
      child: Stack(
        children: [
          // Stars / confetti
          ..._buildStars(),
          // Balloons left
          Positioned(
            left: 20, top: 10,
            child: _BalloonGroup(colors: const [
              Colors.red, Colors.orange, Colors.purple, Colors.green
            ]),
          ),
          // Balloons right
          Positioned(
            right: 20, top: 10,
            child: _BalloonGroup(colors: const [
              Colors.yellow, Colors.teal, Colors.pink, Colors.orange
            ]),
          ),
          // Banner text
          Center(
            child: Transform.rotate(
              angle: -0.05,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                  ],
                ),
                child: const Text(
                  'CONGRATULATIONS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.red,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStars() {
    final positions = [
      [0.1, 0.2], [0.3, 0.7], [0.5, 0.15], [0.7, 0.6],
      [0.85, 0.25], [0.15, 0.8], [0.6, 0.85], [0.9, 0.7],
    ];
    final colors = [Colors.yellow, Colors.red, Colors.green, Colors.pink,
        Colors.orange, Colors.cyan, Colors.lime, Colors.purple];
    return List.generate(positions.length, (i) {
      return Positioned(
        left: positions[i][0] * 300,
        top: positions[i][1] * 180,
        child: Icon(Icons.star, size: 12, color: colors[i % colors.length]),
      );
    });
  }
}

class _BalloonGroup extends StatelessWidget {
  final List<Color> colors;
  const _BalloonGroup({required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80, height: 120,
      child: Stack(
        children: [
          // Strings
          ...List.generate(colors.length, (i) => Positioned(
            left: 10.0 + i * 16,
            top: 40,
            child: Container(
              width: 1, height: 60,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          )),
          // Balloons
          ...List.generate(colors.length, (i) => Positioned(
            left: 4.0 + i * 16,
            top: i.isEven ? 0 : 10,
            child: _Balloon(color: colors[i]),
          )),
        ],
      ),
    );
  }
}

class _Balloon extends StatelessWidget {
  final Color color;
  const _Balloon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22, height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(11),
              topRight: Radius.circular(11),
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
        ),
        Container(
          width: 4, height: 4,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }
}
