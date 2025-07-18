import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:http_parser/http_parser.dart';
import '../models/patient_model.dart';
import '../models/user_model.dart';
import '../../core/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final String _baseUrl = 'https://368b-154-191-181-230.ngrok-free.app';
  final String _fallbackUrl = 'https://368b-154-191-181-230.ngrok-free.app';
  bool _usingFallback = false;

  // Public getter for base URL
  String get baseUrl => _usingFallback ? _fallbackUrl : _baseUrl;

  // Private constructor
  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        validateStatus: (status) => status! < 500,
        headers: {
          'Connection': 'close', // Force HTTP/1.1
          'ngrok-skip-browser-warning': 'true',
          'User-Agent': 'Flutter-EmoGlasses-App',
        },
      ),
    );

    // Configure HTTP adapter for TLS compatibility with ngrok
    if (Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) {
          // Allow all certificates for ngrok in debug mode
          if (kDebugMode && host.contains('ngrok')) {
            print('🔐 Allowing certificate for ngrok host: $host');
            return true;
          }
          return false;
        };
        return client;
      };
    }

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }

          if (ApiConstants.debugMode) {
            print('🌐 API Request: ${options.method} ${options.path}');
            print('🌐 Request URL: ${options.uri}');
            print('🌐 Request Headers: ${options.headers}');
            if (options.data != null) {
              print('🌐 Request Data: ${options.data}');
            }
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          if (ApiConstants.debugMode) {
            print(
              '✅ API Response: ${response.statusCode} ${response.requestOptions.path}',
            );
            print('✅ Response Data: ${response.data}');
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          if (ApiConstants.debugMode) {
            print(
              '❌ API Error: ${error.response?.statusCode} ${error.requestOptions.path}',
            );
            print('❌ Error details: ${error.message}');
          }

          // Handle connection errors with retry logic
          if (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout) {
            // Try switching to fallback URL if using main URL
            if (!_usingFallback) {
              _usingFallback = true;
              _dio.options.baseUrl = _fallbackUrl;
              print('🔄 Switching to fallback URL: $_fallbackUrl');

              // Retry the request with fallback URL
              try {
                final retryResponse = await _dio.request(
                  error.requestOptions.path,
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                  options: Options(
                    method: error.requestOptions.method,
                    headers: error.requestOptions.headers,
                  ),
                );
                return handler.resolve(retryResponse);
              } catch (retryError) {
                print('❌ Fallback request also failed: $retryError');
              }
            }

            // If both URLs fail, try retrying a few times
            if (ApiConstants.maxRetries > 0) {
              for (int i = 0; i < ApiConstants.maxRetries; i++) {
                print('🔄 Retry attempt ${i + 1}/${ApiConstants.maxRetries}');
                await Future.delayed(
                  Duration(seconds: ApiConstants.retryDelay),
                );

                try {
                  final retryResponse = await _dio.request(
                    error.requestOptions.path,
                    data: error.requestOptions.data,
                    queryParameters: error.requestOptions.queryParameters,
                    options: Options(
                      method: error.requestOptions.method,
                      headers: error.requestOptions.headers,
                    ),
                  );
                  return handler.resolve(retryResponse);
                } catch (retryError) {
                  print('❌ Retry ${i + 1} failed: $retryError');
                }
              }
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  String? _token;

  void setToken(String token) {
    _token = token;
    print('🔑 Token set: ${token.substring(0, 20)}...');
  }

  void clearToken() {
    _token = null;
    print('🔑 Token cleared');
  }

  String? get token => _token;

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
      final data = {
        'email': email,
        'password': password,
        'confirmationPassword': confirmationPassword,
        'name': name,
        'role': role,
        if (serialNumber != null) 'serialNumber': serialNumber,
        if (specialist != null) 'specialist': specialist,
      };

      print('🔐 Registering user with data: $data');
      print('🔐 Registration URL: ${_dio.options.baseUrl}/api/users');

      final response = await _dio.post('/api/users', data: data);

      print('🔐 Registration response status: ${response.statusCode}');
      print('🔐 Registration response data type: ${response.data.runtimeType}');
      print('🔐 Registration response data: ${response.data}');

      // Check if response.data is the user object directly or wrapped
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        print('🔐 Response keys: ${responseMap.keys.toList()}');

        // Based on Postman collection: Registration returns user object directly
        // Need to wrap it in 'user' field for consistency with AuthNotifier
        if (responseMap.containsKey('_id') || responseMap.containsKey('id')) {
          print(
            '🔐 Direct user object detected (registration response), wrapping in user field',
          );
          return {
            'user': responseMap,
            'token': null, // Registration doesn't return token
          };
        }

        // If the backend already wraps it correctly (like login response)
        if (responseMap.containsKey('user')) {
          print('🔐 User field found in response');
          return responseMap;
        }

        // Return as-is for other cases
        return responseMap;
      }

      return response.data;
    } catch (e) {
      print('❌ Registration error details: $e');
      if (e is DioException) {
        print('❌ Status code: ${e.response?.statusCode}');
        print('❌ Response data: ${e.response?.data}');
        print('❌ Error type: ${e.type}');
        print('❌ Error message: ${e.message}');
      }
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final data = {'email': email, 'password': password};
      print('🔐 Logging in user with email: $email');
      print('🔐 Login URL: ${_dio.options.baseUrl}/api/users/login');

      final response = await _dio.post('/api/users/login', data: data);
      print('🔐 Login response status: ${response.statusCode}');
      print('🔐 Login response data: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        print('🔐 Login response keys: ${responseMap.keys.toList()}');

        // Set token if available
        if (responseMap['token'] != null) {
          setToken(responseMap['token']);
          print('🔐 Token set successfully');
        }

        // Based on Postman collection: Login returns {user: {...}, token: "..."}
        if (responseMap.containsKey('user') &&
            responseMap.containsKey('token')) {
          print('🔐 Login response format correct');
          return responseMap;
        }

        // Handle edge case if response format is different
        return responseMap;
      }

      return response.data;
    } catch (e) {
      print('❌ Login error details: $e');
      if (e is DioException) {
        print('❌ Status code: ${e.response?.statusCode}');
        print('❌ Response data: ${e.response?.data}');
        print('❌ Error type: ${e.type}');
        print('❌ Error message: ${e.message}');
      }
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      print('Getting profile with token: ${_token?.substring(0, 20)}...');
      final response = await _dio.get('/api/profile');
      print('Profile response: ${response.data}');

      // Check if this is a patient and handle status
      if (response.data['role'] == 'patient') {
        final hasAssignedDoctor = response.data['assignedDoctor'] != null;
        final currentStatus = response.data['status'];

        // If no assigned doctor and status is not inactive, update to inactive
        if (!hasAssignedDoctor && currentStatus != 'inactive') {
          print('No assigned doctor found, updating status to inactive');
          await updateProfile(
            email: response.data['email'],
            name: response.data['name'],
            status: 'inactive',
            serialNumber: response.data['serialNumber'],
          );

          // Get updated profile
          final updatedResponse = await _dio.get('/api/profile');
          return updatedResponse.data;
        }
      }

      return response.data;
    } catch (e) {
      print('Get profile error: $e');
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPatient(String patientId) async {
    try {
      print('Getting patient data for ID: $patientId');
      final response = await _dio.get('/api/patients/$patientId');
      print('Patient data response: ${response.data}');
      return response.data;
    } catch (e) {
      print('Get patient error: $e');
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? email,
    String? name,
    String? serialNumber,
    String? specialist,
    String? assignedDoctor,
    String? status,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (email != null) data['email'] = email;
      if (name != null) data['name'] = name;
      if (serialNumber != null) data['serialNumber'] = serialNumber;
      if (specialist != null) data['specialist'] = specialist;
      if (assignedDoctor != null) data['assignedDoctor'] = assignedDoctor;
      if (status != null) data['status'] = status;

      print('Updating profile with data: $data');
      final response = await _dio.put('/api/profile', data: data);
      print('Update profile response: ${response.data}');

      return response.data;
    } catch (e) {
      print('Update profile error: $e');
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updatePatientStatus(
    String patientId,
    String status,
  ) async {
    try {
      print('Updating status for patient $patientId to $status');
      final response = await _dio.put(
        '/api/patients/$patientId/status',
        data: {'status': status},
      );
      print('Update status response: ${response.data}');
      return response.data;
    } catch (e) {
      print('Update patient status error: $e');
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> uploadAudio(
    File audioFile, {
    DateTime? recordingTime,
  }) async {
    try {
      // Validate file before upload
      if (!await audioFile.exists()) {
        throw Exception('Audio file does not exist');
      }

      final fileSize = await audioFile.length();
      if (fileSize < 10) {
        throw Exception('Audio file is too small or corrupted');
      }

      print('📤 Starting audio upload to backend...');
      print('📤 File path: ${audioFile.path}');
      print('📤 File size: ${fileSize} bytes');
      print('📤 File extension: ${audioFile.path.split('.').last}');
      print('📤 Backend URL: ${_dio.options.baseUrl}');

      // Use provided recording time or current time
      final uploadTime = recordingTime ?? DateTime.now();
      print('📤 Recording timestamp: ${uploadTime.toIso8601String()}');

      // Add retry logic for upload
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          print('📤 Upload attempt ${retryCount + 1}/$maxRetries');

          // Create a new FormData object for each attempt to avoid reuse issues
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileExtension = audioFile.path.split('.').last.toLowerCase();
          final filename = 'audio_$timestamp.$fileExtension';

          print('📤 Creating FormData with filename: $filename');
          print('📤 File extension detected: $fileExtension');

          // Determine content type based on file extension
          String contentType;
          if (fileExtension == 'mp3') {
            contentType = 'audio/mpeg';
          } else if (fileExtension == 'wav') {
            contentType = 'audio/wav';
          } else {
            contentType = 'audio/mpeg'; // Default to MP3
          }

          print('📤 Content type: $contentType');

          // Include recording timestamp in the FormData
          final formData = FormData.fromMap({
            'audio': await MultipartFile.fromFile(
              audioFile.path,
              filename: filename,
              contentType: MediaType.parse(contentType),
            ),
            'recordingTime': uploadTime.toIso8601String(), // Add timestamp
            'uploadedAt':
                uploadTime.toIso8601String(), // Alternative field name
            'timestamp':
                uploadTime.millisecondsSinceEpoch.toString(), // Epoch timestamp
          });

          print('📤 FormData created successfully');
          print('📤 FormData fields: ${formData.fields}');
          print('📤 FormData files: ${formData.files}');
          print('📤 Timestamp included: ${uploadTime.toIso8601String()}');

          final response = await _dio.post(
            '/api/audio/upload',
            data: formData,
            options: Options(
              sendTimeout: Duration(
                seconds: 30,
              ), // Longer timeout for file uploads
              receiveTimeout: Duration(seconds: 30),
              headers: {'Content-Type': 'multipart/form-data'},
            ),
          );

          print('✅ Audio upload successful: ${response.statusCode}');
          print('✅ Response data: ${response.data}');

          // After successful upload, refresh the profile to get updated records
          await getProfile();

          return {
            'success': true,
            'statusCode': response.statusCode,
            'message': 'Audio uploaded successfully',
            'data': response.data,
            'uploadTime': uploadTime.toIso8601String(),
          };
        } catch (uploadError) {
          retryCount++;
          print('❌ Upload attempt $retryCount failed: $uploadError');

          // Check if it's a server-side file type validation error
          if (uploadError.toString().contains('Invalid file type')) {
            throw Exception(
              'Server rejected file type. Please ensure the audio file is in MP3 or WAV format.',
            );
          }

          if (retryCount >= maxRetries) {
            throw Exception(
              'Audio upload failed after $maxRetries attempts: $uploadError',
            );
          }

          // Wait before retry
          await Future.delayed(Duration(seconds: 2 * retryCount));
        }
      }

      throw Exception('Audio upload failed');
    } catch (e) {
      print('❌ Audio upload error: $e');
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> uploadImageFromESP32(
    File imageFile,
    String serialNumber,
  ) async {
    try {
      print('📤 Uploading image from ESP32: ${imageFile.path}');
      print('📤 Serial number: $serialNumber');
      print('📤 Backend URL: ${_dio.options.baseUrl}');

      // Validate file before upload
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final fileSize = await imageFile.length();
      if (fileSize < 10) {
        throw Exception('Image file is too small or corrupted');
      }

      print('📤 File size: ${fileSize} bytes');

      // Create form data with image file - matching Postman collection
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename:
              'glasses_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType.parse('image/jpeg'),
        ),
      });

      final response = await _dio.post(
        '/api/images/upload-image-esp32/$serialNumber',
        data: formData,
        options: Options(
          sendTimeout: Duration(seconds: 30),
          receiveTimeout: Duration(seconds: 30),
        ),
      );

      print('✅ ESP32 image upload successful: ${response.statusCode}');
      print('✅ Response data: ${response.data}');

      return response.data;
    } catch (e) {
      print('❌ ESP32 image upload error: $e');
      throw _handleError(e);
    }
  }

  Future<List<PatientModel>> getPatients() async {
    try {
      print(
        'Getting patients list (attempt 1) with token: ${_token?.substring(0, 20)}...',
      );
      final response = await _dio.get('/api/patients');
      print('Patients response: ${response.data}');

      if (response.data is List) {
        final List<dynamic> patientsData = response.data;
        return patientsData.map((json) => PatientModel.fromJson(json)).toList();
      } else {
        print('Unexpected response format: ${response.data}');
        return [];
      }
    } catch (e) {
      print('Get patients error: $e');
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPatientDetails(String patientId) async {
    try {
      print('Getting patient details for ID: $patientId');
      final response = await _dio.get('/api/patients/$patientId');
      print('Patient details response: ${response.data}');

      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Get patient details error: $e');
      throw _handleError(e);
    }
  }

  Future<void> updateNotificationSettings(Map<String, dynamic> settings) async {
    try {
      await _dio.put('/api/notification-settings', data: settings);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> testConnection() async {
    try {
      print('🔗 Testing API connection to: ${_dio.options.baseUrl}');

      // Test multiple endpoints to find one that works
      final testEndpoints = [
        '/api/users', // Registration endpoint
        '/api/doctors', // Doctors endpoint
        '/api/patients', // Patients endpoint
        '/', // Root endpoint
      ];

      for (final endpoint in testEndpoints) {
        try {
          print('🔗 Testing endpoint: $endpoint');
          final response = await _dio.get(
            endpoint,
            options: Options(
              validateStatus: (status) => status! < 500,
              sendTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );

          print('🔗 Response for $endpoint: ${response.statusCode}');

          // Accept various success status codes
          if ([200, 201, 404, 401, 403].contains(response.statusCode)) {
            print(
              '✅ Connection successful via $endpoint (status: ${response.statusCode})',
            );
            return true;
          }
        } catch (endpointError) {
          print('🔗 Endpoint $endpoint failed: $endpointError');
          continue; // Try next endpoint
        }
      }

      print('❌ All test endpoints failed');
      return false;
    } catch (e) {
      print('❌ API connection test error: $e');
      return false;
    }
  }

  // Helper method to check and update connection status
  Future<bool> checkConnection() async {
    if (!_usingFallback) {
      final mainUrlWorks = await testConnection();
      if (mainUrlWorks) {
        return true;
      }

      // Try fallback URL
      print('🔄 Main URL failed, trying fallback URL...');
      _usingFallback = true;
      _dio.options.baseUrl = _fallbackUrl;
      final fallbackWorks = await testConnection();

      if (!fallbackWorks) {
        // Reset to main URL if both fail
        _usingFallback = false;
        _dio.options.baseUrl = _baseUrl;
      }

      return fallbackWorks;
    }
    return await testConnection();
  }

  Future<UserModel> getDoctorDetails(dynamic doctorId) async {
    try {
      print('Fetching doctor details for ID: $doctorId');
      final id =
          doctorId is Map
              ? doctorId['_id'] ?? doctorId['id']
              : doctorId.toString();

      print('Searching for doctor with ID: $id');
      // Fetch all doctors and find the one with the matching ID
      final allDoctors = await getDoctors();
      final doctor = allDoctors.firstWhere(
        (doc) => doc.id == id,
        orElse:
            () =>
                throw Exception(
                  'Doctor with ID $id not found in the list of all doctors',
                ),
      );

      print('Successfully found doctor details: ${doctor.name}');
      return doctor;
    } catch (e) {
      print('Get doctor details error: $e');
      throw _handleError(e);
    }
  }

  Future<List<UserModel>> getDoctors() async {
    try {
      print('Getting doctors list...');
      final response = await _dio.get('/api/doctors');
      if (response.data is! List) {
        throw Exception('Invalid response format from getDoctors');
      }
      final List<dynamic> doctorsData = response.data;
      return doctorsData
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get doctors error: $e');
      throw _handleError(e);
    }
  }

  Future<void> assignPatientToDoctor({
    required String doctorId,
    required String patientId,
  }) async {
    try {
      print('Assigning patient $patientId to doctor $doctorId...');
      final response = await _dio.post(
        '/api/doctors/$doctorId/request-assign',
        data: {'patientId': patientId},
      );
      print('Assign response: ${response.data}');
    } catch (e) {
      print('Assign patient error: ${e.toString()}');
      throw _handleError(e);
    }
  }

  Future<void> requestAssignmentToDoctor({required String doctorId}) async {
    try {
      print('Requesting assignment to doctor: $doctorId');

      // Get current user profile to get patient ID
      final profile = await getProfile();
      print('Current user profile: $profile');

      final patientId = profile['_id'] ?? profile['id'];
      print('Extracted patient ID: $patientId');

      if (patientId == null) {
        throw Exception('Unable to get current user ID');
      }

      // Check if patient already has an active doctor
      if (profile['assignedDoctor'] != null) {
        throw Exception('You already have an active doctor');
      }

      final requestData = {'patientId': patientId};
      print(
        'Sending assignment request for patient $patientId to doctor $doctorId',
      );
      print('Request data: $requestData');
      print('Request URL: /api/doctors/$doctorId/request-assign');

      final response = await _dio.post(
        '/api/doctors/$doctorId/request-assign',
        data: requestData,
      );

      print('Assignment request response: ${response.data}');

      // After successful request, update profile to ensure status is correct
      await getProfile();

      print('Assignment request sent successfully');
    } catch (e) {
      print('Request assignment error: $e');
      if (e is DioException) {
        print('DioException details:');
        print('  - Status code: ${e.response?.statusCode}');
        print('  - Response data: ${e.response?.data}');
        print('  - Request data: ${e.requestOptions.data}');
        print('  - Request URL: ${e.requestOptions.uri}');
        print('  - Request headers: ${e.requestOptions.headers}');

        if (e.response?.statusCode == 400) {
          final message = e.response?.data['message'] ?? 'Bad request';
          throw Exception(message);
        }
      }
      throw _handleError(e);
    }
  }

  Future<String?> _getCurrentUserId() async {
    try {
      final profile = await getProfile();
      return profile['_id'] ?? profile['id'];
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  Future<void> logoutUser() async {
    try {
      print('Logging out user...');
      await _dio.post('/api/users/logout');
      clearToken();
    } catch (e) {
      print('Logout error: $e');
      clearToken();
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getDoctorAssignmentRequests() async {
    try {
      print('Fetching doctor assignment requests...');
      final response = await _dio.get('/api/doctors/requests');
      return response.data as List<dynamic>;
    } catch (e) {
      print('Get assignment requests error: $e');
      throw _handleError(e);
    }
  }

  Future<void> acceptAssignmentRequest(String requestId) async {
    try {
      print('Accepting assignment request: $requestId');
      final response = await _dio.post('/api/requests/$requestId/accept');

      // After successful acceptance, update patient status to active
      if (response.data is Map<String, dynamic> &&
          response.data['patientId'] != null) {
        await updatePatientStatus(response.data['patientId'], 'active');

        // Update the patient's profile to ensure status is correct
        await getProfile();
      }
    } catch (e) {
      print('Accept assignment error: $e');
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final response = await _dio.get('/api/notification-settings');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await _dio.get('/api/notifications');

      // Check if the response is successful and contains data
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          return response.data as List<dynamic>;
        } else if (response.data is Map<String, dynamic>) {
          // If it's an error response, return empty list
          final responseMap = response.data as Map<String, dynamic>;
          if (responseMap.containsKey('message') &&
              responseMap.containsKey('errors')) {
            print('⚠️ API returned error response: ${responseMap['message']}');
            return [];
          }
          // If it's a wrapped response like {notifications: [...]}
          if (responseMap.containsKey('notifications')) {
            return responseMap['notifications'] as List<dynamic>;
          }
        }
      }

      // If we get here, return empty list
      print('⚠️ Unexpected notification response format: ${response.data}');
      return [];
    } catch (e) {
      print('⚠️ Get notifications error: $e');
      // Return empty list instead of throwing to prevent app crashes
      return [];
    }
  }

  Future<List<dynamic>> getAssignedPatients() async {
    try {
      print('Fetching assigned patients...');
      final response = await _dio.get('/api/doctors/assigned-patients');
      return response.data as List<dynamic>;
    } catch (e) {
      print('Get assigned patients error: $e');
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> searchDoctors(String query) async {
    try {
      print('Searching doctors with query: $query');
      final response = await _dio.get(
        '/api/doctors/search',
        queryParameters: {'q': query},
      );
      return response.data as List<dynamic>;
    } catch (e) {
      print('Search doctors error: $e');
      throw _handleError(e);
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      print('Marking notification $notificationId as read...');
      await _dio.put('/api/notifications/$notificationId/read');
    } catch (e) {
      print('Mark notification as read error: $e');
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getFileById(
    String fileId,
    String fileType,
  ) async {
    try {
      print('Fetching file $fileId of type $fileType...');
      final response = await _dio.get(
        '/api/images/$fileId',
        queryParameters: {'fileType': fileType},
      );
      return response.data;
    } catch (e) {
      print('Get file by id error: $e');
      throw _handleError(e);
    }
  }

  Future<bool> validateToken() async {
    try {
      if (_token == null) {
        print('No token available for validation');
        return false;
      }

      print('Validating token: ${_token?.substring(0, 20)}...');
      final response = await _dio.get('/api/profile');
      print('Token validation successful: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Token validation failed: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        print('Token is invalid or expired');
        clearToken();
      }
      return false;
    }
  }

  bool get hasToken => _token != null;

  // Debug method to check token status
  void logTokenStatus() {
    print('🔍 Token Status Check:');
    print('   - Token available: ${_token != null}');
    if (_token != null) {
      print('   - Token preview: ${_token!.substring(0, 20)}...');
    } else {
      print('   - No token available');
    }
  }

  // Password reset functionality
  Future<void> requestPasswordReset(String email) async {
    try {
      print('Requesting password reset for email: $email');
      await _dio.post('/api/users/forgot-password', data: {'email': email});
    } catch (e) {
      print('Request password reset error: $e');
      throw _handleError(e);
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmationPassword,
  }) async {
    try {
      print('Resetting password with token...');
      await _dio.post(
        '/api/users/reset-password',
        data: {
          'token': token,
          'newPassword': newPassword,
          'confirmationPassword': confirmationPassword,
        },
      );
    } catch (e) {
      print('Reset password error: $e');
      throw _handleError(e);
    }
  }

  // Email verification
  Future<void> requestEmailVerification() async {
    try {
      print('Requesting email verification...');
      await _dio.post('/api/users/verify-email');
    } catch (e) {
      print('Request email verification error: $e');
      throw _handleError(e);
    }
  }

  Future<void> verifyEmail(String token) async {
    try {
      print('Verifying email with token...');
      await _dio.post('/api/users/verify-email', data: {'token': token});
    } catch (e) {
      print('Verify email error: $e');
      throw _handleError(e);
    }
  }

  // Patient statistics and analytics
  Future<Map<String, dynamic>> getPatientStatistics(String patientId) async {
    try {
      print('Fetching patient statistics for ID: $patientId');
      final response = await _dio.get('/api/patients/$patientId/statistics');
      return response.data;
    } catch (e) {
      print('Get patient statistics error: $e');
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getSpecialistStatistics() async {
    try {
      print('Fetching specialist statistics...');
      final response = await _dio.get('/api/doctors/statistics');
      return response.data;
    } catch (e) {
      print('Get specialist statistics error: $e');
      throw _handleError(e);
    }
  }

  // Emotion analysis results
  Future<List<dynamic>> getEmotionAnalysisResults(String patientId) async {
    try {
      print('Fetching emotion analysis results for patient: $patientId');
      final response = await _dio.get('/api/patients/$patientId/emotions');
      return response.data as List<dynamic>;
    } catch (e) {
      print('Get emotion analysis results error: $e');
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getEmotionSummary(String patientId) async {
    try {
      print('Fetching emotion summary for patient: $patientId');
      final response = await _dio.get(
        '/api/patients/$patientId/emotions/summary',
      );
      return response.data;
    } catch (e) {
      print('Get emotion summary error: $e');
      throw _handleError(e);
    }
  }

  // Patient timeline and records
  Future<List<dynamic>> getPatientTimeline(String patientId) async {
    try {
      print('Fetching patient timeline for ID: $patientId');
      final response = await _dio.get('/api/patients/$patientId/timeline');
      return response.data as List<dynamic>;
    } catch (e) {
      print('Get patient timeline error: $e');
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getPatientRecords(String patientId) async {
    try {
      print('Fetching patient records for ID: $patientId');
      final response = await _dio.get('/api/patients/$patientId/records');
      return response.data as List<dynamic>;
    } catch (e) {
      print('Get patient records error: $e');
      throw _handleError(e);
    }
  }

  // Emergency contacts and settings
  Future<List<dynamic>> getEmergencyContacts() async {
    try {
      print('Fetching emergency contacts...');
      final response = await _dio.get('/api/emergency-contacts');
      return response.data as List<dynamic>;
    } catch (e) {
      print('Get emergency contacts error: $e');
      throw _handleError(e);
    }
  }

  Future<void> addEmergencyContact(Map<String, dynamic> contact) async {
    try {
      print('Adding emergency contact: $contact');
      await _dio.post('/api/emergency-contacts', data: contact);
    } catch (e) {
      print('Add emergency contact error: $e');
      throw _handleError(e);
    }
  }

  Future<void> updateEmergencyContact(
    String contactId,
    Map<String, dynamic> contact,
  ) async {
    try {
      print('Updating emergency contact $contactId: $contact');
      await _dio.put('/api/emergency-contacts/$contactId', data: contact);
    } catch (e) {
      print('Update emergency contact error: $e');
      throw _handleError(e);
    }
  }

  Future<void> deleteEmergencyContact(String contactId) async {
    try {
      print('Deleting emergency contact $contactId...');
      await _dio.delete('/api/emergency-contacts/$contactId');
    } catch (e) {
      print('Delete emergency contact error: $e');
      throw _handleError(e);
    }
  }

  // Device management
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      print('Fetching device information...');
      final response = await _dio.get('/api/device/info');
      return response.data;
    } catch (e) {
      print('Get device info error: $e');
      throw _handleError(e);
    }
  }

  Future<void> updateDeviceSettings(Map<String, dynamic> settings) async {
    try {
      print('Updating device settings: $settings');
      await _dio.put('/api/device/settings', data: settings);
    } catch (e) {
      print('Update device settings error: $e');
      throw _handleError(e);
    }
  }

  // Health metrics and monitoring
  Future<List<dynamic>> getHealthMetrics(String patientId) async {
    try {
      print('Fetching health metrics for patient: $patientId');
      final response = await _dio.get(
        '/api/patients/$patientId/health-metrics',
      );
      return response.data as List<dynamic>;
    } catch (e) {
      print('Get health metrics error: $e');
      throw _handleError(e);
    }
  }

  Future<void> addHealthMetric(
    String patientId,
    Map<String, dynamic> metric,
  ) async {
    try {
      print('Adding health metric for patient $patientId: $metric');
      await _dio.post('/api/patients/$patientId/health-metrics', data: metric);
    } catch (e) {
      print('Add health metric error: $e');
      throw _handleError(e);
    }
  }

  // Appointment scheduling
  Future<List<dynamic>> getAppointments() async {
    try {
      print('Fetching appointments...');
      final response = await _dio.get('/api/appointments');
      return response.data as List<dynamic>;
    } catch (e) {
      print('Get appointments error: $e');
      throw _handleError(e);
    }
  }

  Future<void> createAppointment(Map<String, dynamic> appointment) async {
    try {
      print('Creating appointment: $appointment');
      await _dio.post('/api/appointments', data: appointment);
    } catch (e) {
      print('Create appointment error: $e');
      throw _handleError(e);
    }
  }

  Future<void> updateAppointment(
    String appointmentId,
    Map<String, dynamic> appointment,
  ) async {
    try {
      print('Updating appointment $appointmentId: $appointment');
      await _dio.put('/api/appointments/$appointmentId', data: appointment);
    } catch (e) {
      print('Update appointment error: $e');
      throw _handleError(e);
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      print('Canceling appointment $appointmentId...');
      await _dio.delete('/api/appointments/$appointmentId');
    } catch (e) {
      print('Cancel appointment error: $e');
      throw _handleError(e);
    }
  }

  // Messaging and communication
  Future<List<dynamic>> getMessages() async {
    try {
      print('Fetching messages...');
      final response = await _dio.get('/api/messages');
      return response.data as List<dynamic>;
    } catch (e) {
      print('Get messages error: $e');
      throw _handleError(e);
    }
  }

  Future<void> sendMessage(Map<String, dynamic> message) async {
    try {
      print('Sending message: $message');
      await _dio.post('/api/messages', data: message);
    } catch (e) {
      print('Send message error: $e');
      throw _handleError(e);
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      print('Marking message $messageId as read...');
      await _dio.put('/api/messages/$messageId/read');
    } catch (e) {
      print('Mark message as read error: $e');
      throw _handleError(e);
    }
  }

  // Data export and backup
  Future<Map<String, dynamic>> exportPatientData(String patientId) async {
    try {
      print('Exporting patient data for ID: $patientId');
      final response = await _dio.get('/api/patients/$patientId/export');
      return response.data;
    } catch (e) {
      print('Export patient data error: $e');
      throw _handleError(e);
    }
  }

  Future<void> backupData() async {
    try {
      print('Creating data backup...');
      await _dio.post('/api/backup');
    } catch (e) {
      print('Backup data error: $e');
      throw _handleError(e);
    }
  }

  // System health and monitoring
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      print('Checking system health...');
      final response = await _dio.get('/api/system/health');
      return response.data;
    } catch (e) {
      print('Get system health error: $e');
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getApiStatus() async {
    try {
      print('Checking API status...');
      final response = await _dio.get('/api/status');
      return response.data;
    } catch (e) {
      print('Get API status error: $e');
      throw _handleError(e);
    }
  }

  // User preferences and settings
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      print('Fetching user preferences...');
      final response = await _dio.get('/api/user/preferences');
      return response.data;
    } catch (e) {
      print('Get user preferences error: $e');
      throw _handleError(e);
    }
  }

  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      print('Updating user preferences: $preferences');
      await _dio.put('/api/user/preferences', data: preferences);
    } catch (e) {
      print('Update user preferences error: $e');
      throw _handleError(e);
    }
  }

  // Account management
  Future<void> deleteAccount() async {
    try {
      print('Deleting user account...');
      await _dio.delete('/api/user/account');
      clearToken();
    } catch (e) {
      print('Delete account error: $e');
      clearToken();
      throw _handleError(e);
    }
  }

  // Additional endpoints from Postman collection
  Future<List<dynamic>> getDoctorsList() async {
    try {
      print('Fetching doctors list...');
      final response = await _dio.get('/api/doctors');
      return response.data as List<dynamic>;
    } catch (e) {
      print('Get doctors list error: $e');
      throw _handleError(e);
    }
  }

  // Enhanced error handling with specific error types
  Exception _handleError(dynamic error) {
    print('🔥 Handling error: $error');

    if (error is DioException) {
      final response = error.response;
      print('🔥 DioException details:');
      print('   - Status Code: ${response?.statusCode}');
      print('   - Data: ${response?.data}');
      print('   - Error Type: ${error.type}');
      print('   - Error Message: ${error.message}');

      switch (response?.statusCode) {
        case 400:
          // Handle validation errors
          if (response?.data is Map<String, dynamic>) {
            final data = response?.data as Map<String, dynamic>;
            if (data.containsKey('errors') && data['errors'] is List) {
              final errors = data['errors'] as List;
              if (errors.isNotEmpty) {
                final errorMessages =
                    errors
                        .map((e) => e['msg']?.toString() ?? 'Validation error')
                        .toList();
                if (errorMessages.any(
                  (msg) => msg.contains('Email already exists'),
                )) {
                  return Exception(
                    'This email is already registered. Please use a different email or try logging in.',
                  );
                }
                if (errorMessages.any((msg) => msg.contains('serial number'))) {
                  return Exception(
                    'This serial number is already in use. Please check your device serial number.',
                  );
                }
                return Exception(
                  'Validation failed: ${errorMessages.join(', ')}',
                );
              }
            }
          }
          return Exception('Bad request: ${response?.data ?? error.message}');
        case 401:
          return Exception('Unauthorized: Please check your credentials');
        case 403:
          return Exception('Access forbidden: Insufficient permissions');
        case 404:
          return Exception('Resource not found');
        case 422:
          return Exception('Invalid data provided');
        case 500:
          return Exception('Server error: Please try again later');
        case 502:
        case 503:
        case 504:
          return Exception('Service unavailable: Please try again later');
        default:
          return Exception('Network error: ${error.message}');
      }
    }

    if (error is Exception) {
      return error;
    }

    return Exception('Unknown error: ${error.toString()}');
  }

  Future<void> unassignPatient(String patientId) async {
    try {
      print('Unassigning patient: $patientId');
      await _dio.post('/api/patients/$patientId/unassign');

      // After successful unassignment, update patient status to inactive
      await updatePatientStatus(patientId, 'inactive');

      // Update the patient's profile to ensure status is correct
      await getProfile();
    } catch (e) {
      print('Unassign patient error: $e');
      throw _handleError(e);
    }
  }

  Future<void> directAssignPatientToDoctor(
    String patientId,
    String doctorId,
  ) async {
    try {
      print('Directly assigning patient $patientId to doctor $doctorId');
      await _dio.post(
        '/api/patients/$patientId/assign',
        data: {'doctorId': doctorId},
      );

      // After successful assignment, update patient status to active
      await updatePatientStatus(patientId, 'active');
    } catch (e) {
      print('Direct assignment error: $e');
      throw _handleError(e);
    }
  }

  Future<void> createNotification({
    required String recipientId,
    required String type,
    required String message,
  }) async {
    try {
      print('Creating notification for $recipientId: $message');
      final response = await _dio.post(
        '/api/notifications',
        data: {'recipientId': recipientId, 'type': type, 'message': message},
      );
      print('Notification created successfully: ${response.statusCode}');
      print('Notification response: ${response.data}');
    } catch (e) {
      print('Create notification error: $e');
      // Don't throw here to avoid breaking the main flow, but log the error
      if (e is DioException) {
        print(
          'Notification creation failed with status: ${e.response?.statusCode}',
        );
        print('Notification creation error response: ${e.response?.data}');
      }
    }
  }

  // Helper method to create a configured Dio instance for file downloads
  Dio _createFileDownloadDio({
    required Map<String, String> headers,
    Duration? connectTimeout,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: _dio.options.baseUrl,
        connectTimeout: connectTimeout ?? const Duration(seconds: 30),
        sendTimeout: sendTimeout ?? const Duration(seconds: 30),
        receiveTimeout: receiveTimeout ?? const Duration(seconds: 120),
        headers: {
          ...headers,
          'Connection': 'close', // Force HTTP/1.1
          'ngrok-skip-browser-warning': 'true',
          'User-Agent': 'Flutter-EmoGlasses-App',
        },
      ),
    );

    // Apply the same TLS configuration as the main _dio instance
    if (Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) {
          // Allow all certificates for ngrok in debug mode
          if (kDebugMode && host.contains('ngrok')) {
            print(
              '🔐 Allowing certificate for file download to ngrok host: $host',
            );
            return true;
          }
          return false;
        };
        return client;
      };
    }

    return dio;
  }

  // Display audio file
  Future<Uint8List> displayAudio(String fileId, {String? patientToken}) async {
    try {
      print('🎵 Fetching audio file with ID: $fileId');
      print('🎵 Backend URL: ${_dio.options.baseUrl}');

      // Prepare headers with patient token if provided
      Map<String, String> headers = {'Accept': 'audio/*'};
      if (patientToken != null) {
        headers['Authorization'] = 'Bearer $patientToken';
        print('🔑 Using patient token for audio fetch');
      } else if (_token != null) {
        headers['Authorization'] = 'Bearer $_token';
        print('🔑 Using global token for audio fetch');
      } else {
        print('⚠️ No token available for audio fetch');
      }

      print(
        '🎵 Request URL: ${_dio.options.baseUrl}/api/images/$fileId?fileType=audio',
      );
      print('🎵 Headers: $headers');

      // Create a configured Dio instance for file downloads with TLS bypass
      final dio = _createFileDownloadDio(
        headers: headers,
        receiveTimeout: const Duration(
          seconds: 120,
        ), // 2 minutes for large audio files
      );

      final response = await dio.get(
        '/api/images/$fileId',
        queryParameters: {'fileType': 'audio'},
        options: Options(responseType: ResponseType.bytes),
      );

      print('🎵 Audio fetch successful: ${response.statusCode}');
      print('🎵 Audio file size: ${response.data.length} bytes');

      return response.data;
    } catch (e) {
      print('❌ Error fetching audio file: $e');
      print('❌ DioException details:');
      if (e is DioException) {
        print('   - Status code: ${e.response?.statusCode}');
        print('   - Response data: ${e.response?.data}');
        print('   - Error type: ${e.type}');
        print('   - Error message: ${e.message}');
      }
      throw _handleError(e);
    }
  }

  // Display image file
  Future<Uint8List> displayImage(String fileId, {String? patientToken}) async {
    try {
      print('🖼️ Fetching image file with ID: $fileId');
      print('🖼️ Backend URL: ${_dio.options.baseUrl}');

      // Prepare headers with patient token if provided
      Map<String, String> headers = {'Accept': 'image/*'};
      if (patientToken != null) {
        headers['Authorization'] = 'Bearer $patientToken';
        print('🔑 Using patient token for image fetch');
      } else if (_token != null) {
        headers['Authorization'] = 'Bearer $_token';
        print('🔑 Using global token for image fetch');
      } else {
        print('⚠️ No token available for image fetch');
      }

      print(
        '🖼️ Request URL: ${_dio.options.baseUrl}/api/images/$fileId?fileType=image',
      );
      print('🖼️ Headers: $headers');

      // Create a configured Dio instance for file downloads with TLS bypass
      final dio = _createFileDownloadDio(
        headers: headers,
        receiveTimeout: const Duration(
          seconds: 90,
        ), // 1.5 minutes for large images
      );

      final response = await dio.get(
        '/api/images/$fileId',
        queryParameters: {'fileType': 'image'},
        options: Options(responseType: ResponseType.bytes),
      );

      print('🖼️ Image fetch successful: ${response.statusCode}');
      print('🖼️ Image file size: ${response.data.length} bytes');

      return response.data;
    } catch (e) {
      print('❌ Error fetching image file: $e');
      print('❌ DioException details:');
      if (e is DioException) {
        print('   - Status code: ${e.response?.statusCode}');
        print('   - Response data: ${e.response?.data}');
        print('   - Error type: ${e.type}');
        print('   - Error message: ${e.message}');
      }
      throw _handleError(e);
    }
  }

  // Get audio URL for streaming
  String getAudioUrl(String fileId, {String? patientToken}) {
    String url = '$_baseUrl/api/images/$fileId?fileType=audio';
    if (patientToken != null) {
      url += '&token=$patientToken';
    }
    return url;
  }

  // Get image URL for display
  String getImageUrl(String fileId, {String? patientToken}) {
    String url = '$_baseUrl/api/images/$fileId?fileType=image';
    if (patientToken != null) {
      url += '&token=$patientToken';
    }
    return url;
  }

  // Patient assignment request (from patient side)
  Future<void> requestDoctorAssignment(String doctorId) async {
    try {
      print('Requesting assignment to doctor: $doctorId');
      final response = await _dio.post('/api/doctors/$doctorId/request-assign');
      print('Assignment request response: ${response.data}');
    } catch (e) {
      print('Request doctor assignment error: $e');
      throw _handleError(e);
    }
  }

  // Decline assignment request
  Future<void> declineAssignmentRequest(String requestId) async {
    try {
      print('Declining assignment request: $requestId');
      await _dio.post('/api/requests/$requestId/decline');
    } catch (e) {
      print('Decline assignment error: $e');
      throw _handleError(e);
    }
  }

  // Comprehensive test method for audio and image system
  Future<Map<String, dynamic>> testAudioImageSystem() async {
    final results = <String, dynamic>{};

    try {
      print('🧪 Starting comprehensive audio/image system test...');

      // Test 1: Check API connection
      print('🧪 Test 1: Checking API connection...');
      final connectionTest = await testConnection();
      results['api_connection'] = connectionTest;
      print('✅ API connection test: $connectionTest');

      // Test 2: Check authentication
      print('🧪 Test 2: Checking authentication...');
      final hasToken = _token != null;
      results['authentication'] = hasToken;
      print('✅ Authentication test: $hasToken');

      if (hasToken) {
        print('🔑 Token available: ${_token!.substring(0, 20)}...');
      }

      // Test 3: Test profile endpoint
      print('🧪 Test 3: Testing profile endpoint...');
      try {
        final profile = await getProfile();
        results['profile_endpoint'] = true;
        results['user_role'] = profile['role'];
        results['user_id'] = profile['_id'] ?? profile['id'];
        print('✅ Profile endpoint test: Success');
        print('👤 User role: ${profile['role']}');
        print('👤 User ID: ${profile['_id'] ?? profile['id']}');
      } catch (e) {
        results['profile_endpoint'] = false;
        results['profile_error'] = e.toString();
        print('❌ Profile endpoint test: Failed - $e');
      }

      // Test 4: Test audio upload endpoint (without actual file)
      print('🧪 Test 4: Testing audio upload endpoint...');
      try {
        // Create a minimal test file
        final tempDir = await getTemporaryDirectory();
        final testFile = File('${tempDir.path}/test_audio.mp3');
        final testData = List<int>.generate(1000, (i) => i % 256);
        await testFile.writeAsBytes(testData);

        final uploadResult = await uploadAudio(
          testFile,
          recordingTime: DateTime.now(),
        );
        results['audio_upload'] = true;
        results['audio_upload_response'] = uploadResult;
        print('✅ Audio upload test: Success');
        print('📤 Upload response: $uploadResult');

        // Clean up test file
        await testFile.delete();
      } catch (e) {
        results['audio_upload'] = false;
        results['audio_upload_error'] = e.toString();
        print('❌ Audio upload test: Failed - $e');
      }

      // Test 5: Test image display endpoint
      print('🧪 Test 5: Testing image display endpoint...');
      try {
        // Try to fetch a test image (this might fail if no images exist)
        final testImageId = 'test_image_id';
        await displayImage(testImageId);
        results['image_display'] = true;
        print('✅ Image display test: Success');
      } catch (e) {
        // This is expected to fail if no test image exists
        results['image_display'] = false;
        results['image_display_error'] = e.toString();
        print('⚠️ Image display test: Expected failure - $e');
      }

      // Test 6: Test audio display endpoint
      print('🧪 Test 6: Testing audio display endpoint...');
      try {
        // Try to fetch a test audio (this might fail if no audio exists)
        final testAudioId = 'test_audio_id';
        await displayAudio(testAudioId);
        results['audio_display'] = true;
        print('✅ Audio display test: Success');
      } catch (e) {
        // This is expected to fail if no test audio exists
        results['audio_display'] = false;
        results['audio_display_error'] = e.toString();
        print('⚠️ Audio display test: Expected failure - $e');
      }

      print('🧪 Comprehensive test completed!');
      print('📊 Results: $results');
    } catch (e) {
      print('❌ Comprehensive test failed: $e');
      results['overall_error'] = e.toString();
    }

    return results;
  }

  // Test method specifically for audio upload
  Future<Map<String, dynamic>> testAudioUpload() async {
    try {
      print('🎵 Testing audio upload specifically...');

      // Check if we have authentication
      if (_token == null) {
        throw Exception('No authentication token available');
      }

      // Create a test audio file
      final tempDir = await getTemporaryDirectory();
      final testFile = File(
        '${tempDir.path}/test_audio_${DateTime.now().millisecondsSinceEpoch}.mp3',
      );

      // Create a simple test audio file (just some bytes)
      final testData = List<int>.generate(5000, (i) => i % 256);
      await testFile.writeAsBytes(testData);

      print('📁 Test file created: ${testFile.path}');
      print('📁 File size: ${await testFile.length()} bytes');

      // Try to upload with current timestamp
      final result = await uploadAudio(testFile, recordingTime: DateTime.now());

      // Clean up
      await testFile.delete();

      return {
        'success': true,
        'result': result,
        'message': 'Audio upload test completed successfully',
      };
    } catch (e) {
      print('❌ Audio upload test failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Audio upload test failed',
      };
    }
  }

  // Test method specifically for image upload
  Future<Map<String, dynamic>> testImageUpload() async {
    try {
      print('🖼️ Testing image upload specifically...');

      // Create a test image file
      final tempDir = await getTemporaryDirectory();
      final testFile = File(
        '${tempDir.path}/test_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Create a simple test image file (just some bytes)
      final testData = List<int>.generate(10000, (i) => i % 256);
      await testFile.writeAsBytes(testData);

      print('📁 Test image created: ${testFile.path}');
      print('📁 File size: ${await testFile.length()} bytes');

      // Use a test serial number
      const testSerialNumber = 'TEST-SN-123456';

      // Try to upload
      final result = await uploadImageFromESP32(testFile, testSerialNumber);

      // Clean up
      await testFile.delete();

      return {
        'success': true,
        'result': result,
        'message': 'Image upload test completed successfully',
      };
    } catch (e) {
      print('❌ Image upload test failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Image upload test failed',
      };
    }
  }

  // Comprehensive audio flow test
  Future<Map<String, dynamic>> testCompleteAudioFlow() async {
    try {
      print('🧪 Testing complete audio upload and retrieval flow...');

      // Step 1: Check authentication
      if (_token == null) {
        return {
          'success': false,
          'message': 'No authentication token available',
          'step': 'authentication',
        };
      }

      print('✅ Authentication: Token available');

      // Step 2: Test API connectivity
      final connectivity = await testConnection();
      if (!connectivity) {
        return {
          'success': false,
          'message': 'Cannot connect to backend API',
          'step': 'connectivity',
        };
      }

      print('✅ Connectivity: Backend reachable');

      // Step 3: Get user profile to verify endpoints
      final profile = await getProfile();
      final userId = profile['_id'] ?? profile['id'];
      final userRole = profile['role'];

      print('✅ Profile: User $userId (role: $userRole)');

      // Step 4: Test audio upload endpoint
      print('📤 Testing audio upload endpoint...');

      // Create a test audio file
      final tempDir = await getTemporaryDirectory();
      final testAudioFile = File('${tempDir.path}/test_audio_flow.mp3');

      // Create a simple audio file with some data
      final audioBytes = Uint8List.fromList(
        List.generate(2048, (i) => i % 256),
      );
      await testAudioFile.writeAsBytes(audioBytes);

      print(
        '✅ Test file created: ${testAudioFile.path} (${audioBytes.length} bytes)',
      );

      // Upload the test audio
      final uploadResult = await uploadAudio(
        testAudioFile,
        recordingTime: DateTime.now(),
      );
      print('✅ Upload result: ${uploadResult['success']}');

      if (uploadResult['success'] != true) {
        return {
          'success': false,
          'message': 'Audio upload failed: ${uploadResult['message']}',
          'step': 'upload',
          'uploadResult': uploadResult,
        };
      }

      // Step 5: Extract audio ID from upload response
      String? audioId;
      if (uploadResult['data'] != null) {
        final uploadData = uploadResult['data'];
        // Try different possible response structures
        audioId =
            uploadData['audio']?['_id'] ??
            uploadData['_id'] ??
            uploadData['audioId'] ??
            uploadData['fileId'];
      }

      print('✅ Audio uploaded with ID: $audioId');

      if (audioId == null) {
        return {
          'success': false,
          'message': 'Audio uploaded but no file ID returned',
          'step': 'upload_response',
          'uploadResult': uploadResult,
        };
      }

      // Step 6: Test audio retrieval
      print('📥 Testing audio retrieval...');

      try {
        final audioBytes = await displayAudio(audioId);
        print('✅ Audio retrieved: ${audioBytes.length} bytes');

        if (audioBytes.isEmpty) {
          return {
            'success': false,
            'message': 'Audio file retrieved but empty',
            'step': 'retrieval_empty',
          };
        }

        // Step 7: Test audio URL generation
        final audioUrl = getAudioUrl(audioId);
        print('✅ Audio URL generated: $audioUrl');

        // Clean up test file
        if (await testAudioFile.exists()) {
          await testAudioFile.delete();
          print('✅ Test file cleaned up');
        }

        return {
          'success': true,
          'message': 'Complete audio flow test passed successfully',
          'audioId': audioId,
          'audioUrl': audioUrl,
          'uploadedBytes': audioBytes.length,
          'retrievedBytes': audioBytes.length,
          'userId': userId,
          'userRole': userRole,
        };
      } catch (retrievalError) {
        return {
          'success': false,
          'message':
              'Audio upload succeeded but retrieval failed: $retrievalError',
          'step': 'retrieval',
          'audioId': audioId,
          'retrievalError': retrievalError.toString(),
        };
      }
    } catch (e) {
      print('❌ Audio flow test error: $e');
      return {
        'success': false,
        'message': 'Audio flow test failed: $e',
        'step': 'general_error',
        'error': e.toString(),
      };
    }
  }

  // Comprehensive API integration test
  Future<Map<String, dynamic>> testAPIIntegration() async {
    final results = <String, dynamic>{};

    try {
      print('🧪 Starting comprehensive API integration test...');

      // Step 1: Test basic connectivity
      print('🔗 Testing basic connectivity...');
      final connectivity = await testConnection();
      results['connectivity'] = connectivity;
      if (!connectivity) {
        results['error'] = 'Failed to connect to backend';
        return results;
      }
      print('✅ Connectivity: Success');

      // Step 2: Test registration endpoint structure
      print('🔐 Testing registration endpoint (structure only)...');
      try {
        // This will fail but we can check the response structure
        await registerUser(
          email: 'test_structure@test.com',
          password: 'test123',
          confirmationPassword: 'test123',
          name: 'Test User',
          role: 'patient',
          serialNumber: 'TEST-123',
        );
        results['registration_test'] = 'unexpected_success';
      } catch (e) {
        // Expected to fail, but we can check the error type
        if (e.toString().contains('409') || e.toString().contains('conflict')) {
          results['registration_test'] = 'endpoint_accessible';
        } else {
          results['registration_test'] = 'error: $e';
        }
      }

      // Step 3: Test audio upload endpoint (if authenticated)
      if (_token != null) {
        print('🎵 Testing audio endpoints...');
        results['audio_endpoints'] = 'authenticated_tests_available';
      } else {
        results['audio_endpoints'] = 'no_token_for_testing';
      }

      // Step 4: Verify all endpoint URLs
      print('🌐 Verifying endpoint URLs...');
      final endpoints = {
        'registration': '/api/users',
        'login': '/api/users/login',
        'logout': '/api/users/logout',
        'profile': '/api/profile',
        'audio_upload': '/api/audio/upload',
        'patients': '/api/patients',
        'doctors': '/api/doctors',
        'notifications': '/api/notifications',
      };

      results['endpoints'] = endpoints;
      results['base_url'] = baseUrl;

      print('✅ API Integration Test completed');
      results['status'] = 'completed';
      results['timestamp'] = DateTime.now().toIso8601String();
    } catch (e) {
      print('❌ API Integration Test failed: $e');
      results['error'] = e.toString();
      results['status'] = 'failed';
    }

    return results;
  }

  // Get latest emotion analysis
  Future<Map<String, dynamic>?> getLatestEmotion() async {
    try {
      print('🧠 Getting latest emotion analysis...');
      final response = await _dio.get('/api/patients/latest-emotion');
      print('🧠 Latest emotion response: ${response.data}');

      if (response.data != null) {
        return response.data as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      print('❌ Get latest emotion error: $e');
      // Don't throw error for emotion detection - just return null
      return null;
    }
  }
}
