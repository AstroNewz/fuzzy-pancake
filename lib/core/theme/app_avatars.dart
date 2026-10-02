import 'package:flutter/material.dart';

/// App Avatars Helper for the 10 Shuttlecock Mascot Characters
class AppAvatars {
  static const List<Map<String, String>> allAvatars = [
    {'name': 'Default', 'path': 'assets/images/avatars/avatar_1_default.png'},
    {'name': 'Serious', 'path': 'assets/images/avatars/avatar_2_serious.png'},
    {'name': 'Cool', 'path': 'assets/images/avatars/avatar_3_cool.png'},
    {'name': 'Scholar', 'path': 'assets/images/avatars/avatar_4_scholar.png'},
    {'name': 'Farmer', 'path': 'assets/images/avatars/avatar_5_farmer.png'},
    {'name': 'Gamer', 'path': 'assets/images/avatars/avatar_6_gamer.png'},
    {'name': 'Sleepy', 'path': 'assets/images/avatars/avatar_7_sleepy.png'},
    {'name': 'Travel', 'path': 'assets/images/avatars/avatar_8_travel.png'},
    {
      'name': 'Motivator',
      'path': 'assets/images/avatars/avatar_9_motivator.png'
    },
    {'name': 'Minimal', 'path': 'assets/images/avatars/avatar_10_minimal.png'},
  ];

  static String getAvatarForRoll(String? rollNumber) {
    if (rollNumber == null || rollNumber.isEmpty) {
      return allAvatars[0]['path']!;
    }
    final clean = rollNumber.toUpperCase().trim();
    switch (clean) {
      case 'SD-0001':
        return 'assets/images/avatars/avatar_3_cool.png';
      case 'SD-0002':
        return 'assets/images/avatars/avatar_1_default.png';
      case 'SD-0003':
        return 'assets/images/avatars/avatar_6_gamer.png';
      case 'SD-0004':
        return 'assets/images/avatars/avatar_4_scholar.png';
      case 'SD-0005':
        return 'assets/images/avatars/avatar_2_serious.png';
      case 'SD-0006':
        return 'assets/images/avatars/avatar_8_travel.png';
      case 'SD-0007':
        return 'assets/images/avatars/avatar_9_motivator.png';
      default:
        // Hash for other IDs
        final idx = clean.hashCode.abs() % allAvatars.length;
        return allAvatars[idx]['path']!;
    }
  }

  static Widget buildAvatar({
    required String? rollNumber,
    double size = 40,
    BoxBorder? border,
    BorderRadius? borderRadius,
  }) {
    final assetPath = getAvatarForRoll(rollNumber);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(size * 0.25),
        border: border,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(size * 0.25),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.person,
            size: size * 0.6,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
