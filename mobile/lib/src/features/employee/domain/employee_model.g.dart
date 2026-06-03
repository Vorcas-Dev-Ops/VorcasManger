// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmployeeModel _$EmployeeModelFromJson(Map<String, dynamic> json) =>
    EmployeeModel(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      employeeId: json['employee_id'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phone: json['phone'] as String?,
      departmentId: (json['department_id'] as num).toInt(),
      roleId: (json['role_id'] as num).toInt(),
      supervisorId: (json['supervisor_id'] as num?)?.toInt(),
      hireDate: json['hire_date'] as String?,
      status: json['status'] as String?,
      hierarchyLevel: (json['hierarchy_level'] as num?)?.toInt(),
      roleName: json['role_name'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
    );

Map<String, dynamic> _$EmployeeModelToJson(EmployeeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'employee_id': instance.employeeId,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'phone': instance.phone,
      'department_id': instance.departmentId,
      'role_id': instance.roleId,
      'supervisor_id': instance.supervisorId,
      'hire_date': instance.hireDate,
      'status': instance.status,
      'hierarchy_level': instance.hierarchyLevel,
      'role_name': instance.roleName,
      'profile_picture_url': instance.profilePictureUrl,
    };
