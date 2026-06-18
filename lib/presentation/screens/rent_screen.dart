import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../logic/providers/rent_provider.dart';
import '../../logic/providers/room_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/whatsapp_helper.dart';
import '../../data/services/file_storage_service.dart';
import '../../data/database/payment_history_repository.dart';

class RentScreen extends StatefulWidget {
  const RentScreen({super.key});

  @override
  State<RentScreen> createState() => _RentScreenState();
}

class _RentScreenState extends State<RentScreen> {
  final PaymentHistoryRepository _paymentHistoryRepository =
      PaymentHistoryRepository();
  final FileStorageService _fileStorageService = FileStorageService();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RentProvider>(context, listen: false).loadStudents();
      Provider.of<RoomProvider>(context, listen: false).loadRooms();
    });
  }

  Future<void> _markAsPaid(int studentId, String studentName, int roomNumber) async {
    final paymentMode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Payment Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How did the student pay?', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context, 'Cash'),
                    icon: const Icon(Icons.money),
                    label: const Text('Cash'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context, 'UPI'),
                    icon: const Icon(Icons.qr_code),
                    label: const Text('UPI'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (paymentMode != null && mounted) {
      String? screenshotPath;
      
      // If UPI, ask for payment screenshot
      if (paymentMode == 'UPI') {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          dialogTitle: 'Select Payment Screenshot',
        );
        
        if (result != null && result.files.single.path != null) {
          try {
            final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
            
            screenshotPath = await _fileStorageService.savePaymentScreenshot(
              sourcePath: result.files.single.path!,
              studentName: studentName,
              roomNumber: roomNumber,
              month: currentMonth,
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error saving screenshot: $e'),
                  backgroundColor: AppColors.errorColor,
                ),
              );
            }
          }
        }
      }
      
      await Provider.of<RentProvider>(context, listen: false)
          .markAsPaid(studentId, paymentMode, screenshotPath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(screenshotPath != null 
                ? 'Payment marked as paid with screenshot' 
                : 'Payment marked as paid'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    }
  }

  Future<void> _revertToPending(int studentId, String studentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Revert Payment Status'),
        content: Text('Are you sure you want to revert $studentName\'s payment status to Pending? This will delete the payment record for the current month.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revert'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<RentProvider>(context, listen: false).revertToPending(studentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment status reverted to pending'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    }
  }

  Future<void> _viewCurrentMonthScreenshot(int studentId) async {
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final payment = await _paymentHistoryRepository.getPaymentForMonth(
      studentId,
      currentMonth,
    );

    if (payment == null || payment.screenshotPath == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No screenshot saved for this month.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    await _fileStorageService.openScreenshot(payment.screenshotPath!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening payment screenshot...'),
        backgroundColor: AppColors.primaryAccent,
      ),
    );
  }

  Future<void> _sendReminder(String contact, String name, int roomNumber) async {
    final success = await WhatsAppHelper.sendRentReminder(contact, name, roomNumber);
    
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

  Future<void> _startNewMonth() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Month'),
        content: const Text(
          'This will reset all rent statuses to "Pending" and clear payment modes. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldAccent,
            ),
            child: const Text('Start New Month'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<RentProvider>(context, listen: false).startNewMonth();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New month started! All statuses reset to pending.'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<RentProvider>(context, listen: false).loadStudents();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Revenue Tracker
              Consumer2<RentProvider, RoomProvider>(
                builder: (context, rentProvider, roomProvider, _) {
                  return FutureBuilder<List<int>>(
                    future: Future.wait([
                      rentProvider.getCollectedRevenue(),
                      rentProvider.getPotentialRevenue(),
                    ]),
                    builder: (context, snapshot) {
                      final collected = snapshot.data?[0] ?? 0;
                      final potential = snapshot.data?[1] ?? 0;
                      final percentage = potential > 0 ? (collected / potential) : 0.0;
                      
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monthly Revenue Tracker',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Collected', style: TextStyle(color: AppColors.textSecondary)),
                                      Text(
                                        '₹${collected.toString()}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.successColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Potential', style: TextStyle(color: AppColors.textSecondary)),
                                      Text(
                                        '₹${potential.toString()}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  minHeight: 12,
                                  backgroundColor: AppColors.secondaryBackground,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.successColor),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(percentage * 100).toStringAsFixed(1)}% Collected',
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _startNewMonth,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Start New Month'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Rent Table
              Consumer2<RentProvider, RoomProvider>(
                builder: (context, rentProvider, roomProvider, _) {
                  if (rentProvider.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  final students = rentProvider.students;
                  
                  if (students.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No students found',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    );
                  }
                  
                  return SizedBox(
                    width: double.infinity,
                    child: Card(
                      child: LayoutBuilder(
                        builder: (context, tableConstraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: tableConstraints.maxWidth,
                              ),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  AppColors.secondaryBackground,
                                ),
                                columns: const [
                                  DataColumn(label: Text('Room', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Rent Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: students.map((student) {
                          final isPaid = student.rentStatus == 'Paid';
                          final rowColor = isPaid ? AppColors.paymentPaid.withOpacity(0.1) : AppColors.paymentPending.withOpacity(0.1);
                          
                          return DataRow(
                            color: WidgetStateProperty.all(rowColor),
                            cells: [
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    student.roomNumber.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryAccent,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(student.name)),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isPaid ? AppColors.paymentPaid : AppColors.paymentPending,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    student.rentStatus,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(student.paymentMode)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isPaid) ...[
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check_circle,
                                          color: AppColors.successColor,
                                        ),
                                        onPressed: () => _markAsPaid(
                                          student.id!,
                                          student.name,
                                          student.roomNumber,
                                        ),
                                        tooltip: 'Mark as Paid',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.message,
                                          color: AppColors.primaryAccent,
                                        ),
                                        onPressed: () => _sendReminder(
                                          student.contact,
                                          student.name,
                                          student.roomNumber,
                                        ),
                                        tooltip: 'Send Reminder',
                                      ),
                                    ] else ...[
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check_circle,
                                          color: AppColors.successColor,
                                        ),
                                        onPressed: () => _revertToPending(
                                          student.id!,
                                          student.name,
                                        ),
                                        tooltip: 'Revert to Pending',
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.image,
                                          color: AppColors.primaryAccent,
                                        ),
                                        onPressed: () =>
                                            _viewCurrentMonthScreenshot(
                                          student.id!,
                                        ),
                                        tooltip:
                                            'View screenshot for this month',
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                                );
                              }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
