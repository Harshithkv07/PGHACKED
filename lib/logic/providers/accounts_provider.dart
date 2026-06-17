import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/daily_account_model.dart';
import '../../data/database/accounts_repository.dart';
import '../../data/database/database_helper.dart';

class AccountsProvider with ChangeNotifier {
  final AccountsRepository _repo = AccountsRepository();

  DateTime _selectedDate = DateTime.now();
  DailyAccountModel? _todayAccount;
  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;

  DateTime get selectedDate => _selectedDate;
  DailyAccountModel? get todayAccount => _todayAccount;
  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;

  String get selectedDateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get selectedMonthStr => DateFormat('yyyy-MM').format(_selectedDate);

  double get totalExpensesToday =>
      _expenses.fold(0, (sum, e) => sum + e.amount);

  double get remainingBalance {
    if (_todayAccount == null) return 0;
    return _todayAccount!.openingBalance - totalExpensesToday;
  }

  bool get isDayClosed => _todayAccount?.isDayClosed ?? false;

  /// Load account and expenses for the selected date.
  Future<void> loadDay([DateTime? date]) async {
    if (date != null) _selectedDate = date;
    _isLoading = true;
    notifyListeners();

    final dateStr = selectedDateStr;
    _todayAccount = await _repo.getDailyAccount(dateStr);
    _expenses = await _repo.getExpensesForDate(dateStr);

    _isLoading = false;
    notifyListeners();
  }

  /// Get previous day's closing balance (for carry-forward suggestion).
  Future<double?> getPreviousClosingBalance() async {
    final prev = await _repo.getPreviousClosedDay(selectedDateStr);
    return prev?.closingBalance;
  }

  /// Get previous day (closed or open).
  Future<DailyAccountModel?> getPreviousDay() async {
    return await _repo.getPreviousDay(selectedDateStr);
  }

  /// Create or update the opening balance for the selected day.
  Future<void> setOpeningBalance(double amount) async {
    final dateStr = selectedDateStr;

    if (_todayAccount == null) {
      final id = await _repo.insertDailyAccount(DailyAccountModel(
        date: dateStr,
        openingBalance: amount,
      ));
      _todayAccount = DailyAccountModel(
        id: id,
        date: dateStr,
        openingBalance: amount,
      );
    } else {
      final updated = _todayAccount!.copyWith(openingBalance: amount);
      await _repo.updateDailyAccount(updated);
      _todayAccount = updated;
    }
    notifyListeners();
  }

  /// Add a new expense.
  Future<void> addExpense(double amount, String category, String note) async {
    final expense = ExpenseModel(
      date: selectedDateStr,
      amount: amount,
      category: category,
      note: note,
      createdAt: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    );
    final id = await _repo.insertExpense(expense);
    _expenses.insert(0, expense.copyWith(id: id));
    notifyListeners();
  }

  /// Update an existing expense.
  Future<void> updateExpense(ExpenseModel expense) async {
    await _repo.updateExpense(expense);
    final idx = _expenses.indexWhere((e) => e.id == expense.id);
    if (idx != -1) {
      _expenses[idx] = expense;
      notifyListeners();
    }
  }

  /// Delete an expense.
  Future<void> deleteExpense(int id) async {
    await _repo.deleteExpense(id);
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// Close the day: compute closing balance and mark as closed.
  Future<void> closeDay() async {
    if (_todayAccount == null) return;

    final total = await _repo.getTotalExpensesForDate(selectedDateStr);
    final closingBalance = _todayAccount!.openingBalance - total;

    final updated = _todayAccount!.copyWith(
      closingBalance: closingBalance,
      isDayClosed: true,
    );
    await _repo.updateDailyAccount(updated);
    _todayAccount = updated;
    notifyListeners();
  }

  /// Reopen a closed day (undo close, same day only).
  Future<void> reopenDay() async {
    if (_todayAccount == null || !_todayAccount!.isDayClosed) return;

    final updated = _todayAccount!.copyWith(
      closingBalance: null,
      isDayClosed: false,
    );
    // We need to handle null closingBalance in update
    final db = await DatabaseHelper().database;
    await db.update(
      'daily_accounts',
      {
        'closing_balance': null,
        'is_day_closed': 0,
      },
      where: 'id = ?',
      whereArgs: [_todayAccount!.id],
    );
    _todayAccount = DailyAccountModel(
      id: updated.id,
      date: updated.date,
      openingBalance: updated.openingBalance,
      closingBalance: null,
      isDayClosed: false,
    );
    notifyListeners();
  }

  // ─── Navigation ───

  void goToPreviousDay() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    loadDay();
  }

  void goToNextDay() {
    final tomorrow = _selectedDate.add(const Duration(days: 1));
    if (tomorrow.isAfter(DateTime.now())) return; // Can't go to future
    _selectedDate = tomorrow;
    loadDay();
  }

  bool get canGoToNextDay {
    final tomorrow = _selectedDate.add(const Duration(days: 1));
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final tomorrowDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    return !tomorrowDate.isAfter(todayDate);
  }

  bool get isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  // ─── Monthly Summary ───

  Future<Map<String, double>> getMonthlyExpenseByCategory(
      [String? month]) async {
    return _repo.getMonthlyExpenseByCategory(month ?? selectedMonthStr);
  }

  Future<double> getMonthlyTotalExpense([String? month]) async {
    return _repo.getMonthlyTotalExpense(month ?? selectedMonthStr);
  }

  Future<List<DailyAccountModel>> getDailyAccountsForMonth(
      [String? month]) async {
    return _repo.getDailyAccountsForMonth(month ?? selectedMonthStr);
  }
}
