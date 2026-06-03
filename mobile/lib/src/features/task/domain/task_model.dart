import 'package:json_annotation/json_annotation.dart';

part 'task_model.g.dart';

@JsonSerializable()
class TaskModel {
  final int id;
  final String title;
  final String description;
  @JsonKey(name: 'assigned_to')
  final int? assignedTo;
  final String status;
  @JsonKey(name: 'due_date')
  final String? dueDate;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'task_type')
  final String? taskType;
  @JsonKey(name: 'start_time')
  final String? startTime;
  @JsonKey(name: 'meeting_link')
  final String? meetingLink;
  @JsonKey(name: 'assignee_ids')
  final List<int>? assigneeIds;
  @JsonKey(name: 'assignee_names')
  final String? assigneeNames;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    this.assignedTo,
    required this.status,
    this.dueDate,
    required this.createdAt,
    this.taskType,
    this.startTime,
    this.meetingLink,
    this.assigneeIds,
    this.assigneeNames,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => _$TaskModelFromJson(json);
  Map<String, dynamic> toJson() => _$TaskModelToJson(this);
}

