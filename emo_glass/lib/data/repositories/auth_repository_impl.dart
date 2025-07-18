import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiService _apiService;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  AuthRepositoryImpl(this._apiService);

  @override
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.loginUser(
        email: email,
        password: password,
      );

      String? token;
      if (response['token'] != null) {
        token = response['token'].toString();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        _apiService.setToken(token);
      }

      return response;
    } catch (e) {
      print('Login repository error: $e');
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String confirmationPassword,
    required String name,
    required String role,
    String? serialNumber,
    String? specialist,
  }) async {
    try {
      final response = await _apiService.registerUser(
        email: email,
        password: password,
        confirmationPassword: confirmationPassword,
        name: name,
        role: role,
        serialNumber: serialNumber,
        specialist: specialist,
      );

      String? token;
      if (response['token'] != null) {
        token = response['token'].toString();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        _apiService.setToken(token);
      }

      return response;
    } catch (e) {
      print('Registration repository error: $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logoutUser() async {
    try {
      await _apiService.logoutUser();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      _apiService.clearToken();
      print('User logged out successfully');
    } catch (e) {
      print('Logout error: $e');
      _apiService.clearToken();
    }
  }

  @override
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiService.getProfile();
      return response;
    } catch (e) {
      print('Get profile error: $e');
      throw Exception('Failed to get profile: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    String? email,
    String? name,
    String? serialNumber,
    String? specialist,
    String? assignedDoctor,
    String? status,
  }) async {
    try {
      final response = await _apiService.updateProfile(
        email: email,
        name: name,
        serialNumber: serialNumber,
        specialist: specialist,
        assignedDoctor: assignedDoctor,
        status: status,
      );
      return response;
    } catch (e) {
      print('Update profile error: $e');
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token != null) {
        try {
          _apiService.setToken(token);
          final profileData = await _apiService.getProfile();
          final userModel = UserModel.fromJson(profileData);
          await prefs.setString(_userKey, jsonEncode(userModel.toJson()));

          return User(
            id: userModel.id,
            email: userModel.email,
            name: userModel.name,
            role: userModel.role,
            serialNumber: userModel.serialNumber,
            specialist: userModel.specialist,
            assignedDoctor: userModel.assignedDoctor,
            status: userModel.status,
          );
        } catch (e) {
          print('Token validation or profile fetch failed: $e');
          await logoutUser();
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Get current user error: $e');
      await logoutUser();
      return null;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userData = prefs.getString(_userKey);
      return token != null && userData != null;
    } catch (e) {
      print('Check login status error: $e');
      return false;
    }
  }
}
