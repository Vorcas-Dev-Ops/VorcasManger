// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AttendanceModelImpl _$$AttendanceModelImplFromJson(
  Map<String, dynamic> json,
) => _$AttendanceModelImpl(
  id: (json['id'] as num).toInt(),
  checkInTime: json['checkInTime'] as String?,
  checkOutTime: json['checkOutTime'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  date: json['date'] as String,
  workHours: (json['workHours'] as num?)?.toDouble(),
);

Map<String, dynamic> _$$AttendanceModelImplToJson(
  _$AttendanceModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'checkInTime': instance.checkInTime,
  'checkOutTime': instance.checkOutTime,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'date': instance.date,
  'workHours': instance.workHours,
};
