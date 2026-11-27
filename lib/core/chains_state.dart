import 'package:skyward/models/models.dart';

/// The chains to materialize on the next setup, kept outside the freezed
/// SetupParams so it needs no generated-code changes. The chain editor sets
/// this before an apply; setupConfig folds it into the arguments sent to the
/// core.
List<ChainSpec>? _chains;
String? _mainGroupHint;

void setActiveChains(List<ChainSpec>? chains, {String? mainGroupHint}) {
  _chains = chains;
  _mainGroupHint = mainGroupHint;
}

List<ChainSpec>? get activeChains => _chains;
String? get activeMainGroupHint => _mainGroupHint;
