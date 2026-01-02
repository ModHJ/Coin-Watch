import 'package:uuid/uuid.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/user.dart';
import '../services/storage_service.dart';

class AuthService {
  final _uuid = const Uuid();

  /// Register a new user
  Future<User> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    // Check if user already exists
    final existingUser = StorageService.getUserByEmail(email);
    if (existingUser != null) {
      throw Exception('User with this email already exists');
    }
    
    // User doesn't exist, proceed with registration
    // Hash the password before storing
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
    
    final user = User(
      id: _uuid.v4(),
      email: email,
      password: hashedPassword,
      name: name,
    );
    await StorageService.addUser(user);
    return user;
  }

  /// Login user
  Future<User> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    final user = StorageService.getUserByEmail(email);
    if (user == null) {
      throw Exception('Invalid email or password');
    }
    
    // Verify password using bcrypt
    final isValidPassword = BCrypt.checkpw(password, user.password);
    if (!isValidPassword) {
      throw Exception('Invalid email or password');
    }
    
    await StorageService.setCurrentUser(user.id);
    await StorageService.setRememberMe(rememberMe);
    
    return user;
  }

  /// Logout user
  Future<void> logout() async {
    await StorageService.setCurrentUser(null);
  }

  /// Check if user is logged in
  Future<User?> getCurrentUser() async {
    final userId = await StorageService.getCurrentUserId();
    if (userId != null) {
      return StorageService.getUser(userId);
    }
    return null;
  }

  /// Check if remember me is enabled
  Future<bool> shouldRememberMe() async {
    return await StorageService.getRememberMe();
  }
}

