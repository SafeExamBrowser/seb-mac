<!--
  Scratch file — draft comment for seb-win-refactoring issue #1495.
  Not part of the project; delete once posted (do not commit).
-->
## Proposal: adopt RFC 8785 number formatting as the normative floating-point rule for the Config Key (target: SEB 4.0, lockstep release)

### Summary of the root cause

The Config Key is a SHA-256 hash over the canonicalized SEB-JSON, so byte-identical serialization is required on every platform. For doubles this currently isn't specified, and the implementations diverge:

| Platform | Mechanism | `1.2345678901234567` → |
|---|---|---|
| Windows (v3.10.2) | .NET Framework 4.8 `Double.ToString(InvariantInfo)` = "G15" (≤15 significant digits) | `1.23456789012346` |
| macOS/iOS (current) | Foundation `NSNumber` description (shortest round-trip, ≤17 digits) | `1.234567890123457` |

This only surfaces for values not representable in ≤15 significant digits; "nice" values (e.g. `0.1`, `0.5`, `1.5`) serialize identically everywhere today, which is why it went unnoticed.

### Why not just standardize on .NET's "G15"

It's a fragile anchor: it's the behavior of a *frozen, deprecated* framework, and .NET Core 3.0+/.NET 5+ **already changed** the default `Double.ToString()` to shortest-round-trip. So the moment SEB-Windows moves off .NET Framework 4.8, Windows itself drifts away from G15. G15 is also lossy (not round-trippable) and has no formal spec or conformance vectors.

### Proposal

Adopt the **number serialization algorithm from [RFC 8785 (JSON Canonicalization Scheme)](https://www.rfc-editor.org/rfc/rfc8785)** — i.e. the ECMAScript `Number::toString` shortest-round-trip form — as the normative floating-point rule for the Config Key, on **all** components: SEB clients (Windows, macOS/iOS), SEB Server (Java), and LMS plugins (Moodle/PHP, ILIAS, etc.).

**Scope it to numbers only — do *not* switch the Config Key to full JCS.** SEB's Config Key has its own established document canonicalization (alphabetical key sorting, UTF-8, whitespace stripping inside strings, base64 for binary data). Full RFC 8785 disagrees with all of these (JCS sorts by UTF-16 code units, doesn't strip string whitespace, has no binary→base64 concept), so adopting it wholesale would break *every* Config Key. Replacing only the float rule keeps all non-float and nice-float configs byte-identical.

### Migration impact: near-zero for real-world configs

Because RFC 8785, G15, and the macOS shortest-round-trip form all already agree for any value expressible in ≤15 significant digits, adopting the RFC 8785 number rule is a **no-op for every currently-working config**. The only Config Keys that change are those containing "ugly" float values — which are *already* mismatched across platforms today. The current floating-point settings (`screenProctoringImageDownscale`, `batteryChargeThresholdCritical`/`Low`, `defaultPageZoomLevel`/`defaultTextZoomLevel`) hold small, non-negative, human-entered values, so in practice nothing observable changes for existing exams.

### Important implementation caveat: native built-ins are *not* RFC 8785

"Use RFC 8785" must not be read as "call the platform's default float formatter" — none of them conform exactly:

| Platform | Native default | Conforms? |
|---|---|---|
| JavaScript `JSON.stringify` | ECMAScript `Number::toString` | ✅ (this *is* the JCS rule) |
| Java `Double.toString()` | forces decimal point (`1.0`), different exponent thresholds | ❌ — use a JCS lib, e.g. `org.erdtman:java-json-canonicalization` |
| PHP `json_encode` (serialize_precision=-1) | shortest digits, differing exponent/format rules | ❌ — needs a JCS-conformant serializer |
| .NET (Core/5+) shortest, Swift `Double.description` | close, but differ on integer/exponent edge cases | ❌ — format per the spec |

So each platform needs a genuinely conforming serializer, validated against **shared test vectors**. Proposed starting set (please extend):

| Input double | Expected canonical string |
|---|---|
| `1.2345678901234567` | `1.2345678901234567` |
| `0.1 + 0.2` | `0.30000000000000004` |
| `1.0 / 3.0` | `0.3333333333333333` |
| `1.0` | `1` |
| `0.5` | `0.5` |
| `-0.0` | `0` |
| very small / very large (exponent form) | per RFC 8785 §3.2.2.3 |

We should also confirm NaN/±Infinity are disallowed (RFC 8785 / I-JSON forbid them; they can't appear in valid SEB settings anyway).

### Timing

Since this is a coordinated breaking change for the (rare) ugly-value case, it should land simultaneously across all components. The planned **SEB 4.0 lockstep release** is the natural window. Until then, we've applied an interim fix in seb-mac that matches shipping Windows (G15) for *all* values including the reported case, so current field interop is restored without waiting for 4.0.

### Asks for this issue

1. Agreement on RFC 8785 number rule (numbers-only scope) as the normative spec.
2. A shared, versioned test-vector file in a common repo that every implementation validates against in CI.
3. Explicit spec text on: fixed-vs-exponential threshold, exponent casing/sign/min-digits, negative zero, and rejection of NaN/Infinity.
