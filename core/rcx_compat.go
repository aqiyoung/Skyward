package core

// This fork does not gate request-traffic polling on the host being in the
// foreground the way ReClash does. RCX sends foreground hints over
// rcxSetHints; accepting and ignoring them keeps the protocol compatible
// without changing how traffic is sampled here.
func setHostForeground(foreground bool, seq uint64) {}
