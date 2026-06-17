import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/room_config_model.dart';
import '../../logic/providers/student_provider.dart';
import '../../core/constants/app_colors.dart';
import 'room_details_dialog.dart';

class RoomCard extends StatelessWidget {
  final RoomConfigModel room;
  final int occupancy;

  const RoomCard({
    super.key,
    required this.room,
    required this.occupancy,
  });

  Color _getStatusColor() {
    final available = room.capacity - occupancy;
    if (available == 0) return AppColors.roomFull;
    if (available < room.capacity) return AppColors.roomPartial;
    return AppColors.roomEmpty;
  }

  String _getStatusText() {
    final available = room.capacity - occupancy;
    if (available == 0) return 'FULL';
    if (available < room.capacity) return 'PARTIAL';
    return 'EMPTY';
  }

  void _showRoomDetails(BuildContext context) async {
    final students = await Provider.of<StudentProvider>(context, listen: false)
        .getStudentsByRoom(room.roomNumber);
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => RoomDetailsDialog(
          room: room,
          students: students,
          occupancy: occupancy,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final available = room.capacity - occupancy;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive sizing
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final cardPadding = isMobile ? 12.0 : (isTablet ? 14.0 : 16.0);
    final roomNumberFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);
    final bedsFontSize = isMobile ? 16.0 : (isTablet ? 17.0 : 18.0);
    final priceFontSize = isMobile ? 13.0 : 14.0;

    return InkWell(
      onTap: () => _showRoomDetails(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withOpacity(0.3),
              statusColor.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor,
            width: 2,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Room Number
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Room ${room.roomNumber}',
                    style: TextStyle(
                      fontSize: roomNumberFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 8 : 12),
              
              // Status Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 8 : 12),
              
              // Occupancy Info
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$occupancy/${room.capacity} Beds',
                  style: TextStyle(
                    fontSize: bedsFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$available Available',
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isMobile ? 6 : 8),
              
              // Price
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.currency_rupee,
                    size: isMobile ? 14 : 16,
                    color: AppColors.goldAccent,
                  ),
                  Flexible(
                    child: Text(
                      '${room.price}/month',
                      style: TextStyle(
                        fontSize: priceFontSize,
                        color: AppColors.goldAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
