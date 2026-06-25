---
type: handoff
date: 2026-04-23
time: 10:53
project: DAP 4.0 (Tech › Tools + Ecossistema)
topic: Odin Parts LIVE em prod + mapa do ecossistema consolidado, prep pra sprint de automação
tags: [handoff, claudin, dap4, odin-parts, ecossistema, automacao]
---

# Handoff — Odin Parts LIVE + ecossistema consolidado

## Contexto

Sessão começou com brainstorm sobre "command center de tools offline com banco de dados". Thales mandou um zip no Downloads (`App para Reconhecimento de Códigos de Peças Automotivas.zip`) — MVP externo chamado "Odin Parts", construído na plataforma Manus (Forge LLM + Manus OAuth + MySQL + tRPC + TSX + wouter).

**Decisão:** portar o Odin pro monorepo DAP4 como módulo `/parts` dentro de **DAP Tech › Tools**, desacoplando da Manus e substituindo por: Supabase (Postgres + Storage + Auth), OpenAI direto (GPT-4o-mini vision), Express gateway, dashboard React existente.

**Executamos a Rota A** (web production) fim-a-fim: schema Supabase aplicado em produção, backend Python + gateway + 6 páginas JSX, testes, commit, push, deploy na VPS `76.13.170.42`, validação com scan real. Migration + build + smoke test — tudo verde.

Depois consolidamos o mapa canônico do ecossistema DAP 4.0 (algumas unidades foram renomeadas/mescladas desde o registro antigo no global CLAUDE.md). Agora Thales quer começar a **automatizar a locomotiva do ecossistema** e pediu pra salvar o handoff antes de detalhar os pontos-chave da automação numa sessão limpa.

## O que funcionou (com evidência)

- **Migration Postgres aplicada em produção** — evidência: MCP `apply_migration` `parts_recognition_schema` retornou `{success: true}` no projeto `acuufrgoyjwzlyhopaus` (DOCTOR_PRIME). `list_migrations` confirma entrada. 7 tabelas visíveis em `information_schema.tables`. Bucket `parts-images` presente em `storage.buckets`. 0 advisors tocando no módulo.
- **Backend Python (parts_analyzer + parts_repo + parts_service + rotas FastAPI)** — evidência: 14 pytest passando em `agents/tests/test_parts_analyzer.py` (5.54s). Cobre safe_parse_json, normalize_equivalents/vehicles/pricing, compute_inventory_stats, build_dashboard.
- **Gateway Express /api/parts proxy** — evidência: `npx tsc --noEmit` verde em `gateway/`. Rota montada com strictLimiter nas LLM-bound.
- **Dashboard build** — evidência: `npx vite build` verde tanto local quanto na VPS (7 chunks `Parts*.js` gerados). 6 vitest passando em `src/test/parts.test.jsx`.
- **Deploy VPS `make prod`** — evidência: containers `agents-1` e `gateway-1` recriados healthy. Dashboard rebuildado em `/opt/doctor-auto-ai/dashboard/dist/` e servido por Caddy via bind-mount em `/srv/dashboard`.
- **Pipeline LLM end-to-end funcionando** — evidência: `POST /api/parts/identify-code {"code":"06A 115 561 B"}` retornou `{success:true, partId:1, analysis:{description:"Junta de coletor de admissão...", 4 equivalentes (VW/Audi/Seat/Skoda), 6 veículos compatíveis, pricing R$60 BRL avg}}`.
- **Cache hit** — evidência: 2ª call mesmo código = 1.3s vs ~5s da 1ª. `parts` table count=1, `part_equivalents`=4, `compatible_vehicles`=6, `parts_price_records`=1 confirmado via supabase-py exec no container.
- **RLS correto** — evidência: chamadas com API_SECRET (user=`service`) retornam 401 nos endpoints per-user após o fix UUID-filter no gateway, em vez de vazar erros Postgres.
- **Commits limpos, branch publicada** — evidência: `feat/parts-odin @ dac5375`, PR link https://github.com/toliveira1802-sketch/dap4/pull/new/feat/parts-odin. 21 arquivos / +3938 linhas / 2 commits.

## O que NÃO funcionou (e por quê)

- **Teste de smoke via `localhost:3001` falhou (HTTP 000)** — gateway/agents containers não publicam ports no host, só na rede Docker interna (`doctor-auto-ai_internal`). Solução: testar via Caddy em `:80` ou `docker exec` dentro da rede.
- **`wget` dentro do container agents** — não existe no image Alpine/Distroless. Usar `curl` ou `python -c` pra probes internas.
- **1ª versão do gateway tratava `user_id="service"` como usuário válido** — causava 500 Postgres (`invalid input syntax for type uuid: "service"`) em identify-code/identify-image mesmo quando o endpoint não requer user real. Fix: commit `dac5375` filtra via regex UUID no helper `withUser`/`realUserId` de `gateway/src/routes/parts.routes.ts`.
- **Primeira tentativa de vitest com `vi.useFakeTimers()` + `waitFor`** — timeout após 5s porque waitFor usa real timers. Solução: usar `shouldAdvanceTime: true` em `useFakeTimers` + `advanceTimersByTimeAsync` em `act`.
- **`dashboard` container não existe em prod** — o override `docker-compose.override.yml` da VPS desabilita via `profiles: [disabled]`; Caddy serve os estáticos do bind-mount `/opt/doctor-auto-ai/dashboard/dist`. Portanto `docker compose up --build` NÃO rebuilda o dashboard automaticamente — precisa `npm ci && npm run build` manual na VPS após cada deploy de código frontend.

## O que ainda não foi tentado

- **Login real no browser como usuário Supabase final** — Thales precisa abrir `https://app.doctorautoprime40.com/parts`, logar com conta Supabase, e testar scan com foto de etiqueta real. O endpoint por API_SECRET foi validado, mas fluxo JWT end-to-end só passa nesse teste.
- **Rota B (Tauri desktop offline)** — scoped mas não iniciado. Decisão estratégica na sessão: **não fazer** agora. Web já cobre o uso real da oficina (WiFi presente, latência LLM 1-5s é suficiente). PWA + seed de catálogo premium resolvem o mesmo problema com 10% do esforço.
- **Seed de catálogo premium** — batch de `identify-code` nos top códigos alemães (N20/N54 BMW, M274 MB, EA888 VW) pra transformar 90% das consultas futuras em cache hit sub-1s. Não iniciado.
- **PWA** do dashboard — service worker + manifest pra "add to homescreen" no celular do mecânico. Não iniciado.
- **Integração Odin → Kommo** — botão "buscar peça" dentro do fluxo de orçamento que puxa código + equivalentes + preço. Não iniciado.
- **Job de re-cotação + alerta** — APScheduler cron que re-avalia peças do inventário, dispara notificação via socket.io e/ou Meta WhatsApp. Tabela `parts_price_alerts` já existe, cron não.
- **Atualização do CLAUDE.md global** — mapa antigo do ecossistema (com "DAP Dev", "DAP AI", "DAP Social", "DAP Prime" como unidade, "DAP Funilaria") está desatualizado. Memória salva em `project_dap4_ecosystem_map.md` mas o CLAUDE.md fonte ainda precisa ser atualizado. Não feito — Thales prefere consolidar depois da sprint de automação.
- **Entrada em branco no Notion** (March 25, 8:13 PM, sem nome) — Thales ainda não definiu o que é.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `supabase/migrations/20260423_02_parts_recognition_schema.sql` | Completo — aplicado em prod | 7 tabelas + bucket + RLS |
| `agents/services/parts_analyzer.py` | Completo | Vision OCR + cross-ref com JSON schema estrito |
| `agents/services/parts_repo.py` | Completo | Supabase async wrapper + stats/dashboard puros |
| `agents/services/parts_service.py` | Completo | `analyze_and_persist` cache-first |
| `agents/api/routes/parts.py` | Completo | 17 endpoints FastAPI `/agent/parts/*` |
| `agents/tests/test_parts_analyzer.py` | Completo | 14 testes verdes |
| `agents/main.py` | Modificado | Registra router parts com `Depends(verify_auth)` |
| `gateway/src/routes/parts.routes.ts` | Completo (com fix) | Proxy REST + strictLimiter + UUID filter |
| `gateway/src/index.ts` | Modificado | Import + mount de `/api/parts/*` |
| `dashboard/src/pages/parts/PartsHome.jsx` | Completo | Landing brutalista |
| `dashboard/src/pages/parts/PartsScan.jsx` | Completo | Câmera nativa + live getUserMedia + manual |
| `dashboard/src/pages/parts/PartsResults.jsx` | Completo | Resultado com equivalentes/veículos/preço |
| `dashboard/src/pages/parts/PartsInventory.jsx` | Completo | Planilha editável inline + export CSV |
| `dashboard/src/pages/parts/PartsDashboard.jsx` | Completo | KPIs + Recharts |
| `dashboard/src/pages/parts/PartsHistory.jsx` | Completo | Lista por usuário |
| `dashboard/src/pages/parts/PartsAlerts.jsx` | Completo | CRUD alertas |
| `dashboard/src/pages/parts/_shared.jsx` | Completo | OdinButton/Divider/ConfidenceBadge/Toast |
| `dashboard/src/main.jsx` | Modificado | 7 rotas lazy |
| `dashboard/src/lib/api.js` | Modificado | Namespace `parts.*` |
| `dashboard/src/components/Layout.jsx` | Modificado | Sidebar "Parts › Odin" |
| `dashboard/src/test/parts.test.jsx` | Completo | 6 vitest |
| `C:\Users\docto\.claude\projects\...\memory\project_odin_parts_port.md` | Completo | Memória de projeto |
| `C:\Users\docto\.claude\projects\...\memory\project_dap4_ecosystem_map.md` | Completo | Mapa canônico atualizado |
| `C:\Users\docto\.claude\projects\...\memory\MEMORY.md` | Modificado | 2 pointers adicionados |

## Decisões tomadas

- **Rota A (web prod) antes de Rota B (Tauri offline)** — razão: não construir cliente desktop contra backend não-validado. Web é reversível, barato de corrigir. Validou tudo: auth, LLM, storage, RLS, DB, UI.
- **Não fazer Tauri** — razão: a oficina tem WiFi, latência LLM 1-5s é suficiente, offline vira 2º codebase pra manter sem benefício operacional concreto, isola catálogo por device, atrasa features web. PWA + seed premium resolvem o mesmo problema com fração do esforço.
- **OpenAI GPT-4o-mini (OpenAI direto)** em vez de Gemini via Manus Forge — razão: 1 provider, 1 SDK, já usado por Ana/Kimi no DAP4, JSON schema estruturado mais limpo que o original.
- **Schema novo com nomes prefixados `parts_*`** (exceto o catálogo compartilhado `parts/part_equivalents/compatible_vehicles`) — razão: evitar colisão com tabelas CRM/ops existentes e deixar claro o módulo no DB.
- **RLS por `user_id = auth.uid()`** nos per-user + leitura pública authenticated nos shared — razão: histórico/alertas/inventário são privados; catálogo beneficia todos os usuários (1 scan de um mecânico vira cache pra todos).
- **Gateway filtra `user_id` via regex UUID** em vez de passar `"service"` — razão: identify-code/image funcionarem via API_SECRET pra scripts internos + per-user endpoints devolverem 401 claro em vez de 500 Postgres.
- **Doctor Auto Prime não é "unidade" separada** — razão: é a oficina âncora dentro do ecossistema DAP 4.0. Esclarecido pelo Thales nesta sessão.
- **DAP Tech absorveu antigos "DAP Dev" e "DAP AI"** — sub-unidades `AI` (agentes, RAG, produtos IA) e `Tools` (DAP4 codebase, Odin, integrações). Decisão do Thales, não nossa.

## Bloqueios & perguntas abertas

- **Smoke test final depende do Thales** — login real no browser + scan de peça com foto. Sem isso, o path JWT Supabase end-to-end não foi provado no fluxo visual.
- **Scripts de deploy do dashboard** — o `make prod` não inclui rebuild do front. Não tem script `deploy-dashboard.sh` pra orquestrar `git pull + npm ci + npm run build` atomicamente. Pendente criar (ou documentar).
- **PR ainda não aberto no GitHub** — branch está pushed mas Thales ainda precisa abrir o PR pelo link ou via `gh pr create` (permissão dele).
- **Entrada em branco no Notion do ecossistema** (25/03 8:13 PM) — o que é?
- **DAP Funilaria** — saiu do roadmap definitivamente ou só não tá listado no índice atual do Notion?

## Próximo passo exato

**Na próxima sessão, Thales vai dar os pontos-chave da automação do ecossistema.** Ele disse literalmente "preciso começar automatizar o andamento dessa locomotiva". A sessão atual ficou grande (deploy do Odin + mapeamento), então decidimos fazer o handoff e iniciar a próxima sessão limpa.

Passos concretos ao abrir a próxima sessão:
1. Rodar `/resume-handoff` apontando pra este arquivo
2. Esperar Thales listar os **pontos-chave da automação da locomotiva do ecossistema DAP 4.0**
3. Consolidar esses pontos num mapa (possivelmente Excalidraw via MCP no chat)
4. Traduzir em plano de sprint: o que é hook, o que é cron, o que é agente, o que é UI, prioridades por ROI

**Paralelamente** (quando Thales autorizar): rodar seed de catálogo premium no Odin + iniciar PWA do dashboard. Mas essas tarefas só entram depois que ele validar no browser que o Odin funciona no fluxo real dele.

## Setup / comandos úteis

**Deploy de código backend (agents/gateway):**
```
ssh root@76.13.170.42
cd /opt/doctor-auto-ai && git fetch && git checkout <branch> && git pull
make prod
```

**Deploy do dashboard** (separado, não integrado no Makefile):
```
ssh root@76.13.170.42
cd /opt/doctor-auto-ai/dashboard && npm ci && npm run build
# Caddy já serve o dist/ via bind-mount, sem reload necessário
```

**Smoke test Odin live (via Caddy, usando API_SECRET):**
```
ssh root@76.13.170.42 'curl -s -X POST http://127.0.0.1/api/parts/identify-code -H "Content-Type: application/json" -d "{\"code\":\"06A 115 561 B\"}"'
```

**Verificar containers:**
```
ssh root@76.13.170.42 "docker ps --format '{{.Names}}: {{.Status}}' | grep doctor"
```

**Contagem de rows nas tabelas do Odin:**
```
docker exec doctor-auto-ai-agents-1 python -c "
from supabase import create_client; import os
sb = create_client(os.environ['SUPABASE_URL'], os.environ['SUPABASE_SERVICE_ROLE_KEY'])
for t in ['parts','part_equivalents','compatible_vehicles','parts_price_records']:
    r = sb.table(t).select('*', count='exact').execute()
    print(f'{t}: {r.count}')
"
```

**Projeto Supabase:** `acuufrgoyjwzlyhopaus` (DOCTOR_PRIME)
**Branch Git atual (VPS):** `feat/parts-odin @ dac5375`
**PR:** https://github.com/toliveira1802-sketch/dap4/pull/new/feat/parts-odin
