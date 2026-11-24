/// Wire models for the core's link-chain methods. Hand-written (no freezed)
/// so they need no code generation and stay in lockstep with the Go structs in
/// core/chains_types.go.

/// A chain saved in preferences. Hops are proxy/group names, entry first.
class SavedChain {
  const SavedChain({
    required this.id,
    required this.name,
    required this.hops,
    this.targetGroup,
    this.enabled = true,
    this.offered = true,
  });

  final int id;
  final String name;
  final List<String> hops;
  final String? targetGroup;
  final bool enabled;
  final bool offered;

  ChainSpec toSpec() => ChainSpec(
    id: id,
    name: name,
    hops: hops,
    offered: offered,
    targetGroup: targetGroup,
  );

  factory SavedChain.fromJson(Map<String, dynamic> json) => SavedChain(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: (json['name'] as String?) ?? '',
    hops: (json['hops'] as List?)?.cast<String>() ?? const [],
    targetGroup: json['targetGroup'] as String?,
    enabled: json['enabled'] as bool? ?? true,
    offered: json['offered'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hops': hops,
    if (targetGroup != null) 'targetGroup': targetGroup,
    'enabled': enabled,
    'offered': offered,
  };
}

class HopFingerprint {
  const HopFingerprint({
    required this.type,
    required this.server,
    required this.port,
  });

  final String type;
  final String server;
  final int port;

  factory HopFingerprint.fromJson(Map<String, dynamic> json) => HopFingerprint(
    type: (json['type'] as String?) ?? '',
    server: (json['server'] as String?) ?? '',
    port: (json['port'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'server': server,
    'port': port,
  };
}

/// One chain as the core expects it: hops are proxy/group names, entry first.
class ChainSpec {
  const ChainSpec({
    required this.id,
    required this.name,
    required this.hops,
    required this.offered,
    this.targetGroup,
    this.fingerprints,
    this.heal,
  });

  final int id;
  final String name;
  final List<String> hops;
  final bool offered;
  final String? targetGroup;
  final List<HopFingerprint?>? fingerprints;
  final bool? heal;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hops': hops,
    'offered': offered,
    if (targetGroup != null) 'target-group': targetGroup,
    if (fingerprints != null)
      'fingerprints': fingerprints!.map((f) => f?.toJson()).toList(),
    if (heal != null) 'heal': heal,
  };
}

class ChainIssue {
  const ChainIssue({
    required this.hop,
    required this.code,
    this.fingerprint,
    this.suggest = const [],
  });

  final int hop;
  final String code;
  final HopFingerprint? fingerprint;
  final List<String> suggest;

  factory ChainIssue.fromJson(Map<String, dynamic> json) => ChainIssue(
    hop: (json['hop'] as num?)?.toInt() ?? 0,
    code: (json['code'] as String?) ?? '',
    fingerprint: json['fingerprint'] == null
        ? null
        : HopFingerprint.fromJson(json['fingerprint'] as Map<String, dynamic>),
    suggest: (json['suggest'] as List?)?.cast<String>() ?? const [],
  );
}

class ChainMember {
  const ChainMember({
    required this.leaf,
    required this.server,
    required this.port,
  });

  final String leaf;
  final String server;
  final int port;

  factory ChainMember.fromJson(Map<String, dynamic> json) => ChainMember(
    leaf: (json['leaf'] as String?) ?? '',
    server: (json['server'] as String?) ?? '',
    port: (json['port'] as num?)?.toInt() ?? 0,
  );
}

class ChainReport {
  const ChainReport({
    required this.id,
    required this.group,
    required this.status,
    required this.issues,
    required this.members,
    this.hidden = const [],
    required this.udp,
    this.target,
  });

  final int id;
  final String group;
  final String status;
  final List<ChainIssue> issues;
  final Map<String, ChainMember> members;
  final List<String> hidden;
  final String udp;
  final String? target;

  factory ChainReport.fromJson(Map<String, dynamic> json) => ChainReport(
    id: (json['id'] as num?)?.toInt() ?? 0,
    group: (json['group'] as String?) ?? '',
    status: (json['status'] as String?) ?? '',
    issues: (json['issues'] as List?)
            ?.map((e) => ChainIssue.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    members: (json['members'] as Map?)?.map(
          (k, v) => MapEntry(
            k as String,
            ChainMember.fromJson(v as Map<String, dynamic>),
          ),
        ) ??
        const {},
    hidden: (json['hidden'] as List?)?.cast<String>() ?? const [],
    udp: (json['udp'] as String?) ?? '',
    target: json['target'] as String?,
  );
}

class InspectChainParams {
  const InspectChainParams({
    required this.hops,
    this.slot,
    this.targetGroup,
    this.mainGroupHint,
  });

  final List<String> hops;
  final int? slot;
  final String? targetGroup;
  final String? mainGroupHint;

  Map<String, dynamic> toJson() => {
    'hops': hops,
    if (slot != null) 'slot': slot,
    if (targetGroup != null) 'target-group': targetGroup,
    if (mainGroupHint != null) 'main-group-hint': mainGroupHint,
  };
}

class ChainInspection {
  const ChainInspection({
    required this.issues,
    required this.leaves,
    required this.udp,
    required this.blocked,
  });

  final List<ChainIssue> issues;
  final List<String> leaves;
  final List<bool> udp;
  final Map<String, String> blocked;

  factory ChainInspection.fromJson(Map<String, dynamic> json) => ChainInspection(
    issues: (json['issues'] as List?)
            ?.map((e) => ChainIssue.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    leaves: (json['leaves'] as List?)?.cast<String>() ?? const [],
    udp: (json['udp'] as List?)?.map((e) => e == true).toList() ?? const [],
    blocked: (json['blocked'] as Map?)
            ?.map((k, v) => MapEntry(k as String, v as String)) ??
        const {},
  );
}
