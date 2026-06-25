---
type: handoff
date: 2026-05-04
time: 15:50
project: dap4 / portal-consultor
topic: Abrir OS wizard 4 etapas + fix /reset-password
tags: [handoff, claudin, dap4, portal-consultor]
---

# Handoff — Abrir OS wizard 4 etapas + fix /reset-password

## Contexto

Sessão fechou a feature **"Abrir OS — Wizard 4 etapas"** no `portal-familia` (consultor) e corrigiu um bug separado de auth recovery descoberto durante o smoke. Entrei na sessão com spec + plano já commitados de manhã (3218c8e + 8f593e4) e migration aplicada (2ad8ca4 + b187839). Restavam Tasks 3-14 do plano.

A feature substitui o `<CreateOSDialog>` modal antigo por uma página dedicada `/consultor/os/nova` com wizard de 4 etapas (Cliente → Veículo → Serviço → Confirmação), reusando schema existente (clients/vehicles/ordens_servico/ordens_servico_historico) + 2 triggers Postgres novos (gera `numero_os` zero-padded + cria histórico inicial). Pós-criação redireciona pro `/consultor/patio?highlight=<osId>` com pulse 3s no card recém-criado.

Branch: `feat/fase0-instrumentacao-700k`. Suite full: **145 testes verdes em 30 arquivos**, sem regressão.

## O que funcionou (com evidência)

- **Migration triggers `gerar_numero_os` + `before/after_insert_os`** — smoke confirmado em prod: `gerar_numero_os()` retorna `OS-99294` (continuidade com max existente), INSERT + rollback popula `numero_os` e cria 1 row em `ordens_servico_historico` com `tipo='status_change'`.
- **Tasks 3-14 todas verdes via TDD bite-sized** — cada task: red → green → typecheck → commit atômico. 14 commits em sequência, suite cresceu de 109 → 145 testes.
- **Auth manual + magic link recovery** — `ResetPasswordPage` parseia hash manualmente (`detectSessionInUrl: false` no client porque tem o bug do Navigator Lock), valida token via GET `/auth/v1/user`, hidrata authStore via `setAuth({...})`. 6 testes.
- **Reset de senha admin via REST** — Supabase Auth Admin PUT `/auth/v1/admin/users/<id>` funcionou pra desbloquear o login do Thales. Senha temporária em `C:\Users\docto\dap-temp-pass.txt` (24 chars, ACL restrita).

## O que NÃO funcionou (e por quê)

- **Test do PatioKanban com `vi.useFakeTimers()`** — travou em 5s timeout. Causa: TanStack Query usa timers internos que conflitam com fake timers. Fix: troquei pra real timers + `waitFor({ timeout: 5000 })` + test timeout 8s.
- **`useBlocker` no test do NovaOSPage com `MemoryRouter`** — falhou com `useBlocker must be used within a data router`. Fix: trocar pra `createMemoryRouter` + `RouterProvider` (prod já usa data router via `createBrowserRouter`).
- **Selector `getByLabelText(/nova senha/i)`** — ambíguo, casava com "Nova senha" E "Confirmar nova senha". Fix: regex exato `/^nova senha$/i`.
- **Magic link de recovery** — descobri rodando smoke depois da feature pronta. `authService.recoverPassword` redirecionava pra `/reset-password` mas a rota e o componente nunca tinham sido criados. Magic link voltava pro `/login` com hash perdido.
- **Senha do Thales não disponível** — sessões paralelas giram credenciais sem registrar (feedback `feedback_sessoes_paralelas_senha.md`). Magic link recovery quebrado fechou esse caminho. Solução foi reset admin via service_role.

## O que ainda não foi tentado

- **Smoke E2E manual no browser** — os 8 cenários do plano (cliente novo, CPF hit, placa mesmo cliente, transferência, double-click, F5 mid-wizard, sair sem salvar, erro RLS). Thales precisa logar com a senha temp e rodar.
- **Build de produção** — `npm run build` não rodou; bundle pode ter warning crítico não detectado por `tsc --noEmit`.
- **Smoke no Studio (DB)** — confirmar que cria 1 OS via UI gera `numero_os` zero-padded + 1 row em historico (sem duplicação com `registerStatusChange`). Trigger validado em prod isolado, mas ainda não com o flow real do client.
- **Memory persist do fix `/reset-password`** — Thales perguntou se quero salvar; ele encerrou sessão antes de confirmar.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `supabase/migrations/20260504_08_abrir_os_triggers.sql` | Completo (commit 2ad8ca4 — manhã) | Aplicado em prod |
| `portal-familia/src/features/nova-os/store.ts` | Completo | Zustand + sessionStorage |
| `portal-familia/src/features/nova-os/schemas.ts` | Completo | Zod step 1-3 |
| `portal-familia/src/features/nova-os/types.ts` | Completo | Re-export de schema types |
| `portal-familia/src/features/nova-os/hooks/useDebounce.ts` | Completo | Helper |
| `portal-familia/src/features/nova-os/hooks/useClienteByCpf.ts` | Completo | Query debounced 400ms, gating 11 dígitos |
| `portal-familia/src/features/nova-os/hooks/useVeiculoByPlaca.ts` | Completo | Detecta cross-cliente |
| `portal-familia/src/features/nova-os/hooks/useCreateNovaOS.ts` | Completo | Mutation orquestrada cliente→veículo→OS |
| `portal-familia/src/features/nova-os/components/WizardStepper.tsx` | Completo | DAP DS v1.0 |
| `portal-familia/src/features/nova-os/components/Step1Cliente.tsx` | Completo | RHF + Zod + ClienteEncontradoCard |
| `portal-familia/src/features/nova-os/components/Step2Veiculo.tsx` | Completo | RHF + Zod + TransferenciaPlacaModal |
| `portal-familia/src/features/nova-os/components/Step3Servico.tsx` | Completo | Descrição min 10 |
| `portal-familia/src/features/nova-os/components/Step4Confirmacao.tsx` | Completo | Idempotente (ref guard + isPending + aria-busy) |
| `portal-familia/src/features/nova-os/components/ClienteEncontradoCard.tsx` | Completo | |
| `portal-familia/src/features/nova-os/components/VeiculoEncontradoCard.tsx` | Completo | |
| `portal-familia/src/features/nova-os/components/TransferenciaPlacaModal.tsx` | Completo | shadcn Dialog |
| `portal-familia/src/features/nova-os/NovaOSPage.tsx` | Completo | Orquestrador + useBlocker + beforeunload |
| `portal-familia/src/features/nova-os/__tests__/*` | Completo | 7 arquivos de teste |
| `portal-familia/src/router/index.tsx` | Completo | Adicionou `/consultor/os/nova` (antes de `:id`) + `/reset-password` |
| `portal-familia/src/pages/consultor/OSList.tsx` | Completo | Removeu CreateOSDialog inteiro, botão vira Link |
| `portal-familia/src/pages/consultor/PatioKanban.tsx` | Completo | Highlight via `?highlight=` + animate-dap-pulse |
| `portal-familia/tailwind.config.ts` | Completo | Keyframe `dapPulse` + animation `dap-pulse` 1.5s×2 |
| `portal-familia/src/features/consultor/services/clientesService.ts` | Completo | + `getClienteByCpf` |
| `portal-familia/src/features/consultor/services/veiculosService.ts` | Completo | + `getVeiculoByPlaca` |
| `portal-familia/src/features/consultor/services/osService.ts` | Completo | Removeu `registerStatusChange` redundante do `createOS` (trigger DB faz) |
| `portal-familia/src/features/auth/ResetPasswordPage.tsx` | Completo | Parseia hash, hidrata authStore, form Zod |
| `portal-familia/src/features/auth/__tests__/ResetPasswordPage.test.tsx` | Completo | 6 testes |
| `C:\Users\docto\dap-temp-pass.txt` | Temporário | Senha admin do Thales — TROCAR e DELETAR após uso |

## Decisões tomadas

- **`.tsx` em vez de `.test.ts` pros testes que tem JSX inline** — plano original usava `.test.ts` mas TS sem flag JSX quebra. `.tsx` é convenção correta.
- **Real timers no test do PatioKanban highlight** — fake timers travavam com TanStack Query. Trade-off: test fica 3s mais lento, mas determinístico.
- **Reset password via Supabase Auth Admin REST (não SQL direto)** — evita expor plaintext no `execute_sql` do MCP. Headers + body via PowerShell vars que referenciam arquivo local + .env.
- **`/reset-password` sem `PublicOnlyRoute`** — recovery estabelece sessão temporária; bloquear logados quebraria o flow se o user já tivesse sessão antiga.
- **Manter sessão após reset password (não forçar relogin)** — UX. Thales só vai pra `/home` direto.
- **Bug `/reset-password` virou phase nova fora do plano original** — plano de Abrir OS já estava 14/14 verde quando descobri. Não retroativar.

## Bloqueios & perguntas abertas

- **Memory persist do fix de auth** — Thales não confirmou se quer salvar memory referenciando `feedback_supabase_lock_deep_bug.md` + `feedback_supabase_getsession_hang.md`. Aguarda decisão.
- **Push do branch / PR** — `feat/fase0-instrumentacao-700k` tem 17 commits hoje, sem push. Ainda local.
- **Smoke E2E** — Thales precisa rodar manualmente. Eu não toquei browser.
- **Build de produção** — não rodou. Pode ter warning não pego pelo tsc.

## Próximo passo exato

1. Thales pega a senha em `C:\Users\docto\dap-temp-pass.txt` (`Get-Content` no PowerShell), loga em http://localhost:5175 com email `toliveira1802@gmail.com`.
2. Troca a senha no perfil (`/perfil`) e deleta o arquivo `Remove-Item C:\Users\docto\dap-temp-pass.txt`.
3. Testa o wizard em `/consultor/os/nova` rodando os 8 cenários do plano (linhas 4081-4099 de `docs/superpowers/plans/2026-05-04-abrir-os.md`).
4. Se OK, roda `npm run build` em `portal-familia` pra confirmar bundle limpo.
5. Decisão sobre push + PR.

## Setup / comandos úteis

```powershell
# Dev server (já tava rodando no background como ID b5cskz0bg)
cd C:\dev\dap4\portal-familia
npm run dev   # vai pra porta 5175 (5173 e 5174 ocupadas)

# Suite de testes
npm run test --silent   # 145 testes / 30 arquivos

# Build prod (não rodou ainda)
npm run build

# Pegar senha temporária (NÃO COMPARTILHAR)
Get-Content C:\Users\docto\dap-temp-pass.txt

# Limpar senha temporária após login
Remove-Item C:\Users\docto\dap-temp-pass.txt
```

**Branch:** `feat/fase0-instrumentacao-700k`
**Commits hoje:** 17 (último: `f28063b` fix(auth) 15:45)
**Spec:** `C:\dev\dap4\docs\superpowers\specs\2026-05-04-abrir-os-design.md`
**Plano:** `C:\dev\dap4\docs\superpowers\plans\2026-05-04-abrir-os.md` (4137 linhas, 14/14 tasks verdes)
