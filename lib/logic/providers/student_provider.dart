import 'package:flutter/material.dart';
import '../../data/models/student_model.dart';
import '../../data/database/student_repository.dart';
import '../../data/database/room_repository.dart';

class StudentProvider with ChangeNotifier {
  final StudentRepository _studentRepo = StudentRepository();
  final RoomRepository _roomRepo = RoomRepository();
  
  List<StudentModel> _students = [];
  List<StudentModel> _filteredStudents = [];
  bool _isLoading = false;

  List<StudentModel> get students => _filteredStudents;
  bool get isLoading => _isLoading;

  // Load all students
  Future<void> loadStudents() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _students = await _studentRepo.getAllStudents();
      _filteredStudents = List.from(_students);
    } catch (e) {
      print('Error loading students: $e');
      _students = [];
      _filteredStudents = [];
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Add student with room capacity validation
  Future<bool> addStudent(StudentModel student) async {
    try {
      // Check room capacity
      final room = await _roomRepo.getRoomByNumber(student.roomNumber);
      if (room == null) {
        print('Room ${student.roomNumber} does not exist');
        return false; // Room doesn't exist
      }
      
      final currentOccupancy = await _studentRepo.getRoomOccupancy(student.roomNumber);
      if (currentOccupancy >= room.capacity) {
        print('Room ${student.roomNumber} is full (${currentOccupancy}/${room.capacity})');
        return false; // Room is full
      }
      
      // Add student
      final id = await _studentRepo.insertStudent(student);
      print('Student added successfully with ID: $id');
      await loadStudents();
      return true;
    } catch (e) {
      print('Error adding student: $e');
      return false;
    }
  }

  // Update student
  Future<void> updateStudent(StudentModel student) async {
    await _studentRepo.updateStudent(student);
    await loadStudents();
  }

  // Delete student
  Future<void> deleteStudent(int id) async {
    await _studentRepo.deleteStudent(id);
    await loadStudents();
  }

  // Search students
  void searchStudents(String query) {
    if (query.isEmpty) {
      _filteredStudents = List.from(_students);
    } else {
      _filteredStudents = _students.where((student) {
        return student.name.toLowerCase().contains(query.toLowerCase()) ||
               student.contact.contains(query) ||
               student.roomNumber.toString().contains(query);
      }).toList();
    }
    notifyListeners();
  }

  // Get students by room
  Future<List<StudentModel>> getStudentsByRoom(int roomNumber) async {
    return await _studentRepo.getStudentsByRoom(roomNumber);
  }
}
