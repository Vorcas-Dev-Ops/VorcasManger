// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_notifiers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$attendanceHistoryHash() => r'2e37672cd5e04264b80cc12c785a235658a1bedd';

/// See also [attendanceHistory].
@ProviderFor(attendanceHistory)
final attendanceHistoryProvider =
    AutoDisposeFutureProvider<List<Map<String, dynamic>>>.internal(
      attendanceHistory,
      name: r'attendanceHistoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$attendanceHistoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AttendanceHistoryRef =
    AutoDisposeFutureProviderRef<List<Map<String, dynamic>>>;
String _$leaveHistoryHash() => r'c9760b1e82a57e5db9b3b9208b82587cf235d845';

/// See also [leaveHistory].
@ProviderFor(leaveHistory)
final leaveHistoryProvider =
    AutoDisposeFutureProvider<List<Map<String, dynamic>>>.internal(
      leaveHistory,
      name: r'leaveHistoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$leaveHistoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LeaveHistoryRef =
    AutoDisposeFutureProviderRef<List<Map<String, dynamic>>>;
String _$leaveBalancesHash() => r'888f275403b51eb3f7ce3ce04aab0034d7bca8aa';

/// See also [leaveBalances].
@ProviderFor(leaveBalances)
final leaveBalancesProvider =
    AutoDisposeFutureProvider<List<Map<String, dynamic>>>.internal(
      leaveBalances,
      name: r'leaveBalancesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$leaveBalancesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LeaveBalancesRef =
    AutoDisposeFutureProviderRef<List<Map<String, dynamic>>>;
String _$employeeTasksHash() => r'89b8971342a0d8b601fb678b3a6c899cd4d7ff2a';

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

/// See also [employeeTasks].
@ProviderFor(employeeTasks)
const employeeTasksProvider = EmployeeTasksFamily();

/// See also [employeeTasks].
class EmployeeTasksFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [employeeTasks].
  const EmployeeTasksFamily();

  /// See also [employeeTasks].
  EmployeeTasksProvider call(int employeeId) {
    return EmployeeTasksProvider(employeeId);
  }

  @override
  EmployeeTasksProvider getProviderOverride(
    covariant EmployeeTasksProvider provider,
  ) {
    return call(provider.employeeId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'employeeTasksProvider';
}

/// See also [employeeTasks].
class EmployeeTasksProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [employeeTasks].
  EmployeeTasksProvider(int employeeId)
    : this._internal(
        (ref) => employeeTasks(ref as EmployeeTasksRef, employeeId),
        from: employeeTasksProvider,
        name: r'employeeTasksProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$employeeTasksHash,
        dependencies: EmployeeTasksFamily._dependencies,
        allTransitiveDependencies:
            EmployeeTasksFamily._allTransitiveDependencies,
        employeeId: employeeId,
      );

  EmployeeTasksProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.employeeId,
  }) : super.internal();

  final int employeeId;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(EmployeeTasksRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EmployeeTasksProvider._internal(
        (ref) => create(ref as EmployeeTasksRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        employeeId: employeeId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _EmployeeTasksProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EmployeeTasksProvider && other.employeeId == employeeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, employeeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EmployeeTasksRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `employeeId` of this provider.
  int get employeeId;
}

class _EmployeeTasksProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with EmployeeTasksRef {
  _EmployeeTasksProviderElement(super.provider);

  @override
  int get employeeId => (origin as EmployeeTasksProvider).employeeId;
}

String _$attendanceNotifierHash() =>
    r'aadfa0463296d9f41798a6ad7d338bf51b02f7ce';

/// See also [AttendanceNotifier].
@ProviderFor(AttendanceNotifier)
final attendanceNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      AttendanceNotifier,
      Map<String, dynamic>?
    >.internal(
      AttendanceNotifier.new,
      name: r'attendanceNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$attendanceNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AttendanceNotifier = AutoDisposeAsyncNotifier<Map<String, dynamic>?>;
String _$leaveNotifierHash() => r'40da0f0037bcbc295dfebb0736a16a6c570b00c0';

/// See also [LeaveNotifier].
@ProviderFor(LeaveNotifier)
final leaveNotifierProvider =
    AutoDisposeAsyncNotifierProvider<LeaveNotifier, void>.internal(
      LeaveNotifier.new,
      name: r'leaveNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$leaveNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LeaveNotifier = AutoDisposeAsyncNotifier<void>;
String _$taskNotifierHash() => r'f7bc0a39e1a8f642d50846bf198907adcb7ad317';

/// See also [TaskNotifier].
@ProviderFor(TaskNotifier)
final taskNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      TaskNotifier,
      List<Map<String, dynamic>>
    >.internal(
      TaskNotifier.new,
      name: r'taskNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$taskNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TaskNotifier = AutoDisposeAsyncNotifier<List<Map<String, dynamic>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
