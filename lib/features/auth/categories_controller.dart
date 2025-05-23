import 'package:tikitar_demo/core/network/api_base.dart';
import 'dart:developer' as developer;

class CategoryController {

  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final response = await ApiBase.get('/categories');
      final data = response['data'];
      developer.log("Categoreis from controller: $data", name: "CategoryController.fetchCategories");

      if (data != null && data is List && data.isNotEmpty) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('No categories found');
      }
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }
}