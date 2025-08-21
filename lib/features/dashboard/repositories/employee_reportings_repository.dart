import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tikitar_demo/controllers/user_controller.dart';
import 'package:tikitar_demo/features/dashboard/models/employee_reportings.dart';
import 'package:tikitar_demo/features/profile/repositories/profile_repository.dart';
import 'dart:developer' as developer;


// creating provider
final employeeReportingsProvider = AsyncNotifierProvider<EmployeeReportingsRepository, List<EmployeeReportings>>(EmployeeReportingsRepository.new);

class EmployeeReportingsRepository extends AsyncNotifier<List<EmployeeReportings>>{
  @override
  Future<List<EmployeeReportings>> build() async {
    // read data from the riverpod_provider
    final profile = ref.read(profileProvider);

    if (profile == null) {
      // Wait until the profile is loaded externally
      // Or throw an exception / return empty
      debugPrint("profile is null. Cannot fetch employee reportings.");
      return []; // or throw Exception("Profile not set");
    }

    final userId = profile.id;
    
    debugPrint("userId: $userId");
    return await fetchEmployeeReportings(userId: userId);
  }

  Future<List<EmployeeReportings>> fetchEmployeeReportings({required int userId}) async {
    try {
      final responseMap = await UserController.specificEmployeesReporting(userId);
      final employeesList = responseMap['employees'];
      
      if (employeesList == null || employeesList is! List) {
        return [];
      }
      
      return employeesList
          .map((employee) => EmployeeReportings.fromJson(employee))
          .toList();
    } catch (e, stack) {
      developer.log("Error in fetchEmployeeReportings: $e", name: "EmployeeReportingsRepository", error: e, stackTrace: stack);
      return [];
    }
  }
}


