---
type: handoff
date: 2026-05-01
time: 21:04
project: dap-aios + dap4 (decisão B aprovada)
topic: R1→R4 fechadas (R4 RBAC executada por sessão paralela), Mapa Quebra-Cabeça gerado, decisão estratégica B (dap-aios = consumidor de dap4 gateway). Próximo provável: R5 Phase B ou /aios visual fix
tags: [handoff, claudin, dap-aios, dap4, rodada-3, rbac, phase-b]
---

# Handoff — dap-aios R1-R3 + Mapa + Decisão B

## Contexto

Construindo `dap-aios` (`C:\dev\dap-aios`) como **shell de UX multi-portal** do DAP 4.0, separado em rodadas curtas com handoff HTML por rodada. Branch única: `feat/aios-nucleo-consultor`.

Hoje (2026-05-01) terminamos R1 (inventário), R2 (Núcleo + Portal Consultor + Inbox/Chat), R3 (Portal Mecânico) e R0.5 (Mapa do Quebra-Cabeça). Thales decidiu estratégia **B**: dap-aios continua como protótipo UX user-facing, vira consumidor das APIs do dap4 (que está em prod, com Anna IA, Sophia Hub, Parliament, ChromaDB, Supabase). Próxima rodada (R4) é **RBAC** — sidebar dinâmica + role switcher + visões por role (Chairman/Diretor/Consultor/Mecânico/Cliente), sem auth real ainda.

Sessão ficou pesada (R1+R2+R3+mapa+4 audits+debug+hotfix) — handoff feito pra começar R4 fresca.

## O que funcionou (com evidência)

- **R2 commit `e7ece37` — Núcleo AIOS + Portal Consultor + Inbox/Chat 3-painel** — evidência: smoke E2E (customer→vehicle→quote→approve→OS-2026-0001 + 2 eventos); chat 3-pane com send + convert-to-lead; build verde 123 KB gz; code review aplicou 2 CRITICAL + 5 HIGH + 2 MEDIUM antes do commit
- **R3 commit `cfa2be3` — Portal Mecânico** — evidência: 7 tabelas novas (mechanics, checklists, items, comments, attachments, parts, appointments) + 13 endpoints + 5 rotas frontend + 5 tabs no detail + smoke E2E PATCH status / POST comment / POST part / PATCH checklist item; não-regressão `/consultor` confirmada (5 conversations, 3 leads, 1 quote OK)
- **Hotfix seed commit `fd82cdb`** — capturamos `stubUserId` de `.returning()` em vez de hardcoded `1`; reseed agora idempotente (testado 2x consecutivos sem FK violation)
- **R0.5 Mapa do Quebra-Cabeça** — `handoff-aios-mapa-quebra-cabeca.html` com Mermaid embedded; descobertos **18 repos satélites** que eu não conhecia + audit de PITOS (14 docs canônicos identificados); cruzou dap-aios + dap4 + dap-operacao + vault
- **dap4 prod check** — VPS up 53d, 5 containers Docker healthy 7d, gateway/agents/chromadb/caddy/portal-familia rodando, Anna prod intacta no WhatsApp +5511917001822

## O que NÃO funcionou (e por quê)

- **better-sqlite3 v11.7 no Node 24** — pnpm install tentou compilar do source (Windows sem VS Build Tools 2022) e falhou. Resolvido trocando por `@libsql/client` que tem prebuild Node 24 + driver Drizzle equivalente
- **`reusePort: true` em `httpServer.listen()` no Windows** — Node 24 não suporta no win32, retorna `ENOTSUP`. Resolvido com guard `if (process.platform !== "win32")`
- **Porta 5000 ocupada** — dev server do `dap-operacao` (outro projeto) já estava rodando lá. Resolvido pinning `PORT=5050` no script via cross-env
- **Vite alias array `@/*` → `[client/src, packages/ui/src]`** — funciona em TS (path mapping aceita array) mas Vite só aceita string. Tive que reescrever ~50 imports `@/lib/utils` → `../../lib/utils` dentro de `packages/ui/src/`
- **Express 5 module augmentation `express-serve-static-core`** — TS 5.6 não acha o módulo. Resolvido com `declare global { namespace Express { interface Request {...} } }`
- **Spawn de Explore agents** — prompts longos (>~250 palavras) recebem "Prompt is too long". Tive que reescrever em prompts curtos (<200 palavras) e usar `general-purpose` em vez de `Explore`
- **dap4 público offline** — Cloudflare Tunnel retorna HTTP 530 / error 1033. `cloudflared.service` está active mas com falha "control stream encountered a failure while serving · Retrying in 1m4s". Stack interno OK; só o tunnel pra edge Cloudflare está reciclando conexão. Não fizemos nada — espera de aprovação do Thales pra restart

## O que ainda não foi tentado

- **Restart `cloudflared.service` no VPS** — Thales não confirmou se quer mexer agora; pode ser blip da Cloudflare que resolve sozinho
- **DnD real no Pátio Kanban** — auditoria de `dap-operacao` confirmou que ele também não tem (só ícone `LayoutGrid`); decisão foi aceitar botão "avançar pro próximo status"
- **Wire dap-aios → dap4 gateway (Phase B)** — decisão estratégica aprovada (opção B), mas execução fica pra R5+
- **Investigar `doctor-os/dap-portal-aios`** (Trio Sprint Sophia/Walter/Anna em OneDrive) — memória aponta como "fonte canônica AIOS" mas estamos construindo `dap-aios`. Possível duplicação. Precisa decisão estratégica

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `C:\dev\dap-aios\packages\types\src\schema\{core,customers,consultor,mecanico}.ts` | Completo | 13 tabelas R2 + 7 tabelas R3 = 20 total |
| `C:\dev\dap-aios\server\routes\*.ts` | Completo | 9 routers: meta, leads, customers, vehicles, quotes, service-orders, events, conversations, mechanics, checklists, appointments — 34 endpoints REST |
| `C:\dev\dap-aios\server\middleware\auth.ts` | Completo | requireAuth stub (decisão R2 5.1 — opção C, aprovada) |
| `C:\dev\dap-aios\server\lib\events.ts` | Completo | logEvent helper + 17 EventEntities + 19 EventActions |
| `C:\dev\dap-aios\client\src\modules\consultor\` | Completo | 7 pages + 3 components + 2 libs |
| `C:\dev\dap-aios\client\src\modules\mecanico\` | Completo | 5 pages + 4 components + 2 libs |
| `C:\dev\dap-aios\script\seed.ts` | Completo | 9 roles + 6 perms + 2 customers + 3 leads + 5 conversations + 13 messages + 3 mechanics + 4 OS + 1 checklist + 2 comments + 2 parts + 3 appointments |
| `C:\dev\dap-aios\handoff-aios-rodada1-inventario.html` | Completo (R1) | gerado por sessão anterior — não tocado hoje |
| `C:\dev\dap-aios\handoff-aios-rodada2-consultor.html` | Completo (R2) | 16 seções obrigatórias; gerado hoje |
| `C:\dev\dap-aios\handoff-aios-rodada3-mecanico.html` | Completo (R3) | gerado hoje |
| `C:\dev\dap-aios\handoff-aios-mapa-quebra-cabeca.html` | Completo (R0.5) | gerado hoje, com Mermaid embedded; lista 18 repos satélites |
| `C:\dev\dap-aios\client\src\App.tsx` | Em progresso | mockup AIOS shell (1031 linhas inline); ConsultorRoutes + MecanicoRoutes registradas; **R4 vai mexer aqui pra sidebar dinâmica + role context** |
| `C:\dev\dap-aios\packages\ui\src\components\ui\*.tsx` | Completo | imports `@/` reescritos pra paths relativos (era pré-condição pro Vite) |

## Decisões tomadas

- **R2 §5.1 — Auth: Opção C (adiar auth real)** — razão: `CLAUDE.md` proíbe cookies sem aprovação; conflito direto com legado dap-operacao que usa session+cookie+bcrypt; melhor adiar do que travar a rodada toda. Senha do user seed = sentinel `__stub_no_auth_yet__` (rejeitada por bcrypt real quando vier)
- **R2 §5.2 — Scripts: Opção A (religar agora)** — razão: aceitar que refactor monorepo ficou inacabado; commit isolado `e889a9a` pra reverter facilmente se der ruim
- **R2 — better-sqlite3 → @libsql/client** — razão: Node 24 + Windows sem VS Build Tools 2022; @libsql/client tem prebuild Node 24 e driver Drizzle equivalente
- **R3 — DnD não implementado no Pátio** — razão: dap-operacao também não tem; tempo investido em DnD não paga vs. botão "avançar"; pode adicionar depois
- **R3 — Continuar na branch `feat/aios-nucleo-consultor`** — razão: R2 ainda não pushada/mergeada; manter série linear simplifica PR final
- **R0.5 — Mapa antes de mais features** — razão: 18 repos satélites descobertos sugerem que estávamos recriando coisas existentes (status enum SO duplicava dap-operacao; pátio kanban pobre vs nada melhor em lugar nenhum)
- **Estratégica — Opção B aprovada** (dap-aios = consumidor de dap4 gateway) — razão: dap4 é cérebro+dados em prod, dap-aios é shell user-facing multi-portal; dap4 não tem Layout multi-role. Refactorar Layout do dap4 é mais trabalho que wirar dap-aios → dap4. Aceita-se 2 repos com 1 dia de wiring depois

## Bloqueios & perguntas abertas

5 decisões pendentes do Mapa Quebra-Cabeça (cada uma trava/destrava uma rodada inteira):

1. **dap-aios atual é canon ou `doctor-os/dap-portal-aios` (Trio Sprint) vence?** — possível duplicação; memória aponta o outro mas estamos construindo neste
2. **`doctor-auto-prime`** (C:\dev\doctor-auto-prime, 26k LOC, sem remote) — descartar ou tem peças a salvar?
3. **Quando dap-aios troca libsql por gateway DAP4 (Fase B)?** — agora ou depois de R4 RBAC? (recomendei depois)
4. **Sala do Conselho Dify** está arquivada em `PITOS/DAP 4.0/_archive/2026-04-23/` mas memória cita como canônica — qual vence?
5. **Tenant primário pra dap-aios** = DAP Prime único, ou multi-tenant desde já?

Outros bloqueios menores:
- **dap4 público offline** (HTTP 530 / Cloudflare error 1033). Aguardando aprovação Thales pra restart `cloudflared.service` (operação reversível)
- **Master TODO em PITOS** (`DAP 4.0/Notas/001-dap40-master-todo.md`) modificado pela última vez 2026-04-10 — desatualizado, deveria refletir R3+R0.5
- **Memória `project_thales_agent.md`** referencia `C:\dev\thales-agent` que **não existe no FS**

## ⚠ Atualização pós-handoff (sessão paralela)

Enquanto eu salvava este handoff, **outra sessão executou R4 RBAC inteira** + Portal Cliente placeholder. 10 commits novos sobre `fd82cdb`:

```
aa5b5e4 fix(rbac): keep user in place on role change when location is allowed
e43cc35 docs: handoff HTML Rodada 4 — RBAC scaffolding   ← handoff R4 já existe
a99724d feat(rbac): wire RequirePermission guards and default-landing redirect
6863017 feat(cliente): add placeholder Portal Cliente module
8f3c9be feat(rbac): add AIOSEntry chooser with Mural view for non-executive roles
d464cc2 feat(rbac): add RequirePermission guard with default-landing redirect
ab73fce feat(rbac): extract AppSidebar and filter entries by role permissions
d54ce45 feat(rbac): add RoleSwitcher dropdown component
639757f fix(rbac): propagate X-Stub-Role through module API wrappers
df98878 feat(rbac): add RoleProvider context and stub-role header injection
```

`pnpm run check` verde. `handoff-aios-rodada4-rbac.html` existe na raiz do repo. Working tree limpo.

**Implementação R4 inclui:**
- `server/middleware/auth.ts` lê header `X-Stub-Role` e mapeia pra um dos 9 roles + permissions
- `/api/me/permissions` endpoint
- `client/src/lib/role-context.ts` com `RoleProvider` + `getActiveRoleFromStorage`
- `RoleSwitcher` component
- `AppSidebar` extraído de `App.tsx` + filtrado por `can_access_*`
- `<RequirePermission slug="...">` guard com default-landing redirect
- `AIOSEntry` chooser: Sala completa (Chairman/Diretor) vs Mural resumido (Consultor/Mecânico)
- Portal `/cliente` placeholder
- `X-Stub-Role` propagado em consultor + mecanico module APIs
- Script `script/check-rbac.ts` (validação extra)

## Próximo passo exato (atualizado)

**R5 sugerida:** Phase B — wire dap-aios → dap4 gateway. As 3 perguntas operacionais ainda valem:
- Ordem: já R4 feito → Phase B (R5) é o próximo natural
- Endpoints: (a) consumir dap4 quando tem + (c) libsql onde não tem (recomendado)
- Conexão dev: (i) consertar tunnel CF, (ii) deploy na VPS, (iii) SSH tunnel local (recomendado)

Antes de R5 considerar:
- Validar visualmente R4 no browser (trocar de role no switcher → sidebar reage → tentar `/gestao` como Consultor → redireciona)
- Atualizar Master TODO em PITOS pra incluir R3 + R4 entregues
- Resolver as 5 decisões pendentes do Mapa Quebra-Cabeça (#1 ainda relevante: dap-aios é canon ou doctor-os/dap-portal-aios vence?)

Original "próximo passo" abaixo (já obsoleto):

---

**R4 — RBAC + visões por role.** Sem precisar pensar:

1. Em sessão fresca, abrir `C:\dev\dap-aios`, branch já está em `feat/aios-nucleo-consultor` (último commit: `fd82cdb`)
2. Implementar:
   - Role switcher no canto da sidebar (toggle Chairman/Diretor/Consultor/Mecânico/Cliente sem auth real)
   - Sidebar dinâmica filtrada por permissions (`can_access_consultor`, `can_access_aios`, etc — já modeladas na R2)
   - Route guards: `<RequirePermission slug="can_access_X">` envelvendo cada Routes module
   - Default landing por role (Chairman → `/`, Diretor → `/gestao`, Consultor → `/consultor`, Mecânico → `/mecanico`, Cliente → `/cliente`)
   - 2 vistas do AIOS: "Sala do Conselho" completa (Chairman/Diretor) vs "Mural" resumido (Consultor/Mecânico)
3. Smoke E2E: trocar de role → sidebar reage → tentar acessar rota proibida → redirecionada
4. Commit: `feat: add RBAC scaffolding with role switcher`
5. Handoff `handoff-aios-rodada4-rbac.html` com 16 seções padrão
6. Estimativa: 3-4h (~mesma escala R3)

**Antes de começar R4**, idealmente Thales responde as 5 decisões pendentes do Mapa Quebra-Cabeça (#1 e #5 afetam diretamente R4). Mas R4 pode rodar com o assumido atual:
- (1) dap-aios é canon (estamos construindo nele)
- (5) tenant único DAP Prime (não multi-tenant ainda)

## Setup / comandos úteis

```powershell
cd C:\dev\dap-aios

# se DB sumir/corromper:
Remove-Item data.db, data.db-shm, data.db-wal -Force -ErrorAction SilentlyContinue
pnpm run db:push
pnpm run db:seed

# dev:
pnpm run dev   # http://localhost:5050

# se houver fantasma na 5050:
Get-Process node -ErrorAction SilentlyContinue | Where-Object { try { (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)").CommandLine -like '*dap-aios*' } catch { $false } } | Stop-Process -Force

# verificar dap4 prod (current state HTTP 530):
curl -s -o /dev/null -w "HTTP %{http_code}\n" -m 10 https://portal.doctorautoprime40.com/

# SSH VPS:
ssh -i ~/.ssh/id_ed25519 root@76.13.170.42
```

URLs locais úteis:
- http://localhost:5050/#/ — AIOS shell (mandala mockup)
- http://localhost:5050/#/consultor — Portal Consultor R2
- http://localhost:5050/#/consultor/inbox — Inbox/Chat 3-pane
- http://localhost:5050/#/mecanico — Portal Mecânico R3
- http://localhost:5050/#/mecanico/patio — Pátio Kanban
- http://localhost:5050/#/mecanico/os/1 — Detalhe técnico OS

Histórico de commits (`feat/aios-nucleo-consultor`):
```
fd82cdb fix(seed): capture user id from .returning instead of hardcoding 1
cfa2be3 feat: add portal mecanico technical workflow            (R3)
e7ece37 feat: inicia nucleo AIOS e portal consultor             (R2)
e889a9a chore: re-enable dev/build/check scripts and wire monorepo (R2)
1c0a97f docs: handoff HTML Rodada 1
799b992 docs: inventaria portais AIOS e plano de implementação (Rodada 1)
```
