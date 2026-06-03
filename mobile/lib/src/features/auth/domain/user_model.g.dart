// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      roleId: (json['roleId'] as num).toInt(),
      roleName: json['roleName'] as String,
      employeeId: (json['employeeId'] as num).toInt(),
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      hierarchyLevel: (json['hierarchyLevel'] as num).toInt(),
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      phone: json['phone'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      joinedDate: json['joinedDate'] as String?,
      departmentName: json['departmentName'] as String?,
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'roleId': instance.roleId,
      'roleName': instance.roleName,
      'employeeId': instance.employeeId,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'hierarchyLevel': instance.hierarchyLevel,
      'mustChangePassword': instance.mustChangePassword,
      'phone': instance.phone,
      'profilePictureUrl': instance.profilePictureUrl,
      'joinedDate': instance.joinedDate,
      'departmentName': instance.departmentName,
    };
