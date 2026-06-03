// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LeaveModelImpl _$$LeaveModelImplFromJson(Map<String, dynamic> json) =>
    _$LeaveModelImpl(
      id: (json['id'] as num).toInt(),
      employeeId: (json['employee_id'] as num).toInt(),
      leaveType: json['leave_type'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      reason: json['reason'] as String?,
      status: json['status'] as String,
      employeeName: json['employee_name'] as String?,
      approvedBy: (json['approved_by'] as num?)?.toInt(),
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$$LeaveModelImplToJson(_$LeaveModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'employee_id': instance.employeeId,
      'leave_type': instance.leaveType,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'reason': instance.reason,
      'status': instance.status,
      'employee_name': instance.employeeName,
      'approved_by': instance.approvedBy,
      'created_at': instance.createdAt,
    };
