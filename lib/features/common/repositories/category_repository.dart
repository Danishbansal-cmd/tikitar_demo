import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tikitar_demo/controllers/categories_controller.dart';
import 'package:tikitar_demo/features/common/models/category_model.dart';


final categoryProvider =
    AsyncNotifierProvider<CategoryNotifier, List<CategoryModel>>(
  CategoryNotifier.new,
);

// 1. Notifier class
class CategoryNotifier extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() async {
    // You can replace this with your API call
    return await fetchCategories();
  }

  // Optional: Manual reload or update method
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await fetchCategories();
    });
  }

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final categoryMaps = await CategoryController.fetchCategories();
      return categoryMaps.map((category) => CategoryModel.fromJson(category)).toList();
    } catch (e) {
      // Optional: Log or handle errors if needed
      debugPrint("error fetchCategories: $e");
      return [];
    }
  }
}

