import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme.dart';
import '../../core/providers/providers.dart';
import '../../data/models/patient_model.dart';
import 'doctor_assignment_requests_screen.dart';

class AssignPatientsScreen extends ConsumerWidget {
  const AssignPatientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final apiService = ref.read(apiServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Assign Patients',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.assignment_ind_outlined),
            tooltip: 'Assignment Requests',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoctorAssignmentRequestsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => ref.refresh(patientsProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: patientsAsync.when(
        data: (patients) {
          final unassigned =
              patients
                  .where(
                    (p) =>
                        (p.status == 'inactive' || p.status == null) &&
                        (p.specialist == null || p.specialist!.isEmpty),
                  )
                  .toList();

          if (unassigned.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppColors.subtitle,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No Unassigned Patients',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'All patients are currently assigned to specialists.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.subtitle,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: unassigned.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final patient = unassigned[i];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(
                              patient.name.isNotEmpty
                                  ? patient.name[0].toUpperCase()
                                  : 'P',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (patient.email != null &&
                                    patient.email!.isNotEmpty)
                                  Text(
                                    patient.email!,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppColors.subtitle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Unassigned',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      if (patient.serialNumber != null &&
                          patient.serialNumber!.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Iconsax.scan_barcode,
                              size: 16,
                              color: AppColors.subtitle,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Serial: ${patient.serialNumber}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.subtitle,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                      ],
                      if (patient.status != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 12,
                              color:
                                  patient.status == 'active'
                                      ? AppColors.success
                                      : AppColors.warning,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Status: ${patient.status}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.subtitle,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(Iconsax.user_add, size: 18),
                          label: Text(
                            'Assign to Me',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed:
                              currentUser == null
                                  ? null
                                  : () => _assignPatientToDoctor(
                                    context,
                                    ref,
                                    apiService,
                                    currentUser.id,
                                    patient,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  SizedBox(height: 16),
                  Text(
                    'Error Loading Patients',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    e.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.subtitle,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(patientsProvider),
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Future<void> _assignPatientToDoctor(
    BuildContext context,
    WidgetRef ref,
    dynamic apiService,
    String doctorId,
    PatientModel patient,
  ) async {
    try {
      await apiService.directAssignPatientToDoctor(
        doctorId: doctorId,
        patientId: patient.id,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${patient.name} assigned successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      // Refresh the patients list
      ref.refresh(patientsProvider);

      // Also refresh current user data in case patient is viewing their profile
      ref.refresh(currentUserProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Failed to assign ${patient.name}: ${e.toString()}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
