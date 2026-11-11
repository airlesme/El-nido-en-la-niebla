# NIDO_DEV_ONLY_MARKER
# Positive-control canary for tools/ci/audit_artifact.sh (ADR-0018 D3/D4).
# Must be present in playtest-* artifacts and absent from demo-* artifacts.
# No class_name (ADR-0018 D3); nothing references this file.
extends RefCounted

const CANARY: String = "NIDO_DEV_ONLY_MARKER_CANARY_7f3a9c"
