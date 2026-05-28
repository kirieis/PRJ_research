# Token contract — Lucy Auth Service

## Purpose
This document specifies the JWT token contract used by Lucy services and the Node realtime server. It describes issuer/audience values, required and optional claims for each token type, validation rules, JWKS and introspection behaviour, TTLs and key rotation guidance.

**Location:** lucy-auth-service/docs/token-contract.md

---

## 1. Signing and algorithms
- Preferred algorithm: `RS256` (RSA with SHA-256).
- Fallback: `HS256` (symmetric) only if no RSA key is configured.
- Tokens MUST include a `kid` header when RS256 is used.

Notes for implementers:
- The service exposes a JWKS endpoint at `GET /.well-known/jwks.json` when an RSA private key is configured.
- If no RSA key is configured, the service validates using a symmetric secret (configured in `Jwt:Secret`).

## 2. Issuer and audiences
- Issuer (`iss`): configured value `Jwt:Issuer` (example: `https://auth.lucy.example`). Clients MUST verify `iss` equals configured issuer.
- Access token audience (`aud`): configured value `Jwt:Audience`.
- Realtime / anonymous token audience (`aud`): configured value `Jwt:RealtimeAudience` (default: `Lucy.Realtime`).

Validation rules:
- Validate `iss` and `aud` strictly.
- Accept tokens with `aud` equal to either access audience (for app APIs) or realtime audience (for Node) depending on endpoint.

## 3. Token types and claims
There are two primary token types:

A. Access Token (for App backends / APIs)
- Purpose: authenticate a logged-in user for HTTP APIs.
- Algorithm: RS256 preferred.
- TTL: configurable `Jwt:AccessTokenMinutes` (default 120 minutes).
- Required claims:
  - `iss` (issuer)
  - `sub` (subject): canonical user id (integer string) or UUID.
  - `aud` (audience): access audience.
  - `exp` (expiry)
  - `iat` (issued at)
  - `jti` (token id) — recommended for revoke support.
  - `role` — user role (e.g., `LUCY`, `Pro`, `Super`).
- Optional claims:
  - `email` (only if necessary) — avoid PII in tokens when not required.
  - `name`, `displayName`.

Constraints:
- Keep PII out of access tokens unless the consuming service requires them. Prefer server-side lookups using `sub`.

B. Realtime / Anonymous Token (for Node / Agora)
- Purpose: allow Node (realtime server) to verify access to audio rooms. Must not expose PII for anonymous users.
- Algorithm: RS256 preferred.
- TTL: configurable `Jwt:RealtimeTokenMinutes` (default 30 minutes).
- Required claims:
  - `iss`, `aud` (must equal realtime audience), `exp`, `iat`, `jti`.
  - `sub`: for authenticated users, a stable user id; for anonymous flows, an anonymous id or ephemeral identifier (do NOT contain email or actual user id if anonymity is required).
  - `anon`: boolean `true` when token represents an anonymous persona.
  - `persona`: object or string describing persona display name (e.g., `Anonymous Fox`) — optional but useful for UI.
- Optional claims:
  - `avatar` (URL or persona id).

Constraints:
- When `anon=true`, token MUST NOT include email or other PII.
- Node should treat `anon=true` tokens as limited-privilege sessions (e.g., no profile editing).

## 4. Example payloads
Access token (payload example):

{
  "iss": "https://auth.lucy.example",
  "aud": "Lucy.App",
  "sub": "12345",
  "role": "LUCY",
  "iat": 1610000000,
  "exp": 1610007200,
  "jti": "a1b2c3d4"
}

Realtime anonymous token (payload example):

{
  "iss": "https://auth.lucy.example",
  "aud": "Lucy.Realtime",
  "sub": "anon-9f12ab",
  "anon": true,
  "persona": "Anonymous Fox",
  "avatar": "https://cdn.lucy/avatar/fox-01.png",
  "iat": 1610000000,
  "exp": 1610001800,
  "jti": "r1t2y3"
}

## 5. JWKS and verification (for Dev4 Node)
- JWKS endpoint: `GET /api/auth/.well-known/jwks.json` (or `/.well-known/jwks.json` depending on routing). Returns `keys: [{ kty, use, alg, kid, n, e }]`.
- Node verification recommendation (pseudo-code):

Use `jwks-rsa` + `jsonwebtoken` (or equivalent in TypeScript):

```js
const jwksClient = require('jwks-rsa');
const jwt = require('jsonwebtoken');

const client = jwksClient({ jwksUri: 'https://auth.lucy.example/.well-known/jwks.json' });
function getKey(header, callback) {
  client.getSigningKey(header.kid, function(err, key) {
    if (err) return callback(err);
    const signingKey = key.getPublicKey();
    callback(null, signingKey);
  });
}

jwt.verify(token, getKey, { algorithms: ['RS256'], issuer: 'https://auth.lucy.example', audience: 'Lucy.Realtime' }, function(err, decoded) {
  // handle verification / decoded claims
});
```

Caching: cache JWKS keys and respect `kid` rotation. Use short JWKS refresh interval (e.g., 5 minutes) but keep cached old keys during rotation overlap.

## 6. Introspection endpoint
- Endpoint: `POST /api/auth/introspect`
- Request: `{ "token": "<JWT>" }`
- Response on valid token (example): `{ "active": true, "claims": { ... } }`.
- Response on invalid/expired: `{ "active": false, "claims": null }`.

Notes: Node may call introspect as a fallback when JWKS cannot be fetched or for additional server-side checks (e.g., revocation state).

## 7. Validation policy & clock skew
- Clock skew: allow 1 minute (configured in service).
- Validate `iss`, `aud`, signature, and `exp` strictly.
- Ensure `nbf` if present is checked.

## 8. Revocation & refresh
- Access tokens are short-lived; for long sessions use refresh tokens or re-issue realtime tokens on server request.
- For token revocation, maintain a server-side revoke list (database keyed by `jti`) checked during introspection or via middleware when performance cost is acceptable.

## 9. Key rotation
- When rotating keys:
  - Publish new key to JWKS with new `kid`.
  - Keep old keys in JWKS for overlap period equal to max token TTL.
  - Remove old keys only after all tokens signed with them have expired or been revoked.

## 10. Error mapping (useful for clients)
- `AUTH_UNAUTHORIZED` — token missing or invalid.
- `AUTH_FORBIDDEN` — token valid but lacks required role/permission.
- Introspect false => treat as unauthorized.

## 11. Implementation notes (server config pointers)
- Config values exist in `lucy-auth-service/Options/JwtOptions.cs`:
  - `Issuer`, `Audience`, `Secret`, `RsaPrivateKeyPem`, `RsaKeyId`, `AccessTokenMinutes`, `RealtimeAudience`, `RealtimeTokenMinutes`.
- The JWKS endpoint and introspect endpoint are implemented in `Program.cs` — Dev4 should read `Jwt:RealtimeAudience` and `Jwt:Issuer` from config when validating.

---

If you want, I can:
- add this file to the repo now, or
- expand with example Node TypeScript verification code and unit test snippets.

Which would you like next?