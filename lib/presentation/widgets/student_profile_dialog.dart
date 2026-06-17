import 'package:flutter/material.dart';
import '../../data/models/student_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/whatsapp_helper.dart';
import 'rent_history_dialog.dart';

class StudentProfileDialog extends StatefulWidget {
  final StudentModel student;

  const StudentProfileDialog({
    super.key,
    required this.student,
  });

  @override
  State<StudentProfileDialog> createState() => _StudentProfileDialogState();
}

class _StudentProfileDialogState extends State<StudentProfileDialog> {

  Future<void> _sendWhatsAppMessage(String phone, String message) async {
    final success = await WhatsAppHelper.sendCustomMessage(phone, message);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? 'Opening WhatsApp...' 
            : 'Failed to open WhatsApp. Please check if WhatsApp is installed.'),
          backgroundColor: success ? AppColors.primaryAccent : AppColors.errorColor,
          duration: Duration(seconds: success ? 2 : 4),
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon, String? whatsappPhone, String? whatsappMessage}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (icon != null && whatsappPhone != null && whatsappMessage != null)
                  IconButton(
                    icon: Icon(icon, size: 20, color: AppColors.primaryAccent),
                    onPressed: () => _sendWhatsAppMessage(whatsappPhone, whatsappMessage),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryAccent.withOpacity(0.2),
                  child: Text(
                    widget.student.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.student.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Room ${widget.student.roomNumber}',
                          style: const TextStyle(
                            color: AppColors.primaryAccent,
                            fontWeight: FontWeight.bold,
                          ),
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
            
            // Student Details
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    
                    _buildInfoRow('Date of Birth', widget.student.dob),
                    _buildInfoRow(
                      'Contact Number',
                      widget.student.contact,
                      icon: Icons.message,
                      whatsappPhone: widget.student.contact,
                      whatsappMessage: 'Hello ${widget.student.name}!',
                    ),
                    
                    const SizedBox(height: 24),
                    Text(
                      'Family Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    
                    _buildInfoRow("Father's Name", widget.student.fatherName),
                    _buildInfoRow(
                      "Father's Number",
                      widget.student.fatherNumber,
                      icon: Icons.message,
                      whatsappPhone: widget.student.fatherNumber,
                      whatsappMessage: 'Hello, this is regarding ${widget.student.name}.',
                    ),
                    _buildInfoRow("Mother's Name", widget.student.motherName),
                    _buildInfoRow(
                      "Mother's Number",
                      widget.student.motherNumber,
                      icon: Icons.message,
                      whatsappPhone: widget.student.motherNumber,
                      whatsappMessage: 'Hello, this is regarding ${widget.student.name}.',
                    ),
                    
                    const SizedBox(height: 24),
                    Text(
                      'Academic & PG Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    
                    _buildInfoRow('College/Workplace', widget.student.college),
                    _buildInfoRow('Hometown', widget.student.hometown),
                    _buildInfoRow('Address', widget.student.address),
                    _buildInfoRow('Advance Amount', '₹${widget.student.advanceAmount}'),
                    _buildInfoRow('Agreement Submitted', widget.student.agreementSubmitted),
                    _buildInfoRow('Rent Status', widget.student.rentStatus),
                    _buildInfoRow('Payment Mode', widget.student.paymentMode),
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => RentHistoryDialog(student: widget.student),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('View Rent History'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
