import 'package:flutter/material.dart';
import '../../data/models/room_config_model.dart';
import '../../data/models/student_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/whatsapp_helper.dart';

class RoomDetailsDialog extends StatelessWidget {
  final RoomConfigModel room;
  final List<StudentModel> students;
  final int occupancy;

  const RoomDetailsDialog({
    super.key,
    required this.room,
    required this.students,
    required this.occupancy,
  });

  @override
  Widget build(BuildContext context) {
    final available = room.capacity - occupancy;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.meeting_room,
                    size: 32,
                    color: AppColors.primaryAccent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room ${room.roomNumber}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${room.capacity}-Sharing • ₹${room.price}/month',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Occupancy Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoItem(
                    label: 'Capacity',
                    value: room.capacity.toString(),
                    color: AppColors.primaryAccent,
                  ),
                  _InfoItem(
                    label: 'Occupied',
                    value: occupancy.toString(),
                    color: AppColors.roomPartial,
                  ),
                  _InfoItem(
                    label: 'Available',
                    value: available.toString(),
                    color: available > 0 ? AppColors.roomEmpty : AppColors.roomFull,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Occupants List
            Text(
              'Current Occupants',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Expanded(
              child: students.isEmpty
                  ? const Center(
                      child: Text(
                        'No students in this room',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryAccent.withOpacity(0.2),
                              child: Text(
                                student.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primaryAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(student.name),
                            subtitle: Text(student.contact),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.message,
                                color: AppColors.primaryAccent,
                              ),
                              onPressed: () {
                                WhatsAppHelper.sendCustomMessage(
                                  student.contact,
                                  'Hello ${student.name}!',
                                );
                              },
                              tooltip: 'Send WhatsApp Message',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
