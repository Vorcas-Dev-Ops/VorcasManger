import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/event_model.dart';
import '../data/event_repository.dart';

part 'event_notifier.g.dart';

@riverpod
class EventNotifier extends _$EventNotifier {
  @override
  FutureOr<List<EventModel>> build() async {
    return _fetchEvents();
  }

  Future<List<EventModel>> _fetchEvents() async {
    return await ref.watch(eventRepositoryProvider).getEvents();
  }

  Future<void> refreshEvents() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchEvents());
  }

  Future<void> createEvent(Map<String, dynamic> data) async {
    await ref.read(eventRepositoryProvider).createEvent(data);
    await refreshEvents();
  }
}
