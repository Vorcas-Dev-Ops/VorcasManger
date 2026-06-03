import 'package:json_annotation/json_annotation.dart';

part 'document_model.g.dart';

@JsonSerializable()
class DocumentModel {
  final int id;
  @JsonKey(name: 'employee_id')
  final int employeeId;
  final String title;
  @JsonKey(name: 'file_url')
  final String fileUrl;
  final String type;
  @JsonKey(name: 'created_at')
  final String createdAt;

  DocumentModel({
    required this.id,
    required this.employeeId,
    required this.title,
    required this.fileUrl,
    required this.type,
    required this.createdAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) => _$DocumentModelFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentModelToJson(this);
}
