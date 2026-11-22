// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../traffic_statistics.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How often live connections are snapshotted into the history table.

@ProviderFor(trafficSampleInterval)
final trafficSampleIntervalProvider = TrafficSampleIntervalProvider._();

/// How often live connections are snapshotted into the history table.

final class TrafficSampleIntervalProvider
    extends $FunctionalProvider<Duration, Duration, Duration>
    with $Provider<Duration> {
  /// How often live connections are snapshotted into the history table.
  TrafficSampleIntervalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trafficSampleIntervalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trafficSampleIntervalHash();

  @$internal
  @override
  $ProviderElement<Duration> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Duration create(Ref ref) {
    return trafficSampleInterval(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Duration value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Duration>(value),
    );
  }
}

String _$trafficSampleIntervalHash() =>
    r'232d72ae6f469f6871da0240e55a849d5fe18a6b';

/// How long history rows are kept before being pruned.

@ProviderFor(trafficHistoryRetention)
final trafficHistoryRetentionProvider = TrafficHistoryRetentionProvider._();

/// How long history rows are kept before being pruned.

final class TrafficHistoryRetentionProvider
    extends $FunctionalProvider<Duration, Duration, Duration>
    with $Provider<Duration> {
  /// How long history rows are kept before being pruned.
  TrafficHistoryRetentionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trafficHistoryRetentionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trafficHistoryRetentionHash();

  @$internal
  @override
  $ProviderElement<Duration> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Duration create(Ref ref) {
    return trafficHistoryRetention(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Duration value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Duration>(value),
    );
  }
}

String _$trafficHistoryRetentionHash() =>
    r'7da4a34132b90abcad9afb5078846436d9f187ef';

/// Periodically persists the live connection list so the statistics page has
/// history. Runs only while the core is connected and the app is visible.

@ProviderFor(TrafficSampler)
final trafficSamplerProvider = TrafficSamplerProvider._();

/// Periodically persists the live connection list so the statistics page has
/// history. Runs only while the core is connected and the app is visible.
final class TrafficSamplerProvider
    extends $NotifierProvider<TrafficSampler, void> {
  /// Periodically persists the live connection list so the statistics page has
  /// history. Runs only while the core is connected and the app is visible.
  TrafficSamplerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trafficSamplerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trafficSamplerHash();

  @$internal
  @override
  TrafficSampler create() => TrafficSampler();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$trafficSamplerHash() => r'3adbd587d9b19fffbec961d2cbe2c420da981781';

/// Periodically persists the live connection list so the statistics page has
/// history. Runs only while the core is connected and the app is visible.

abstract class _$TrafficSampler extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The range a statistics view currently shows: the start of the period.

@ProviderFor(TrafficRange)
final trafficRangeProvider = TrafficRangeProvider._();

/// The range a statistics view currently shows: the start of the period.
final class TrafficRangeProvider
    extends $NotifierProvider<TrafficRange, DateTime> {
  /// The range a statistics view currently shows: the start of the period.
  TrafficRangeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trafficRangeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trafficRangeHash();

  @$internal
  @override
  TrafficRange create() => TrafficRange();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$trafficRangeHash() => r'3b5639ddf9ca66a27f23cf96141fd1265d2b8037';

/// The range a statistics view currently shows: the start of the period.

abstract class _$TrafficRange extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Loads history for the selected period and aggregates it off-isolate.

@ProviderFor(trafficStatistics)
final trafficStatisticsProvider = TrafficStatisticsFamily._();

/// Loads history for the selected period and aggregates it off-isolate.

final class TrafficStatisticsProvider
    extends
        $FunctionalProvider<
          AsyncValue<TrafficStatistics>,
          TrafficStatistics,
          FutureOr<TrafficStatistics>
        >
    with
        $FutureModifier<TrafficStatistics>,
        $FutureProvider<TrafficStatistics> {
  /// Loads history for the selected period and aggregates it off-isolate.
  TrafficStatisticsProvider._({
    required TrafficStatisticsFamily super.from,
    required (TrafficPeriod, TrafficRankKind) super.argument,
  }) : super(
         retry: null,
         name: r'trafficStatisticsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trafficStatisticsHash();

  @override
  String toString() {
    return r'trafficStatisticsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<TrafficStatistics> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TrafficStatistics> create(Ref ref) {
    final argument = this.argument as (TrafficPeriod, TrafficRankKind);
    return trafficStatistics(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is TrafficStatisticsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trafficStatisticsHash() => r'c31220d9ae53c99c83d65455dccd13a727b86890';

/// Loads history for the selected period and aggregates it off-isolate.

final class TrafficStatisticsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<TrafficStatistics>,
          (TrafficPeriod, TrafficRankKind)
        > {
  TrafficStatisticsFamily._()
    : super(
        retry: null,
        name: r'trafficStatisticsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Loads history for the selected period and aggregates it off-isolate.

  TrafficStatisticsProvider call(TrafficPeriod period, TrafficRankKind kind) =>
      TrafficStatisticsProvider._(argument: (period, kind), from: this);

  @override
  String toString() => r'trafficStatisticsProvider';
}

/// Per-app traffic for one usage period, with installed-app labels resolved.

@ProviderFor(appUsage)
final appUsageProvider = AppUsageFamily._();

/// Per-app traffic for one usage period, with installed-app labels resolved.

final class AppUsageProvider
    extends
        $FunctionalProvider<AsyncValue<AppUsage>, AppUsage, FutureOr<AppUsage>>
    with $FutureModifier<AppUsage>, $FutureProvider<AppUsage> {
  /// Per-app traffic for one usage period, with installed-app labels resolved.
  AppUsageProvider._({
    required AppUsageFamily super.from,
    required AppUsagePeriod super.argument,
  }) : super(
         retry: null,
         name: r'appUsageProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$appUsageHash();

  @override
  String toString() {
    return r'appUsageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AppUsage> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AppUsage> create(Ref ref) {
    final argument = this.argument as AppUsagePeriod;
    return appUsage(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AppUsageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$appUsageHash() => r'2c657ff5209880ce8cbbd74c34903d1a01a91b15';

/// Per-app traffic for one usage period, with installed-app labels resolved.

final class AppUsageFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<AppUsage>, AppUsagePeriod> {
  AppUsageFamily._()
    : super(
        retry: null,
        name: r'appUsageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Per-app traffic for one usage period, with installed-app labels resolved.

  AppUsageProvider call(AppUsagePeriod period) =>
      AppUsageProvider._(argument: period, from: this);

  @override
  String toString() => r'appUsageProvider';
}
