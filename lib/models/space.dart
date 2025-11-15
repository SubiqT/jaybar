class Space {
  final int index;
  final bool hasFocus;
  final bool isOccupied;
  
  Space({
    required this.index,
    required this.hasFocus,
    required this.isOccupied,
  });
  
  factory Space.fromJson(Map<String, dynamic> json) {
    return Space(
      index: json['index'],
      hasFocus: json['has-focus'] ?? false,
      isOccupied: (json['windows'] as List?)?.isNotEmpty ?? false,
    );
  }
}
