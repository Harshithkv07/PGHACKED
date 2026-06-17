import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/room_provider.dart';
import '../../core/constants/app_colors.dart';

class PriceManagerDialog extends StatefulWidget {
  const PriceManagerDialog({super.key});

  @override
  State<PriceManagerDialog> createState() => _PriceManagerDialogState();
}

class _PriceManagerDialogState extends State<PriceManagerDialog> {
  final _priceController = TextEditingController();
  final Set<int> _selectedRoomNumbers = {};
  int? _selectedCapacity;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _updateSingleRoom() async {
    if (_selectedRoomNumbers.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one room and enter a price'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final newPrice = int.tryParse(_priceController.text);
    if (newPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    for (final roomNumber in _selectedRoomNumbers) {
      await roomProvider.updateRoomPrice(roomNumber, newPrice);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedRoomNumbers.length == 1
                ? 'Room price updated successfully'
                : 'Prices updated for ${_selectedRoomNumbers.length} rooms',
          ),
          backgroundColor: AppColors.successColor,
        ),
      );
    }
  }

  Future<void> _updateByCapacity() async {
    if (_selectedCapacity == null || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a capacity and enter a price'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final newPrice = int.tryParse(_priceController.text);
    if (newPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    await Provider.of<RoomProvider>(context, listen: false)
        .updatePriceByCapacity(_selectedCapacity!, newPrice);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All $_selectedCapacity-sharing rooms updated successfully'),
          backgroundColor: AppColors.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Manager',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Rooms List
            Expanded(
              child: Consumer<RoomProvider>(
                builder: (context, roomProvider, _) {
                  final rooms = roomProvider.rooms;
                  
                  return SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        AppColors.secondaryBackground,
                      ),
                      // We render our own checkbox column; disable DataTable's built-in one
                      showCheckboxColumn: false,
                      columns: const [
                        DataColumn(label: Text('Select')),
                        DataColumn(label: Text('Room No')),
                        DataColumn(label: Text('Sharing')),
                        DataColumn(label: Text('Current Price')),
                      ],
                      rows: rooms.map((room) {
                        final isSelected =
                            _selectedRoomNumbers.contains(room.roomNumber);
                        return DataRow(
                          cells: [
                            DataCell(
                              Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedRoomNumbers.add(room.roomNumber);
                                      _selectedCapacity = room.capacity;
                                    } else {
                                      _selectedRoomNumbers.remove(room.roomNumber);
                                    }
                                  });
                                },
                              ),
                            ),
                            DataCell(Text(room.roomNumber.toString())),
                            DataCell(Text('${room.capacity}-Sharing')),
                            DataCell(Text('₹${room.price}')),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            
            // New Price Input
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'New Price',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateSingleRoom,
                    child: const Text('Update Selected'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateByCapacity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryAccent,
                    ),
                    child: const Text('Update All (Same Sharing)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
