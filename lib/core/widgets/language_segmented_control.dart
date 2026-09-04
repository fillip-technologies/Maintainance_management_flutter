import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';
import '../theme/colors.dart';

class LanguageSegmentedControl extends ConsumerWidget {
  const LanguageSegmentedControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isHindi = currentLocale.languageCode == 'hi';

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Sleek neutral slate track
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon prefix
          const Padding(
            padding: EdgeInsets.only(left: 8, right: 6),
            child: Icon(
              Icons.translate_rounded,
              size: 15,
              color: AppColors.primary,
            ),
          ),

          // English Segment
          _SegmentPill(
            title: 'English',
            isSelected: !isHindi,
            onTap: () {
              if (isHindi) {
                ref.read(localeProvider.notifier).setLocale(const Locale('en'));
              }
            },
          ),

          const SizedBox(width: 2),

          // Hindi Segment
          _SegmentPill(
            title: 'हिन्दी',
            isSelected: isHindi,
            onTap: () {
              if (!isHindi) {
                ref.read(localeProvider.notifier).setLocale(const Locale('hi'));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SegmentPill extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentPill({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
