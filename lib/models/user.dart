import 'package:hive/hive.dart';

class User extends HiveObject {
  final String id;
  final String email;
  final String password; // Stored as bcrypt hash
  final String? name;

  User({
    required this.id,
    required this.email,
    required this.password,
    this.name,
  });
}

// Hive Adapter for User
class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 2;

  @override
  User read(BinaryReader reader) {
    return User(
      id: reader.readString(),
      email: reader.readString(),
      password: reader.readString(),
      name: reader.readBool() ? reader.readString() : null,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.email);
    writer.writeString(obj.password);
    writer.writeBool(obj.name != null);
    if (obj.name != null) {
      writer.writeString(obj.name!);
    }
  }
}

