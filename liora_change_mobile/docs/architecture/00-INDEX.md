# Liora Change — Master Engineering Specification

**Document Status:** Living Architecture Blueprint  
**Audience:** Engineering, Product, Security, AI, DevOps, QA, Leadership  
**Platform:** AI-Powered Behavioral Transformation Platform  
**Primary Clients:** Flutter Mobile, Filament Admin, Future Web  
**Backend:** Laravel 12 / PHP 8.4 / MySQL / Redis  

> **Hackathon teams:** use the practical MVP pack first → [`../mvp/README.md`](../mvp/README.md).  
> This architecture series is long-term reference. MVP docs win if there is a conflict.

---

## Chapter Index

| # | Chapter | File | Status |
|---|---------|------|--------|
| 01 | Executive Summary | [01-executive-summary.md](./01-executive-summary.md) | Done |
| 02 | Product Vision | [02-product-vision.md](./02-product-vision.md) | Done |
| 03 | Business Goals | [03-business-goals.md](./03-business-goals.md) | Done |
| 04 | User Personas | [04-user-personas.md](./04-user-personas.md) | Current |
| 05 | User Journeys | TBD | Pending |
| 06 | Functional Requirements | TBD | Pending |
| 07 | Non-Functional Requirements | TBD | Pending |
| 08 | Domain Model | TBD | Pending |
| 09 | Bounded Contexts (DDD) | TBD | Pending |
| 10 | High-Level Architecture | TBD | Pending |
| 11 | System Context Diagram | TBD | Pending |
| 12 | Container Diagram | TBD | Pending |
| 13 | Component Diagram | TBD | Pending |
| 14 | Feature Architecture | TBD | Pending |
| 15 | Database Architecture | TBD | Pending |
| 16 | Entity Relationship Diagram | TBD | Pending |
| 17 | Table Specifications | TBD | Pending |
| 18 | REST API Strategy | TBD | Pending |
| 19 | API Versioning | TBD | Pending |
| 20 | Authentication & Authorization | TBD | Pending |
| 21 | API Error Standards | TBD | Pending |
| 22 | Mobile Architecture | TBD | Pending |
| 23 | Backend Architecture | TBD | Pending |
| 24 | AI Architecture | TBD | Pending |
| 25 | RAG Architecture | TBD | Pending |
| 26 | Voice Assistant Architecture | TBD | Pending |
| 27 | Notification Architecture | TBD | Pending |
| 28 | Gamification Architecture | TBD | Pending |
| 29 | Analytics Architecture | TBD | Pending |
| 30 | Search Architecture | TBD | Pending |
| 31 | Admin Architecture | TBD | Pending |
| 32 | Event-Driven Design | TBD | Pending |
| 33 | Queue Architecture | TBD | Pending |
| 34 | Scheduler Architecture | TBD | Pending |
| 35 | Caching Strategy | TBD | Pending |
| 36 | Redis Usage | TBD | Pending |
| 37 | Security Architecture | TBD | Pending |
| 38 | Privacy & Compliance | TBD | Pending |
| 39 | Logging & Monitoring | TBD | Pending |
| 40 | Deployment on Render | TBD | Pending |
| 41 | Docker Architecture | TBD | Pending |
| 42 | CI/CD with GitHub Actions | TBD | Pending |
| 43 | Disaster Recovery | TBD | Pending |
| 44 | Scalability Strategy | TBD | Pending |
| 45 | Testing Strategy | TBD | Pending |
| 46 | Release Strategy | TBD | Pending |
| 47 | AI Governance | TBD | Pending |
| 48 | Prompt Management | TBD | Pending |
| 49 | Knowledge Base Management | TBD | Pending |
| 50 | Development Roadmap | TBD | Pending |

---

## Reading Order

1. Product & strategy chapters (01–07) establish *why* and *what*.
2. Domain chapters (08–09) establish the language of the system.
3. Architecture chapters (10–14) establish *how systems fit together*.
4. Data & API chapters (15–21) establish contracts.
5. Platform chapters (22–31) establish implementation blueprints per surface.
6. Cross-cutting chapters (32–39) establish operational excellence.
7. Delivery chapters (40–46) establish how we ship and recover.
8. AI governance chapters (47–49) establish safe AI operations.
9. Roadmap (50) sequences delivery for millions of users.

---

## Change Control

- Chapters are versioned by git history.
- Architecture Decision Records (ADRs) will be referenced from each chapter’s **Architecture Decisions** section.
- No chapter authorizes implementation code; chapters authorize design intent only.
