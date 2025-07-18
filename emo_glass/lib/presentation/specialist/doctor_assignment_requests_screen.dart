import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme.dart';
import '../../core/providers/providers.dart';
import '../../data/services/api_service.dart';

class DoctorAssignmentRequestsScreen extends ConsumerStatefulWidget {
  const DoctorAssignmentRequestsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DoctorAssignmentRequestsScreen> createState() =>
      _DoctorAssignmentRequestsScreenState();
}

class _DoctorAssignmentRequestsScreenState
    extends ConsumerState<DoctorAssignmentRequestsScreen> {
  Timer? _pollingTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.refresh(doctorAssignmentRequestsProvider);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleRequestAction(
    BuildContext context,
    String requestId,
  ) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(apiServiceProvider).acceptAssignmentRequest(requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment request accepted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the providers
      if (!mounted) return;
      ref.refresh(doctorAssignmentRequestsProvider);
      ref.refresh(patientsProvider);
      ref.refresh(assignedPatientsProvider);
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Error processing request';

      if (e.toString().contains('not found')) {
        errorMessage = 'Request not found. It may have been processed already.';
      } else if (e.toString().contains('unauthorized')) {
        errorMessage = 'You are not authorized to process this request.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(doctorAssignmentRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(doctorAssignmentRequestsProvider);
            },
            tooltip: 'Refresh requests',
          ),
        ],
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending requests',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(doctorAssignmentRequestsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                final patientName = request['patientName'] ?? 'Unknown Patient';
                final patientId = request['patientId'] ?? '';
                final timestamp = request['createdAt'] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(Icons.person)),
                    title: Text(patientName),
                    subtitle: Text('Requested: $timestamp'),
                    trailing:
                        _isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : IconButton(
                              icon: const Icon(Icons.check),
                              color: Colors.green,
                              onPressed:
                                  () => _handleRequestAction(
                                    context,
                                    request['_id'],
                                  ),
                              tooltip: 'Accept request',
                            ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading requests',
                    style: TextStyle(fontSize: 18, color: Colors.red[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
