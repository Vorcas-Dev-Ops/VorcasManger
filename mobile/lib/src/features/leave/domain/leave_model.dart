import 'package:freezed_annotation/freezed_annotation.dart';

part 'leave_model.freezed.dart';
part 'leave_model.g.dart';

@freezed
class LeaveModel with _$LeaveModel {
  const factory LeaveModel({
    required int id,
    @JsonKey(name: 'employee_id') required int employeeId,
    @JsonKey(name: 'leave_type') required String leaveType,
    @JsonKey(name: 'start_date') required String startDate,
    @JsonKey(name: 'end_date') required String endDate,
    String? reason,
    required String status,
    @JsonKey(name: 'employee_name') String? employeeName,
    @JsonKey(name: 'approved_by') int? approvedBy,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _LeaveModel;

  factory LeaveModel.fromJson(Map<String, dynamic> json) => _$LeaveModelFromJson(json);
}
