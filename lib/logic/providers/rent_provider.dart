import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/student_model.dart';
import '../../data/models/payment_history_model.dart';
import '../../data/database/student_repository.dart';
import '../../data/database/room_repository.dart';
import '../../data/database/payment_history_repository.dart';

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

  // Start new month (reset all to pending)
  Future<void> startNewMonth() async {
    await _studentRepo.resetAllRentStatus();
    await loadStudents();
  }

  // Get students by rent status
  List<StudentModel> getStudentsByStatus(String status) {
    return _students.where((s) => s.rentStatus == status).toList();
  }
}
