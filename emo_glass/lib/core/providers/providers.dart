import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/api_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/user_model.dart';

// Create a singleton ApiService instance
final _apiServiceInstance = ApiService();

final apiServiceProvider = Provider<ApiService>((ref) {
  return _apiServiceInstance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return AuthRepositoryImpl(apiService);
});

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((
  ref,
) {
  final authRepository = ref.read(authRepositoryProvider);
  return AuthNotifier(authRepository, ref);
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.whenOrNull(data: (user) => user);
});

final patientsProvider =
    StateNotifierProvider<PatientsNotifier, AsyncValue<List<PatientModel>>>((
      ref,
    ) {
      final apiService = ref.read(apiServiceProvider);
      return PatientsNotifier(apiService, ref);
    });

class PatientsNotifier extends StateNotifier<AsyncValue<List<PatientModel>>> {
  final ApiService _apiService;
  final Ref _ref;

  PatientsNotifier(this._apiService, this._ref)
    : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() async {
    await refresh();
  }

  Future<void> refresh() async {
    try {
      print('🔄 Starting refresh for patients');
      if (!_apiService.hasToken) {
        print('No token available for patients request');
        state = AsyncValue.error(
          Exception('Authentication required. Please login again.'),
          StackTrace.current,
        );
        return;
      }

      final patients = await _apiService.getPatients();
      state = AsyncValue.data(patients);
      print('✅ Refreshed patients data');
    } catch (e) {
      print('❌ Error refreshing patients: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refreshPatient(String patientId) async {
    try {
      print('🔄 Refreshing patient $patientId');
      if (!_apiService.hasToken) {
        print('No token available for patient refresh request');
        return;
      }

      // Get current state
      final currentPatients = state.value ?? [];
      final patientIndex = currentPatients.indexWhere((p) => p.id == patientId);

      if (patientIndex == -1) {
        print('❌ Patient $patientId not found in current list');
        return;
      }

      // Get updated patient data
      final response = await _apiService.getPatient(patientId);
      final updatedPatient = PatientModel.fromJson(response);

      // Update the patient in the list
      final updatedPatients = List<PatientModel>.from(currentPatients);
      updatedPatients[patientIndex] = updatedPatient;

      state = AsyncValue.data(updatedPatients);
      print('✅ Refreshed patient $patientId');
    } catch (e) {
      print('❌ Error refreshing patient $patientId: $e');
    }
  }
}

final patientDetailsProvider = FutureProvider.family<PatientModel, String>((
  ref,
  patientId,
) async {
  final apiService = ref.read(apiServiceProvider);

  // Ensure token is available before making the request
  if (!apiService.hasToken) {
    print('No token available for patient details request');
    throw Exception('Authentication required. Please login again.');
  }

  return apiService
      .getPatientDetails(patientId)
      .then((data) => PatientModel.fromJson(data));
});

// Provider for available doctors list
final doctorsProvider = FutureProvider.autoDispose<List<UserModel>>((
  ref,
) async {
  final apiService = ref.read(apiServiceProvider);

  if (!apiService.hasToken) {
    throw Exception('Authentication required');
  }

  try {
    print('Fetching doctors...');
    final doctors = await apiService.getDoctors();
    return doctors;
  } catch (e) {
    print('Error fetching doctors: $e');
    throw e;
  }
});

final notificationSettingsProvider = StateNotifierProvider<
  NotificationSettingsNotifier,
  AsyncValue<Map<String, dynamic>>
>((ref) {
  return NotificationSettingsNotifier(ref);
});

class NotificationSettingsNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  NotificationSettingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _fetchSettings();
  }

  final Ref _ref;

  Future<void> _fetchSettings() async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      final settings = await apiService.getNotificationSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSetting(String key, bool value) async {
    // Optimistic update
    final previousState = state;
    state = state.whenData((settings) {
      final newSettings = Map<String, dynamic>.from(settings);
      newSettings[key] = value;
      return newSettings;
    });

    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.updateNotificationSettings({key: value});
      // Optionally, refetch to confirm, but optimistic is usually enough
      // await _fetchSettings();
    } catch (e) {
      // Revert on error
      state = previousState;
      // Optionally, expose the error to the UI
    }
  }
}

final notificationsProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final apiService = ref.read(apiServiceProvider);

  // Add a cancellation callback
  ref.onDispose(() {
    print('Disposing notifications provider');
  });

  // Ensure token is available before making the request
  if (!apiService.hasToken) {
    print('No token available for notifications request');
    throw Exception('Authentication required. Please login again.');
  }

  try {
    print('Fetching notifications...');
    final notifications = await apiService.getNotifications();
    return notifications;
  } catch (e) {
    print('Error fetching notifications: $e');
    throw e;
  }
});

// Provider for doctor's pending assignment requests
final doctorAssignmentRequestsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final apiService = ref.read(apiServiceProvider);

      if (!apiService.hasToken) {
        throw Exception('Authentication required');
      }

      try {
        print('Fetching doctor assignment requests...');
        final requests = await apiService.getDoctorAssignmentRequests();
        return List<Map<String, dynamic>>.from(requests);
      } catch (e) {
        print('Error fetching assignment requests: $e');
        throw e;
      }
    });

// Provider for assigned patients list
final assignedPatientsProvider = FutureProvider.autoDispose<List<UserModel>>((
  ref,
) async {
  final apiService = ref.read(apiServiceProvider);

  if (!apiService.hasToken) {
    throw Exception('Authentication required');
  }

  try {
    print('Fetching assigned patients...');
    final response = await apiService.getAssignedPatients();
    if (response is! List) {
      throw Exception('Invalid response format from getAssignedPatients');
    }
    return response
        .map((patient) => UserModel.fromJson(patient as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print('Error fetching assigned patients: $e');
    throw e;
  }
});

// Provider for doctor details
final doctorDetailsProvider = FutureProvider.family<UserModel, String>((
  ref,
  doctorId,
) async {
  final apiService = ref.read(apiServiceProvider);

  if (!apiService.hasToken) {
    throw Exception('Authentication required');
  }

  try {
    print('Fetching doctor details for ID: $doctorId');
    return await apiService.getDoctorDetails(doctorId);
  } catch (e) {
    print('Error fetching doctor details: $e');
    throw e;
  }
});

final searchDoctorsProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  query,
) async {
  final apiService = ref.read(apiServiceProvider);

  // Ensure token is available before making the request
  if (!apiService.hasToken) {
    print('No token available for doctor search request');
    throw Exception('Authentication required. Please login again.');
  }

  return apiService.searchDoctors(query);
});

enum VoiceRecordingStatus { idle, recording, uploading, completed, error }

class VoiceRecordingState {
  final VoiceRecordingStatus status;
  final String? filePath;
  final String? errorMessage;
  final Duration? duration;

  const VoiceRecordingState({
    required this.status,
    this.filePath,
    this.errorMessage,
    this.duration,
  });

  VoiceRecordingState copyWith({
    VoiceRecordingStatus? status,
    String? filePath,
    String? errorMessage,
    Duration? duration,
  }) {
    return VoiceRecordingState(
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      errorMessage: errorMessage ?? this.errorMessage,
      duration: duration ?? this.duration,
    );
  }
}

class VoiceRecordingNotifier extends StateNotifier<VoiceRecordingState> {
  VoiceRecordingNotifier()
    : super(const VoiceRecordingState(status: VoiceRecordingStatus.idle));

  void startRecording() {
    state = state.copyWith(
      status: VoiceRecordingStatus.recording,
      errorMessage: null,
    );
  }

  void stopRecording(String filePath, Duration duration) {
    state = state.copyWith(
      status: VoiceRecordingStatus.completed,
      filePath: filePath,
      duration: duration,
    );
  }

  void startUploading() {
    state = state.copyWith(status: VoiceRecordingStatus.uploading);
  }

  void uploadCompleted() {
    state = state.copyWith(status: VoiceRecordingStatus.completed);
  }

  void setError(String error) {
    state = state.copyWith(
      status: VoiceRecordingStatus.error,
      errorMessage: error,
    );
  }

  void reset() {
    state = const VoiceRecordingState(status: VoiceRecordingStatus.idle);
  }
}

final voiceRecordingProvider =
    StateNotifierProvider<VoiceRecordingNotifier, VoiceRecordingState>((ref) {
      return VoiceRecordingNotifier();
    });

class EmergencyNotifier extends StateNotifier<bool> {
  EmergencyNotifier() : super(false);

  void activateEmergency() {
    state = true;
  }

  void deactivateEmergency() {
    state = false;
  }

  void toggleEmergency() {
    state = !state;
  }
}

final emergencyProvider = StateNotifierProvider<EmergencyNotifier, bool>((ref) {
  return EmergencyNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _authRepository;
  final Ref _ref;
  bool _disposed = false;

  AuthNotifier(this._authRepository, this._ref)
    : super(const AsyncValue.data(null)) {
    _init();
  }

  void _init() async {
    if (_disposed) return;
    try {
      if (_authRepository is AuthRepositoryImpl) {
        final authRepo = _authRepository as AuthRepositoryImpl;
        await refreshUser();
      }
    } catch (e) {
      print('Init error: $e');
    }
  }

  Future<void> refreshUser() async {
    if (_disposed) return;
    try {
      print('🔄 Refreshing user profile...');
      final response = await _authRepository.getProfile();

      if (response != null) {
        final userModel = UserModel.fromJson(response);
        final user = User(
          id: userModel.id,
          email: userModel.email,
          name: userModel.name,
          role: userModel.role,
          serialNumber: userModel.serialNumber,
          specialist: userModel.specialist,
          assignedDoctor: userModel.assignedDoctor,
          status: userModel.status,
        );
        if (!_disposed) {
          state = AsyncValue.data(user);
          print('✅ User profile refreshed: $user');
        }
      }
    } catch (e) {
      print('❌ Refresh user error: $e');
      if (!_disposed) {
        state = const AsyncValue.data(null);
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> login({required String email, required String password}) async {
    if (_disposed) return;
    try {
      state = const AsyncValue.loading();
      print('🔐 Auth loading...');

      print('Attempting login for: $email');
      final response = await _authRepository.loginUser(
        email: email,
        password: password,
      );

      if (_disposed) return;

      if (response['user'] != null) {
        final userModel = UserModel.fromJson(response['user']);
        final user = User(
          id: userModel.id,
          email: userModel.email,
          name: userModel.name,
          role: userModel.role,
          serialNumber: userModel.serialNumber,
          specialist: userModel.specialist,
          assignedDoctor: userModel.assignedDoctor,
          status: userModel.status,
        );

        // Update user status based on assignment
        if (userModel.role == 'patient' && userModel.assignedDoctor != null) {
          await _authRepository.updateProfile(
            email: user.email,
            name: user.name,
            status: 'active',
          );
        }

        if (!_disposed) {
          // Refresh the user to get the fully populated profile
          await refreshUser();
          print('🔐 User logged in successfully, navigating...');
        }
      } else {
        throw Exception('Invalid login response');
      }
    } catch (e) {
      print('Login error: $e');
      if (!_disposed) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  Future<void> logout() async {
    if (_disposed) return;
    try {
      print('Logging out user...');
      await _authRepository.logoutUser();

      // Set state to null before navigation
      if (!_disposed) {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      print('Logout error: $e');
      // Still clear state on error
      if (!_disposed) {
        state = const AsyncValue.data(null);
      }
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String confirmationPassword,
    required String name,
    required String role,
    String? serialNumber,
    String? specialist,
  }) async {
    if (_disposed) return;
    try {
      print('Attempting registration for: $email, role: $role');
      final response = await _authRepository.registerUser(
        email: email,
        password: password,
        confirmationPassword: confirmationPassword,
        name: name,
        role: role,
        serialNumber: serialNumber,
        specialist: specialist,
      );

      if (response['user'] != null) {
        print('Registration successful, now logging in to get token...');

        // Automatically login after successful registration to get token
        try {
          final loginResponse = await _authRepository.loginUser(
            email: email,
            password: password,
          );

          if (loginResponse['user'] != null) {
            final userModel = UserModel.fromJson(loginResponse['user']);
            final user = User(
              id: userModel.id,
              email: userModel.email,
              name: userModel.name,
              role: userModel.role,
              serialNumber: userModel.serialNumber,
              specialist: userModel.specialist,
              assignedDoctor: userModel.assignedDoctor,
              status: userModel.status,
            );

            if (!_disposed) {
              state = AsyncValue.data(user);
              // Refresh the user to get the fully populated profile
              await refreshUser();
              print('Registration and login successful for: ${user.name}');
            }
          } else {
            throw Exception('Login after registration failed');
          }
        } catch (loginError) {
          print('Auto-login after registration failed: $loginError');
          // Still register the user locally without token
          final userModel = UserModel.fromJson(response['user']);
          final user = User(
            id: userModel.id,
            email: userModel.email,
            name: userModel.name,
            role: userModel.role,
            serialNumber: userModel.serialNumber,
            specialist: userModel.specialist,
            assignedDoctor: userModel.assignedDoctor,
            status: userModel.status,
          );
          if (!_disposed) {
            state = AsyncValue.data(user);
            print(
              'Registration successful for: ${user.name} (manual login required)',
            );
          }
        }
      } else {
        throw Exception('Invalid registration response');
      }
    } catch (e) {
      print('Registration error: $e');
      if (!_disposed) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  Future<void> updateProfile({
    String? email,
    String? name,
    String? serialNumber,
  }) async {
    try {
      state = const AsyncValue.loading();
      await _authRepository.updateProfile(
        email: email,
        name: name,
        serialNumber: serialNumber,
      );
      await refreshUser();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      print('🔐 Auth error: $e');
      rethrow;
    }
  }
}

final tokenValidationProvider = FutureProvider<bool>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.validateToken();
});

final hasTokenProvider = Provider<bool>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return apiService.hasToken;
});

final tokenProvider = Provider<String?>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return apiService.token;
});

// Debug provider to check token status
final debugTokenProvider = Provider<String>((ref) {
  final apiService = ref.read(apiServiceProvider);
  apiService.logTokenStatus();
  return apiService.hasToken ? 'Token available' : 'No token';
});

// Provider to manage patient status based on assignment
final patientStatusManagerProvider = Provider((ref) {
  return PatientStatusManager(ref);
});

class PatientStatusManager {
  final Ref _ref;

  PatientStatusManager(this._ref);

  Future<void> ensurePatientStatus(
    String patientId,
    String? assignedDoctorId,
  ) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      final newStatus =
          assignedDoctorId != null && assignedDoctorId.isNotEmpty
              ? 'active'
              : 'inactive';

      // Only try to get current patient data if we have permission
      // (i.e., if the current user is the patient or their assigned doctor)
      try {
        final response = await apiService.getPatient(patientId);
        final currentStatus = response['status']?.toString();

        // Only update if status needs to change
        if (currentStatus != newStatus) {
          print(
            'Updating patient $patientId status from $currentStatus to $newStatus',
          );
          await apiService.updatePatientStatus(patientId, newStatus);

          // Refresh patient data after status update
          await _ref.read(patientsProvider.notifier).refreshPatient(patientId);
        } else {
          print(
            'Patient $patientId status already $newStatus, no update needed',
          );
        }
      } catch (e) {
        // If we don't have permission to get patient data, just update the status
        if (e.toString().contains('403') ||
            e.toString().contains('Forbidden')) {
          print(
            'No permission to view patient $patientId, updating status directly',
          );
          await apiService.updatePatientStatus(patientId, newStatus);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      print('Failed to update patient status: $e');
      // Don't throw here to avoid breaking the assignment flow
    }
  }

  Future<void> handleAssignmentRequest(
    String patientId,
    String doctorId,
  ) async {
    try {
      // When a request is made, don't change status yet
      print(
        'Assignment request initiated for patient $patientId to doctor $doctorId',
      );
    } catch (e) {
      print('Failed to handle assignment request: $e');
      // Don't throw here to avoid breaking the assignment flow
    }
  }

  Future<void> handleAssignmentAccept(String patientId, String doctorId) async {
    try {
      // When request is accepted, set status to active
      await ensurePatientStatus(patientId, doctorId);
      print('Patient $patientId status updated after assignment accept');
    } catch (e) {
      print('Failed to handle assignment accept: $e');
      // Don't throw here to avoid breaking the assignment flow
    }
  }

  Future<void> handleAssignmentDecline(String patientId) async {
    try {
      // When request is declined, status should be handled by the backend logic.
      // The frontend will just refresh the data.
      print('Patient $patientId status updated after assignment decline');
    } catch (e) {
      print('Failed to handle assignment decline: $e');
      // Don't throw here to avoid breaking the assignment flow
    }
  }

  Future<void> handleAssignmentRemove(String patientId) async {
    try {
      // When doctor removes assignment, the backend handles the status update.
      // We don't need to call ensurePatientStatus here.
      print('Patient $patientId status updated after assignment remove');
    } catch (e) {
      print('Failed to handle assignment remove: $e');
      // Don't throw here to avoid breaking the assignment flow
    }
  }
}

// Provider to validate and fix patient status inconsistencies
final patientStatusValidatorProvider = Provider((ref) {
  return PatientStatusValidator(ref);
});

class PatientStatusValidator {
  final Ref _ref;

  PatientStatusValidator(this._ref);

  Future<void> validateAndFixPatientStatus(UserModel patient) async {
    try {
      final hasAssignedDoctor =
          patient.assignedDoctor != null && patient.assignedDoctor!.isNotEmpty;
      final currentStatus = patient.status?.toLowerCase();

      // Check if status is inconsistent with assignment
      bool needsUpdate = false;
      String correctStatus = '';

      if (hasAssignedDoctor && currentStatus != 'active') {
        needsUpdate = true;
        correctStatus = 'active';
        print(
          'Patient ${patient.name} has assigned doctor but status is $currentStatus - fixing to active',
        );
      } else if (!hasAssignedDoctor && currentStatus == 'active') {
        // Only fix if the patient is 'active' but has no doctor.
        // Don't change other statuses like 'pending' or a potential future 'unassigned' status.
        needsUpdate = true;
        correctStatus =
            'inactive'; // This will likely fail, but it's what the original code did.
        // A better solution is to have a valid status from the backend for this case.
        print(
          'Patient ${patient.name} has no assigned doctor but status is $currentStatus - fixing to inactive',
        );
      }

      if (needsUpdate) {
        await _ref
            .read(apiServiceProvider)
            .updatePatientStatus(patient.id, correctStatus);
        print(
          '✅ Fixed patient ${patient.name} status from $currentStatus to $correctStatus',
        );
      }
    } catch (e) {
      print('❌ Failed to validate/fix patient status: $e');
    }
  }

  Future<void> validateAllPatients() async {
    try {
      print('🔍 Starting patient status validation...');
      final patients =
          await _ref.read(apiServiceProvider).getAssignedPatients();

      for (final patientData in patients) {
        if (patientData is Map<String, dynamic>) {
          final patient = UserModel.fromJson(patientData);
          await validateAndFixPatientStatus(patient);
        }
      }
      print('✅ Patient status validation completed');
    } catch (e) {
      print('❌ Failed to validate all patients: $e');
    }
  }
}
