import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/payment_history_model.dart';
import '../../data/models/student_model.dart';
import '../../data/database/payment_history_repository.dart';
import '../../data/services/file_storage_service.dart';
import '../../core/constants/app_colors.dart';

class RentHistoryDialog extends StatefulWidget {
  final StudentModel student;

  const RentHistoryDialog({super.key, required this.student});

  @override
  State<RentHistoryDialog> createState() => _RentHistoryDialogState();
}

class _RentHistoryDialogState extends State<RentHistoryDialog> {
  final PaymentHistoryRepository _paymentRepo = PaymentHistoryRepository();
  final FileStorageService _fileService = FileStorageService();
  List<PaymentHistoryModel> _paymentHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() => _isLoading = true);
    
    try {
      // Get all payment history from database
      final history = await _paymentRepo.getStudentPaymentHistory(widget.student.id!);
      
      // Generate complete history from joining date to current month
      final completeHistory = _generateCompleteHistory(history);
      
      setState(() {
        _paymentHistory = completeHistory;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading payment history: $e');
      setState(() => _isLoading = false);
    }
  }

  List<PaymentHistoryModel> _generateCompleteHistory(List<PaymentHistoryModel> existingHistory) {
    // Parse joining date (assuming DOB is in DD/MM/YYYY format)
    // For now, we'll use current year as joining year
    // You might want to add a joining_date field to student model
    final now = DateTime.now();
    final joiningDate = DateTime(now.year, 1, 1); // Assume joined in January for demo
    
    final months = <PaymentHistoryModel>[];
    var currentMonth = DateTime(joiningDate.year, joiningDate.month, 1);
    final today = DateTime(now.year, now.month, 1);
    
    while (currentMonth.isBefore(today) || currentMonth.isAtSameMomentAs(today)) {
      final monthStr = DateFormat('yyyy-MM').format(currentMonth);
      
      // Check if we have a record for this month
      final matching = existingHistory.where((h) => h.month == monthStr);
      final existing = matching.isEmpty ? null : matching.first;
      
      if (existing != null) {
        months.add(existing);
      } else {
        // Create pending record for missing months
        months.add(PaymentHistoryModel(
          studentId: widget.student.id!,
          month: monthStr,
          paymentStatus: 'Pending',
          paymentMode: '-',
        ));
      }
      
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    }
    
    return months.reversed.toList(); // Most recent first
  }

  Future<void> _viewScreenshot(String screenshotPath) async {
    await _fileService.openScreenshot(screenshotPath);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rent Payment History',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.student.name} - Room ${widget.student.roomNumber}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            
            // Payment Stats
            if (!_isLoading && _paymentHistory.isNotEmpty)
              _buildPaymentStats(),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Payment History List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _paymentHistory.isEmpty
                      ? const Center(child: Text('No payment history found'))
                      : ListView.builder(
                          itemCount: _paymentHistory.length,
                          itemBuilder: (context, index) {
                            final payment = _paymentHistory[index];
                            return _buildPaymentItem(payment);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStats() {
    final paid = _paymentHistory.where((p) => p.paymentStatus == 'Paid').length;
    final pending = _paymentHistory.where((p) => p.paymentStatus == 'Pending').length;
    final total = _paymentHistory.length;
    
    return Card(
      color: AppColors.secondaryBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total Months', total.toString(), AppColors.primaryAccent),
            _buildStatItem('Paid', paid.toString(), AppColors.successColor),
            _buildStatItem('Pending', pending.toString(), AppColors.paymentPending),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
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

  Widget _buildPaymentItem(PaymentHistoryModel payment) {
    final isPaid = payment.paymentStatus == 'Paid';
    final monthDate = DateFormat('yyyy-MM').parse(payment.month);
    final monthName = DateFormat('MMMM yyyy').format(monthDate);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isPaid ? AppColors.successColor.withOpacity(0.2) : AppColors.paymentPending.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isPaid ? Icons.check_circle : Icons.pending,
            color: isPaid ? AppColors.successColor : AppColors.paymentPending,
          ),
        ),
        title: Text(
          monthName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isPaid ? Icons.payment : Icons.schedule,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  isPaid ? 'Paid via ${payment.paymentMode}' : 'Payment Pending',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (payment.paidDate != null) ...[
              const SizedBox(height: 2),
              Text(
                'Paid on: ${payment.paidDate}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        trailing: payment.screenshotPath != null
            ? IconButton(
                icon: const Icon(Icons.image, color: AppColors.primaryAccent),
                onPressed: () => _viewScreenshot(payment.screenshotPath!),
                tooltip: 'View Payment Screenshot',
              )
            : null,
      ),
    );
  }
}
