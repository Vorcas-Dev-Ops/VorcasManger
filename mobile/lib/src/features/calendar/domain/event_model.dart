import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_model.freezed.dart';
part 'event_model.g.dart';

@freezed
class EventModel with _$EventModel {
  const factory EventModel({
    required int id,
    required String title,
    String? description,
    required String eventDate,
    required String eventType, // 'Meeting' or 'Holiday'
    required int createdBy,
    required String createdAt,
  }) = _EventModel;

  factory EventModel.fromJson(Map<String, dynamic> json) => _$EventModelFromJson(json);
}
