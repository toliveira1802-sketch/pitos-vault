---
projeto: AutoDiag Copilot
status: design
criado: 2026-04-17
repo: C:/dev/autodiag-copilot
modelo: B2C single-user, offline-first, RAG
stack: Next.js 15 + Supabase + Drizzle + pgvector + Vercel
---

# AutoDiag Copilot — Index

SaaS B2C de diagnóstico veicular para entusiastas e mecânicos solo. Lê DTCs do scanner OBD-II, interpreta com RAG sobre base técnica (Bosch, OEM, SOPs DAP), funciona offline-first.

## Persona-alvo
- **Primária:** entusiasta dono de alemão premium (BMW/Audi/MB/VW) que faz manutenção própria
- **Secundária:** mecânico solo trabalhando em garagem própria
- **Não atende v1:** oficinas multi-user (vai pra v2)

## Estrutura

- [[001-estado-e-roadmap|Estado & Roadmap]] — **doc vivo**: onde estamos, estrutura por camada, status por feature, próximas features
- [[specs/2026-04-17-autodiag-copilot-design|Design Spec inicial]] — schema, RLS, write queue offline, stack, tracks paralelas
- [[docs/2026-06-05-diagnostic-engine-build|Motor de Diagnóstico (2026-06-05)]] — agente ReAct + 3 tools, transporte OBD/BLE, import VCDS/ODIS, sonda BLE pro eaata

## Tracks ativas (sprint 1)

| Track | Skill | Status |
|---|---|---|
| Designer | `/hm-designer` | aguardando spawn |
| Engineer | `/hm-engineer` | aguardando spawn |
| QA | `/hm-qa` | aguardando spawn |

## Decisões-chave

- **Single-user puro** — sem accounts/tenants/orgs. Compartilhamento fica pra v2.
- **Offline-first como restrição de design**, não bolt-on. IndexedDB é store primário.
- **RLS via `auth.uid()`** — defesa no Postgres, não na aplicação.
- **pgvector** em vez de ChromaDB separado — menos infra até 1M vectors.
- **Vertical inicial:** alemães premium (BMW/Audi/MB/VW). Expansão depois.

## Métricas 90 dias
- 500 signups
- 30% activation
- 60% W4 retention
- < 1s p95 sync latency
- Zero cross-user data leak

## Fora de escopo v1
- Compartilhamento multi-user
- Native mobile (PWA cobre)
- ~~Web Bluetooth direto~~ → infra BLE construída e testada em 2026-06-05 (`lib/obd`); falta teste de hardware do eaata. Caminho primário de "scan real" virou **import VCDS/ODIS**. Ver [[docs/2026-06-05-diagnostic-engine-build|Motor de Diagnóstico]].
- Osciloscópio Web Serial → adiado pra V5
- Marketplace de oficinas
- Billing (entra com 100 users)
- i18n (PT-BR only)

## Repo

`C:/dev/autodiag-copilot` — git inicializado, primeiro commit é o spec.

## Créditos

- 🛸 **Menção honrosa: Antigravity** — foi quem **iniciou** o projeto AutoDiag Copilot (bootstrap do early-stage).
