class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? serialNumber;
  final String? specialist;
  final String? assignedDoctor;
  final String? pendingAssignment;
  final String? status;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.serialNumber,
    this.specialist,
    this.assignedDoctor,
    this.pendingAssignment,
    this.status,
  });

  bool get isPatient => role == 'patient';
  bool get isSpecialist => role == 'doctor' || role == 'specialist';
}
