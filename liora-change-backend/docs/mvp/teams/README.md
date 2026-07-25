# Team handoff docs

**Goal:** Backend and Mobile integrate easily because **all data shapes are identical**.

## Read in this order

| Order | Who | File |
|-------|-----|------|
| 1 | **Everyone** | [SHARED-DATA-CONTRACT.md](./SHARED-DATA-CONTRACT.md) |
| 2a | **Mobile only** | [MOBILE-TEAM-GUIDE.md](./MOBILE-TEAM-GUIDE.md) |
| 2b | **Backend only** | [BACKEND-TEAM-GUIDE.md](./BACKEND-TEAM-GUIDE.md) |

## How integration stays in sync

```text
SHARED-DATA-CONTRACT  ← single source of truth (fields, enums, schemas)
        │
        ├──────────────► MOBILE models / fromJson
        │
        └──────────────► BACKEND API Resources / DB columns / Filament forms
```

If a field differs between app and API → **fix SHARED first**, then both sides.

## Related

- Full HTTP examples: [../05-api-contract.md](../05-api-contract.md)
- Filament: [../08-filament-admin.md](../08-filament-admin.md)
- **AI Motivation + simple RAG chat:** [../09-simple-ai-rag-chat.md](../09-simple-ai-rag-chat.md)
- Joint checklist: [../07-integration-checklist.md](../07-integration-checklist.md)
