---
projeto: AutoDiag Copilot
tipo: doc-arquitetura
status: implementado (working tree, sem commit)
data: 2026-06-05
repo: C:/dev/autodiag-copilot
tags: [autodiag, arquitetura, agente, obd, vcds, bluetooth]
---

# AutoDiag — Motor de Diagnóstico: Agente, OBD/BLE, VCDS, Sonda eaata

Doc de arquitetura do que foi construído na sessão de 2026-06-05. Volta de [[000-index|Index]]. Continuidade operacional em [[../Inbox - Claudin/handoff-2026-06-05-1806-autodiag-agent-obd-vcds|handoff da sessão]].

## Visão geral

Quatro frentes encadeadas que fecham um ciclo só: o RAG single-shot virou **agente de verdade**, o agente ganhou **fontes de dado reais** (scanner ao vivo e import de ferramenta profissional), e a integração com o scanner físico do Thales (eaata) passou a ser **medida empiricamente** em vez de chutada.

O fio condutor de engenharia: **núcleo determinístico puro e testável** separado da **borda de I/O fina** (LLM, Web Bluetooth, Web Serial). Onde moram os bugs (decode, parse, framing) é 100% testado; o que depende de hardware/rede é shell mínimo.

Estado: tudo no **working tree, sem commit**. Suite **137/137**, `tsc` limpo, ESLint limpo.

## 1. Harness de agente de diagnóstico

`/api/rag/query` deixou de pré-injetar todo o conhecimento num prompt e disparar uma chamada. Agora é um agente **ReAct + typed tools** (Vercel AI SDK v4, `streamText` + `maxSteps:5`) que decide o que buscar.

**Action space (3 ferramentas tipadas)** — `lib/rag/agent/tools.ts`:
- `lookup_dtc_codes` — significado exato dos códigos no dicionário curado.
- `search_diagnostic_knowledge` — busca semântica (pgvector) para sintomas sem código.
- `get_freeze_frame_data` — sensores congelados no instante da falha (RPM, carga, temp, fuel trim).

**Contrato de observação** — toda tool retorna `{ status, summary, data, next_actions }`. Nunca lançam pro modelo: falha vira `status:"error"` com instrução de retry segura **e** condição de parada (anti-loop).

**Budget de contexto** — o conhecimento de DTC deixou de ser pré-stuffado; chega via observação que o agente puxa sob demanda. System prompt = só o invariante (persona + protocolo + formato do roadmap). Hardening anti-injeção preservado em `lib/rag/prompt.ts`.

> Ciclo do mecânico coberto: **o que o código significa** (lookup) · **o que mais pode ser** (semântico) · **em que condição falhou** (freeze-frame).

## 2. Transporte OBD-II BLE (ELM327) — `lib/obd/`

- `decode.ts` — **núcleo puro**: decode de DTC mode 03 (SAE J2012) e 10 PIDs. Testado com vetores canônicos.
- `transport.ts` — interface `ObdTransport` + erros tipados (timeout/command).
- `elm327.ts` — cliente: framing por prompt `>`, handshake AT, `scan()` (protocolo + DTCs + snapshot ao vivo). Transport injetável → testável com fake.
- `web-bluetooth.ts` — borda BLE; descobre características por **propriedade** (write/notify), não por UUID fixo → robusto a variação de fabricante.

## 3. Import VCDS / ODIS — `lib/vcds/` (alvo de integração escolhido)

Para oficina premium VAG, o autoscan do VCDS é dado **ordens de magnitude** mais rico que ELM327 genérico, e o agente já tem persona VCDS/ODIS. Casa com a tese "SOP interno → produto externo".

- `parse.ts` — parser puro e tolerante do autoscan: VIN, km, módulos, faltas (código VAG 4-6 dígitos, P-code hex tipo P17BF), **freeze-frame por falha**. Nunca lança — scan parcial > falha de parse.
- `normalize.ts` — só faltas com P-code viram DTC; faltas VAG-only vão pro resumo (nada se perde).
- UI: rota `app/(app)/scan/import/` — cola/upload do `.txt` → preview ao vivo (❄ marca códigos com freeze-frame) → grava.

## 4. Sonda BLE pro eaata — `lib/obd/ble-inspect.ts` + `app/(app)/scan/ble-probe/`

Instrumento empírico para resolver a incógnita do scanner físico (ver decisão abaixo). Rodada **no Chrome do próprio eaata**, enumera o GATT, detecta canal serial e diz: **alcançável** (com UUIDs service/notify/write) ou **não alcançável** (provável SPP clássico). `summarizeGatt` é puro/testado; `probeBluetooth` é a glue.

## Persistência compartilhada — `lib/diagnostics/`

`persist-scan.ts` (Dexie + fila de sync, **freeze-frame por DTC**) usada por simulador, ELM327 e VCDS. `types.ts` define `NormalizedScan` neutro (sem Dexie/React). Refatorou ~90 linhas inline da página de scan.

## Topologia real do eaata (esclarecida pelo Thales)

```
Tablet Android (eaata, Chrome, WiFi)  ──Bluetooth──  VCI (plugada no carro)
```

O eaata **não é um dongle ELM327**: é um tablet Android com uma VCI separada; a ligação tablet↔VCI é Bluetooth. O "abre o Chrome" é o tablet abrindo Chrome. A oficina também tem **ODIS e VCDS** (Ross-Tech) oficiais.

**Incógnita aberta:** o VCI é BLE-GATT (alcançável pelo Web Bluetooth do Chrome) ou Bluetooth clássico SPP (inacessível a qualquer navegador)? → a Sonda BLE responde isso no hardware.

## Decisões-chave desta sessão

- **Alvo de integração = Import VCDS/ODIS** (Thales escolheu). `lib/obd` segue válido para um ELM327 BLE dedicado — decisão de produto em aberto.
- **Núcleo puro vs borda de I/O** em todas as frentes (agente, obd, vcds).
- **Regex DTC ampliado p/ hex** (`^[A-Z][0-9A-F]{4}$`) — aceita códigos VAG do VCDS; corrigiu bug latente dos presets DSG (P17BF/P189C tomavam 400).
- **Sonda como instrumento** — não escrever mais código de transporte do eaata até ter o relatório da sonda no hardware.
- **Osciloscópio Web Serial → V5** (adiado).

## Atualização de escopo

O [[000-index|Index]] listava "Web Bluetooth direto" como *fora de escopo v1*. Isso evoluiu: a infra BLE (`lib/obd`) existe e está testada; o que falta é o teste de hardware do eaata. O caminho primário de "scan real" passou a ser o **import VCDS/ODIS**, com BLE como opção paralela.

## Próximo passo

Thales roda a **Sonda BLE no eaata** (HTTPS via `cloudflared tunnel --url http://localhost:3000`, abrir no Chrome do tablet, desconectar o app nativo da VCI antes) e cola o relatório. Com ele: fixar UUIDs em `web-bluetooth.ts` ou confirmar SPP e seguir 100% no VCDS. Pendência menor: passar as descrições ricas do VCDS pro prompt do agente.

## Mapa de arquivos (working tree)

| Camada | Arquivos |
|---|---|
| Agente | `lib/rag/agent/{observation,tools,system-prompt,run}.ts`, `lib/rag/prompt.ts`, `app/api/rag/query/route.ts` |
| OBD/BLE | `lib/obd/{decode,transport,elm327,web-bluetooth,ble-inspect,index}.ts` |
| VCDS | `lib/vcds/{parse,normalize,types,index}.ts` |
| Persistência | `lib/diagnostics/{types,persist-scan}.ts` |
| UI | `app/(app)/scan/{page,import/page,ble-probe/page}.tsx`, `app/(app)/diagnostics/[id]/page.tsx` |
| Testes | `tests/unit/{rag,obd,vcds}/*` (+51 nesta sessão) |
