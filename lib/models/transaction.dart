import 'package:hive/hive.dart';

class Transaction extends HiveObject {
  final String id;
  final String userId; // Associate transaction with user
  final String description;
  final double unitPrice;
  final int quantity;
  final double total;
  final DateTime date;
  final TransactionType type;
  final String currency; // Make currency required
  final String? categoryId; // Optional category

  Transaction({
    required this.id,
    required this.userId,
    required this.description,
    required this.unitPrice,
    required this.quantity,
    required this.total,
    required this.date,
    required this.type,
    required this.currency,
    this.categoryId,
  });

  // Factory constructor for creating adjustment entries
  factory Transaction.adjustment({
    required String id,
    required String userId,
    required double amount,
    required DateTime date,
    required String currency,
    String? description,
  }) {
    return Transaction(
      id: id,
      userId: userId,
      description: description ?? 'Balance Adjustment',
      unitPrice: amount,
      quantity: 1,
      total: amount,
      date: date,
      type: amount >= 0 ? TransactionType.income : TransactionType.expense,
      currency: currency,
    );
  }
}

enum TransactionType {
  income,
  expense,
}

// Hive Adapter for Transaction
class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 0;

  @override
  Transaction read(BinaryReader reader) {
    return Transaction(
      id: reader.readString(),
      userId: reader.readString(),
      description: reader.readString(),
      unitPrice: reader.readDouble(),
      quantity: reader.readInt(),
      total: reader.readDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      type: TransactionType.values[reader.readInt()],
      currency: reader.readString(),
      categoryId: reader.readBool() ? reader.readString() : null,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.userId);
    writer.writeString(obj.description);
    writer.writeDouble(obj.unitPrice);
    writer.writeInt(obj.quantity);
    writer.writeDouble(obj.total);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeInt(obj.type.index);
    writer.writeBool(true); // Currency is always present now
    writer.writeString(obj.currency);
    writer.writeBool(obj.categoryId != null);
    if (obj.categoryId != null) {
      writer.writeString(obj.categoryId!);
    }
  }
}

// Hive Adapter for TransactionType
class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = 1;

  @override
  TransactionType read(BinaryReader reader) {
    return TransactionType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    writer.writeInt(obj.index);
  }
}

