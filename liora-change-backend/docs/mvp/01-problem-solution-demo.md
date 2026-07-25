# 01 — Problem → Solution → Demo

## The problem

People want to change (wake earlier, quit sugar, exercise, study…), but:

1. They start with vague intentions  
2. Habit apps only track checkboxes  
3. One missed day → streak shame → they quit  
4. Motivation is generic and poorly timed  

**Result:** intention dies. Behavior does not change.

---

## Our solution (what Liora Change is)

Liora Change is a **behavioral transformation MVP**:

| Step | What the product does |
|------|------------------------|
| 1. Intention | Turn a goal into a **structured challenge** |
| 2. Action | Daily **check-in** (complete / skip with reason) |
| 3. Feedback | Show **progress, streak, XP** |
| 4. Recovery | After a miss, show a **recovery nudge** (not shame) |
| 5. Support | **AI motivation** from the user’s challenge + **simple RAG chatbot** |

We are **not** building voice or a heavy vector DB. We **do** ship simple OpenAI motivation + MySQL RAG chat for the hackathon.

---

## Demo story (3 minutes)

Use this exact story for judges:

1. **Register / Login** as “Alex”  
2. **Create challenge:** “Morning Walk — 7 days”  
3. **Activate** challenge → status `active`  
4. **Check in today** → complete → streak = 1, XP gained  
5. **Skip tomorrow** (or simulate miss) → streak resets, recovery message appears  
6. **Recover:** check in again + show encouraging message  
7. **Dashboard:** progress %, streak, XP, recent activity  
8. **AI Motivation:** tap Motivate → text mentions their challenge title  
9. **AI Chatbot:** ask “What if I miss a day?” → grounded recovery answer  
10. **(Backend) Filament admin:** Categories / Templates / Knowledge / Users  

**Punchline:**  
> “Trackers punish failure. Liora helps you recover — with AI coaching grounded in your challenge and our knowledge base.”

---

## Problem → screen → API map

| Problem moment | Mobile screen | API |
|----------------|---------------|-----|
| I want to start | Create Challenge | `POST /challenges` + `POST /challenges/{id}/activate` |
| I did it today | Check-in | `POST /challenges/{id}/check-ins` |
| I couldn’t today | Skip / Miss | same check-in with `status: skipped` |
| Am I improving? | Dashboard | `GET /dashboard` |
| I feel bad after miss | Recovery banner | `GET /recovery/current` + motivation |
| Keep me going | Motivation card | `POST /ai/motivation` (OpenAI + challenge context) |
| Ask for help | Coach chat | `POST /ai/chat` (simple RAG) |

---

## Success criteria for the hackathon

Demo is successful if a judge can see:

- [ ] Auth works  
- [ ] Challenge created and activated  
- [ ] Check-in updates streak/progress  
- [ ] Skip/miss triggers recovery UI (not only “streak lost”)  
- [ ] Dashboard shows progress + XP  
- [ ] AI motivation mentions the user’s challenge  
- [ ] AI chatbot answers with simple RAG (seeded knowledge)  
- [ ] Filament admin works (login + templates/categories/knowledge)  
- [ ] Backend and mobile used the **same API contract**
