import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/room_provider.dart';
import '../../core/constants/app_colors.dart';

class StatsPanel extends StatelessWidget {
  const StatsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, _) {
        final totalCapacity = roomProvider.getTotalCapacity();
        final totalOccupied = roomProvider.getTotalOccupied();
        final totalAvailable = roomProvider.getTotalAvailable();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
            
            return Card(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : (isTablet ? 20 : 24)),
                child: isMobile
                  ? Column(
                      children: [
                        _StatItem(
                          icon: Icons.bed,
                          label: 'Total Capacity',
                          value: totalCapacity.toString(),
                          color: AppColors.primaryAccent,
                          isMobile: isMobile,
                          isTablet: isTablet,
                        ),
                        const Divider(height: 24),
                        _StatItem(
                          icon: Icons.people,
                          label: 'Occupied',
                          value: totalOccupied.toString(),
                          color: AppColors.roomPartial,
                          isMobile: isMobile,
                          isTablet: isTablet,
                        ),
                        const Divider(height: 24),
                        _StatItem(
                          icon: Icons.hotel,
                          label: 'Available',
                          value: totalAvailable.toString(),
                          color: AppColors.roomEmpty,
                          isMobile: isMobile,
                          isTablet: isTablet,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _StatItem(
                            icon: Icons.bed,
                            label: 'Total Capacity',
                            value: totalCapacity.toString(),
                            color: AppColors.primaryAccent,
                            isMobile: isMobile,
                            isTablet: isTablet,
                          ),
                        ),
                        const VerticalDivider(width: 32),
                        Expanded(
                          child: _StatItem(
                            icon: Icons.people,
                            label: 'Occupied',
                            value: totalOccupied.toString(),
                            color: AppColors.roomPartial,
                            isMobile: isMobile,
                            isTablet: isTablet,
                          ),
                        ),
                        const VerticalDivider(width: 32),
                        Expanded(
                          child: _StatItem(
                            icon: Icons.hotel,
                            label: 'Available',
                            value: totalAvailable.toString(),
                            color: AppColors.roomEmpty,
                            isMobile: isMobile,
                            isTablet: isTablet,
                          ),
                        ),
                      ],
                    ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isMobile;
  final bool isTablet;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isMobile ? 32.0 : (isTablet ? 36.0 : 40.0);
    final valueFontSize = isMobile ? 24.0 : (isTablet ? 28.0 : 32.0);
    final labelFontSize = isMobile ? 12.0 : 14.0;
    final iconPadding = isMobile ? 12.0 : 16.0;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(iconPadding),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: color,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: labelFontSize,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
