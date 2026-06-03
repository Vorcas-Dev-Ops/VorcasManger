import 'package:json_annotation/json_annotation.dart';

part 'department_model.g.dart';

@JsonSerializable()
class DepartmentModel {
  final int id;
  final String name;
  final String description;

  DepartmentModel({required this.id, required this.name, required this.description});

  factory DepartmentModel.fromJson(Map<String, dynamic> json) => DepartmentModel(
        id: json['id'] as int,
        name: json['name'] as String? ?? 'Unknown Department',
        description: json['description'] as String? ?? '',
      );
  Map<String, dynamic> toJson() => _$DepartmentModelToJson(this);
}
