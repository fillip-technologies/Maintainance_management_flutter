import 'issue_model.dart';

class HardwareTypeModel {
  final String id;
  final String name;
  final Map<String, dynamic> specFields;
  final List<IssueCategoryModel> issueCategories;

  const HardwareTypeModel({
    required this.id,
    required this.name,
    this.specFields = const {},
    this.issueCategories = const [],
  });

  factory HardwareTypeModel.fromJson(Map<String, dynamic> json) {
    final catList = (json['issueCategories'] ?? json['issue_categories']) as List<dynamic>?;

    return HardwareTypeModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      specFields: (json['specFields'] ?? json['spec_fields']) as Map<String, dynamic>? ?? const {},
      issueCategories: catList
              ?.map((e) => IssueCategoryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'spec_fields': specFields,
      'issue_categories': issueCategories.map((e) => e.toJson()).toList(),
    };
  }
}
