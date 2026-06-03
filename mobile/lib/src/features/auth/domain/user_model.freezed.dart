// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return _UserModel.fromJson(json);
}

/// @nodoc
mixin _$UserModel {
  int get id => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  int get roleId => throw _privateConstructorUsedError;
  String get roleName => throw _privateConstructorUsedError;
  int get employeeId => throw _privateConstructorUsedError;
  String get firstName => throw _privateConstructorUsedError;
  String get lastName => throw _privateConstructorUsedError;
  int get hierarchyLevel => throw _privateConstructorUsedError;
  bool get mustChangePassword => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  String? get profilePictureUrl => throw _privateConstructorUsedError;
  String? get joinedDate => throw _privateConstructorUsedError;
  String? get departmentName => throw _privateConstructorUsedError;

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call({
    int id,
    String email,
    int roleId,
    String roleName,
    int employeeId,
    String firstName,
    String lastName,
    int hierarchyLevel,
    bool mustChangePassword,
    String? phone,
    String? profilePictureUrl,
    String? joinedDate,
    String? departmentName,
  });
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? roleId = null,
    Object? roleName = null,
    Object? employeeId = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? hierarchyLevel = null,
    Object? mustChangePassword = null,
    Object? phone = freezed,
    Object? profilePictureUrl = freezed,
    Object? joinedDate = freezed,
    Object? departmentName = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            roleId: null == roleId
                ? _value.roleId
                : roleId // ignore: cast_nullable_to_non_nullable
                      as int,
            roleName: null == roleName
                ? _value.roleName
                : roleName // ignore: cast_nullable_to_non_nullable
                      as String,
            employeeId: null == employeeId
                ? _value.employeeId
                : employeeId // ignore: cast_nullable_to_non_nullable
                      as int,
            firstName: null == firstName
                ? _value.firstName
                : firstName // ignore: cast_nullable_to_non_nullable
                      as String,
            lastName: null == lastName
                ? _value.lastName
                : lastName // ignore: cast_nullable_to_non_nullable
                      as String,
            hierarchyLevel: null == hierarchyLevel
                ? _value.hierarchyLevel
                : hierarchyLevel // ignore: cast_nullable_to_non_nullable
                      as int,
            mustChangePassword: null == mustChangePassword
                ? _value.mustChangePassword
                : mustChangePassword // ignore: cast_nullable_to_non_nullable
                      as bool,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            profilePictureUrl: freezed == profilePictureUrl
                ? _value.profilePictureUrl
                : profilePictureUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            joinedDate: freezed == joinedDate
                ? _value.joinedDate
                : joinedDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            departmentName: freezed == departmentName
                ? _value.departmentName
                : departmentName // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
    _$UserModelImpl value,
    $Res Function(_$UserModelImpl) then,
  ) = __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String email,
    int roleId,
    String roleName,
    int employeeId,
    String firstName,
    String lastName,
    int hierarchyLevel,
    bool mustChangePassword,
    String? phone,
    String? profilePictureUrl,
    String? joinedDate,
    String? departmentName,
  });
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
    _$UserModelImpl _value,
    $Res Function(_$UserModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? roleId = null,
    Object? roleName = null,
    Object? employeeId = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? hierarchyLevel = null,
    Object? mustChangePassword = null,
    Object? phone = freezed,
    Object? profilePictureUrl = freezed,
    Object? joinedDate = freezed,
    Object? departmentName = freezed,
  }) {
    return _then(
      _$UserModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        roleId: null == roleId
            ? _value.roleId
            : roleId // ignore: cast_nullable_to_non_nullable
                  as int,
        roleName: null == roleName
            ? _value.roleName
            : roleName // ignore: cast_nullable_to_non_nullable
                  as String,
        employeeId: null == employeeId
            ? _value.employeeId
            : employeeId // ignore: cast_nullable_to_non_nullable
                  as int,
        firstName: null == firstName
            ? _value.firstName
            : firstName // ignore: cast_nullable_to_non_nullable
                  as String,
        lastName: null == lastName
            ? _value.lastName
            : lastName // ignore: cast_nullable_to_non_nullable
                  as String,
        hierarchyLevel: null == hierarchyLevel
            ? _value.hierarchyLevel
            : hierarchyLevel // ignore: cast_nullable_to_non_nullable
                  as int,
        mustChangePassword: null == mustChangePassword
            ? _value.mustChangePassword
            : mustChangePassword // ignore: cast_nullable_to_non_nullable
                  as bool,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        profilePictureUrl: freezed == profilePictureUrl
            ? _value.profilePictureUrl
            : profilePictureUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        joinedDate: freezed == joinedDate
            ? _value.joinedDate
            : joinedDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        departmentName: freezed == departmentName
            ? _value.departmentName
            : departmentName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserModelImpl implements _UserModel {
  const _$UserModelImpl({
    required this.id,
    required this.email,
    required this.roleId,
    required this.roleName,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.hierarchyLevel,
    this.mustChangePassword = false,
    this.phone,
    this.profilePictureUrl,
    this.joinedDate,
    this.departmentName,
  });

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

  @override
  final int id;
  @override
  final String email;
  @override
  final int roleId;
  @override
  final String roleName;
  @override
  final int employeeId;
  @override
  final String firstName;
  @override
  final String lastName;
  @override
  final int hierarchyLevel;
  @override
  @JsonKey()
  final bool mustChangePassword;
  @override
  final String? phone;
  @override
  final String? profilePictureUrl;
  @override
  final String? joinedDate;
  @override
  final String? departmentName;

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, roleId: $roleId, roleName: $roleName, employeeId: $employeeId, firstName: $firstName, lastName: $lastName, hierarchyLevel: $hierarchyLevel, mustChangePassword: $mustChangePassword, phone: $phone, profilePictureUrl: $profilePictureUrl, joinedDate: $joinedDate, departmentName: $departmentName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.roleId, roleId) || other.roleId == roleId) &&
            (identical(other.roleName, roleName) ||
                other.roleName == roleName) &&
            (identical(other.employeeId, employeeId) ||
                other.employeeId == employeeId) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.hierarchyLevel, hierarchyLevel) ||
                other.hierarchyLevel == hierarchyLevel) &&
            (identical(other.mustChangePassword, mustChangePassword) ||
                other.mustChangePassword == mustChangePassword) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.profilePictureUrl, profilePictureUrl) ||
                other.profilePictureUrl == profilePictureUrl) &&
            (identical(other.joinedDate, joinedDate) ||
                other.joinedDate == joinedDate) &&
            (identical(other.departmentName, departmentName) ||
                other.departmentName == departmentName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    email,
    roleId,
    roleName,
    employeeId,
    firstName,
    lastName,
    hierarchyLevel,
    mustChangePassword,
    phone,
    profilePictureUrl,
    joinedDate,
    departmentName,
  );

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserModelImplToJson(this);
  }
}

abstract class _UserModel implements UserModel {
  const factory _UserModel({
    required final int id,
    required final String email,
    required final int roleId,
    required final String roleName,
    required final int employeeId,
    required final String firstName,
    required final String lastName,
    required final int hierarchyLevel,
    final bool mustChangePassword,
    final String? phone,
    final String? profilePictureUrl,
    final String? joinedDate,
    final String? departmentName,
  }) = _$UserModelImpl;

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  @override
  int get id;
  @override
  String get email;
  @override
  int get roleId;
  @override
  String get roleName;
  @override
  int get employeeId;
  @override
  String get firstName;
  @override
  String get lastName;
  @override
  int get hierarchyLevel;
  @override
  bool get mustChangePassword;
  @override
  String? get phone;
  @override
  String? get profilePictureUrl;
  @override
  String? get joinedDate;
  @override
  String? get departmentName;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
