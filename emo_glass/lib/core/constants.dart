class AppConstants {
  static const String baseUrl = 'https://368b-154-191-181-230.ngrok-free.app';
  static const String logoPath = 'assets/images/image.png';
}

class ApiConstants {
  // Update this URL with your current ngrok tunnel
  // Run: ngrok http 3000 (or your backend port)
  // Then replace the URL below with the new ngrok URL
  static const String baseUrl = 'https://368b-154-191-181-230.ngrok-free.app';

  // Backup URL in case ngrok is down
  static const String fallbackUrl = 'http://localhost:3000';

  // Connection timeouts - increased for slower connections
  static const int connectionTimeout = 60; // seconds
  static const int receiveTimeout = 60; // seconds

  // Polling intervals
  static const int pollingInterval = 30; // seconds for real-time updates

  // Retry configuration
  static const int maxRetries = 3;
  static const int retryDelay = 2; // seconds

  // Mock data toggle - set to true if backend is unreachable
  static const bool useMockData = false;

  // Debug mode - enables detailed logging
  static const bool debugMode = true;

  // API Endpoints
  static const String loginEndpoint = '/api/users/login';
  static const String registerEndpoint = '/api/users';
  static const String profileEndpoint = '/api/profile';
  static const String doctorsEndpoint = '/api/doctors';
  static const String patientsEndpoint = '/api/patients';
  static const String notificationsEndpoint = '/api/notifications';
  static const String assignmentRequestsEndpoint = '/api/doctors/requests';
}
