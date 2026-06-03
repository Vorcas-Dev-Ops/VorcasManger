import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/api_client.dart';
import '../domain/event_model.dart';

part 'event_repository.g.dart';

class EventRepository {
  final Dio _dio;

  EventRepository(this._dio);

  Future<List<EventModel>> getEvents() async {
    try {
      final response = await _dio.get('/event');
      final data = response.data as List;
      return data.map((e) => EventModel.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createEvent(Map<String, dynamic> data) async {
    try {
      await _dio.post('/event', data: data);
    } catch (e) {
      rethrow;
    }
  }
}

@riverpod
EventRepository eventRepository(EventRepositoryRef ref) {
  return EventRepository(ref.watch(dioClientProvider));
}
