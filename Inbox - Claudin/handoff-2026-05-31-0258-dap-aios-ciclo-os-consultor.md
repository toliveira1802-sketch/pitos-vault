---
type: handoff
date: 2026-05-31
time: 02:58
project: DAP4 / dap-aios
topic: Ciclo completo do Consultor (cliente → OS → fechar/cancelar) + isolamento de testes + fix de permissões
tags: [handoff, claudin, dap-aios, consultor, testes, supabase]
---

# Handoff — dap-aios: ciclo OS do Consultor entregue tela a tela

## Contexto
Sessão longa fatiando o **fluxo de negócio do Portal Consultor** no dap-aios
(`C:\THALES\DAP4.0\dap-aios`) tela a tela, pra gerar **dado real**: cadastrar
cliente → veículo → abrir OS → trabalhar → **fechar ou cancelar**. Começou como
`/resume-handoff` da sessão de 30/05 manhã. No meio, descobri e corrigi a causa
de um incidente (banco do app sendo zerado pelos testes). Tudo no branch
`feat/ai-sprint4b-anna-shadow-ui`, **pushado** (HEAD `ee08c19`). Banco = Supabase
DAP AIOS (`hlhfqnhsvwxodtwdkkhf`). App: `pnpm dev` → http://localhost:5050.

## O que funcionou (com evidência)
- **Fix permissões (incidente 403)** — tabela `public.permissions` estava VAZIA → toda role ≠ admin dava 403. Restaurei 36 grants espelhando seed.ts via SQL (MCP). Evidência: consultor=17, gestor=15, mecanico=3, admin=1.
- **Isolamento de testes por schema** (commit `9bd50f5`) — testes agora rodam no schema `test` (espelho de public). Evidência: 307→322 testes verdes E `public.permissions=36` intacto antes/depois da suíte.
- **Fatia Clientes** (commit `06f08e8`) — cadastro afrouxado (só nome+telefone) + dedupe (409 CUSTOMER_DUPLICATE, botão "Abrir cadastro"). Validado no browser pelo Thales ("deu certo").
- **Fatia Abrir OS** (commit `b2e41f6`) — auto-atribui consultor logado como advisor + bloqueia 2ª OS ativa no mesmo veículo (409 VEHICLE_HAS_OPEN_ORDER). 5 testes novos.
- **Fatia Fechar/Cancelar** (commit `ee08c19`) — botão "Cancelar OS" no header → modal com motivo obrigatório → status=canceled + evento service_order_canceled. Fechar = funil comercial → entregue (já existia). 3 testes novos.
- **Tudo verde**: tsc client+server+types, ESLint, 322 testes, Husky pre-commit OK em todos os commits.

## O que NÃO funcionou (e por quê)
- **`pnpm test` zerava o banco do app** — `wipeAll()` (db-helpers.ts) dava TRUNCATE CASCADE em `permissions/users/customers` no MESMO banco do app (não havia isolamento). Foi a causa raiz do 403. RESOLVIDO com schema `test` + trava `current_schema()='test'`.
- **Here-string de commit com aspas duplas** quebra o PowerShell ("pathspec..."). Solução: nunca usar `"` dentro de `git commit -m @'...'@`; escrevo `Em-breve`/`Abrir-cadastro`. Os arquivos já ficam staged — só refazer o commit.
- **`git push` joga URL no stderr** → PowerShell pinta NativeCommandError (exit 255) mesmo com push OK. Confirmar com `git status -sb`.
- **action novo de evento** (`service_order_canceled`) precisou ser adicionado ao enum em `packages/types/src/schema/events.ts` — senão tsc + runtime (recordEvent) falham.

## O que ainda não foi tentado
- **Deploy na VPS** — Thales pediu lá no começo; é o próximo marco natural. Falta mapear: build de produção do dap-aios, onde hospedar (front+server), wiring do Supabase em prod.
- **Validação no browser do cancelamento** — implementado e testado por TDD, mas o Thales ainda não clicou no botão (os "2"/"erro" dele eram typos, não bug real).
- **Auto-sync do schema test após db:push** — hoje manual (`test:db:setup`). Poderia entrar num hook/CI.

## Arquivos tocados (principais, por fatia)
| Arquivo | Fatia |
|---------|-------|
| `server/scripts/setup-test-schema.ts` (novo) | Isolamento testes |
| `server/src/db/client.ts` (search_path test) | Isolamento testes |
| `server/test/setup/db-helpers.ts` (trava wipeAll) | Isolamento testes |
| `client/.../NewCustomerForm.tsx` | Clientes (afrouxar+dedupe) |
| `server/src/services/customerService.ts` (CustomerDuplicateError) | Clientes |
| `server/src/services/serviceOrderService.ts` (advisor auto, bloqueio, cancel+reason) | Abrir OS + Cancelar |
| `server/src/routes/service-orders.ts` | Abrir OS + Cancelar |
| `client/.../NewServiceOrderModal.tsx` | Abrir OS (409 UI) |
| `client/.../os-detail/CancelOrderButton.tsx` (novo) | Cancelar |
| `client/.../os-detail/ServiceOrderHeader.tsx` | Cancelar (integra botão) |
| `packages/types/src/schema/events.ts` | Cancelar (enum) |

## Decisões tomadas (pelo Thales)
- **Clientes:** afrouxar campos (só nome+telefone); SEM validação de dígito de CPF; dedupe bloqueia+puxa cadastro antigo; limpar lixo do banco.
- **Abrir OS:** auto-atribuir consultor logado como advisor SIM; bloquear OS duplicada no mesmo veículo SIM; campos do Step 3 OK como estão.
- **Fechar/Cancelar:** botão no header + confirmação SIM; motivo obrigatório SIM; SEM botão "Fechar" dedicado (mantém funil comercial → entregue).
- **Isolamento de teste:** schema dedicado no mesmo projeto (não 2º projeto nem Docker) — escolha do Thales.

## Bloqueios & perguntas abertas
- Nenhum bloqueio técnico. Banco do app começou limpo (0 clientes) de propósito — dado real do zero.
- **requireAuth fail-closed** (commit anterior 021a900): exige `SUPABASE_JWT_SECRET` no `.env` de prod pra validação local rápida; sem ele cai no fallback remoto (mais lento mas seguro). Garantir no deploy.

## Próximo passo exato
Decidir entre **(A)** validar no browser o cancelamento (abrir OS → botão "Cancelar OS" no header → motivo → confirma; ver status "Cancelada" + motivo no Event Timeline) e fechar a fatia; ou **(B)** iniciar o **deploy na VPS** — mapear build de produção do dap-aios (`pnpm build` gera `dist/server/index.cjs` + client estático), definir host, wirar Supabase DAP AIOS em prod e `SUPABASE_JWT_SECRET`. Recomendo (A) rápido e depois (B).

## Setup / comandos úteis
- App: `pnpm dev` → http://localhost:5050 (rodando em background nesta sessão).
- **Commit:** PowerShell com `$env:PATH = "C:\Users\docto\AppData\Roaming\npm;" + $env:PATH` (Husky precisa de pnpm no PATH). NUNCA aspas duplas dentro de here-string `@'...'@`.
- Testes: `pnpm --filter @aios/server test` (rodam no schema `test`, seguros). Após `pnpm db:push`: rodar `pnpm --filter @aios/server test:db:setup` pra re-espelhar o schema.
- Typecheck: `pnpm --filter @aios/{client,server,types} check`.
- Restaurar permissões sem reseed: `cd server; npx tsx scripts/grant-permission.ts <role> <resource> <action>`.
- Consultor de teste: `consultor.teste@doctorautoprime.com` / `Teste@DAP2026`. Admin dev: `toliveira1802@gmail.com` / `12345678`.
- HEAD: `ee08c19`. Memória nova: `feedback_dap_aios_test_isolation.md`.
