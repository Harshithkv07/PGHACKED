class RoomConfigModel {
  final int roomNumber;
  final int capacity;
  final int price;

  RoomConfigModel({
    required this.roomNumber,
    required this.capacity,
    required this.price,
  });

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'room_number': roomNumber,
      'capacity': capacity,
      'price': price,
    };
  }

  // Create from Map
  factory RoomConfigModel.fromMap(Map<String, dynamic> map) {
    return RoomConfigModel(
      roomNumber: map['room_number'],
      capacity: map['capacity'],
      price: map['price'],
    );
  }

  // Copy with method for updates
  RoomConfigModel copyWith({
    int? roomNumber,
    int? capacity,
    int? price,
  }) {
    return RoomConfigModel(
      roomNumber: roomNumber ?? this.roomNumber,
      capacity: capacity ?? this.capacity,
      price: price ?? this.price,
    );
  }
}
