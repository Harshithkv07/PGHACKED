class StudentModel {
  final int? id;
  final int roomNumber;
  final String name;
  final String dob;
  final String contact;
  final String fatherName;
  final String fatherNumber;
  final String motherName;
  final String motherNumber;
  final String college;
  final String hometown;
  final String address;
  final String advanceAmount;
  final String agreementSubmitted;
  final String rentStatus;
  final String paymentMode;

  StudentModel({
    this.id,
    required this.roomNumber,
    required this.name,
    required this.dob,
    required this.contact,
    required this.fatherName,
    required this.fatherNumber,
    required this.motherName,
    required this.motherNumber,
    required this.college,
    required this.hometown,
    required this.address,
    required this.advanceAmount,
    required this.agreementSubmitted,
    this.rentStatus = 'Pending',
    this.paymentMode = '-',
  });

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room_number': roomNumber,
      'name': name,
      'dob': dob,
      'contact': contact,
      'father_name': fatherName,
      'father_number': fatherNumber,
      'mother_name': motherName,
      'mother_number': motherNumber,
      'college': college,
      'hometown': hometown,
      'address': address,
      'advance_amount': advanceAmount,
      'agreement_submitted': agreementSubmitted,
      'rent_status': rentStatus,
      'payment_mode': paymentMode,
    };
  }

  // Create from Map
  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'],
      roomNumber: map['room_number'],
      name: map['name'],
      dob: map['dob'],
      contact: map['contact'],
      fatherName: map['father_name'],
      fatherNumber: map['father_number'],
      motherName: map['mother_name'],
      motherNumber: map['mother_number'],
      college: map['college'],
      hometown: map['hometown'],
      address: map['address'],
      advanceAmount: map['advance_amount'],
      agreementSubmitted: map['agreement_submitted'],
      rentStatus: map['rent_status'] ?? 'Pending',
      paymentMode: map['payment_mode'] ?? '-',
    );
  }

  // Copy with method for updates
  StudentModel copyWith({
    int? id,
    int? roomNumber,
    String? name,
    String? dob,
    String? contact,
    String? fatherName,
    String? fatherNumber,
    String? motherName,
    String? motherNumber,
    String? college,
    String? hometown,
    String? address,
    String? advanceAmount,
    String? agreementSubmitted,
    String? rentStatus,
    String? paymentMode,
  }) {
    return StudentModel(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      contact: contact ?? this.contact,
      fatherName: fatherName ?? this.fatherName,
      fatherNumber: fatherNumber ?? this.fatherNumber,
      motherName: motherName ?? this.motherName,
      motherNumber: motherNumber ?? this.motherNumber,
      college: college ?? this.college,
      hometown: hometown ?? this.hometown,
      address: address ?? this.address,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      agreementSubmitted: agreementSubmitted ?? this.agreementSubmitted,
      rentStatus: rentStatus ?? this.rentStatus,
      paymentMode: paymentMode ?? this.paymentMode,
    );
  }
}
