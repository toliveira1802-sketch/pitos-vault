---
type: handoff
date: 2026-06-05
time: 18:06
project: AutoDiag Copilot (C:\dev\autodiag-copilot)
topic: Harness de agente de diagnóstico + transporte OBD BLE + import VCDS/ODIS + sonda BLE pro eaata
tags: [handoff, claudin]
---

# Handoff — AutoDiag: agent harness, OBD/BLE, VCDS import, sonda eaata

## Contexto

AutoDiag Copilot é o SaaS offline-first de diagnóstico OBD-II pra entusiastas de alemães premium (foco VAG). Lê DTCs, interpreta via `dtc_dictionary` global, enriquece com RAG (pgvector) sobre SOPs Bosch/OEM/DAP, e o agente "Mestre Mecânico Digital" (Claude Sonnet 4.6) monta um Roadmap de Oficina em 5 fases.

Esta sessão começou pelo skill `/agent-harness-construction` e evoluiu por 4 frentes encadeadas, todas fechando num ciclo único: **converter o RAG single-shot num harness de agente de verdade** → **dar ao agente fontes de dado reais** (scanner ao vivo e import de ferramenta pro) → **medir empiricamente como integrar o scanner físico do Thales (eaata)**.

Tudo está no **working tree, sem commit** (Thales só commita quando pede). Stack: Next 15.1.6 (App Router) + React 19, Vercel AI SDK v4 (`ai@^4.0.10`, `@ai-sdk/anthropic@^1`), Dexie/IndexedDB, Supabase/Postgres schema `ferramentas`, pnpm-only.

## O que funcionou (com evidência)

- **Harness de agente (ReAct + typed tools)** — `/api/rag/query` deixou de ser RAG single-shot e virou agente com 3 ferramentas tipadas, `streamText` + `maxSteps:5`. Evidência: `tsc` exit 0, suite passou.
- **Action space com 3 tools** — `lookup_dtc_codes` (exato), `search_diagnostic_knowledge` (semântico), `get_freeze_frame_data` (sensores no instante da falha). Cada tool retorna envelope determinístico `{status, summary, data, next_actions}`; nunca lançam pro modelo (contrato de recovery com retry + stop condition). Evidência: testes de recovery em `tests/unit/rag/tools.test.ts`.
- **Transporte OBD-II BLE (ELM327)** — `lib/obd/`: núcleo puro testado (decode DTC mode 03 SAE J2012, 10 PIDs) + cliente ELM327 sobre transport injetável + `WebBluetoothTransport`. Evidência: 22 testes (`decode.test.ts` com vetores canônicos `0x01 0x43→P0143`, `elm327.test.ts` com FakeTransport).
- **Import VCDS/ODIS** — `lib/vcds/`: parser puro tolerante do autoscan (VIN, km, módulos, faltas, freeze-frame POR falha; códigos VAG 4-6 dígitos; P-codes hex tipo P17BF) + normalize. Rota `app/(app)/scan/import/page.tsx` (cola/upload .txt → preview ao vivo → grava). Evidência: 11 testes (parse + normalize).
- **Persistência compartilhada** — `lib/diagnostics/persist-scan.ts` (Dexie+sync, freeze-frame por DTC) usada por simulador, ELM327 e VCDS. Refatorou ~90 linhas inline da página de scan.
- **Sonda BLE pro eaata** — `lib/obd/ble-inspect.ts` (`summarizeGatt` puro + `probeBluetooth` glue) + rota `app/(app)/scan/ble-probe/page.tsx`. Enumera GATT, detecta canal serial, diz reachable SIM/NÃO + UUIDs. Evidência: 5 testes.
- **Suite total: 137/137 passando, `tsc --noEmit` exit 0, ESLint limpo** nos arquivos tocados (rodado via `node_modules/.bin/tsc.CMD` e `vitest.CMD` — ver setup abaixo).

## O que NÃO funcionou (e por quê)

- **`pnpm` no PATH desta máquina (ambiente do Claude)** — `pnpm` não está no PATH e `corepack enable` falhou com `EPERM: operation not permitted, open 'C:\Program Files\nodejs\pnpm'` (precisa admin). **Workaround usado:** rodei tudo via `node_modules/.bin/tsc.CMD` e `node_modules/.bin/vitest.CMD` direto. Pro Thales, `pnpm` normal deve funcionar (ou bootstrap admin).
- **ESLint direto no path da página** — `eslint.CMD "app/(app)/scan/page.tsx"` retorna exit 255 porque o shell mastiga os parênteses de `(app)` e colchetes de `[id]`. **Workaround:** `node node_modules/eslint/bin/eslint.js --no-eslintrc -c .eslintrc.json --parser-options ecmaFeatures:jsx --ext .tsx "<path>"`.
- **Identificar o scanner "eaata360" por busca web** — nome provavelmente fonético/garbled, não achou nada. **Resolveu por raciocínio:** depois o Thales esclareceu a topologia real (ver Decisões).
- **Bug pego nos testes (corrigido):** regex VAG do parser exigia 5-6 dígitos (`\d{5,6}`) e rejeitava o código `8326` (4 dígitos). Corrigido pra `\d{4,6}`.

## O que ainda não foi tentado

- **Rodar a sonda BLE no hardware real (eaata)** — é o próximo passo bloqueante. Sem isso não sabemos se a VCI é BLE-GATT (alcançável) ou SPP clássico (não alcançável por navegador).
- **Agente usar as descrições ricas do VCDS** — hoje o agente recebe só os P-codes + freeze-frame; o texto OEM da falha do VCDS (mais rico que o dicionário genérico) ainda NÃO é passado pro prompt. Foi oferecido, ficou pendente.
- **Script `pnpm dev:tunnel`** — oferecido pra subir `next dev` + `cloudflared` de uma vez; não criado ainda.
- **Osciloscópio Web Serial** — adiado pra V5 por decisão do Thales (não construir agora).

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `lib/rag/agent/observation.ts` | Completo | Envelope `{status,summary,data,next_actions}` + ok/warn/fail |
| `lib/rag/agent/tools.ts` | Completo | 3 tools tipadas, deps injetáveis, recovery contract |
| `lib/rag/agent/system-prompt.ts` | Completo | Prompt invariante + initial message anti-injeção |
| `lib/rag/agent/run.ts` | Completo | `runDiagnosticAgent` (streamText + maxSteps:5) |
| `lib/rag/prompt.ts` | Completo | Repurposado: fronteira de sanitização compartilhada |
| `app/api/rag/query/route.ts` | Completo | Dirige o harness; auth+rate-limit+zod mantidos |
| `lib/obd/decode.ts` | Completo | Decode DTC mode03 + PIDs (puro, testado) |
| `lib/obd/transport.ts` | Completo | Interface ObdTransport + erros tipados |
| `lib/obd/elm327.ts` | Completo | Cliente framing por prompt '>', handshake AT, scan() |
| `lib/obd/web-bluetooth.ts` | Completo | Transport BLE; descoberta de char por propriedade (robusto a UUID) |
| `lib/obd/ble-inspect.ts` | Completo | Sonda: summarizeGatt (puro) + probeBluetooth (glue) |
| `lib/obd/index.ts` | Completo | Barrel |
| `lib/vcds/parse.ts` | Completo | Parser autoscan VCDS/ODIS (puro, tolerante) |
| `lib/vcds/normalize.ts` | Completo | VcdsScan → NormalizedScan |
| `lib/vcds/types.ts` `index.ts` | Completo | — |
| `lib/diagnostics/types.ts` | Completo | NormalizedScan neutro (sem Dexie/React) |
| `lib/diagnostics/persist-scan.ts` | Completo | Persistência compartilhada, freeze-frame por DTC |
| `lib/api/validation.ts` | Completo | regex DTC ampliado p/ hex `^[A-Z][0-9A-F]{4}$`; +freezeFrames |
| `app/(app)/scan/page.tsx` | Completo | Botão Bluetooth real + link sonda + link import; usa persist compartilhado |
| `app/(app)/scan/import/page.tsx` | Completo | Import VCDS/ODIS (paste/upload→preview→grava) |
| `app/(app)/scan/ble-probe/page.tsx` | Completo | Sonda BLE (rodar no eaata) |
| `app/(app)/diagnostics/[id]/page.tsx` | Completo | Envia freezeFrames por DTC pro /api/rag/query |
| `vitest.config.ts` | Completo | alias `server-only`→stub |
| `tests/setup.ts` | Completo | env público dummy pra importar módulos server em unit |
| `tests/stubs/server-only.ts` | Completo | stub |
| `tests/unit/{rag,obd,vcds}/*` | Completo | +51 testes nesta sessão (total 137) |

## Decisões tomadas

- **Topologia real do eaata (esclarecida pelo Thales)** — eaata NÃO é dongle ELM327: é **tablet Android** + **VCI separada**, ligação **tablet↔VCI por Bluetooth**. O "abre Chrome" é o tablet abrindo Chrome. Razão de importar: Web Bluetooth só fala BLE-GATT; se a VCI for SPP clássico, navegador não alcança.
- **Alvo de integração = Import VCDS/ODIS** (Thales escolheu) — dado VAG muito mais rico que ELM327 genérico, casa com a persona VCDS/ODIS do agente e com "SOP interno → produto externo". `lib/obd` segue válido pra um ELM327 BLE dedicado, decisão de produto em aberto.
- **Núcleo puro vs borda de I/O** — em obd e vcds, toda lógica de decode/parse é função pura testável; Web Bluetooth/Web Serial ficam shells finos não-testáveis sem hardware. Mesma filosofia do harness (lógica de agente vs I/O do LLM).
- **Regex DTC hex** — ampliado pra aceitar P17BF/P189C (códigos VAG do VCDS); de quebra corrigiu bug latente dos presets DSG que tomavam 400 no endpoint.
- **Sonda como instrumento** — em vez de chutar BLE-GATT vs SPP, construí a página de sonda pra medir no hardware. Decisão de não escrever mais código de transporte do eaata até ter o relatório.

## Bloqueios & perguntas abertas

- **BLOQUEIO PRINCIPAL:** precisa do relatório da sonda BLE rodada no eaata pra saber se a VCI é alcançável. Sem isso, o caminho de live-scan do eaata fica indefinido.
- Pegadinha do teste: Web Bluetooth exige contexto seguro (HTTPS ou localhost). `http://IP-da-rede:3000` é bloqueado pelo Chrome. Por isso o túnel HTTPS.
- A VCI pode não aparecer pro Chrome se estiver pareada/conectada ao app nativo do eaata na hora (BLE não compartilha conexão) — desconectar o app do fabricante antes de sondar.

## Próximo passo exato

**Thales roda a sonda no eaata e cola o relatório.** Procedimento: subir o app local + expor por HTTPS via `cloudflared tunnel --url http://localhost:3000` (cloudflared já instalado em `C:\Users\docto\bin\cloudflared`), abrir a URL `https://*.trycloudflare.com` no **Chrome do eaata**, ir em **Scan → "Diagnosticar conexão BLE (sonda)"**, desconectar o app nativo da VCI, **"Sondar dispositivo BLE"** → selecionar a VCI → **"Copiar relatório"** → colar na próxima sessão. Com o relatório: se houver `serialCandidate` (service/notify/write), fixar os UUIDs em `lib/obd/web-bluetooth.ts` `KNOWN_SERVICES` e o live-scan do eaata funciona; se "não alcançável", confirmar SPP clássico e seguir 100% no VCDS import.

## Setup / comandos úteis

```powershell
# Bootstrap pnpm (1ª vez; admin se EPERM)
corepack enable; corepack prepare pnpm@latest --activate

cd C:\dev\autodiag-copilot
pnpm install

# Subir + expor HTTPS pro eaata (2 terminais)
pnpm dev
cloudflared tunnel --url http://localhost:3000   # abre a URL trycloudflare no eaata

# Alternativa HTTPS local (cert self-signed, aceitar aviso no Chrome)
pnpm exec next dev --experimental-https -H 0.0.0.0   # https://<IP>:3000

# Gate (nesta máquina pnpm fora do PATH — usar bins locais):
node_modules/.bin/tsc.CMD --noEmit
node_modules/.bin/vitest.CMD run tests/unit
# ESLint em página com (app)/[id] no path:
$env:ESLINT_USE_FLAT_CONFIG='false'; node node_modules/eslint/bin/eslint.js --no-eslintrc -c .eslintrc.json --parser-options ecmaFeatures:jsx --ext .tsx "<path>"
```

Memórias do projeto atualizadas em `~/.claude/projects/C--dev-autodiag-copilot/memory/`: `obd-scanner-target.md` (topologia eaata + sonda + VCDS implementado), `roadmap-v5-oscilloscope.md`.
