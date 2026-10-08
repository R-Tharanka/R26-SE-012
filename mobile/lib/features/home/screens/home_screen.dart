import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../berry_disease/berry_scanner_screen.dart';
import '../../grading_forecast/screens/berry_capture_screen.dart';
import '../../grading_forecast/screens/grading_forecast_home_screen.dart';
import '../../plant_health/screens/plant_health_scanner_screen.dart';
import '../../recommendations/analysis_ui.dart' show FadeSlideIn;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // ------------------------------------------------------------
  // Navigation
  // ------------------------------------------------------------

  void _navigateToQualityAndPrice() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const GradingForecastHomeScreen(),
      ),
    );
  }

  void _navigateToPlantHealth() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PlantHealthScannerScreen(),
      ),
    );
  }

  void _navigateToBerryDisease() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const BerryScannerScreen(),
      ),
    );
  }

  void _navigateToCapture() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const BerryCaptureScreen(),
      ),
    );
  }

  // ------------------------------------------------------------
  // Feature Information
  // ------------------------------------------------------------

  void _showFeatureInfo(
    String title,
    String category,
    String description,
    VoidCallback onStart,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D6A4F),
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1C1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF49454F),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onStart();
                },
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Start Crop Scan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4332),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // Help
  // ------------------------------------------------------------

  void _showHelpDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.help_outline,
              color: Color(0xFF1B4332),
            ),
            SizedBox(width: 8),
            Text('PepperCare Help'),
          ],
        ),
        content: const Text(
          'PepperCare helps you monitor your black pepper crops.\n\n'
          '• Check Your Crop: Detect pests, leaf diseases, berry diseases, '
          'and check quality & market price forecasts.\n'
          '• Take Photo: Capture pepper berries or leaves to instantly '
          'analyze quality and get AI decision support.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Build
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF9F9F6);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AppLogo(size: 30),
            SizedBox(width: 10),
            Text('PepperCare'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDarkMode ? 'Light mode' : 'Dark mode',
            icon: Icon(
              isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              setState(() {
                toggleTheme();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  140,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopHeader(),

                    const SizedBox(height: 20),

                    _buildFarmStatusCard(),

                    const SizedBox(height: 28),

                    const Text(
                      'Check Your Crop',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1E),
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildCropCheckGrid(),

                    const SizedBox(height: 28),

                    _buildRecentResultsHeader(),

                    const SizedBox(height: 14),

                    _buildRecentResultCard(
                      badgeText: 'HEALTHY',
                      badgeBgColor: const Color(0xFFD8F3DC),
                      badgeTextColor: const Color(0xFF1B4332),
                      timeText: '2 hours ago',
                      title: 'Main Plot A',
                      subtitle:
                          'No signs of root wilt or pests...',
                      thumbnail:
                          const _PepperClusterThumbnail(),
                    ),

                    const SizedBox(height: 12),

                    _buildRecentResultCard(
                      badgeText: 'WARNING',
                      badgeBgColor: const Color(0xFFFDE2E4),
                      badgeTextColor: const Color(0xFFB91C1C),
                      timeText: 'Yesterday',
                      title: 'North Slope',
                      subtitle:
                          'Possible early leaf gall thrips...',
                      thumbnail:
                          const _SpottedLeafThumbnail(),
                    ),
                  ],
                ),
              ),
            ),

            // --------------------------------------------------
            // Bottom Actions
            // --------------------------------------------------

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Center(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _navigateToCapture,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF1B4332),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: Colors.black38,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(26),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Take Photo',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  Container(
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F4F0),
                      border: Border(
                        top: BorderSide(
                          color: Color(0xFFE5E5E0),
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          index: 0,
                          icon: Icons.home_rounded,
                          label: 'Home',
                        ),
                        _buildNavItem(
                          index: 1,
                          icon: Icons.camera_alt_outlined,
                          label: 'Capture',
                          onTapOverride: _navigateToCapture,
                        ),
                        _buildNavItem(
                          index: 2,
                          icon: Icons.history_rounded,
                          label: 'History',
                        ),
                      ],
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

  // ------------------------------------------------------------
  // Header
  // ------------------------------------------------------------

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            _AppLogo(size: 34),
            SizedBox(width: 8),
            Text(
              'PepperCare',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4332),
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: _showHelpDialog,
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF2D6A4F),
                width: 1.8,
              ),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: Color(0xFF1B4332),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // Farm Status
  // ------------------------------------------------------------

  Widget _buildFarmStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFE6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FARM STATUS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7C6255),
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  'Mostly\nHealthy',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C1C1E),
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Text(
                '85%',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E6B39),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text(
            '3 plots checked today.\nOverall vitality is high.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF555555),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Crop Feature Grid
  // ------------------------------------------------------------

  Widget _buildCropCheckGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.15,
      children: [
        FadeSlideIn(
          delayMs: 0,
          child: _buildCropCard(
            icon: Icons.bug_report_outlined,
            iconBgColor: const Color(0xFFFDE8E1),
            iconColor: const Color(0xFFE07A5F),
            title: 'Pests',
            onTap: () => _showFeatureInfo(
              'Pest Detection',
              'PLANT HEALTH',
              'Detect pests on pepper leaves, stems, and berries '
                  'using AI-powered analysis and provide treatment '
                  'recommendations.',
              _navigateToPlantHealth,
            ),
          ),
        ),

        FadeSlideIn(
          delayMs: 90,
          child: _buildCropCard(
            icon: Icons.health_and_safety,
            iconBgColor: const Color(0xFFDCF8DB),
            iconColor: const Color(0xFF2B9348),
            title: 'Leaf Health',
            onTap: () => _showFeatureInfo(
              'Leaf Health & Severity',
              'PLANT HEALTH',
              'Analyze pepper leaves for diseases and determine '
                  'disease severity using AI-based image analysis.',
              _navigateToPlantHealth,
            ),
          ),
        ),

        FadeSlideIn(
          delayMs: 180,
          child: _buildCropCard(
            icon: Icons.coronavirus_outlined,
            iconBgColor: const Color(0xFFFCE4EC),
            iconColor: const Color(0xFFC24176),
            title: 'Berry Disease',
            onTap: () => _showFeatureInfo(
              'Berry Disease',
              'BERRY ANALYSIS',
              'Scan pepper berries to identify diseases and '
                  'analyze affected areas for appropriate '
                  'remediation.',
              _navigateToBerryDisease,
            ),
          ),
        ),

        FadeSlideIn(
          delayMs: 270,
          child: _buildCropCard(
            icon: Icons.trending_up,
            iconBgColor: const Color(0xFFFFF0D9),
            iconColor: const Color(0xFFF39C12),
            title: 'Quality &\nPrice',
            onTap: _navigateToQualityAndPrice,
          ),
        ),
      ],
    );
  }

  Widget _buildCropCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 26,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E),
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // Recent Results
  // ------------------------------------------------------------

  Widget _buildRecentResultsHeader() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Results',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1E),
            letterSpacing: -0.3,
          ),
        ),
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('History page loading...'),
              ),
            );
          },
          child: const Text(
            'View All',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B9348),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentResultCard({
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required String timeText,
    required String title,
    required String subtitle,
    required Widget thumbnail,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 72,
              height: 72,
              child: thumbnail,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius:
                            BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeTextColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      timeText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6E6E73),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Bottom Navigation
  // ------------------------------------------------------------

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    VoidCallback? onTapOverride,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        if (onTapOverride != null) {
          onTapOverride();
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: isSelected
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4332),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF8E8E93),
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.agriculture_rounded,
          color: const Color(0xFF1B4332),
          size: size,
        ),
      ),
    );
  }
}

// ================================================================
// Pepper Cluster Thumbnail
// ================================================================

class _PepperClusterThumbnail extends StatelessWidget {
  const _PepperClusterThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF386641),
      child: CustomPaint(
        painter: _PepperClusterPainter(),
      ),
    );
  }
}

class _PepperClusterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = const Color(0xFF6A994E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final berryPaint = Paint()
      ..color = const Color(0xFF4C9A2A)
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = const Color(0xFFA7C957)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(
        size.width * 0.3,
        size.height * 0.1,
      )
      ..cubicTo(
        size.width * 0.4,
        size.height * 0.4,
        size.width * 0.5,
        size.height * 0.7,
        size.width * 0.6,
        size.height * 0.9,
      );

    canvas.drawPath(path, stemPaint);

    final berryPositions = [
      Offset(size.width * 0.35, size.height * 0.25),
      Offset(size.width * 0.45, size.height * 0.3),
      Offset(size.width * 0.38, size.height * 0.4),
      Offset(size.width * 0.52, size.height * 0.45),
      Offset(size.width * 0.42, size.height * 0.55),
      Offset(size.width * 0.56, size.height * 0.6),
      Offset(size.width * 0.48, size.height * 0.7),
      Offset(size.width * 0.58, size.height * 0.78),
    ];

    for (final pos in berryPositions) {
      canvas.drawCircle(
        pos,
        6,
        berryPaint,
      );

      canvas.drawCircle(
        pos + const Offset(-1.5, -1.5),
        2,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// ================================================================
// Spotted Leaf Thumbnail
// ================================================================

class _SpottedLeafThumbnail extends StatelessWidget {
  const _SpottedLeafThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1B4332),
      child: CustomPaint(
        painter: _SpottedLeafPainter(),
      ),
    );
  }
}

class _SpottedLeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leafPaint = Paint()
      ..color = const Color(0xFF2B9348)
      ..style = PaintingStyle.fill;

    final spotPaint = Paint()
      ..color = const Color(0xFFFFD166)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(
        size.width * 0.5,
        size.height * 0.15,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.4,
        size.width * 0.6,
        size.height * 0.85,
      )
      ..quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.4,
        size.width * 0.5,
        size.height * 0.15,
      );

    canvas.drawPath(path, leafPaint);

    canvas.drawCircle(
      Offset(
        size.width * 0.4,
        size.height * 0.4,
      ),
      4.5,
      spotPaint,
    );

    canvas.drawCircle(
      Offset(
        size.width * 0.55,
        size.height * 0.5,
      ),
      3.5,
      spotPaint,
    );

    canvas.drawCircle(
      Offset(
        size.width * 0.35,
        size.height * 0.6,
      ),
      3,
      spotPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
} 
