// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationRepositoryHash() =>
    r'e21c761bce1ed54592535e0088c9d39d59102c9e';

/// See also [notificationRepository].
@ProviderFor(notificationRepository)
final notificationRepositoryProvider =
    AutoDisposeProvider<NotificationRepository>.internal(
      notificationRepository,
      name: r'notificationRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationRepositoryRef =
    AutoDisposeProviderRef<NotificationRepository>;
String _$notificationsHash() => r'9595de262e869b78cab16aa062aed11eb32f68f0';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [notifications].
@ProviderFor(notifications)
const notificationsProvider = NotificationsFamily();

/// See also [notifications].
class NotificationsFamily extends Family<AsyncValue<List<NotificationModel>>> {
  /// See also [notifications].
  const NotificationsFamily();

  /// See also [notifications].
  NotificationsProvider call(int userId) {
    return NotificationsProvider(userId);
  }

  @override
  NotificationsProvider getProviderOverride(
    covariant NotificationsProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'notificationsProvider';
}

/// See also [notifications].
class NotificationsProvider
    extends AutoDisposeFutureProvider<List<NotificationModel>> {
  /// See also [notifications].
  NotificationsProvider(int userId)
    : this._internal(
        (ref) => notifications(ref as NotificationsRef, userId),
        from: notificationsProvider,
        name: r'notificationsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$notificationsHash,
        dependencies: NotificationsFamily._dependencies,
        allTransitiveDependencies:
            NotificationsFamily._allTransitiveDependencies,
        userId: userId,
      );

  NotificationsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final int userId;

  @override
  Override overrideWith(
    FutureOr<List<NotificationModel>> Function(NotificationsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NotificationsProvider._internal(
        (ref) => create(ref as NotificationsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<NotificationModel>> createElement() {
    return _NotificationsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationsProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NotificationsRef
    on AutoDisposeFutureProviderRef<List<NotificationModel>> {
  /// The parameter `userId` of this provider.
  int get userId;
}

class _NotificationsProviderElement
    extends AutoDisposeFutureProviderElement<List<NotificationModel>>
    with NotificationsRef {
  _NotificationsProviderElement(super.provider);

  @override
  int get userId => (origin as NotificationsProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
