# 02 — MVP Scope (In / Out)

## In scope (MVP-MUST)

### Mobile
- Register / Login / Logout  
- Home dashboard  
- Create challenge (simple form)  
- Challenge list + detail  
- Activate challenge  
- Daily check-in (complete / skip)  
- Streak + XP display  
- Recovery banner after miss/skip  
- Basic profile (name, timezone optional)

### Backend API
- Sanctum auth  
- Challenges CRUD (minimum: create, list, show, activate)  
- Check-ins  
- Progress / streak / XP calculation  
- Dashboard aggregate endpoint  
- Recovery current endpoint  
- Consistent JSON error format  
- Seed data: demo member + admin + templates/categories  

### Backend Admin — Filament (MVP-MUST)
- Filament panel live at `/liora_change`  
- Admin login (seeded `admin@liora.change`)  
- Manage **Users**  
- Manage **Challenge Categories**  
- Manage **Challenge Templates**  
- (Existing resources in repo — wire/seed for demo; see [08-filament-admin.md](./08-filament-admin.md))  

Filament and API share the **same MySQL** data. Mobile never calls Filament directly.

### Demo-only AI (MVP-NICE)
- `POST /ai/motivation` returns personalized text  
  - Can be **template-based** (no OpenAI required for demo)  
  - If OpenAI key exists, optional real call

---

## Nice if time (MVP-NICE)

- Challenge templates list from API (`GET /challenge-templates`) consumed by mobile  
- Badges unlocked list  
- Daily reward claim  
- Filament: Challenges list, Featured challenges, simple widgets  
- Calendar heatmap endpoint  
- Forgot password  

---

## Out of scope (LATER — do not build for hackathon)

| Cut | Why |
|-----|-----|
| Full RAG / vector DB | Too heavy for demo |
| Voice STT/TTS | Integration risk |
| Risk prediction ML | Not needed to prove loop |
| Social accountability partners | Scope explosion |
| Certificates / image generation | Polish, not core |
| Multi-language full i18n | English OK for demo (Amharic later) |
| Complex subscription billing | Not needed |
| Microservices | Modular Laravel only |

---

## Challenge status machine (keep simple)

```text
draft → ready → active ⇄ paused → completed
                      ↘ cancelled / archived
```

**Hackathon minimum path:**

```text
draft → active → (completed optional)
```

Mobile may call activate directly from draft if backend allows  
`draft → active` (recommended for speed).

**Backend decision for MVP:** allow `draft → active` directly.

---

## Definition of Done (joint)

| Area | Done means |
|------|------------|
| API | All MVP-MUST endpoints in [05-api-contract.md](./05-api-contract.md) return correct shapes |
| Mobile | Happy path demo story works on a device/emulator against staging/local API |
| Filament | Admin can log in and manage categories + templates (+ see users) |
| Data | Seeded demo member + admin + sample templates available |
| Docs | Any new field added to API is updated in the contract same day |
