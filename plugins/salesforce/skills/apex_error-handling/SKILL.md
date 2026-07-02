---
description: House pattern for surfacing Apex errors from a Salesforce package with a uniform, code-based error contract. Use when adding or handling any Apex error path — throwing from a controller/REST resource/Canvas bridge, or when a raw platform error (e.g. "Variable does not exist: tmpVar1") leaks to a client. Establishes a code registry + envelope and keeps it updated.
---

# apex_error-handling — uniform package error codes

When working on how a Salesforce package surfaces Apex errors, use a single uniform, structured
error contract — never let raw/ masked platform errors (like `Variable does not exist: tmpVar1`,
which is really a `WITH USER_MODE` access denial) leak to a client.

## Rules

1. **If the package has no error-code system, create one:**
   - a central normalizer class (pattern: `ApiErrors`) that turns exceptions into an envelope;
   - a registry doc `docs/ERROR_CODES.md` (the source of truth);
   - a uniform **camelCase** envelope: `{ codeNumber, name, detail, objectName?, fieldName?, debug? }`.
2. **Numbering:** 1000s access/security · 2000s validation · 3000s not-found · 9000s unexpected.
3. **Normalize at the transport entry points** (Canvas bridge + REST resources), not per-query — one
   catch that routes through the normalizer. Bridge: rethrow access errors as an
   `AuraHandledException` carrying the envelope JSON. REST: set `statusCode = 403` + envelope body.
4. **Register every new code** in `docs/ERROR_CODES.md` in the SAME change as the Apex.
5. `detail` is stable English — the client localizes by `name`/`codeNumber`. `debug`
   (exceptionType/origin/line/rawMessage/stackTrace) is GATED off for subscribers (on only in
   sandbox/scratch) — never leak stack traces to a managed-package subscriber (security review).
6. Prefer this over ad-hoc `throw`/raw platform errors.

Reference implementation: AcctSeedUI-SF `ApiErrors.cls` + `docs/ERROR_CODES.md`.
