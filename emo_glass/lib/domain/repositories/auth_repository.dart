import '../entities/user.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  });
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String confirmationPassword,
    required String name,
    required String role,
    String? serialNumber,
    String? specialist,
  });
  Future<void> logoutUser();
  Future<User?> getCurrentUser();
  Future<bool> isLoggedIn();
  Future<Map<String, dynamic>> getProfile();
  Future<Map<String, dynamic>> updateProfile({
    String? email,
    String? name,
    String? serialNumber,
    String? specialist,
    String? assignedDoctor,
    String? status,
  });
}
