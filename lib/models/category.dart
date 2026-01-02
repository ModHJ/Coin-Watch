import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class Category extends HiveObject {
  final String id;
  final String name;
  final int colorValue; // Store color as int value
  final bool isDefault; // Whether it's a default category
  final String? userId; // null for default categories, userId for custom ones

  Category({
    required this.id,
    required this.name,
    required this.colorValue,
    this.isDefault = false,
    this.userId,
  });

  Color get color => Color(colorValue);

  // Default categories
  static List<Category> getDefaultCategories() {
    return [
      Category(
        id: 'gas',
        name: 'Gas',
        colorValue: Colors.orange.value,
        isDefault: true,
      ),
      Category(
        id: 'food',
        name: 'Food & Drinks',
        colorValue: Colors.green.value,
        isDefault: true,
      ),
      Category(
        id: 'transportation',
        name: 'Transportation',
        colorValue: Colors.blue.value,
        isDefault: true,
      ),
      Category(
        id: 'entertainment',
        name: 'Entertainment',
        colorValue: Colors.purple.value,
        isDefault: true,
      ),
      Category(
        id: 'shopping',
        name: 'Shopping',
        colorValue: Colors.pink.value,
        isDefault: true,
      ),
      Category(
        id: 'bills',
        name: 'Bills & Utilities',
        colorValue: Colors.red.value,
        isDefault: true,
      ),
      Category(
        id: 'healthcare',
        name: 'Healthcare',
        colorValue: Colors.teal.value,
        isDefault: true,
      ),
      Category(
        id: 'education',
        name: 'Education',
        colorValue: Colors.indigo.value,
        isDefault: true,
      ),
      Category(
        id: 'other',
        name: 'Other',
        colorValue: Colors.grey.value,
        isDefault: true,
      ),
    ];
  }
}

// Hive Adapter for Category
class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 3;

  @override
  Category read(BinaryReader reader) {
    return Category(
      id: reader.readString(),
      name: reader.readString(),
      colorValue: reader.readInt(),
      isDefault: reader.readBool(),
      userId: reader.readBool() ? reader.readString() : null,
    );
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeInt(obj.colorValue);
    writer.writeBool(obj.isDefault);
    writer.writeBool(obj.userId != null);
    if (obj.userId != null) {
      writer.writeString(obj.userId!);
    }
  }
}

