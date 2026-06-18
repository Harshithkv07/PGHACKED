import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/student_model.dart';
import '../../data/models/payment_history_model.dart';
import '../../data/database/student_repository.dart';
import '../../data/database/room_repository.dart';
import '../../data/database/payment_history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RentProvider with ChangeNotifier {
  final StudentRepository _studentRepo = StudentRepository();
  final RoomRepository _roomRepo = RoomRepository();
  final PaymentHistoryRepository _paymentHistoryRepo = PaymentHistoryRepository();
  
  List<StudentModel> _students = [];
  bool _isLoading = false;

  List<StudentModel> get students => _students;
  bool get isLoading => _isLoading;

  // Load all students for rent tracking
  Future<void> loadStudents() async {
    _isLoading = true;
    notifyListeners();
    
    _students = await _studentRepo.getAllStudents();
    
    _isLoading = false;
    notifyListeners();
  }

  // Calculate total potential revenue
  Future<int> getPotentialRevenue() async {
    int total = 0;
    final rooms = await _roomRepo.getAllRooms();
    
    for (var student in _students) {
      final room = rooms.firstWhere(
        (r) => r.roomNumber == student.roomNumber,
        orElse: () => rooms.first,
      );
      total += room.price;
    }
    
    return total;
  }

  // Calculate collected revenue
  Future<int> getCollectedRevenue() async {
    int total = 0;
    final rooms = await _roomRepo.getAllRooms();
    
    for (var student in _students.where((s) => s.rentStatus == 'Paid')) {
      final room = rooms.firstWhere(
        (r) => r.roomNumber == student.roomNumber,
        orElse: () => rooms.first,
      );
      total += room.price;
    }
    
    return total;
  }

  // Mark student as paid
  Future<void> markAsPaid(int studentId, String paymentMode, [String? screenshotPath]) async {
    final student = _students.firstWhere((s) => s.id == studentId);
    final updatedStudent = student.copyWith(
      rentStatus: 'Paid',
      paymentMode: paymentMode,
    );
    
    await _studentRepo.updateStudent(updatedStudent);
    
    // Create payment history record
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final paidDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    
    final paymentRecord = PaymentHistoryModel(
      studentId: studentId,
      month: currentMonth,
      paymentStatus: 'Paid',
      paymentMode: paymentMode,
      screenshotPath: screenshotPath,
      paidDate: paidDate,
    );
    
    await _paymentHistoryRepo.upsertPaymentRecord(paymentRecord);
    await loadStudents();
  }

  // Revert student status to pending
  Future<void> revertToPending(int studentId) async {
    try {
      final student = _students.firstWhere((s) => s.id == studentId);
      final updatedStudent = student.copyWith(
        rentStatus: 'Pending',
        paymentMode: '-',
      );
      
      await _studentRepo.updateStudent(updatedStudent);
      
      // Delete payment history record for the current month
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      final existing = await _paymentHistoryRepo.getPaymentForMonth(studentId, currentMonth);
      if (existing != null) {
        await _paymentHistoryRepo.deletePaymentRecord(existing.id!);
      }
      
      await loadStudents();
    } catch (e) {
      print('Error reverting payment to pending: $e');
    }
  }

  // Start new month (archive current month status and reset all to pending)
  Future<void> startNewMonth() async {
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    
    // Archive current active states if they don't already have history records
    for (var student in _students) {
      final existing = await _paymentHistoryRepo.getPaymentForMonth(student.id!, currentMonth);
      if (existing == null) {
        final paymentRecord = PaymentHistoryModel(
          studentId: student.id!,
          month: currentMonth,
          paymentStatus: student.rentStatus,
          paymentMode: student.paymentMode,
          paidDate: student.rentStatus == 'Paid' ? DateFormat('dd/MM/yyyy').format(DateTime.now()) : null,
        );
        await _paymentHistoryRepo.upsertPaymentRecord(paymentRecord);
      }
    }

    await _studentRepo.resetAllRentStatus();
    
    // Update last active month in SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_active_rent_month', currentMonth);
    } catch (e) {
      print('Error saving last active month: $e');
    }
    
    await loadStudents();
  }

  // Automatically check if the calendar month has transitioned and handle it by archiving and resetting
  Future<void> checkAndHandleMonthTransition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      final lastActiveMonth = prefs.getString('last_active_rent_month');

      if (lastActiveMonth == null) {
        // First run or fresh database: initialize the active month to the current month
        await prefs.setString('last_active_rent_month', currentMonth);
        return;
      }

      if (lastActiveMonth != currentMonth) {
        // A new month has transitioned!
        // Load latest students from DB to make sure we archive actual data
        final currentStudentsList = await _studentRepo.getAllStudents();
        
        // 1. Archive the final status of all students for the last active month
        for (var student in currentStudentsList) {
          final existing = await _paymentHistoryRepo.getPaymentForMonth(student.id!, lastActiveMonth);
          if (existing == null) {
            final paymentRecord = PaymentHistoryModel(
              studentId: student.id!,
              month: lastActiveMonth,
              paymentStatus: student.rentStatus,
              paymentMode: student.paymentMode,
              paidDate: student.rentStatus == 'Paid' ? DateFormat('dd/MM/yyyy').format(DateTime.now()) : null,
            );
            await _paymentHistoryRepo.upsertPaymentRecord(paymentRecord);
          }
        }

        // 2. Reset student statuses to pending for the new month
        await _studentRepo.resetAllRentStatus();

        // 3. Update the last active rent month to the current month
        await prefs.setString('last_active_rent_month', currentMonth);

        // 4. Reload students list
        await loadStudents();
      }
    } catch (e) {
      print('Error handling month transition: $e');
    }
  }

  // Get students by rent status
  List<StudentModel> getStudentsByStatus(String status) {
    return _students.where((s) => s.rentStatus == status).toList();
  }
}
