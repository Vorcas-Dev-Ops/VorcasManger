// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskModel _$TaskModelFromJson(Map<String, dynamic> json) => TaskModel(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String,
  assignedTo: (json['assigned_to'] as num?)?.toInt(),
  status: json['status'] as String,
  dueDate: json['due_date'] as String?,
  createdAt: json['created_at'] as String,
  taskType: json['task_type'] as String?,
  startTime: json['start_time'] as String?,
  meetingLink: json['meeting_link'] as String?,
  assigneeIds: (json['assignee_ids'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  assigneeNames: json['assignee_names'] as String?,
);

Map<String, dynamic> _$TaskModelToJson(TaskModel instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'assigned_to': instance.assignedTo,
  'status': instance.status,
  'due_date': instance.dueDate,
  'created_at': instance.createdAt,
  'task_type': instance.taskType,
  'start_time': instance.startTime,
  'meeting_link': instance.meetingLink,
  'assignee_ids': instance.assigneeIds,
  'assignee_names': instance.assigneeNames,
};
