class CompanyModel {
  final int? id;
  final int? userId;
  final int? companyId;
  final int? categoryId;
  final String? name;

  CompanyModel({
    this.id,
    this.userId,
    this.companyId,
    this.categoryId,
    this.name,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'],
      userId: json['user_id'],
      companyId: json['company_id'],
      categoryId: json['category_id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'company_id': companyId,
      'category_id': categoryId,
      'name': name,
    };
  }
}
