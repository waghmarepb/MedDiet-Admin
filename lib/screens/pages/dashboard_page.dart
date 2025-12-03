import 'package:flutter/material.dart';
import 'dart:math' as math;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(
          children: [
            // Header at top
            _buildHeader(),
            // Main content area with 2 columns
            Expanded(
              child: Row(
                children: [
                  // Center column - Transactions & Summary (80%)
                  Expanded(
                    flex: 8,
                    child: _buildCenterColumn(),
                  ),
                  // Right column - Contacts (20%)
                  Expanded(
                    flex: 2,
                    child: _buildRightSidebar(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Good Evening Mikey!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Personal Account',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2D3142),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.credit_card, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF2D3142)),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined, size: 18, color: Color(0xFF2D3142)),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFFDB777),
                child: const Text(
                  'M',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCenterColumn() {
    return Builder(
      builder: (context) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickSummary(),
              const SizedBox(height: 30),
              _buildAllUsersList(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Summary On Your Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSummaryCard('Total Patients', '1,234', 'INR', const Color(0xFF5B4FA3), true)),
            const SizedBox(width: 16),
            Expanded(child: _buildSummaryCard('Active Plans', '856', 'INR', const Color(0xFF00BCD4), false)),
            const SizedBox(width: 16),
            Expanded(child: _buildSummaryCard('Consultations', '342', 'INR', const Color(0xFF5B4FA3), false, showBars: true)),
            const SizedBox(width: 16),
            Expanded(child: _buildPieChartCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildAllUsersList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'All Users',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 14),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: const Icon(Icons.arrow_forward_ios, size: 14),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserItem(
                context,
                'Mike Taylor',
                'Patient - Diet Plan Active',
                'Chicago, TX',
                const Color(0xFF5B4FA3),
              ),
              const SizedBox(height: 12),
              _buildUserItem(
                context,
                'Jack Green',
                'Patient - Consultation Scheduled',
                'Oakland, CO',
                const Color(0xFF00BCD4),
              ),
              const SizedBox(height: 12),
              _buildUserItem(
                context,
                'Carmen Lewis',
                'Patient - New Registration',
                'Milwaukee, CA',
                const Color(0xFFFF9800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserItem(
    BuildContext context,
    String title,
    String subtitle,
    String location,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.person, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFBDBDBD),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, String currency, Color color, bool showAreaChart, {bool showBars = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9E9E9E),
                ),
              ),
              Icon(Icons.trending_up, color: Colors.green, size: 14),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          Text(
            currency,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFBDBDBD),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 70,
            child: showAreaChart
                ? CustomPaint(
                    size: const Size(double.infinity, 70),
                    painter: AreaChartPainter(color),
                  )
                : showBars
                    ? CustomPaint(
                        size: const Size(double.infinity, 70),
                        painter: BarChartPainter(color),
                      )
                    : CustomPaint(
                        size: const Size(double.infinity, 70),
                        painter: LineChartPainter(color),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Graph',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9E9E9E),
                ),
              ),
              const Icon(Icons.trending_up, color: Colors.green, size: 14),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: DonutChartPainter(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '35%\nEducation',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF9E9E9E),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightSidebar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calendar Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MY CALENDAR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: 'April',
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                          underline: const SizedBox(),
                          dropdownColor: const Color(0xFF6366F1),
                          isDense: true,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          items: ['January', 'February', 'March', 'April', 'May', 'June', 
                                  'July', 'August', 'September', 'October', 'November', 'December']
                              .map((String month) {
                            return DropdownMenuItem<String>(
                              value: month,
                              child: Text(month),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {},
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Week Days Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWeekDay('Sun'),
                      _buildWeekDay('Mon'),
                      _buildWeekDay('Tue'),
                      _buildWeekDay('Wed'),
                      _buildWeekDay('Thu'),
                      _buildWeekDay('Fri'),
                      _buildWeekDay('Sat'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Calendar Days Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCalendarDay('12', false),
                      _buildCalendarDay('13', true),
                      _buildCalendarDay('14', false),
                      _buildCalendarDay('15', false),
                      _buildCalendarDay('16', false),
                      _buildCalendarDay('17', false),
                      _buildCalendarDay('18', false),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Date Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'APRIL, 13',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[400],
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Appointments List
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildAppointmentItem(
                        '2:00 pm',
                        'Meeting with chief physician Dr. Williams',
                        const Color(0xFFEC4899),
                      ),
                      const SizedBox(height: 16),
                      _buildAppointmentItem(
                        '2:30 pm',
                        'Consultation with Mr. White',
                        const Color(0xFF8B5CF6),
                      ),
                      const SizedBox(height: 16),
                      _buildAppointmentItem(
                        '3:00 pm',
                        'Consultation with Mrs. Maisey',
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 16),
                      _buildAppointmentItem(
                        '3:50 pm',
                        'Examination of Mrs. Lee\'s freckle',
                        const Color(0xFF8B5CF6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekDay(String day) {
    return SizedBox(
      width: 30,
      child: Text(
        day,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildCalendarDay(String day, bool isSelected) {
    return Container(
      width: 30,
      height: 40,
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              )
            : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          day,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentItem(String time, String title, Color dotColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time
        SizedBox(
          width: 55,
          child: Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Dot
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        // Title
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom Painters
class AreaChartPainter extends CustomPainter {
  final Color color;
  AreaChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.lineTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.4, size.height * 0.3);
    path.lineTo(size.width * 0.6, size.height * 0.4);
    path.lineTo(size.width * 0.8, size.height * 0.2);
    path.lineTo(size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LineChartPainter extends CustomPainter {
  final Color color;
  LineChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.lineTo(size.width * 0.25, size.height * 0.7);
    path.lineTo(size.width * 0.5, size.height * 0.4);
    path.lineTo(size.width * 0.75, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.3);

    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.5), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BarChartPainter extends CustomPainter {
  final Color color;
  BarChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barWidth = size.width / 10;
    final bars = [0.7, 0.5, 0.9, 0.4, 0.6, 0.8, 0.3, 0.7];

    for (int i = 0; i < bars.length; i++) {
      final x = i * (size.width / bars.length) + barWidth / 2;
      final barHeight = size.height * bars[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - barHeight, barWidth * 0.6, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint..color = color.withOpacity(i % 2 == 0 ? 1.0 : 0.5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint1 = Paint()
      ..color = const Color(0xFF5B4FA3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;

    final paint2 = Paint()
      ..color = const Color(0xFF00BCD4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;

    final paint3 = Paint()
      ..color = const Color(0xFF2D3142)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      -math.pi / 2,
      math.pi * 0.7,
      false,
      paint1,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      -math.pi / 2 + math.pi * 0.7,
      math.pi * 0.8,
      false,
      paint2,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      -math.pi / 2 + math.pi * 1.5,
      math.pi * 0.5,
      false,
      paint3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

