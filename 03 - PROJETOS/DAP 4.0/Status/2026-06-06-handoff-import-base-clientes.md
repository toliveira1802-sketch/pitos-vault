---
type: handoff
date: 2026-06-06
time: "07:10"
project: dap-aios (banco hlhf)
topic: Import da base legada cliente→veículo→OS fechada (planejado + decisões travadas; build ainda NÃO iniciado)
tags: [handoff, claudin, dap-aios, import, hlhf, clientes, veiculos, service-orders, legado]
status: in-progress
---

# Handoff — Import da base de clientes legada (planejado, pré-build)

> Continuação direta de `2026-06-06-handoff-finance-drizzle-adoption.md` (Fase 1, PR #55
> mergeado). Esta é a **Fase 2**: trazer a base legada de clientes/veículos/OS pro `hlhf`.
> **Importante:** esta rodada chegou até **plano + decisões travadas**. Nenhuma linha de
> código de import foi escrita ainda. O próximo passo é construir o dry-run.

## Contexto

Thales achou a base de clientes/operação até 31/05 e quer popular o AIOS (banco `hlhf`)
com **cliente → veículo → OS entregue** a partir do histórico legado de orçamentos
autorizados. São **dois arquivos** que se complementam:

- `C:\Users\docto\Downloads\relatorio_orçamento (2).csv` — header plano dos orçamentos
  (~636 linhas AU): nº orçamento, cliente (nome), placa, veículo (só modelo, sem marca),
  **Empresa (Bosch/Prime)**, **Faturado (Sim/Não)**, total, valor particular/seguradora,
  datas. **Não tem telefone nem marca separada.**
- `C:\Users\docto\Downloads\fdsaws.pdf` — relatório "Serviços/Peças por Veículo",
  mesmo recorte (01/01–31/05/2026, Autorizados), **228 páginas**, agrupado por placa.
  Rodapé: **628 orçamentos · R$ 1.422.507,11** (Peças 842.508,45 + Serviços 579.998,66).
  Traz o que faltava: **telefone do cliente**, **marca+modelo separados** (header
  "Veículo: AVW7I75 VOLKSWAGEN GOLF TURBO GTI"), itens discriminados por OS, nº OS/Compl,
  datas entrada/autorização.

O PDF é a fonte mais rica (telefone resolve dedup; marca resolve `vehicles.brand` NOT NULL).
O CSV entra como join por nº de orçamento pra trazer Empresa + Faturado.

## O que funcionou (com evidência)

- **Leitura/diagnóstico das duas fontes** — PDF lido inteiro (228 págs) via Read; rodapé
  confirma 628 orçamentos / R$ 1.422.507,11. CSV analisado em rodadas anteriores (636 AU,
  formato decimal vírgula, sem telefone/CPF).
- **Schemas alvo confirmados** (lidos de `packages/types/src/schema/consultor.ts`):
  - `customers`: `name` NOT NULL; `phone`, `email`, `document`, `tier`(default 'bronze'),
    `archived_at` etc. opcionais. **Sem coluna de brand/canal.** Índices em name/phone/document.
  - `vehicles`: `customer_id` NOT NULL + FK ON DELETE RESTRICT; **`brand` NOT NULL**,
    **`model` NOT NULL**; `plate`, `version`, `year`, `fuel_type`, `vin`, `color`, `mileage` opcionais.
  - `service_orders` (lido em rodada anterior): `code` unique NOT NULL, `customer_id`,
    `vehicle_id`, `status`, `commercial_status`, `priority`, `source`, `opened_at`,
    `delivered_at`, `patio_box`, `advance_payment_cents`, `is_revision`. **Sem coluna brand.**
  - `service_order_items` (`service-order-items.ts`): **AINDA NÃO foi lido em detalhe** —
    confirmar colunas obrigatórias (kind/description/qty/unitCents/totalCents?) antes de gerar.

## O que NÃO funcionou (e por quê)

- **Plano inicial só-CSV** — descartado porque o CSV não tem telefone (dedup fraco) nem
  marca (quebra `vehicles.brand` NOT NULL). O PDF (chegou depois) resolve ambos; por isso
  a fonte virou PDF+CSV, não CSV sozinho.
- Nenhuma falha de execução de import — porque o build ainda não começou.

## O que ainda não foi tentado

- **Extrair o PDF → texto estruturado** e parsear por OS. Caminho previsto: `pdftotext -layout`
  (checar se existe no host) ou parser via node; validar com **checksum** (somatório dos totais
  parseados tem que bater 628 OS / R$ 1.422.507,11 — se não bater, parse reprova, não importa).
  ⚠️ risco real: nomes de cliente quebram em 2 linhas no PDF (ex: "EMPRESA DE ONIBUS PASSARO\nMARRON S/A.").
- Com a decisão de **item sintético** (ver abaixo), talvez NEM precise parsear linha-a-linha:
  basta nº OS + cliente + telefone + placa + marca + datas + **total por OS**. Reavaliar se o
  caminho mais barato é parsear só os blocos de cabeçalho de OS + "Total referente ao orçamento".

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| (nenhum) | Não iniciado | Fase 2 não escreveu código ainda. Script de import a criar. |

> Sugestão de local pro script quando for criar: `dap-aios/server/scripts/import-legacy-base.ts`
> (espelha `migrate.ts`/`setup-test-schema.ts`), com flag `--dry-run` default e `--apply` explícito.

## Decisões tomadas

- **Fonte = PDF (autoritativo), enriquecido pelo CSV** — razão: PDF tem telefone (dedup) +
  marca (brand NOT NULL) + itens; CSV só agrega Empresa/Faturado via join por nº orçamento.
- **Itens da OS = 1 item sintético por OS carregando o total** (Thales escolheu agora) —
  cada OS vira 1 `service_order_item` (ex: "Serviço importado — orç. NNNNN") com o total em
  cents. Razão: mais simples/seguro; preserva o valor financeiro; não depende de parse linha-a-linha.
- **Dedup de cliente:** por **telefone** (normalizado) → fallback **nome normalizado**.
- **Dedup de veículo:** por **placa**.
- **OS:** `status` entregue; `code` determinístico **`IMP-{nº orçamento}`** (idempotência);
  `opened_at` = data de entrada; `delivered_at` = data de autorização; `commercial_status` = aprovado.
- **Bosch/Prime (Empresa do CSV):** **não há coluna nativa** em customer/vehicle/OS →
  gravar em `service_orders.internalNotes`/`source`. (Confirmar nome exato do campo no schema de OS.)
- **`vehicles.brand`:** extrair do header "Veículo:" do PDF (primeira palavra após a placa = marca).
- **Gate obrigatório:** **dry-run com relatório** (nº clientes/veículos/OS, R$ total, conflitos,
  linhas rejeitadas) → aprovação do Thales → só então `--apply` grava no `hlhf`.

## Bloqueios & perguntas abertas

- **Ler `service-order-items.ts`** pra confirmar campos obrigatórios do item sintético
  (kind? description? qty? unitCents? totalCents?) — pendente, bloqueia a montagem do insert.
- **Confirmar campo de OS pra Empresa Bosch/Prime** (`internalNotes` vs `source`) — ler schema de OS.
- **Ferramenta de extração do PDF** no host Windows (pdftotext disponível? senão, plano B).
- Guardrail do projeto: **DDL/escrita no hlhf só via caminho controlado**; import é DML (insert),
  não DDL — ok, mas ainda assim **só após dry-run aprovado** (ação relevante na fonte de verdade).

## Próximo passo exato

1. Ler `packages/types/src/schema/service-order-items.ts` e a parte de `internalNotes`/`source`
   em `service-orders.ts` pra travar os campos obrigatórios.
2. Decidir o caminho de extração do PDF (testar `pdftotext -layout fdsaws.pdf out.txt` no host;
   se indisponível, plano B com node).
3. Escrever `dap-aios/server/scripts/import-legacy-base.ts` em modo **dry-run**: parseia PDF
   (cabeçalhos de OS + total por orçamento) + join CSV (Empresa/Faturado), monta os registros
   (customers→vehicles→service_orders→1 item sintético), roda **checksum 628 OS / R$ 1.422.507,11**,
   e imprime relatório SEM gravar.
4. Mostrar relatório do dry-run pro Thales → aprovação → rodar `--apply` contra `hlhf`.

## Setup / comandos úteis

- Banco alvo: Supabase **hlhf** (`hlhfqnhsvwxodtwdkkhf`, sa-east-1), via MCP ou Session Pooler 5432 (user `postgres`, bypassa RLS).
- pnpm não está no PATH: prefixar `C:\Users\docto\AppData\Roaming\npm` em `$env:Path` ou usar `pnpm.cmd`.
- Fontes: `C:\Users\docto\Downloads\relatorio_orçamento (2).csv` · `C:\Users\docto\Downloads\fdsaws.pdf`.
- PowerShell: cuidado com `.Trim()` em campo nulo de CSV → coalescer com `"$($_.Campo)".Trim()`.
