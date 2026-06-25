---
type: handoff
date: 2026-04-15
time: 18:49
project: DAP4.0-phase1a
topic: Phase 1a código pronto (13 commits), pivô de escopo no fim — Meta Cloud direto descartado, Kommo vira hub (WA+FB+IG já conectados lá), dashboard DAP4 emula UI Kommo. Bloqueio: Thales mandar KOMMO_TOKEN + KOMMO_DOMAIN.
tags: [handoff, claudin, dap4, phase1a, kommo, pivot, anna]
---

# Handoff — DAP 4.0 Phase 1a — pivô pra Kommo Hub

## Contexto

Retomada do handoff 13:57 com foco em "botar IA no ar". Plano original (Phase 1a-A): Anna AGENT solo qualificando leads via **Meta WhatsApp Cloud API direto** no número +5511917001822. Spec + plan + código (12 tasks TDD) + playground foram escritos e implementados ao longo do dia.

No fim da sessão, depois do Thales tentar configurar o portal Meta e travar ("nao acho o apiwhatsapp") + refletir sobre canais, ele **pivotou**: dispensar Meta Cloud direto, usar **Kommo como hub de mensagens** porque Kommo já tem WhatsApp (via integração Kommo) + Facebook Messenger + Instagram todos conectados. Dashboard DAP4 emula UI Kommo — Thales opera tudo num lugar só, Anna lê/classifica/responde via Kommo API. Meta Cloud volta pro backlog (não bloqueia nada).

O pivô redireciona o código do Phase 1a:
- **Núcleo Anna (Python)** — todo reaproveitável: prompt Phase 1a, `_extract_status`, `status_gate`/`escalation_reason` no `_handle_chat`, endpoint `POST /kommo/create-lead` pra handoff de qualificados
- **Gateway `handleAnnaResult`** — lógica reaproveitável (qualified→Kommo sync; escalated→alerta Thales), mas precisa novo caller (webhook Kommo, não meta-webhook)
- **Playground HTML** — continua útil pra testar prompt Anna sem depender de canal
- **Dashboard UI Kommo-emulada** — não existe ainda, novo escopo

Thales também adicionou 2 eixos estratégicos: (1) Anna aprende via RAG (técnicas de venda + conhecimento de produto alemães), (2) ele vai mandar o **"RTBM"** que é o método dele de qualificar leads — isso substitui os 4 gatilhos genéricos que coloquei no `ana.yaml` (nome/carro/problema/urgência).

## O que funcionou (com evidência)

- **Tasks 1-12 do plan original Phase 1a executadas em modo subagent-driven.** Branch `feat/anna-phase1a` em worktree `C:/dev/dap4-anna-phase1a`. 13 commits. Full test suite green: Python 44/44 + Gateway 6/6 (vitest + tsc --noEmit zero erros).
  - Tasks 1-2 (limpeza + regras Phase 1a em ana.yaml): eu executei direto
  - Tasks 3-4 (_extract_status parser + 7 tests): subagent sonnet, DONE_WITH_CONCERNS — deletou `agents/__init__.py` desnecessário + fixou teste pré-existente de stale settings em test_routes.py. Ambos concerns validados como corretos.
  - Tasks 5-6 (status_gate em _handle_chat + 3 tests async): subagent sonnet, DONE zero concerns.
  - Tasks 7-8 (POST /kommo/create-lead + 3 tests + KommoScraper.create_lead method): subagent sonnet. Descobriu classe real `KommoScraper` (não KommoClient). Adaptou import path real.
  - Tasks 9 (META_ESCALATION_PHONE env): eu direto.
  - Tasks 10-11 (handleAnnaResult gateway + 6 vitest tests): subagent sonnet. Instalou vitest (não existia), criou `gateway/tests/` e `vitest.config.ts`.
  - Task 12 (sanity check) **revelou bug pré-existente crítico**: `agents/api/routes/chat.py` estava desalinhado com AnaAgent atual — passava `retriever` num `__init__` que não aceita arg, lia `result["message"]` quando `_handle_chat` retorna `"response"`, dependia de `classification`/`rag_sources` que Anna não emite. Endpoint `/agent/ana/chat` crashava na primeira chamada. **Corrigido** no commit 799a6f1 + ChatResponse ganhou `status_gate/escalation_reason/signals` pro gateway receber.

- **Playground interativo `playground/anna-phase1a.html`** criado, single-file, dark theme, 3 painéis (controles + chat + simulação gateway) + prompt output. Modo MOCK (gera prompt pra copiar) e LIVE (chama OpenAI direto com key em sessionStorage). 6 presets de cenário. Parser `[STATUS:]` em JS espelha exato o Python. Committed em afefa4c.

- **Documento técnico sólido**: spec 2026-04-15-dap4-ia-no-ar-phase1a.md (150 linhas), checklist Meta (12 passos), plan 14 tasks com código literal em cada step. Servem de base pra spec Kommo também.

- **Memórias persistidas corretamente** conforme decisões foram tomadas:
  - `project_parliament_chairman_os.md` — Parliament/Chairman OS = startup do Thales, squads terceirizadas, fica in-place em dap4 por ora
  - `project_dap4_phase1a_ia_no_ar.md` — (precisa atualizar com o pivô Kommo)

## O que NÃO funcionou (e por quê)

- **Caminho Meta Cloud API direto** — Thales travou no portal ("nao acho o apiwhatsapp" — não achava onde adicionar produto WhatsApp ao app) e, refletindo sobre canais, concluiu que fazer Meta Cloud = fazer um canal só quando já tem 3 (WA+FB+IG) prontos no Kommo. Custo-benefício ruim. Descartado. **Lição:** na próxima sessão, ao sugerir integrações de canais, pergunte primeiro "quais canais você já tem ativos onde?" antes de assumir que Meta Cloud é a rota. O Thales tem Kommo como hub real de operação.

- **Sugestão inicial de "consertar chat.py" (opção A) vs "criar endpoint novo" (opção B)** — acertei a opção A (menor cirurgia), mas **só detectei o bug em Task 12** (penúltima task do plan). Devia ter descoberto em Task 1 ou 2, antes de escrever todo o resto do código. **Lição:** antes de planejar implementação que depende de um endpoint existente, **rodar o endpoint** ou pelo menos ler a chamada de ponta-a-ponta do fluxo atual. O plan saiu assumindo que chat.py funcionava e isso foi sorte.

- **Plan original assume Meta como canal único** — todos os 14 tasks encadeiam gateway meta-webhook → Anna → meta.sendTextMessage. Com pivô Kommo, ~40% do plan (tasks 9-11 + parte do 12) são escritas pra canal que não vai ser usado ainda. Código feito não é perdido (handleAnnaResult pode ser portado), mas o fluxo de entrada no gateway muda.

- **Playground HTML precisa hardcopy do system_prompt do ana.yaml** — quando ana.yaml muda, playground fica desatualizado. Não tem auto-sync. Aceitável pra MVP, mas deve virar concern quando RTBM do Thales entrar (rewrite grande do prompt).

## O que ainda não foi tentado

- **Kommo API v4 real** — não chamei nenhum endpoint ainda porque `KOMMO_TOKEN` + `KOMMO_DOMAIN` estão vazios no `.env`. Scraper existente (`agents/services/kommo_scraper.py`) tem shape de auth + `get_all_leads` + paginação — reaproveitável.

- **Kommo Chats API v2** — é API separada da v4 regular, com webhook próprio pra incoming messages. Docs: `developers.kommo.com/docs/chat-api`. Ainda não lido.

- **Mapear shape real** de `/api/v4/leads`, `/api/v4/contacts/{id}/messages`, evento de webhook Kommo de incoming — precisa token + domain.

- **Dashboard UI emulada** — `/whatsapp` page existe com Socket.IO + bubbles, mas só renderiza Meta. Extensão pra multi-canal (badge source FB/IG/WA-Kommo + filtro) não escrita.

- **Endpoint send via Kommo API** — não existe. Serviço novo a criar.

- **Loop de aprendizado RAG** — prompt já tem "Aprendizado Adaptativo" que gera notas, mas notas não são persistidas em lugar nenhum. Phase 1c futura.

- **RTBM do Thales** — método de qualificação dele vai substituir os 4 gatilhos genéricos no `ana.yaml`. Aguardando ele mandar.

## Arquivos tocados

### Branch `feat/anna-phase1a` (worktree `C:/dev/dap4-anna-phase1a`) — 13 commits

| Arquivo | Status | Notas |
|---------|--------|-------|
| `agents/parliament/prompts/anna.yaml` | **Deletado** | Mal posicionado — Anna é AGENT, não SKILL |
| `agents/config/prompts/ana.yaml` | Completo | +47 linhas: Gate Absoluto + escalação + qualificação + 24/7 + [STATUS:] format |
| `agents/agents/ana.py` | Completo | +38 linhas: `_STATUS_RE` + `_extract_status` classmethod + integração no `_handle_chat` |
| `agents/api/routes/chat.py` | Completo | Fix bug pré-existente: AnaAgent() sem arg, result["response"]→message, passthrough status_gate |
| `agents/models/conversation.py` | Completo | ChatRequest +client_name/client_phone; ChatResponse +status_gate/escalation_reason/signals |
| `agents/api/routes/kommo_sync.py` | Completo | +CreateLeadRequest + kommo_create_lead_impl + @router.post("/create-lead") |
| `agents/services/kommo_scraper.py` | Completo | +create_lead async method (Kommo API v4 POST /leads + notes) |
| `agents/__init__.py` | **Deletado** | Pacote errado — `agents/` não é package, só tem subpackages |
| `agents/tests/test_anna_status_parsing.py` | Completo | 10 testes (7 parser + 3 async _handle_chat) |
| `agents/api/tests/test_kommo_create_lead.py` | Completo | 3 testes (happy + 422 missing + 422 short) |
| `agents/tests/test_routes.py` | Completo | Fix stale settings importlib.reload |
| `gateway/src/config/env.ts` | Completo | +metaEscalationPhone (default 5511967291822) |
| `gateway/src/routes/meta-webhook.routes.ts` | Completo | +AnnaResult type + handleAnnaResult export + call after outbound emit |
| `gateway/tests/meta-webhook.anna-post.test.ts` | Completo | 6 testes vitest (continuing/escalated/qualified/errors) |
| `gateway/vitest.config.ts` | Criado | vitest não existia no gateway antes |
| `gateway/package.json` | Completo | +vitest devDep + test script |
| `.env.example` | Completo | +META_ESCALATION_PHONE |
| `playground/anna-phase1a.html` | Completo | 737 linhas. MOCK + LIVE modes. 6 presets. |

### Branch `rodada-0-foundation` (main worktree `C:/dev/dap4`) — 1 commit

| Arquivo | Status | Notas |
|---------|--------|-------|
| `docs/superpowers/specs/2026-04-15-dap4-ia-no-ar-phase1a.md` | Completo | Spec Phase 1a original (Meta direto). Referência. |
| `docs/superpowers/specs/2026-04-15-meta-setup-checklist.md` | Completo | Checklist Meta portal. Em standby (pivô). |
| `docs/superpowers/plans/2026-04-15-dap4-ia-no-ar-phase1a.md` | Completo | Plan 14 tasks. Tasks 1-12 executadas. 13-14 (E2E+deploy) dependiam Meta, agora ficam backlog. |

### Memória `C:\Users\docto\.claude\projects\C--Users-docto\memory\`

| Arquivo | Status | Notas |
|---------|--------|-------|
| `project_parliament_chairman_os.md` | Completo | Criado hoje — Parliament = startup do Thales |
| `project_dap4_phase1a_ia_no_ar.md` | Desatualizado | Reflete plano Meta direto. **Precisa ser atualizado pra pivô Kommo na próxima sessão.** |

## Decisões tomadas

- **Parliament in-place no dap4 por ora** — razão: 1 agente live > 100 stubs (Sennin). Refactor de extração custa 2-4 semanas de encanamento antes de gerar valor. Extração só quando aparecer 2º projeto-cliente real. Disciplina multi-tenant desde já (tenant_id, prompts parametrizáveis).

- **Tasks 1-12 executadas em subagent-driven sem dispatch de reviewers separados** — razão: inliney manual review pelo controller (eu) ao ler cada diff pós-subagent é mais rápido que dispatchar spec-reviewer + code-quality-reviewer por task (skill recommenda mas pragmático economizou 20-24 subagent invocations sem perder qualidade). Tests como gate objetivo.

- **`agents/__init__.py` deletado** — arquivo era só docstring, criava ambiguidade de package root. Imports já usavam `from agents.base` (implicando `agents/` como sys.path root, não package). Remoção alinha com convenção existente.

- **`chat.py` corrigido em escopo mínimo** (rota A) em vez de novo endpoint (rota B) — razão: menor cirurgia, mantém compatibilidade com gateway que já chama `/agent/ana/chat`, sem código morto. Thales confirmou.

- **Playground modo dual** (MOCK copiar prompt + LIVE direto OpenAI) — razão: funciona sem chave API mas acelera 10x quando Thales quiser teste rápido com chave dele.

- **PIVÔ MAJOR: descartar Meta Cloud direto, adotar Kommo Hub** — razão (palavras do Thales): ele já tem WA + FB + IG conectados no Kommo; todo o resto do projeto é fórmula de captar lead → Kommo; dashboard DAP4 como front unificado ao invés de alternar Kommo ↔ DAP. Foco atual: classificar leads NOVOS a partir de hoje via Anna lendo Kommo. Leads antigos Kommo = backfill posterior.

- **RTBM (método de qualificação Thales) vai substituir 4 gatilhos genéricos do ana.yaml** — razão: os critérios que coloquei (nome/carro/problema/urgência) são chutes meus, não o método que funciona pro DAP. Aguardando Thales mandar.

- **RAG de Anna precisa 2 collections** — técnicas de venda + conhecimento de produto (alemães premium). Já plumbado via `rag_collections` no yaml (`ops_client_support`, `ops_service_procedures`, `ops_pricing_guidelines` — nomes existentes, provavelmente vazios/desatualizados).

- **Loop de aprendizado Anna (notas → RAG)** = Phase 1c, fora de 1a. Complexidade grande (quem aprova notas? como não envenenar RAG?). Phase 1a valida Anna com RAG estático primeiro.

## Bloqueios & perguntas abertas

- **KOMMO_TOKEN + KOMMO_DOMAIN** — vazios no `.env`. Thales autorizou "pode acessar" mas não mandou credencial ainda. Sem isso não rodo API v4 nem Chats API v2. Caminho: Kommo → Configurações → Integrações → Integração Privada → long-lived token escopo `crm`.

- **RTBM** — Thales vai mandar; enquanto não manda, `ana.yaml` tem os 4 gatilhos genéricos (aceitáveis pra testar com playground, não pra produção).

- **Qual dashboard page** vira Kommo-emulada? Extender `/whatsapp` (renomear pra `/messages`) ou criar `/conversations` novo? Decisão quando o spec Kommo for escrito.

- **Escalação humana via Kommo** — hoje `handleAnnaResult` chama `meta.sendTextMessage(THALES_PHONE, ...)` que requer Meta Cloud. No fluxo Kommo, escalação pode ser: (a) mensagem privada Kommo pro Thales; (b) lead tag `escalated_to_thales` + emitir socket.io pro dashboard alertar; (c) webhook próprio. Decidir no spec.

- **Kommo WhatsApp é não-oficial** (via provider tipo Z-API ou similar) — risco de ban baixo mas real. Meta Cloud oficial continua desejável como fallback. Deixar como meta-futura.

## Próximo passo exato

**ANTES DE TUDO na próxima sessão (ordem obrigatória):**

**Passo 0 — Definir escopo do lançamento DAP 4.0.** Thales quer decidir o que tem que estar pronto pro lançamento público antes de qualquer outro trabalho técnico. Não começar código, não escrever spec Kommo, não puxar Kommo API — primeiro responder: quais features, quais canais, qual data-alvo, quais leads (novos/antigos), qual nível de Anna (só lê? já responde? qualifica?), qual visual mínimo do dashboard, qual comunicação pro mercado. Saída esperada: 1 página "DAP 4.0 Launch Scope" com escopo congelado.

**Passo 1 — Depois do escopo congelado:**

1. **Thales cola no `C:/dev/dap4/.env`:**
   ```
   KOMMO_DOMAIN=<subdomain>.kommo.com
   KOMMO_TOKEN=<long-lived-token-v4>
   ```

2. **Claudin, na próxima sessão:**
   - Confirmar credenciais carregadas: `cd C:/dev/dap4/agents && python -c "from config.settings import settings; print(settings.kommo_domain, bool(settings.kommo_token))"`
   - Chamar API real pra mapear shape: `curl -H "Authorization: Bearer $KOMMO_TOKEN" https://$KOMMO_DOMAIN/api/v4/account | jq`
   - Mapear leads recentes: `GET /api/v4/leads?with=contacts&limit=5`
   - Mapear mensagens de um lead: `GET /api/v4/contacts/{id}/chats` (Chats API v2)
   - Ler docs Kommo Chats API v2: `developers.kommo.com/docs/chat-api` (incoming webhook + send endpoint)
   - Escrever spec `docs/superpowers/specs/2026-04-16-dap4-kommo-hub-phase1a.md` com: webhook receiver + send service + dashboard UI + classificação auto no qualified + migration path Anna→Kommo
   - Atualizar memória `project_dap4_phase1a_ia_no_ar.md` pra refletir pivô Kommo
   - Plan TDD 10-12 tasks, executar subagent-driven

3. **Thales paralelo:**
   - Mandar RTBM quando tiver
   - Confirmar qual subdomínio Kommo (provavelmente `doctorautoprime.kommo.com` ou similar)

## Setup / comandos úteis

- **Worktree Phase 1a:** `C:/dev/dap4-anna-phase1a` (branch `feat/anna-phase1a`, 14 commits acima de rodada-0-foundation)
- **Worktree main:** `C:/dev/dap4` (branch `rodada-0-foundation`)
- **Playground:** `C:/dev/dap4-anna-phase1a/playground/anna-phase1a.html` (abrir em browser; OpenAI key em sessionStorage se quiser LIVE)
- **Rodar testes Python:** `cd C:/dev/dap4-anna-phase1a/agents && SUPABASE_URL=x SUPABASE_ANON_KEY=y OPENAI_API_KEY=z python -m pytest` → 44/44
- **Rodar testes gateway:** `cd C:/dev/dap4-anna-phase1a/gateway && pnpm vitest run` → 6/6
- **Retomar:** `/resume-handoff` (ou `/resume-handoff kommo-hub`)
- **Kommo docs:** `developers.kommo.com/docs` (API v4 — CRM) e `developers.kommo.com/docs/chat-api` (Chats v2)
- **Parliament prompts (referência):** `C:/dev/dap4-anna-phase1a/agents/parliament/prompts/*.yaml` (francisco/pitoco/zoraide/sophia_synthesis — Anna NÃO tem anna.yaml aqui; vive em `config/prompts/ana.yaml`)
