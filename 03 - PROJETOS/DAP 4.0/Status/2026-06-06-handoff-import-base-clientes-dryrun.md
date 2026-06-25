---
type: handoff
date: 2026-06-06
time: "09:30"
project: dap-aios (banco hlhf)
topic: Import da base legada cliente→veículo→OS — APLICADO no hlhf (636 OS, R$ 1.432.167,11), verificado
tags: [handoff, claudin, dap-aios, import, hlhf, clientes, veiculos, service-orders, legado, aplicado]
status: concluido
---

> ✅ **APPLY EXECUTADO E VERIFICADO (2026-06-06 ~09:40).** Thales aprovou a opção "636 (inclui as 8 sem placa)".
> Gravado no hlhf em transação atômica. Verificação SQL no banco:
> - 636 OS `IMP-` (todas `delivered`) · 405 clientes legado · 532 veículos (527 + 5 seed) · 636 itens.
> - **SUM(service_order_items.total_cents) = 143.216.711 = R$ 1.432.167,11** ← bate o checksum EXATO.
> - 9 veículos `INDEFINIDO` (8 sem placa + `FAD4D72`) · 1568 eventos `legacy_import` (405+527+636).
> - Idempotência confirmada: re-rodar `--apply` aborta ("Já existem 636 OS IMP-").
> - Fix cosmético aplicado (relatório não diz mais "dry-run" no modo apply); tsc+eslint limpos.

> 🔁 **REFATORADO PRA INCREMENTAL (2026-06-06 ~10:00).** O script agora suporta import mensal:
> rodar com um export fresco do sistema (web) acrescenta SÓ o que é novo, sem duplicar.
> - Dedup de cliente (nome) e veículo (placa) agora bate **contra o banco existente** + o lote.
> - OS cujo `code IMP-` já existe são **puladas**; só as novas entram. `onConflictDoNothing(code)` de rede.
> - Code de OS agora distingue complemento: `IMP-{orç}` (compl 0) ou `IMP-{orç}-{compl}` (compl≠0).
>   Alinhei a 1 linha histórica afetada no banco: `IMP-36465` → `IMP-36465-1` (orç. VICTOR, R$ 9.000).
> - Checksum fixo de maio virou `--verify-snapshot` (opcional); gate agora é **consistência interna**
>   (comPlaca + semPlaca == total). Validado: dry-run no CSV de maio = 636 puladas, 0 novas. ✅
> - Thales escolheu: **ele mesmo exporta o CSV** do sistema (web). Workflow de automação de browser
>   (Playwright login+download) fica pra Fase B futura.
>
> **FLUXO MENSAL (pronto):** Thales exporta o relatório de orçamentos Autorizados (CSV) + opcional o
> PDF "Serviços/Peças por Veículo" → `pnpm import:legacy --csv <novo.csv> --pdf <novo.pdf>` (dry-run,
> revisa "OS novas") → `--apply` grava só o delta.
>
> **Próximo:** (1) Thales exportar o CSV com junho e me apontar → importo o delta de junho.
> (2) validar que Consultor/FinanceiroPage enxergam os dados. (3) Fase B: workflow Playwright.

> ✅ **JUNHO APLICADO (2026-06-06 ~10:30).** Delta incremental rodado com `relatorio_orçamento (3).csv`
> (01–05/06, 18 AU) + `relatorio_orçamento (2).pdf` (período junho, marcas/telefones).
> - +18 OS · +12 clientes (6 recorrentes de maio reaproveitados) · +14 veículos · +18 itens.
> - 13 marcas do PDF, 1 INDEFINIDO (a 1 sem placa) · 10 clientes novos com telefone.
> - 1 linha FE (Fechado, R$ 2.000) fora do escopo (só Autorizados, igual maio).
> - Verificação banco: **654 OS IMP- · 417 clientes legado · 546 veículos · 654 itens ·
>   SUM(itens)=147.073.479 = R$ 1.470.734,79** (= 1.432.167,11 maio + 38.567,68 junho, exato). ✅
> - Incremental provado: dedup contra o banco reaproveitou 6 clientes + 3 veículos de maio.
> **Pendente:** validar Consultor/FinanceiroPage; Fase B (workflow Playwright) quando Thales topar.

> ✅ **VALIDAÇÃO UI + BUSCA/PAGINAÇÃO DE CLIENTES (2026-06-06 ~11:30).**
> Validação (via os próprios services das rotas): OS importadas aparecem — `view=history`=654,
> `view=active`=5 (seeds), joins customer/vehicle certos. **Achado:** a página de Clientes usava
> `listCustomers` com `limit:200` fixo, sem busca nem paginação → com 418 clientes, ~218 ficavam
> inalcançáveis. **Corrigido:**
> - `customerService.listCustomers`: agora `{ archived, q, limit, offset } → { items, total }`.
>   Busca `q` por nome/telefone/documento (ILIKE, índices já existem). orderBy com **tiebreaker
>   por id** (sem ele, updatedAt idêntico do import vazava linha entre páginas — bug pego na validação).
> - Rota `GET /api/customers`: aceita `q/limit/offset`, devolve `data` (array, pickers intactos) + `meta.total`.
> - Client: `api.getWithMeta` (preserva meta) + hook `useCustomersPaged` + `CustomersPage` com
>   busca debounced (300ms) + paginação (24/pág). Pickers de OS/Agenda seguem em `useCustomers` (array).
> - Testes: +5 integração (q nome/tel/doc, paginação sem overlap com updatedAt idêntico, sem-match).
>   34/34 verdes em customers.test. `pnpm check` (types) + eslint limpos. Validado no hlhf: total=418,
>   busca "silva"=51, overlap entre páginas=false.
> - ⚠️ **Pré-existente (NÃO meu):** `customers-vehicles-integrity.test.ts` tem 1 teste de FK (23503)
>   falhando — schema de `test` não replica a FK; provado via git stash que falha sem minhas mudanças.
> - Nota: telefones do PDF foram salvos sem prefixo 55 (ex "11980354779"); busca casa o que está salvo.
> **Pendente:** pickers de OS/Agenda também se beneficiariam de busca server-side (hoje top-200);
> FinanceiroPage ainda em mock; consertar o teste de FK do schema de test; Fase B workflow Playwright.
---

# Handoff — Import da base legada: dry-run pronto e validado

> Continuação direta de `2026-06-06-handoff-import-base-clientes.md` (Fase 2, planejamento).
> Esta rodada **construiu e validou o dry-run**. O checksum triplo bate exato. **Nada foi
> gravado no banco.** Próximo passo é só decisão de gate: rodar `--apply`.

## Resumo executivo

O script de import existe, roda, e o dry-run fecha 100% com a fonte. A grande mudança vs o
plano anterior: **a arquitetura foi invertida com base em evidência** — o CSV é a fonte
autoritativa (não o PDF). O CSV é UTF-8 limpo, `;`-delimitado, 1 linha por orçamento, com
todos os campos de OS/financeiro estruturados (inclusive Total já pronto). O PDF só enriquece
**placa→marca** e **placa→telefone**. Isso elimina o pesadelo de parsear floats flutuantes do
layout do PDF que o plano original previa.

## A descoberta que travou tudo (reconciliação triple checksum)

| Conjunto | OS | Valor |
|---|---|---|
| **AU com placa** | **628** | **R$ 1.422.507,11** ← bate EXATO o rodapé do PDF |
| AU sem placa | 8 | R$ 9.660,00 |
| **AU total** | **636** | **R$ 1.432.167,11** |

- O PDF é "Serviços/Peças **por Veículo**" → orçamentos **sem placa não aparecem nele**. Por
  isso o PDF mostra 628 e o CSV tem 636: a diferença são exatamente as **8 sem placa** (R$ 9.660).
- As "6 linhas corrompidas" que o handoff anterior temia **não são dados** — são o rodapé do
  relatório (subtotais mensais jan–mai que somam 1.432.167,11). Nenhuma linha de cliente perdida.
- O dry-run trava esses 3 números como **checksum**. Se a fonte não bater, o import **aborta**.

## O que foi implementado (com evidência)

### `server/scripts/import-legacy-base.ts` (novo, ~640 linhas, tsc+eslint limpos)
- Parser CSV próprio (`;` + aspas), `brlToCents`, `parseBrDateTime` (DD/MM/YYYY HH:MM:SS).
- **PDF map** placa→{marca, telefone}: extrai via `pdftotext -enc UTF-8 -layout` (auto-descobre
  o binário no `C:\Program Files\Git\mingw64\bin` se não estiver no PATH); âncora `Veículo: PLACA MARCA MODELO`.
- **buildPlan**: monta clientes (dedup por nome normalizado), veículos (dedup por placa),
  OS (1 por orçamento), 1 item sintético por OS. Puro, sem tocar no banco.
- **verifyChecksum**: triple checksum; bloqueia apply se falhar.
- **printReport**: relatório dry-run completo.
- **applyPlan**: transação atômica (customers→vehicles→service_orders→items) + 1 evento de
  criação por entidade (regra de arquitetura #4). Idempotência: aborta se já houver código `IMP-%`.
- CLI: `--apply` (default dry-run), `--skip-no-plate`, `--csv`, `--pdf`, `--pdf-txt`, `--limit`.
- Registrado como `pnpm import:legacy` (raiz + `@aios/server`).

### Decisões de schema travadas (corrigem o handoff anterior)
- `service_orders.commercialStatus` = **`entregue`** (o enum NÃO tem `aprovado` como o handoff dizia).
- Empresa Bosch/Prime → **`internalNotes`** (texto livre). **NÃO** `source` — `source` é enum
  fechado (`walk_in|whatsapp|phone|referral|returning|other`), não aceita "Bosch"/"Prime".
- Item sintético: `kind='labor'`, `status='approved'` (pra somar no total da OS), `unitCents=totalCents`.
- `status='delivered'`, `openedAt`=Data de Entrada, `deliveredAt`=Data de Autorização, `code='IMP-{orçamento}'`.

### Decisão de dedup INVERTIDA (mais segura, com evidência)
Dedup de cliente é por **NOME normalizado**, não por telefone. Motivo: o telefone do PDF tem
ruído — número da própria oficina (`5140025005`) vaza no bloco e apareceria em placas distintas,
o que **mesclaria clientes não relacionados**. Telefone entra só como contato best-effort (314/636).

## Resultado do dry-run (última execução)

```
Linhas AU: 636  | Com placa: 628 (R$ 1.422.507,11) | Sem placa: 8 (R$ 9.660,00)
Triple checksum: ✅ TODOS OK
Criaria: 405 clientes · 527 veículos · 636 OS (R$ 1.432.167,11) · 636 itens
Marca do PDF: 518 · fallback INDEFINIDO: 9 | Clientes com telefone: 314
Empresa: Bosch 355 / Prime 281 | Faturado: Não 449 / Sim 187
⚠️ 6 placas com >1 cliente (carro vendido): FPI2496, ETC1E65, RYI3H82, RXM0F66, RYO2C22, EGT2H55
```

## Estado do banco hlhf (read-only, confirmado)
1 customer, 5 vehicles, 5 service_orders (seed), 0 items, **0 códigos IMP-**. Slate limpo —
sem colisão, sem dedup-contra-existente.

## Verificações (evidência)
- ✅ `pnpm --filter @aios/server check` (tsc --noEmit) exit 0.
- ✅ `eslint import-legacy-base.ts` exit 0 (0 erros/warnings).
- ✅ `pnpm import:legacy` (dry-run) roda e fecha checksum triplo.
- ✅ Temporários de análise removidos do Downloads.

## Arquivos tocados
| Arquivo | Mudança |
|---|---|
| `server/scripts/import-legacy-base.ts` | novo — script de import (dry-run + apply) |
| `server/package.json` | + script `import:legacy` |
| `package.json` (raiz) | + script `import:legacy` |

## Decisões abertas pro Thales (gate do --apply)
1. **8 OS sem placa (R$ 9.660):** importar com veículo placeholder (`INDEFINIDO`/`INDEFINIDO`,
   plate=null) **ou** pular com `--skip-no-plate`? Default atual = importar (preserva histórico).
2. **6 placas com >1 cliente** (carro vendido entre clientes): hoje a OS linka cliente E veículo
   pela verdade da própria linha do CSV; o veículo fica registrado com o 1º dono. Aceitável?
3. **9 veículos marca `INDEFINIDO`** (8 sem placa + 1 placa sem match no PDF: `FAD4D72`). OK?

## Próximo passo exato
1. Thales revisa o relatório do dry-run acima.
2. Decide as 3 questões de gate (sem placa, multi-cliente, INDEFINIDO).
3. Rodar `pnpm import:legacy --apply` (eu executo após aprovação — escreve no hlhf em transação).
4. Pós-apply: validar contagens no hlhf (636 OS IMP-, SUM(total_cents) dos itens = R$ 1.432.167,11)
   e conferir que a `FinanceiroPage`/Consultor enxergam os dados.

## Setup / comandos
- Banco: Supabase **hlhf** (`hlhfqnhsvwxodtwdkkhf`) via `server/.env` (`DATABASE_URL`, Session Pooler 5432).
- pnpm fora do PATH: `$env:Path = "C:\Users\docto\AppData\Roaming\npm;$env:Path"` no PowerShell.
- Fontes: `C:\Users\docto\Downloads\relatorio_orçamento (2).csv` · `fdsaws.pdf`.
- Dry-run: `pnpm import:legacy` · Apply: `pnpm import:legacy --apply`.
