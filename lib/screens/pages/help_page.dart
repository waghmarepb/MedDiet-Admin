import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:meddiet/constants/app_colors.dart';
import 'package:meddiet/widgets/common_header.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1440, 1024),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30.r),
            child: Column(
              children: [
                const CommonHeader(title: 'Help & Support'),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 40.w, vertical: 20.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FAQ Section
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: EdgeInsets.all(30.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Frequently Asked Questions',
                                  style: TextStyle(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2D3142),
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                Expanded(
                                  child: ListView(
                                    children: [
                                      _buildFAQItem(
                                        'How do I add a new patient?',
                                        'Go to Patients page and click on "Add New Patient" button.',
                                      ),
                                      _buildFAQItem(
                                        'How do I create a diet plan?',
                                        'Navigate to Diet Plans and click "Create New Plan".',
                                      ),
                                      _buildFAQItem(
                                        'How can I schedule appointments?',
                                        'Use the Appointments page to schedule and manage all consultations.',
                                      ),
                                      _buildFAQItem(
                                        'How do I view reports?',
                                        'Check the Reports & Analytics page for detailed insights.',
                                      ),
                                      _buildFAQItem(
                                        'How to change my password?',
                                        'Go to Settings > Account Settings > Change Password.',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 30.w),
                        // Contact Section
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(30.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Contact Support',
                                  style: TextStyle(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2D3142),
                                  ),
                                ),
                                SizedBox(height: 30.h),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        _buildContactCard(
                                          'Email Support',
                                          'support@meddiet.com',
                                          Icons.email,
                                          AppColors.primary,
                                        ),
                                        SizedBox(height: 20.h),
                                        _buildContactCard(
                                          'Phone Support',
                                          '+91 123 456 7890',
                                          Icons.phone,
                                          AppColors.success,
                                        ),
                                        SizedBox(height: 20.h),
                                        _buildContactCard(
                                          'Live Chat',
                                          'Start a conversation',
                                          Icons.chat,
                                          AppColors.accent,
                                        ),
                                        SizedBox(height: 30.h),
                                        Container(
                                          padding: EdgeInsets.all(20.w),
                                          decoration: BoxDecoration(
                                            gradient:
                                                AppColors.primaryGradient,
                                            borderRadius:
                                                BorderRadius.circular(16.r),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(Icons.support_agent,
                                                  color: Colors.white,
                                                  size: 48.sp),
                                              SizedBox(height: 12.h),
                                              Text(
                                                'Need Help?',
                                                style: TextStyle(
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(height: 8.h),
                                              Text(
                                                'Our support team is available 24/7 to assist you.',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.help_outline, color: AppColors.info, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3142),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
      String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
