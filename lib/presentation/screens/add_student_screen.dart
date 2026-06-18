import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/student_model.dart';
import '../../logic/providers/student_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/whatsapp_helper.dart';
import '../../logic/providers/room_provider.dart';
import '../../logic/providers/rent_provider.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for all fields
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _contactController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _fatherNumberController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _motherNumberController = TextEditingController();
  final _collegeController = TextEditingController();
  final _hometownController = TextEditingController();
  final _addressController = TextEditingController();
  final _roomNumberController = TextEditingController();
  final _advanceAmountController = TextEditingController();
  
  String _agreementSubmitted = 'No';

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _contactController.dispose();
    _fatherNameController.dispose();
    _fatherNumberController.dispose();
    _motherNameController.dispose();
    _motherNumberController.dispose();
    _collegeController.dispose();
    _hometownController.dispose();
    _addressController.dispose();
    _roomNumberController.dispose();
    _advanceAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // ~18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryAccent,
              surface: AppColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _dobController.clear();
    _contactController.clear();
    _fatherNameController.clear();
    _fatherNumberController.clear();
    _motherNameController.clear();
    _motherNumberController.clear();
    _collegeController.clear();
    _hometownController.clear();
    _addressController.clear();
    _roomNumberController.clear();
    _advanceAmountController.clear();
    setState(() {
      _agreementSubmitted = 'No';
    });
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    final student = StudentModel(
      roomNumber: int.parse(_roomNumberController.text),
      name: _nameController.text.trim(),
      dob: _dobController.text.trim(),
      contact: _contactController.text.trim(),
      fatherName: _fatherNameController.text.trim(),
      fatherNumber: _fatherNumberController.text.trim(),
      motherName: _motherNameController.text.trim(),
      motherNumber: _motherNumberController.text.trim(),
      college: _collegeController.text.trim(),
      hometown: _hometownController.text.trim(),
      address: _addressController.text.trim(),
      advanceAmount: _advanceAmountController.text.trim(),
      agreementSubmitted: _agreementSubmitted,
    );

    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final success = await studentProvider.addStudent(student);

    if (!mounted) return;

    if (success) {
      // Sync changes with dashboard and rent modules
      Provider.of<RoomProvider>(context, listen: false).loadRooms();
      Provider.of<RentProvider>(context, listen: false).loadStudents();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student added successfully!'),
          backgroundColor: AppColors.successColor,
        ),
      );

      // Ask if user wants to send welcome message
      final sendMessage = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Send Welcome Message?'),
          content: const Text('Do you want to send a WhatsApp welcome message to the student?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (sendMessage == true) {
        await WhatsAppHelper.sendWelcomeMessage(
          student.contact,
          student.name,
          student.roomNumber,
        );
      }

      _clearForm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Room is full! Cannot add more students.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Two-column layout for desktop/tablet
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildLeftColumn()),
                        const SizedBox(width: 24),
                        Expanded(child: _buildRightColumn()),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildLeftColumn(),
                        const SizedBox(height: 16),
                        _buildRightColumn(),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 32),
              
              // Save button
              Center(
                child: SizedBox(
                  width: 300,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _saveStudent,
                    icon: const Icon(Icons.save),
                    label: const Text('SAVE STUDENT'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal & Family Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primaryAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Student Name *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) => Validators.validateRequired(value, 'Student name'),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _dobController,
              decoration: const InputDecoration(
                labelText: 'Date of Birth (DD/MM/YYYY) *',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: _selectDate,
              validator: Validators.validateDate,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Contact Number *',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: Validators.validatePhone,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _fatherNameController,
              decoration: const InputDecoration(
                labelText: "Father's Name *",
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => Validators.validateRequired(value, "Father's name"),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _fatherNumberController,
              decoration: const InputDecoration(
                labelText: "Father's Number *",
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: Validators.validatePhone,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _motherNameController,
              decoration: const InputDecoration(
                labelText: "Mother's Name *",
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => Validators.validateRequired(value, "Mother's name"),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _motherNumberController,
              decoration: const InputDecoration(
                labelText: "Mother's Number *",
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: Validators.validatePhone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightColumn() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Academic & PG Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primaryAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _collegeController,
              decoration: const InputDecoration(
                labelText: 'College/Workplace *',
                prefixIcon: Icon(Icons.school),
              ),
              validator: (value) => Validators.validateRequired(value, 'College/Workplace'),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _hometownController,
              decoration: const InputDecoration(
                labelText: 'Hometown *',
                prefixIcon: Icon(Icons.location_city),
              ),
              validator: (value) => Validators.validateRequired(value, 'Hometown'),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Residence Address *',
                prefixIcon: Icon(Icons.home),
              ),
              maxLines: 2,
              validator: (value) => Validators.validateRequired(value, 'Address'),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _roomNumberController,
              decoration: const InputDecoration(
                labelText: 'Assign Room Number *',
                prefixIcon: Icon(Icons.meeting_room),
              ),
              keyboardType: TextInputType.number,
              validator: (value) => Validators.validateNumber(value, 'Room number'),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _advanceAmountController,
              decoration: const InputDecoration(
                labelText: 'Advance Amount *',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
              validator: (value) => Validators.validateRequired(value, 'Advance amount'),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _agreementSubmitted,
              decoration: const InputDecoration(
                labelText: 'Agreement Submitted? *',
                prefixIcon: Icon(Icons.description),
              ),
              items: ['Yes', 'No'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _agreementSubmitted = newValue!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
