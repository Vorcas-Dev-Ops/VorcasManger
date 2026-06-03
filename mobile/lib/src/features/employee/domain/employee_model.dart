import 'package:json_annotation/json_annotation.dart';

part 'employee_model.g.dart';

@JsonSerializable()
class EmployeeModel {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'employee_id')
  final String? employeeId;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  final String? phone;
  @JsonKey(name: 'department_id')
  final int departmentId;
  @JsonKey(name: 'role_id')
  final int roleId;
  @JsonKey(name: 'supervisor_id')
  final int? supervisorId;
  @JsonKey(name: 'hire_date')
  final String? hireDate;
  final String? status;
  @JsonKey(name: 'hierarchy_level')
  final int? hierarchyLevel;
  @JsonKey(name: 'role_name')
  final String? roleName;
  @JsonKey(name: 'profile_picture_url')
  final String? profilePictureUrl;

  EmployeeModel({
    required this.id,
    required this.userId,
    this.employeeId,
    this.firstName,
    this.lastName,
    this.phone,
    required this.departmentId,
    required this.roleId,
    this.supervisorId,
    this.hireDate,
    this.status,
    this.hierarchyLevel,
    this.roleName,
    this.profilePictureUrl,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory EmployeeModel.fromJson(Map<String, dynamic> json) => _$EmployeeModelFromJson(json);
  Map<String, dynamic> toJson() => _$EmployeeModelToJson(this);
}
