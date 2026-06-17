import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../logic/providers/accounts_provider.dart';
import '../../logic/providers/rent_provider.dart';
import '../../data/models/expense_model.dart';

class MonthlySummarySheet extends StatefulWidget {
  const MonthlySummarySheet({super.key});

  @override
  State<MonthlySummarySheet> createState() => _MonthlySummarySheetState();
}

class _MonthlySummarySheetState extends State<MonthlySummarySheet> {
  late DateTime _selectedMonth;
  Map<String, double> _categoryTotals = {};
  double _totalExpense = 0;
  double _totalRent = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);

    final monthStr = DateFormat('yyyy-MM').format(_selectedMonth);
    final accountsProvider =
        Provider.of<AccountsProvider>(context, listen: false);
    final rentProvider = Provider.of<RentProvider>(context, listen: false);

    _categoryTotals =
        await accountsProvider.getMonthlyExpenseByCategory(monthStr);
    _totalExpense =
        await accountsProvider.getMonthlyTotalExpense(monthStr);

    // Get total rent collected
    await rentProvider.loadStudents();
    _totalRent = (await rentProvider.getCollectedRevenue()).toDouble();

    setState(() => _isLoading = false);
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
          _selectedMonth.year, _selectedMonth.month + delta, 1);
    });
    _loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(_selectedMonth);
    final profit = _totalRent - _totalExpense;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Handle ───
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ─── Month Picker ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left,
                    color: AppColors.primaryAccent),
              ),
              Text(
                monthLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right,
                    color: AppColors.primaryAccent),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else ...[
            // ─── Category Breakdown ───
            if (_categoryTotals.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    const Text('No expenses this month',
                        style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              )
            else ...[
              ..._buildCategoryRows(),
              const SizedBox(height: 16),
            ],

            // ─── Totals ───
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                children: [
                  _totalRow('Total Expenditure',
                      '₹${_totalExpense.toStringAsFixed(2)}',
                      color: AppColors.errorColor),
                  const SizedBox(height: 8),
                  _totalRow('Total Rent Received',
                      '₹${_totalRent.toStringAsFixed(2)}',
                      color: AppColors.successColor),
                  const Divider(color: AppColors.borderColor, height: 20),
                  _totalRow(
                    profit >= 0 ? 'Profit' : 'Loss',
                    '₹${profit.abs().toStringAsFixed(2)}',
                    color: profit >= 0
                        ? AppColors.successColor
                        : AppColors.errorColor,
                    bold: true,
                    icon: profit >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildCategoryRows() {
    // Sort by amount descending
    final sorted = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((entry) {
      final pct = _totalExpense > 0 ? entry.value / _totalExpense : 0.0;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _categoryColor(entry.key).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _categoryIcon(entry.key),
                    color: _categoryColor(entry.key),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(entry.key,
                      style: const TextStyle(color: AppColors.textPrimary)),
                ),
                Text(
                  '₹${entry.value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColors.cardBackground,
                valueColor: AlwaysStoppedAnimation(_categoryColor(entry.key)),
                minHeight: 4,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _totalRow(String label, String value,
      {Color? color, bool bold = false, IconData? icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: bold ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: bold ? 16 : 14,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: bold ? 20 : 14,
          ),
        ),
      ],
    );
  }
}

// ─── Shared helpers (duplicated for isolation) ───

IconData _categoryIcon(String category) {
  switch (category) {
    case 'Staff Advance':
      return Icons.person_outline;
    case 'Groceries':
      return Icons.shopping_cart;
    case 'Maintenance':
      return Icons.build;
    case 'Staff Salaries':
      return Icons.payments;
    case 'Wi-Fi':
      return Icons.wifi;
    case 'Other':
      return Icons.more_horiz;
    default:
      return Icons.receipt;
  }
}

Color _categoryColor(String category) {
  switch (category) {
    case 'Staff Advance':
      return const Color(0xFF00D9FF);
    case 'Groceries':
      return const Color(0xFF2ED573);
    case 'Maintenance':
      return const Color(0xFFFFB800);
    case 'Staff Salaries':
      return const Color(0xFF7B2FFF);
    case 'Wi-Fi':
      return const Color(0xFFFF6B81);
    case 'Other':
      return const Color(0xFF6C7A9C);
    default:
      return const Color(0xFFB0B3C1);
  }
}
