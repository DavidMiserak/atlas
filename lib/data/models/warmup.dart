class WarmupItem {
  final int? id;
  final String name;
  final int reps;
  final int orderIndex;

  WarmupItem({
    this.id,
    required this.name,
    required this.reps,
    required this.orderIndex,
  });

  WarmupItem.fromMap(Map<String, dynamic> map)
      : id = map['warmup_item_id'],
        name = map['name'],
        reps = map['reps'],
        orderIndex = map['order_index'];

  Map<String, dynamic> toMap() {
    return {
      'warmup_item_id': id,
      'name': name,
      'reps': reps,
      'order_index': orderIndex,
    };
  }
}
