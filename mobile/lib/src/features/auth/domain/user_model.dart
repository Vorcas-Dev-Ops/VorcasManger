import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required int id,
    required String email,
    required int roleId,
    required String roleName,
    required int employeeId,
    required String firstName,
    required String lastName,
    required int hierarchyLevel,
    @Default(false) bool mustChangePassword,
    String? phone,
    String? profilePictureUrl,
    String? joinedDate,
    String? departmentName,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}
