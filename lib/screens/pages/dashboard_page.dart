import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Root container keeps same look, but sizes are responsive.
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.r),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 8, child: _buildCenterColumn()),
                  Expanded(flex: 2, child: _buildRightSidebar()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Header with responsive paddings and FittedBox to avoid overflow.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title - allow it to shrink if needed
          Flexible(
            child: Text(
              'Good Evening Mikey!',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3142),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Right side: group of controls. Wrap in FittedBox to prevent overflow.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Personal Account',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF2D3142),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(Icons.keyboard_arrow_down, size: 18.sp),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.credit_card, color: Colors.white, size: 18.sp),
                ),
                SizedBox(width: 12.w),
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: Icon(Icons.chat_bubble_outline, size: 18.sp, color: const Color(0xFF2D3142)),
                ),
                SizedBox(width: 12.w),
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.notifications_outlined, size: 18.sp, color: const Color(0xFF2D3142)),
                      Positioned(
                        right: -2.w,
                        top: -2.h,
                        child: Container(
                          width: 8.w,
                          height: 8.h,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: const Color(0xFFFDB777),
                  child: Text(
                    'M',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterColumn() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickSummary(),
          SizedBox(height: 30.h),
          _buildAllUsersList(context),
        ],
      ),
    );
  }

  Widget _buildQuickSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + View All (wrap to prevent overflow)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Quick Summary On Your Account',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3142),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: TextStyle(
                  color: const Color(0xFF9E9E9E),
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Responsive cards: use LayoutBuilder to switch between Row (desktop) and Wrap (narrow)
        LayoutBuilder(builder: (context, constraints) {
          // If narrow, use wrap (cards will wrap onto next line)
          if (constraints.maxWidth < 1000.w) {
            // choose 1 or 2 columns based on width
            int columns = constraints.maxWidth < 600.w ? 1 : 2;
            double itemWidth = (constraints.maxWidth - (16.w * (columns - 1))) / columns;
            return Wrap(
              spacing: 16.w,
              runSpacing: 16.h,
              children: [
                SizedBox(width: itemWidth, child: _buildSummaryCard('Total Patients', '1,234', 'INR', const Color(0xFF5B4FA3), true)),
                SizedBox(width: itemWidth, child: _buildSummaryCard('Active Plans', '856', 'INR', const Color(0xFF00BCD4), false)),
                SizedBox(width: itemWidth, child: _buildSummaryCard('Consultations', '342', 'INR', const Color(0xFF5B4FA3), false, showBars: true)),
                SizedBox(width: itemWidth, child: _buildPieChartCard()),
              ],
            );
          } else {
            // Desktop: keep single row; use Expanded to distribute space
            return Row(
              children: [
                Expanded(child: _buildSummaryCard('Total Patients', '1,234', 'INR', const Color(0xFF5B4FA3), true)),
                SizedBox(width: 16.w),
                Expanded(child: _buildSummaryCard('Active Plans', '856', 'INR', const Color(0xFF00BCD4), false)),
                SizedBox(width: 16.w),
                Expanded(child: _buildSummaryCard('Consultations', '342', 'INR', const Color(0xFF5B4FA3), false, showBars: true)),
                SizedBox(width: 16.w),
                Expanded(child: _buildPieChartCard()),
              ],
            );
          }
        }),
      ],
    );
  }

  Widget _buildAllUsersList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row — wrap to avoid overflow
        Padding(
          padding: EdgeInsets.only(right: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'All Users',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3142),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // controls: shrink when necessary
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                      ),
                      child: Icon(Icons.arrow_back_ios_new, size: 14.sp),
                    ),
                    SizedBox(width: 10.w),
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                      ),
                      child: Icon(Icons.arrow_forward_ios, size: 14.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(20.r),
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
              SizedBox(height: 12.h),
              _buildUserItem(
                context,
                'Jack Green',
                'Patient - Consultation Scheduled',
                'Oakland, CO',
                const Color(0xFF00BCD4),
              ),
              SizedBox(height: 12.h),
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.person, color: iconColor, size: 22.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFFBDBDBD),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 14.w),
          Container(
            width: 36.w,
            height: 36.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.arrow_forward, color: Colors.white, size: 18.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, String currency, Color color, bool showAreaChart, {bool showBars = false}) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
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
                style: TextStyle(fontSize: 13.sp, color: const Color(0xFF9E9E9E)),
              ),
              Icon(Icons.trending_up, color: Colors.green, size: 14.sp),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            amount,
            style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142)),
          ),
          Text(
            currency,
            style: TextStyle(fontSize: 11.sp, color: const Color(0xFFBDBDBD)),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 70.h,
            child: showAreaChart
                ? CustomPaint(
                    size: Size(double.infinity, 70.h),
                    painter: AreaChartPainter(color),
                  )
                : showBars
                    ? CustomPaint(
                        size: Size(double.infinity, 70.h),
                        painter: BarChartPainter(color),
                      )
                    : CustomPaint(
                        size: Size(double.infinity, 70.h),
                        painter: LineChartPainter(color),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Graph', style: TextStyle(fontSize: 13.sp, color: const Color(0xFF9E9E9E))),
              Icon(Icons.trending_up, color: Colors.green, size: 14.sp),
            ],
          ),
          SizedBox(height: 20.h),
          Center(
            child: SizedBox(
              width: 100.w,
              height: 100.w,
              child: CustomPaint(painter: DonutChartPainter()),
            ),
          ),
          SizedBox(height: 12.h),
          Center(
            child: Text(
              '35%\nEducation',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.sp, color: const Color(0xFF9E9E9E), height: 1.3),
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
        padding: EdgeInsets.all(24.w),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24.r,
                offset: Offset(0, 8.h),
                spreadRadius: -4.r,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calendar Header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MY CALENDAR',
                          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.5),
                        ),
                        SizedBox(width: 12.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: DropdownButton<String>(
                            value: 'April',
                            icon: Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16.sp),
                            underline: const SizedBox(),
                            dropdownColor: const Color(0xFF6366F1),
                            isDense: true,
                            style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.w600),
                            items: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
                                .map((String month) {
                              return DropdownMenuItem<String>(
                                value: month,
                                child: Text(month, style: TextStyle(fontSize: 12.sp)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Week Days Row - FittedBox to avoid overflow in very narrow sidebars
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
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
                ),

                SizedBox(height: 16.h),

                // Calendar Days Row
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
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
                ),

                SizedBox(height: 32.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'APRIL, 13',
                      style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600, color: Colors.grey[400], letterSpacing: 1.2),
                    ),
                    Text(
                      'See all',
                      style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500, color: Colors.grey[400]),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildAppointmentItem('2:00 pm', 'Meeting with chief physician Dr. Williams', const Color(0xFFEC4899)),
                      SizedBox(height: 16.h),
                      _buildAppointmentItem('2:30 pm', 'Consultation with Mr. White', const Color(0xFF8B5CF6)),
                      SizedBox(height: 16.h),
                      _buildAppointmentItem('3:00 pm', 'Consultation with Mrs. Maisey', const Color(0xFF10B981)),
                      SizedBox(height: 16.h),
                      _buildAppointmentItem('3:50 pm', 'Examination of Mrs. Lee\'s freckle', const Color(0xFF8B5CF6)),
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
      width: 30.w,
      child: Text(
        day,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500, color: Colors.grey[500]),
      ),
    );
  }

  Widget _buildCalendarDay(String day, bool isSelected) {
    return Container(
      width: 30.w,
      height: 40.h,
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
            : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Center(
        child: Text(
          day,
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF374151)),
        ),
      ),
    );
  }

  Widget _buildAppointmentItem(String time, String title, Color dotColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 55.w,
          child: Text(
            time,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          width: 6.w,
          height: 6.h,
          margin: EdgeInsets.only(top: 6.h),
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF374151), fontWeight: FontWeight.w500, height: 1.4),
          ),
        ),
      ],
    );
  }
}

// ------------------------------
// Custom Painters (unchanged logic, use size provided by parent)
// ------------------------------
class AreaChartPainter extends CustomPainter {
  final Color color;
  AreaChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.3)..style = PaintingStyle.fill;
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
    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.lineTo(size.width * 0.25, size.height * 0.7);
    path.lineTo(size.width * 0.5, size.height * 0.4);
    path.lineTo(size.width * 0.75, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.3);
    canvas.drawPath(path, paint);
    final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
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
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final barWidth = size.width / 10;
    final bars = [0.7, 0.5, 0.9, 0.4, 0.6, 0.8, 0.3, 0.7];
    for (int i = 0; i < bars.length; i++) {
      final x = i * (size.width / bars.length) + barWidth / 2;
      final barHeight = size.height * bars[i];
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - barHeight, barWidth * 0.6, barHeight), const Radius.circular(4));
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
    final paint1 = Paint()..color = const Color(0xFF5B4FA3)..style = PaintingStyle.stroke..strokeWidth = 16;
    final paint2 = Paint()..color = const Color(0xFF00BCD4)..style = PaintingStyle.stroke..strokeWidth = 16;
    final paint3 = Paint()..color = const Color(0xFF2D3142)..style = PaintingStyle.stroke..strokeWidth = 16;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 8), -math.pi / 2, math.pi * 0.7, false, paint1);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 8), -math.pi / 2 + math.pi * 0.7, math.pi * 0.8, false, paint2);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 8), -math.pi / 2 + math.pi * 1.5, math.pi * 0.5, false, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
