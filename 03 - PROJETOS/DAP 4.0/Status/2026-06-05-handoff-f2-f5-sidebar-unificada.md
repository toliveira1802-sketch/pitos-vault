---
type: handoff
date: 2026-06-05
time: "00:45"
project: dap-aios
topic: F2-F5 da refatoração de portais — Sidebar unificada declarativa + modo AIOS multi-seção (mergeada + em staging)
tags: [handoff, claudin, dap-aios, arquitetura, portais, sidebar, frontend]
---

# Handoff — F2-F5: Sidebar unificada declarativa (mergeada, em staging)

> Continuação direta do F1 (`2026-06-04-handoff-f1-role-aios-readonly.md`). Esta rodada fechou
> o frontend da refatoração de portais: aposentou os 3 paradigmas de nav, montou uma config
> declarativa + Sidebar única, e afinou a estrutura no loop visual com o Thales (Vite + screenshots).
> **PR #47 mergeado em `main` (`e59b063`); deploy em staging validado.**

## Contexto

O F1 deixou o backend pronto (role `aios` read-only + allowedPortals). Mas o `aios@` logando no
staging caía em **tela preta** (resolvido no handoff anterior com o deploy do F1) e via o LegacyNav
incompleto. Esta rodada entregou o F2-F5: navegação unificada, hierárquica e declarativa, com o
modo multi-seção do AIOS.

## O que funcionou (com evidência)

- **Config de nav declarativa** — `client/src/shared/nav/{types,consultor,gestao,mecanico,aios,cliente,registry}.ts`. Uma fonte de verdade por portal (ícones, hrefs, testIds, CTA). Evidência: `registry.test.ts` 11 testes verdes.
- **Sidebar unificada** — `Sidebar.tsx` de 817 linhas / 3 paradigmas (ConsultorNav/GestaoNav/LegacyNav) → 1 componente, 2 modos: single-portal (consultor/gestor/mecânico) e multi-portal colapsável (aios/admin) na ordem `AIOS · Gestão · Consultor · Mecânico · Cliente`. **LegacyNav aposentado.** Evidência: screenshots do `aios@` logado (modo multi, todas as seções na ordem certa).
- **Calculadoras fora** da nav e de `PORTAL_ROUTES` (DEAD-NAV; rotas resolvem por URL direta). Evidência: `portals.test.ts` + `registry.test.ts`.
- **Loop visual com o Thales** — 3 iterações de screenshot. Ajustes aplicados: (1) seções colapsadas por default, só AIOS aberta; (2) badge "Observação" removido (AIOS terá ação própria); (3) ordem mantida; (4) "Sala do Conselho" fora da Gestão; (5) Operação/Comercial do Consultor colapsáveis; (6) AIOS = Sophia/Walter/Anna (Conhecimento→Walter, Anna Shadow→Anna, Shadow vira ação dentro da Anna); (7) Gestão: Comercial agrupa Vendas&CRM+Pós-venda, Equipe→RH; (8) usuário `aios@` renomeado pra "AIOS" no banco.
- **Bug pego pelo reviewer automático (codex P2) e corrigido** — a Sidebar fixava o portal do subdomínio incondicionalmente; um gestor em `consultor.*` (fora do allowedPortals) veria nav do Consultor enquanto o RouteGuard o manda pra `/gestao`. Fix: `fixedPortal` só vale se `allowed.includes(pinned)`. Commit `d88dffa`.
- **Gate** — `pnpm check` OK · client 36/36 · **server 350/350** · lint 0 errors (15 warnings pré-existentes em `dashboardService`, fora de escopo). CI: 9 checks obrigatórios verdes.
- **Merge + deploy** — PR #47 squash-merged (`e59b063`). VPS `/opt/dap-aios/src` `3467c99→e59b063`, rebuild + recreate. Evidência: container `Up (healthy)`, 4 subdomínios `*/api/health → 200`.

## O que NÃO funcionou (e por quê)

- **Merge inicial bloqueado** — branch protection exige (a) resolução de comentários e (b) os 9 checks required. O "E2E Playwright" (workflow `informational`, NÃO required) falha sempre — não bloqueia. O bloqueio real era a thread aberta do reviewer codex; resolvida após aplicar o fix → merge limpo (sem `--admin`).
- **Login do `aios@` deu "Invalid credentials" na 1ª tentativa** no Playwright — foi timing/refresh-token stale; a sessão estabeleceu e o login funciona.

## Arquivos tocados

| Arquivo | Status | Commit |
|---------|--------|--------|
| `client/src/shared/nav/types.ts` | Criado | feat nav |
| `client/src/shared/nav/{consultor,gestao,mecanico,aios,cliente}.ts` | Criados | feat nav |
| `client/src/shared/nav/registry.ts` | Criado (PORTAL_ORDER + defaultCollapsedKeys) | feat nav |
| `client/src/shared/components/Sidebar.tsx` | Reescrito (817→~480 linhas) | feat nav + fix `d88dffa` |
| `client/src/auth/portals.ts` | Modificado (calculadoras fora, ordem aios-first) | feat nav |
| `client/src/shared/nav/registry.test.ts` | Criado (11 testes) | test nav |
| `client/src/auth/portals.test.ts` | Modificado | test nav |
| `e2e/consultor-sidebar.spec.ts` | Modificado (grupos colapsam, testid novo) | test nav |
| `.gitignore` | +`.tmp-screenshots/` +`.playwright-mcp/` | test nav |
| Banco `hlhf`: `users.name` do `aios@` → "AIOS" | via Supabase MCP | — |

## Decisões tomadas

- **Refactor estrutural, não redesign** (spec §6) — preservei a linguagem visual do ConsultorNav; só unifiquei estrutura + adicionei o modo multi-seção. Baixou o risco de design.
- **Modo decidido por role + hostname** — subdomínio fixo → single-portal daquele portal (se a role o acessa); senão multi (aios/admin) ou single do 1º allowedPortal.
- **CTA via `ctaId`** (não função no spec) — Sidebar resolve `new-os` → modal. `sidebar-new-os` preservado no rodapé do modo multi pra não quebrar o wizard e2e.
- **Default-colapso semeado no localStorage na 1ª visita** — portais fechados menos AIOS + grupos `defaultCollapsed`. Smart-expand força aberto na rota ativa.
- **Shadow virou ação dentro da Anna** (não item de nav) — decisão do Thales; href ainda aponta `/aios/anna/shadow` por ora.

## Bloqueios & perguntas abertas

- **Interceptor de toast `AIOS_READ_ONLY` no client** ainda não existe — os botões de escrita do aios ficam clicáveis e o servidor barra com 403, mas sem feedback visual ("não gravado"). É a próxima fatia natural (era F3 do plano original).
- **Portal Cliente** segue placeholder ("soon") — construir de verdade é outra frente.
- **Mecânico** tem hierarquia mínima (Pátio + Agenda soon) — cresce quando o portal amadurecer.
- **Dívida herdada**: systemd `dap-aios` legado órfão em `:5050` na VPS (candidato a desligar); 15 warnings de lint pré-existentes em `dashboardService.ts` (débito Sprint 4b).

## Próximo passo exato

**Validação do Thales em staging**: hard-refresh + login como `aios@` em `aios.doctorautoprime40.com` → confirmar a sidebar nova (só AIOS aberta, demais colapsadas; Walter/Anna; Gestão com Comercial/RH). Depois, decidir a próxima fatia entre:
1. **Toast `AIOS_READ_ONLY`** no client (interceptor de resposta em `lib/api.ts` + toast) — fecha a UX do read-only.
2. **Portal Cliente** de verdade (sai do placeholder).
3. **Embutir Calculadoras** nos portais (código dorme em `/calculadoras/*`).

## Setup / comandos úteis

- main em `e59b063`. Branches `feat/refatora-portais-aios` e `feat/sidebar-unificada-nav` mergeadas e deletadas.
- pnpm fora do PATH: `export PATH="/c/Users/docto/AppData/Roaming/npm:$PATH"`.
- Testes da nav: `pnpm --filter @aios/client exec vitest run src/shared/nav/registry.test.ts src/auth/portals.test.ts`.
- Deploy staging: `cd /opt/dap-aios/src && git fetch origin && git reset --hard origin/main && docker build -t dap-aios:staging . && docker compose -p doctor-auto-ai -f docker-compose.staging.yml up -d --force-recreate aios-staging`.
- Usuários: `aios@doctorautoprime40.com` (role aios, senha definida pelo Thales) · `consultor.teste@`/`gestao.teste@`/`mecanico.teste@doctorautoprime40.com` (senha `12345678`).
