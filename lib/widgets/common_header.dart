import 'package:flutter/material.dart';
import 'package:meddiet/services/auth_service.dart';
import 'package:meddiet/constants/app_colors.dart';

class CommonHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  final bool showAvatar;

  const CommonHeader({
    super.key,
    required this.title,
    this.action,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 16, 40, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
                letterSpacing: -0.5,
              ),
            ),
          ),
          Row(
            children: [
              if (action != null) action!,
              if (action != null && showAvatar) const SizedBox(width: 16),
              if (showAvatar)
                InkWell(
                  onTap: () => Scaffold.of(context).openEndDrawer(),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFFDB777),
                    child: Text(
                      (AuthService.doctorData?['name']?[0] ?? 'D').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
