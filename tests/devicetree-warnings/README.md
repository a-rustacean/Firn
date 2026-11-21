# Gravity schema baseline

These are the reviewed warnings for the pinned Gravity kernel, not a
wildcard allow-list. The test compares every warning exactly and continues
to fail on new diagnostics, including binding/schema syntax errors.

Gravity lacks bindings for DCP, PMP, MTP and several experimental blocks.
Its disabled audio, ISP and USB4 descriptions also have existing binding
gaps. They remain present in its source but are not enabled by Firn.
PCIe's conflicting register counts and the PMP mailbox's two power domains
are corrected in the downstream binding patch rather than allow-listed.

The separate wiring test checks both boards, firmware handoff, fixed USB
hosts, Ethernet/radio selection, HDMI GPIOs and the Air's thermal trips.
