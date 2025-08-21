


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tikitar_demo/controllers/company_controller.dart';
import 'package:tikitar_demo/features/companies/models/company_model.dart';
import 'package:tikitar_demo/features/profile/repositories/profile_repository.dart';


final companyProvider = AsyncNotifierProvider<CompanyRepository, List<CompanyModel>>(
  CompanyRepository.new,
);

class CompanyRepository extends AsyncNotifier<List<CompanyModel>>{
  @override
  Future<List<CompanyModel>> build() async {
    // read data from the riverpod_provider
    final profile = ref.read(profileProvider);

    if (profile == null) {
      // Wait until the profile is loaded externally
      // Or throw an exception / return empty
      return []; // or throw Exception("Profile not set");
    }

    final userId = profile.id;
    return await fetchAllCompanies(userId: userId);
  }

  Future<List<CompanyModel>> fetchAllCompanies({required int userId}) async {
    try {
      final responseList = await CompanyController.getOnlyCompanies(userId);
      return responseList.map((companyData) => CompanyModel.fromJson(companyData)).toList();
    } catch (e) {
      return [];
    }
  }
}