# Dev 2 Anonymous Room Flow

Scope tai lieu nay chi cover phan Dev 2 tuan 1-5, khong thay the token contract cua Dev 6.

## Tong quan

- `accessToken` dung cho app, da bo claim `email` de han che PII khong can thiet.
- `realtimeToken` dung cho Node/realtime room, khong chua `email` hoac `user id` that.
- `persona` duoc luu rieng trong `dbo.user_personas` de hien thi danh tinh an danh on dinh theo user.

## Endpoint moi

`POST /api/auth/anonymous-room-access`

Authorization: `Bearer <accessToken>`

Request:

```json
{
  "channelName": "room-42",
  "roomId": 42,
  "rotatePersona": false
}
```

Response:

```json
{
  "realtimeToken": "<jwt>",
  "tokenType": "Bearer",
  "expiresAt": "2026-05-25T09:30:00+00:00",
  "channelName": "room-42",
  "roomId": 42,
  "persona": {
    "subject": "prs_3f0c8f7a6d354f4cb24414a5b6dbfd47",
    "displayName": "Anonymous Fox",
    "avatarCode": "fox",
    "avatarUrl": null,
    "isAnonymous": true
  }
}
```

## Claims

`accessToken`

- `sub`: internal user id
- `role`
- `userId`
- `languageId` neu co
- `isAnonymous`
- `token_use=access`

`realtimeToken`

- `sub`: persona subject (`prs_<guid>`)
- `role`
- `displayName`
- `avatarCode`
- `avatarUrl` neu co
- `languageId` neu co
- `channelName`
- `roomId` neu co
- `isAnonymous=true`
- `token_use=realtime`

`realtimeToken` audience mac dinh la `Lucy.Realtime`.
