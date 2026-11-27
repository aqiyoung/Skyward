import 'package:skyward/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'generated/update.g.dart';

/// The download that finished verification and is waiting for installation.
@riverpod
class PreparedUpdateState extends _$PreparedUpdateState {
  @override
  PreparedUpdate? build() => null;

  void set(PreparedUpdate? update) => state = update;
}
