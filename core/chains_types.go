package core

// Chain wire types shared with the host. Ported from ReClash's Go core so the
// dashboard can describe and inspect link chains built from proxy hops.

type ChainSpec struct {
	ID           int                 `json:"id"`
	Name         string              `json:"name"`
	Hops         []string            `json:"hops"`
	Offered      bool                `json:"offered"`
	TargetGroup  *string             `json:"target-group"`
	Fingerprints []*ChainFingerprint `json:"fingerprints,omitempty"`
	// Heal lets a missing hop take the one node its fingerprint matches, for
	// chains nobody on the device can repair by hand.
	Heal bool `json:"heal,omitempty"`
}

type ChainFingerprint struct {
	Type   string `json:"type"`
	Server string `json:"server"`
	Port   int    `json:"port"`
}

type ChainIssue struct {
	Hop         int               `json:"hop"`
	Code        string            `json:"code"`
	Fingerprint *ChainFingerprint `json:"fingerprint,omitempty"`
	Suggest     []string          `json:"suggest,omitempty"`
	// The hop whose candidate makes the issue, which for a UDP mismatch is
	// the one that cannot carry it rather than the one that needs it.
	cause int
}

type ChainMember struct {
	Leaf   string `json:"leaf"`
	Server string `json:"server"`
	Port   int    `json:"port"`
}

type ChainReport struct {
	ID      int                    `json:"id"`
	Group   string                 `json:"group"`
	Status  string                 `json:"status"`
	Issues  []ChainIssue           `json:"issues"`
	Members map[string]ChainMember `json:"members"`
	Hidden  []string               `json:"hidden,omitempty"`
	UDP     string                 `json:"udp"`
	Target  *string                `json:"target"`
}

type InspectChainParams struct {
	Hops          []string `json:"hops"`
	Slot          *int     `json:"slot,omitempty"`
	TargetGroup   *string  `json:"target-group,omitempty"`
	MainGroupHint string   `json:"main-group-hint,omitempty"`
}

type ChainInspection struct {
	Issues  []ChainIssue      `json:"issues"`
	Leaves  []string          `json:"leaves"`
	UDP     []bool            `json:"udp"`
	Blocked map[string]string `json:"blocked"`
}
