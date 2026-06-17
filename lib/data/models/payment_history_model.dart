class PaymentHistoryModel {
  final int? id;
  final int studentId;
  final String month; // Format: YYYY-MM
  final String paymentStatus; // 'Paid' or 'Pending'
  final String paymentMode; // 'Cash', 'UPI', or '-'
  final String? screenshotPath;
  final String? paidDate; // Format: DD/MM/YYYY

  PaymentHistoryModel({
    this.id,
    required this.studentId,
    required this.month,
    required this.paymentStatus,
    required this.paymentMode,
    this.screenshotPath,
    this.paidDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'month': month,
      'payment_status': paymentStatus,
      'payment_mode': paymentMode,
      'screenshot_path': screenshotPath,
      'paid_date': paidDate,
    };
  }

  factory PaymentHistoryModel.fromMap(Map<String, dynamic> map) {
    return PaymentHistoryModel(
      id: map['id'] as int?,
      studentId: map['student_id'] as int,
      month: map['month'] as String,
      paymentStatus: map['payment_status'] as String,
      paymentMode: map['payment_mode'] as String,
      screenshotPath: map['screenshot_path'] as String?,
      paidDate: map['paid_date'] as String?,
    );
  }

  PaymentHistoryModel copyWith({
    int? id,
    int? studentId,
    String? month,
    String? paymentStatus,
    String? paymentMode,
    String? screenshotPath,
    String? paidDate,
  }) {
    return PaymentHistoryModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      month: month ?? this.month,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMode: paymentMode ?? this.paymentMode,
      screenshotPath: screenshotPath ?? this.screenshotPath,
      paidDate: paidDate ?? this.paidDate,
    );
  }
}
