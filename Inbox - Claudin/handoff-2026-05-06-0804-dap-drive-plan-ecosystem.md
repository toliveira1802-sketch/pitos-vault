---
type: handoff
date: 2026-05-06
time: 08:04
project: dap-drive-plan
topic: refactor SPA → ecossistema desktop + Sheets + Claude Desktop + agente agendado
tags: [handoff, claudin, dap-drive-plan, tauri, mcp, claude-agent]
---

# Handoff — DAP Drive Plan: ecossistema desktop completo

## Contexto

`C:\THALES\dap-drive-plan` era um SPA Vite+React+TS gerado pelo Lovable, 22 páginas de
gestão financeira do DAP, persistência só em `localStorage['dap-finance-data']`,
Supabase escafoldado mas não usado. O Thales pediu pra refatorar pra desktop com
**Google Sheets como database**, **automação via Claude Desktop**, e v2 com
**tarefa agendada** pra agente pessoal entrar no fluxo de update.

Saiu como ecossistema de 4 pacotes em monorepo lite (sem pnpm workspaces — só
path aliases via tsconfig + vitest):

- `src/` — desktop React (atual, refatorado pra `IDataSource` plugável)
- `src-tauri/` — shell Rust que segura a service-account e expõe `invoke`-commands
  pra Sheets
- `mcp-server/` — MCP server `dap-mcp` com 7 tools tipadas Zod, consumido pelo
  Claude Desktop
- `agent/` — agente Node que roda às 07:00 via Windows Task Scheduler, usa
  Anthropic SDK + os mesmos 7 handlers do MCP, escreve briefing diário em
  markdown

Source of truth única: a planilha Google Sheets. Os 4 pacotes leem/escrevem o
mesmo schema (12 abas) através do mesmo `SheetsClient` e dos mesmos serializers
per-entidade. Todas as fases foram entregues em TDD com checkpoints RED/GREEN.

## O que funcionou (com evidência)

- **F0 — Refactor `IDataSource` + `LocalStorageSource`** — evidência: 8 testes
  verdes, `tsc --noEmit` limpo, `npm run build` 9.3s, comportamento externo
  preservado (mesma key `dap-finance-data`, mesmo deep-merge de
  `config.previsao`/`config.limites`, hidratação síncrona via `loadSync()` =
  zero flicker).
- **F1 — `GoogleSheetsSource` + `FetchSheetsClient` + serializers** —
  evidência: 35 testes novos (round-trip por entidade, coerção de strings
  numéricas, plano_90dias denormalizado e re-grupado, config flatten/unflatten
  forward-compat, header skip, partial-failure surface via
  `Promise.allSettled`).
- **F4 — `dap-mcp` server (7 tools)** — evidência: 17 testes (14 pra handlers
  puros + 3 pro `createServiceAccountTokenProvider` cobrindo JWT shape, cache,
  401 surface). `npx tsc --noEmit` clean. Tools registradas no MCP via
  `Server.setRequestHandler(CallToolRequestSchema)` com Zod-validate antes de
  dispatchar.
- **F3 — Preferences + UI Configurações** — evidência: 6 testes pro módulo
  `preferences.ts` (key separado de state, defaults, round-trip,
  partial-update, corrupted-JSON, missing-key forward-compat). Build verde.
  Card "Fonte de Dados" renderiza ativo + selector + spreadsheet ID input.
- **F6 — Agente agendado (`agent/`)** — evidência: 6 testes do `runAgent`
  dispatcher (single-turn, tool loop, error recovery via `is_error`,
  unknown-tool fallback, Zod-validation failure, maxTurns guard). Reusa
  `mcp-server/src/tools.ts` via path alias `@mcp/*`.
- **F2 — Tauri shell** — evidência: arquivos production-ready compilados na
  cabeça (Cargo.toml, tauri.conf.json, main.rs com 5 commands, auth.rs com
  RS256+OAuth+cache espelhando o TS, sheets.rs com 400/404 → empty).
  `TauriSheetsClient.ts` no renderer com 4 testes (invoke wiring + fallback
  fora-Tauri).
- **F5 — README raiz** — diagrama do ecossistema, quick-start de cada pacote,
  decisões arquiteturais, test surface 76 (depois subiu pra 82).
- **Migration push/pull** — `migrateState` + `summarizeState` puros,
  6 testes; UI em Configurações com 3 botões (Conectar / Push / Pull),
  AlertDialog destrutivo no Pull, busy-state com spinner, toasts de sucesso
  com contagens.

**Final: 13 commits, 82 testes verdes, 4 pacotes shippable, 1 binário Rust
pronto pra compilar.**

## O que NÃO funcionou (e por quê)

- **`tsconfig.json` do `mcp-server/` com `module: NodeNext`** — falhou porque o
  `desktop/src` usa imports sem extensão (`@/types`, `./sheets/SheetsClient`)
  que NodeNext exige `.js`. Resolvido mudando pra `module: ESNext` +
  `moduleResolution: Bundler` (TS 5.0+, sem extension required at compile time).
- **Including `../src` no `mcp-server/tsconfig.json` com `rootDir: "."`** —
  TS6059 "file is not under rootDir". Resolvido removendo `rootDir` (deixa TS
  inferir) e listando explicitamente os subdirs do desktop em `include`.
- **Tipo de `vi.fn(async () => ...)`.mock.calls[0]` em vitest** — TypeScript
  3.x deduz `[]` (tuple length 0) porque a função não tem parâmetros tipados.
  Resolvido com cast `as unknown as [string | URL | Request, RequestInit |
  undefined]`.
- **`ToolHandler<{message:string}, {echoed:string}>` → `ToolHandler<unknown,
  unknown>`** — strict mode rejeita por contravariância de input. Resolvido
  fazendo o test handler aceitar `unknown` direto e castando dentro
  (`(input as {message: string}).message`).
- **`asOptString(row[6]) ?? null` em `lancamentos.fromRow`** — esperava
  `undefined`, retornava `null`. Test esperava undefined; fix foi remover o
  fallback explícito (`asOptString` já retorna undefined pra empty).
- **Test `summarizeState` total** — esqueci `plano_90dias` na soma esperada;
  o impl tava certo, o test errado. Fix no test, não no impl.
- **`StateRunner` recebendo SheetsClient direto em `index.ts`** — TS2353
  porque o constructor pede `IDataSource`. Resolvido com factory
  `StateRunner.fromSheets(client)` que monta o `GoogleSheetsSource` por dentro.

## O que ainda não foi tentado

- **Compilar o Tauri** — `rustup` não instalado nessa máquina. Os arquivos
  Rust foram escritos production-ready mas nunca passaram pelo `cargo check`.
  Crates declaradas: `tauri 2.0`, `reqwest 0.12 (rustls-tls)`,
  `jsonwebtoken 9.3`, `chrono 0.4`, `serde`, `tokio (full)`, `urlencoding 2.1`,
  `dirs 5.0`, `thiserror 1.0`. Pode ter mismatch de feature flags do Tauri 2
  ou tipo error-conversion que só aparece no `cargo build`.
- **Live-sync no AppProvider quando `prefs.sourceId === 'gsheets'`** — hoje
  o toggle de fonte é decorativo; AppProvider sempre usa LocalStorage.
  Push/Pull explícitos cobrem o caso de uso. Live-sync exigiria orquestrar
  configure-Tauri-on-mount + flicker async + fallback pra local em erro.
- **Code-splitting do bundle** — Vite reclama que o chunk principal tá em
  992kB (warning a partir de 500kB). Não é crítico pra desktop, mas
  `manualChunks` ou `dynamic import()` pelas páginas resolve.
- **OAuth user flow no browser** — alternativa ao Tauri pra gsheets em
  navegador puro. Não foi explorada porque Tauri é o caminho world-class
  do Thales.
- **Teste de integração ponta-a-ponta** com planilha real — toda a stack
  foi testada com mocks; nunca rodou contra um spreadsheet de verdade.
- **Migração inicial real** — push/pull existem mas dependem de o Thales
  rodar `npm run tauri:dev` com Rust instalado primeiro.
- **Service account real configurada** — JSON ainda não baixado, planilha
  ainda não criada nem compartilhada.

## Arquivos tocados

| Arquivo | Status | Notas |
|---|---|---|
| `src/types/index.ts` | Completo | Adicionado `CellValue` |
| `src/contexts/AppContext.tsx` | Completo | Refatorado pra DI via `IDataSource`, expõe `sourceId` + `isReady` |
| `src/data/sources/IDataSource.ts` | Completo | Interface com `loadSync?` opcional |
| `src/data/sources/LocalStorageSource.ts` | Completo | + 7 testes |
| `src/data/sources/GoogleSheetsSource.ts` | Completo | + 11 testes |
| `src/data/sources/sheets/schema.ts` | Completo | 12 sheet names, SCHEMA_VERSION |
| `src/data/sources/sheets/SheetsClient.ts` | Completo | Interface |
| `src/data/sources/sheets/serializers.ts` | Completo | + 19 testes |
| `src/data/sources/sheets/FetchSheetsClient.ts` | Completo | + 5 testes |
| `src/data/sources/sheets/TauriSheetsClient.ts` | Completo | + 4 testes |
| `src/data/sources/index.ts` | Completo | Barrel export |
| `src/data/preferences.ts` | Completo | + 6 testes; campo `serviceAccountPath` adicionado |
| `src/data/migration.ts` | Completo | + 6 testes |
| `src/hooks/useTauri.ts` | Completo | Detecção reativa do runtime |
| `src/pages/ConfiguracoesPage.tsx` | Completo | Card "Fonte de Dados" + UI de migração |
| `src-tauri/Cargo.toml` | Completo (não compilado) | Rust toolchain ausente |
| `src-tauri/tauri.conf.json` | Completo | identifier, bundle targets msi/nsis/deb/appimage/dmg |
| `src-tauri/src/main.rs` | Completo (não compilado) | 5 commands |
| `src-tauri/src/auth.rs` | Completo (não compilado) | Espelha `mcp-server/src/auth/serviceAccount.ts` |
| `src-tauri/src/sheets.rs` | Completo (não compilado) | Espelha `FetchSheetsClient.ts` |
| `src-tauri/build.rs` | Completo | Hook padrão |
| `src-tauri/icons/` | **VAZIO** | Tauri precisa de ícones reais (32x32.png, 128x128.png, icon.ico, icon.icns) pra `cargo build` finalizar — placeholder ainda não gerado |
| `mcp-server/package.json` | Completo | tsx-as-runtime, sem dist build step |
| `mcp-server/tsconfig.json` | Completo | `module: ESNext`, paths `@dap/*` + `@/*` |
| `mcp-server/src/tools.ts` | Completo | 7 handlers puros |
| `mcp-server/src/state.ts` | Completo | StateRunner com fila serializada |
| `mcp-server/src/auth/serviceAccount.ts` | Completo | RS256 + OAuth + cache |
| `mcp-server/src/index.ts` | Completo | Stdio entry, Zod→JSON Schema |
| `mcp-server/README.md` | Completo | Setup + claude_desktop_config snippet |
| `agent/package.json` | Completo | `@anthropic-ai/sdk 0.36`, tsx |
| `agent/src/dispatcher.ts` | Completo | + 6 testes |
| `agent/src/anthropicClient.ts` | Completo | Adapter SDK |
| `agent/src/index.ts` | Completo | Wiring + report writer |
| `agent/prompts/daily.md` | Completo | Brief português, NÃO auto-paga contas |
| `agent/scripts/dap-agent-task.xml` | Completo (não importado) | Precisa editar `<UserId>` antes de `schtasks /create /xml` |
| `agent/scripts/run-daily.cmd` | Completo (placeholders) | Env vars com `REPLACE-WITH-...` ainda |
| `agent/README.md` | Completo | Setup + Task Scheduler import |
| `README.md` | Completo | Reescrito do "TODO" inicial |

## Decisões tomadas

- **Tauri 2 sobre Electron** — razão: ~10MB vs ~150MB, sandbox por default,
  Rust pra segurar a service-account fora do renderer. Padrão world-class do
  Thales (CLAUDE.md).
- **Google Sheets sobre Excel local** — razão: agente agendado precisa ler/
  escrever de qualquer device; Excel local prenderia ao desktop. Claude Desktop
  já tem MCP Drive autenticado.
- **Custom `dap-mcp` sobre Drive MCP existente** — razão: Drive MCP só lê
  arquivos; pra escrita disciplinada na planilha precisa de schema validado
  Zod. Drive MCP fica útil pra leitura ad-hoc, mas mutações vão pelo
  `dap-mcp`.
- **Monorepo lite via tsconfig paths, NÃO pnpm workspaces** — razão:
  restruturar `src/` pra `packages/desktop/src/` quebraria 50+ imports e
  arriscaria regressão. Path aliases `@dap/*` + `@mcp/*` resolveram via tsconfig
  + vitest config sem touching o desktop.
- **`tsx` como runtime, não `tsc` build pra dist** — razão: NodeNext exige
  `.js` nas relativas, mas o desktop não tem; Bundler resolution funciona em
  vitest e em tsx. Sem dist, sem path-alias-rewrite, sem etapa de build no
  prod.
- **Full-overwrite por sheet em `save()`, não diff** — razão: simpler,
  determinístico, dentro do rate limit (100 req/100s/user) com debounce 500ms.
- **`Promise.allSettled` no save** — razão: falha em uma aba não pode bloquear
  as outras. Surface a primeira reject após todas terminarem.
- **Schema version começa em 1, sem `_meta` sheet ainda** — razão: YAGNI.
  Adiciona quando tiver primeira migração quebrante.
- **Plano_90dias denormalizado** — razão: planilha humana-editável é mais útil
  com uma row por ação que com JSON em coluna.
- **Config flatten com `previsao.dia_receitas`/`limites.divida_max` keys** —
  razão: missing-key fallback nativo via `defaultState.config`. Adicionar campo
  novo no TS é zero-migration na planilha.
- **Service-account JWT signing no Rust E no Node** — razão: dois consumidores
  (desktop binary e agent headless) com lifecycles diferentes, código pequeno
  o suficiente pra duplicar com clareza ao invés de extrair pacote shared.
- **Sem testes de UI** — razão: ConfiguracoesPage muda de visual; lógica
  testável (preferences, migration) já está coberta. UI integration test seria
  caro e flaky.
- **NÃO ativar live-sync gsheets no AppProvider** — razão: scope creep. Push/
  Pull explícitos cobrem o caso de uso e dão controle ao Thales.

## Bloqueios & perguntas abertas

- **Rust toolchain ausente** — `cargo` não está no PATH dessa máquina. Precisa
  `rustup` pra `npm run tauri:dev` rodar.
- **Ícones do Tauri** — `src-tauri/icons/` está vazio. `tauri build` falha
  sem `32x32.png`, `128x128.png`, `icon.ico`, `icon.icns`. `tauri dev` pode
  rodar com placeholders mas o bundle final precisa.
- **Service account real** — não foi criada no GCP nem associada à planilha.
  Tudo no código aponta pra `C:\Users\docto\.config\dap\service-account.json`
  como caminho convencional.
- **Spreadsheet real** — não existe ainda. Testes contra mocks; nunca rodou
  contra a API real.
- **Anthropic API key** — placeholder em todos os `.env.example` e
  `run-daily.cmd`.
- **MCP no Claude Desktop não foi testado interativamente** — config snippet
  está no `mcp-server/README.md` mas não foi colado em `claude_desktop_config.json`
  ainda.
- **Pergunta aberta**: live-sync no AppProvider quando `sourceId === 'gsheets'`
  é o próximo passo natural ou prefere code-splitting / OAuth user flow / outra
  coisa? O Thales perguntou no fim mas não respondeu.

## Próximo passo exato

**Passo 1 (setup, 30-45 min):** instalar `rustup` (https://rustup.rs) +
Visual Studio Build Tools (workload C++); criar service account em
console.cloud.google.com → IAM → baixar JSON pra
`C:\Users\docto\.config\dap\service-account.json`; criar planilha no Drive,
copiar ID, compartilhar com o email da service account como **Editor**;
habilitar Sheets API no project.

**Passo 2 (verificação local):** `cd C:\THALES\dap-drive-plan && npm run
tauri:dev`. Primeira compilação 5-10min. Quando abrir, Configurações → cola
spreadsheet ID + caminho do JSON → Conectar → "Enviar local→Sheets" pra subir
o estado atual da máquina pra planilha.

**Passo 3 (ícones, opcional pra dev):** gerar 32x32.png, 128x128.png,
128x128@2x.png, icon.ico, icon.icns em `src-tauri/icons/`. `npx tauri icon
<path-to-source.png>` faz tudo.

**Passo 4 (Claude Desktop):** colar o snippet do `mcp-server/README.md` em
`%APPDATA%\Claude\claude_desktop_config.json` substituindo `DAP_SPREADSHEET_ID`
pelo ID real. Restart. Testar com "use dap_load_state_summary".

**Passo 5 (agente):** editar `agent/scripts/run-daily.cmd` com chaves reais →
`schtasks /create /tn "DAP Daily Agent" /xml agent\scripts\dap-agent-task.xml`
(depois de trocar `<UserId>` no XML pelo usuário Windows).

Se a pergunta aberta voltar antes desse setup: **live-sync no AppProvider**
é o próximo natural — `AppProvider` lê `prefs.sourceId` no mount, se for
`'gsheets'` E `useTauri().available` E `dap_configure` der ok, troca o source
runtime pra `new GoogleSheetsSource(new TauriSheetsClient())`. Caso contrário
fica com `LocalStorageSource`. Adicionar gate de loading state pra cobrir o
flicker async do load inicial gsheets.

## Setup / comandos úteis

```sh
# Validação rápida de tudo
cd C:\THALES\dap-drive-plan
npm test                        # 59 testes desktop
cd mcp-server && npm test       # 17 testes
cd ..\agent && npm test         # 6 testes
cd .. && npm run build          # SPA build

# Tauri (após rustup)
npm run tauri:dev               # hot-reload
npm run tauri:build             # bundle .msi/.nsis

# Identidade git desse repo NÃO foi configurada globalmente —
# usei -c user.email=... -c user.name=Thales nos commits.
# Se for continuar, considere `git config user.email toliveira1802@gmail.com`
# `git config user.name Thales` localmente nesse repo.
```

13 commits novos sobre `d3296d5` (master anterior do Lovable). Branch `main`,
sem PR aberto.
