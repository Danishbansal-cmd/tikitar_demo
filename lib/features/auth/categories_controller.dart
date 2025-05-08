import 'package:tikitar_demo/core/network/api_base.dart';

class CategoryController {

  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final response = await ApiBase.get('/categories');
      final data = response['data'];
      print("Categoreis from controller: $data");

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