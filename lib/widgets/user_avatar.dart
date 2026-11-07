import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/format.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final double radius;
  const UserAvatar({super.key, required this.name, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primarySoft,
      child: Text(
        initials(name),
        style: TextStyle(
          color: AppColors.primary,
          fontSize: radius * 0.62,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
