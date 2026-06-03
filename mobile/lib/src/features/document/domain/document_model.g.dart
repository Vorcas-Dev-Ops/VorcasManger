// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentModel _$DocumentModelFromJson(Map<String, dynamic> json) =>
    DocumentModel(
      id: (json['id'] as num).toInt(),
      employeeId: (json['employee_id'] as num).toInt(),
      title: json['title'] as String,
      fileUrl: json['file_url'] as String,
      type: json['type'] as String,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$DocumentModelToJson(DocumentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'employee_id': instance.employeeId,
      'title': instance.title,
      'file_url': instance.fileUrl,
      'type': instance.type,
      'created_at': instance.createdAt,
    };
