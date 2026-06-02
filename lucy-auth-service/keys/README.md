# JWT signing keys

Place the RS256 private key for local development at:

```text
keys/lucy-auth-private.pem
```

Do not commit real private keys. Production should provide the key through a secret manager or an environment variable such as:

```text
Jwt__RsaPrivateKeyPem
```

The public key is exposed to Realtime Service through:

```text
GET /api/auth/.well-known/jwks.json
```
