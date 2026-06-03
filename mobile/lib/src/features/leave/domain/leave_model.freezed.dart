// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leave_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LeaveModel _$LeaveModelFromJson(Map<String, dynamic> json) {
  return _LeaveModel.fromJson(json);
}

/// @nodoc
mixin _$LeaveModel {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'employee_id')
  int get employeeId => throw _privateConstructorUsedError;
  @JsonKey(name: 'leave_type')
  String get leaveType => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_date')
  String get startDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'end_date')
  String get endDate => throw _privateConstructorUsedError;
  String? get reason => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'employee_name')
  String? get employeeName => throw _privateConstructorUsedError;
  @JsonKey(name: 'approved_by')
  int? get approvedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this LeaveModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LeaveModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LeaveModelCopyWith<LeaveModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LeaveModelCopyWith<$Res> {
  factory $LeaveModelCopyWith(
    LeaveModel value,
    $Res Function(LeaveModel) then,
  ) = _$LeaveModelCopyWithImpl<$Res, LeaveModel>;
  @useResult
  $Res call({
    int id,
    @JsonKey(name: 'employee_id') int employeeId,
    @JsonKey(name: 'leave_type') String leaveType,
    @JsonKey(name: 'start_date') String startDate,
    @JsonKey(name: 'end_date') String endDate,
    String? reason,
    String status,
    @JsonKey(name: 'employee_name') String? employeeName,
    @JsonKey(name: 'approved_by') int? approvedBy,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class _$LeaveModelCopyWithImpl<$Res, $Val extends LeaveModel>
    implements $LeaveModelCopyWith<$Res> {
  _$LeaveModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LeaveModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? employeeId = null,
    Object? leaveType = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? reason = freezed,
    Object? status = null,
    Object? employeeName = freezed,
    Object? approvedBy = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            employeeId: null == employeeId
                ? _value.employeeId
                : employeeId // ignore: cast_nullable_to_non_nullable
                      as int,
            leaveType: null == leaveType
                ? _value.leaveType
                : leaveType // ignore: cast_nullable_to_non_nullable
                      as String,
            startDate: null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as String,
            endDate: null == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as String,
            reason: freezed == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            employeeName: freezed == employeeName
                ? _value.employeeName
                : employeeName // ignore: cast_nullable_to_non_nullable
                      as String?,
            approvedBy: freezed == approvedBy
                ? _value.approvedBy
                : approvedBy // ignore: cast_nullable_to_non_nullable
                      as int?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LeaveModelImplCopyWith<$Res>
    implements $LeaveModelCopyWith<$Res> {
  factory _$$LeaveModelImplCopyWith(
    _$LeaveModelImpl value,
    $Res Function(_$LeaveModelImpl) then,
  ) = __$$LeaveModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    @JsonKey(name: 'employee_id') int employeeId,
    @JsonKey(name: 'leave_type') String leaveType,
    @JsonKey(name: 'start_date') String startDate,
    @JsonKey(name: 'end_date') String endDate,
    String? reason,
    String status,
    @JsonKey(name: 'employee_name') String? employeeName,
    @JsonKey(name: 'approved_by') int? approvedBy,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class __$$LeaveModelImplCopyWithImpl<$Res>
    extends _$LeaveModelCopyWithImpl<$Res, _$LeaveModelImpl>
    implements _$$LeaveModelImplCopyWith<$Res> {
  __$$LeaveModelImplCopyWithImpl(
    _$LeaveModelImpl _value,
    $Res Function(_$LeaveModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LeaveModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? employeeId = null,
    Object? leaveType = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? reason = freezed,
    Object? status = null,
    Object? employeeName = freezed,
    Object? approvedBy = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$LeaveModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        employeeId: null == employeeId
            ? _value.employeeId
            : employeeId // ignore: cast_nullable_to_non_nullable
                  as int,
        leaveType: null == leaveType
            ? _value.leaveType
            : leaveType // ignore: cast_nullable_to_non_nullable
                  as String,
        startDate: null == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as String,
        endDate: null == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as String,
        reason: freezed == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        employeeName: freezed == employeeName
            ? _value.employeeName
            : employeeName // ignore: cast_nullable_to_non_nullable
                  as String?,
        approvedBy: freezed == approvedBy
            ? _value.approvedBy
            : approvedBy // ignore: cast_nullable_to_non_nullable
                  as int?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LeaveModelImpl implements _LeaveModel {
  const _$LeaveModelImpl({
    required this.id,
    @JsonKey(name: 'employee_id') required this.employeeId,
    @JsonKey(name: 'leave_type') required this.leaveType,
    @JsonKey(name: 'start_date') required this.startDate,
    @JsonKey(name: 'end_date') required this.endDate,
    this.reason,
    required this.status,
    @JsonKey(name: 'employee_name') this.employeeName,
    @JsonKey(name: 'approved_by') this.approvedBy,
    @JsonKey(name: 'created_at') this.createdAt,
  });

  factory _$LeaveModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LeaveModelImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'employee_id')
  final int employeeId;
  @override
  @JsonKey(name: 'leave_type')
  final String leaveType;
  @override
  @JsonKey(name: 'start_date')
  final String startDate;
  @override
  @JsonKey(name: 'end_date')
  final String endDate;
  @override
  final String? reason;
  @override
  final String status;
  @override
  @JsonKey(name: 'employee_name')
  final String? employeeName;
  @override
  @JsonKey(name: 'approved_by')
  final int? approvedBy;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;

  @override
  String toString() {
    return 'LeaveModel(id: $id, employeeId: $employeeId, leaveType: $leaveType, startDate: $startDate, endDate: $endDate, reason: $reason, status: $status, employeeName: $employeeName, approvedBy: $approvedBy, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LeaveModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.employeeId, employeeId) ||
                other.employeeId == employeeId) &&
            (identical(other.leaveType, leaveType) ||
                other.leaveType == leaveType) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.employeeName, employeeName) ||
                other.employeeName == employeeName) &&
            (identical(other.approvedBy, approvedBy) ||
                other.approvedBy == approvedBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    employeeId,
    leaveType,
    startDate,
    endDate,
    reason,
    status,
    employeeName,
    approvedBy,
    createdAt,
  );

  /// Create a copy of LeaveModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LeaveModelImplCopyWith<_$LeaveModelImpl> get copyWith =>
      __$$LeaveModelImplCopyWithImpl<_$LeaveModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LeaveModelImplToJson(this);
  }
}

abstract class _LeaveModel implements LeaveModel {
  const factory _LeaveModel({
    required final int id,
    @JsonKey(name: 'employee_id') required final int employeeId,
    @JsonKey(name: 'leave_type') required final String leaveType,
    @JsonKey(name: 'start_date') required final String startDate,
    @JsonKey(name: 'end_date') required final String endDate,
    final String? reason,
    required final String status,
    @JsonKey(name: 'employee_name') final String? employeeName,
    @JsonKey(name: 'approved_by') final int? approvedBy,
    @JsonKey(name: 'created_at') final String? createdAt,
  }) = _$LeaveModelImpl;

  factory _LeaveModel.fromJson(Map<String, dynamic> json) =
      _$LeaveModelImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'employee_id')
  int get employeeId;
  @override
  @JsonKey(name: 'leave_type')
  String get leaveType;
  @override
  @JsonKey(name: 'start_date')
  String get startDate;
  @override
  @JsonKey(name: 'end_date')
  String get endDate;
  @override
  String? get reason;
  @override
  String get status;
  @override
  @JsonKey(name: 'employee_name')
  String? get employeeName;
  @override
  @JsonKey(name: 'approved_by')
  int? get approvedBy;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;

  /// Create a copy of LeaveModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LeaveModelImplCopyWith<_$LeaveModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
