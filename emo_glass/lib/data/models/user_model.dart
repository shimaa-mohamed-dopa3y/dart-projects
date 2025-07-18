class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? serialNumber; // For patients
  final String? specialist; // For specialists (specialty)
  final String? assignedDoctor; // For patients (doctor ID)
  final String? pendingAssignment; // For patients (pending doctor ID)
  final String? status; // Patient status (active/inactive)

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.serialNumber,
    this.specialist, // This is the specialty for doctors
    this.assignedDoctor, // This is the assigned doctor ID for patients
    this.pendingAssignment, // This is the pending doctor ID for patients
    this.status, // Patient status
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle both _id and id fields, prioritizing _id as that's what the API returns
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';

    // For debugging
    print('Creating UserModel from JSON:');
    print('- Raw ID fields: _id=${json['_id']}, id=${json['id']}');
    print('- Using ID: $id');
    print('- Raw specialist field: ${json['specialist']}');
    print('- Specialist type: ${json['specialist']?.runtimeType}');
    print('- Raw assignedDoctor field: ${json['assignedDoctor']}');
    print('- assignedDoctor type: ${json['assignedDoctor']?.runtimeType}');
    print('- Raw JSON: $json');

    String? specialistValue = json['specialist']?.toString();
    print('- Parsed specialist value: $specialistValue');

    dynamic assignedDoctorData = json['assignedDoctor'];
    String? assignedDoctorId;
    if (assignedDoctorData is Map<String, dynamic>) {
      assignedDoctorId = assignedDoctorData['_id']?.toString();
    } else {
      assignedDoctorId = assignedDoctorData?.toString();
    }
    print('- Parsed assignedDoctor ID: $assignedDoctorId');

    return UserModel(
      id: id,
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      serialNumber: json['serialNumber']?.toString(),
      specialist: specialistValue,
      assignedDoctor: assignedDoctorId,
      pendingAssignment: json['pendingAssignment']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
    };

    if (serialNumber != null) {
      data['serialNumber'] = serialNumber;
    }

    if (specialist != null && specialist!.isNotEmpty) {
      data['specialist'] = specialist;
      print('Adding specialist to JSON: $specialist');
    }

    if (assignedDoctor != null) {
      data['assignedDoctor'] = assignedDoctor;
    }

    if (pendingAssignment != null) {
      data['pendingAssignment'] = pendingAssignment;
    }

    if (status != null) {
      data['status'] = status;
    }

    print('Converting UserModel to JSON:');
    print('- Final data: $data');
    return data;
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? serialNumber,
    String? specialist,
    String? assignedDoctor,
    String? pendingAssignment,
    String? status,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      serialNumber: serialNumber ?? this.serialNumber,
      specialist: specialist ?? this.specialist,
      assignedDoctor: assignedDoctor ?? this.assignedDoctor,
      pendingAssignment: pendingAssignment ?? this.pendingAssignment,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, role: $role, serialNumber: $serialNumber, specialist: $specialist, assignedDoctor: $assignedDoctor, pendingAssignment: $pendingAssignment, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.role == role &&
        other.serialNumber == serialNumber &&
        other.specialist == specialist &&
        other.assignedDoctor == assignedDoctor &&
        other.pendingAssignment == pendingAssignment &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      name,
      role,
      serialNumber,
      specialist,
      assignedDoctor,
      pendingAssignment,
      status,
    );
  }
}
