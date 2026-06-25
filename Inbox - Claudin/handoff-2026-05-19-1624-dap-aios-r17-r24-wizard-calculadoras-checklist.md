---
type: handoff
date: 2026-05-19
time: 16:24
project: dap-aios
topic: R16.5 → R24 — wizard polished, importer Excel, calculadoras embedded, adiantamento e checklist na OS Detail
tags: [handoff, claudin, dap-aios, r17, r18, r20, r21, r24]
---

# Handoff — R16.5 → R24

## Contexto

Sessão longa no portal Consultor do DAP AIOS (`C:\THALES\DAP4.0\dap-aios`). Construímos da blindagem cliente-veículo até checklist UI completa, passando por:

- importer Excel real → 3 customers (Vilma, Pet Avian PJ, Leandro) + 3 vehicles (Santa Fé, Fiorino, F-Pace) carregados na base local
- wizard Nova OS refatorado pra ficar descobrível (CTA "criar novo cliente" sempre visível, KM Atual no momento certo)
- 3 calculadoras embedded na sidebar da OS reduzidas pra 1 (só Precificação) + margem virou auto-cálculo no FinancialSummary
- pricing pode ser aplicado em item kind=part com 1 clique
- histórico de runs visível na sidebar
- adiantamento do cliente (schema novo + UI 3 estados)
- checklist técnico (schema existia desde R9, faltava UI completa)

Sistema rodando ao vivo em `http://localhost:5050` (server em background, Vite HMR). Anna linkada (`supabase_user_id = 680906ea-91e7-4bed-be91-99be27a3e894`).

Decisão arquitetural-chave registrada nos handoffs R18/R19 (commit `11e28ad`): calculadoras já estavam implementadas (R7), só faltava plug UI — interpretação C do briefing, sem mudar arquitetura. O briefing original assumia que tudo seria do zero.

## O que funcionou (com evidência)

- **R16.5 blindagem cliente-veículo** — commit `034b146`. FK vehicles.customer_id trocada cascade→restrict, archive customer, permission customers:delete granular, 176/176 tests verdes.
- **R17 importer Excel** — commit `5a70b06`. `pnpm import:excel customers ./data/aios-import-customers.xlsx` rodou contra dados reais: 3/3 importados, 0 órfãos, eventos emitidos via service. Re-rodar detecta duplicatas via `resolveCustomerByExternalId`. Inclui parser de notes que extrai `Acquisition: X | Tier: Y | Endereço: Z` (formato atual dos templates).
- **R18+R20 wizard polished + calculadoras sidebar** — commit `f10f41d`. Asterisco vermelho, mensagem inline "obrigatório", FormField shared, KM Atual no Step 3 (depois movido pro Step 2 em R20-c4), sidebar reorganizada em 3 regiões, CalculatorsPanel com 3 tabs (Pricing/Margin/Labor), 212/212 tests.
- **R20-c2 aplicar resultado Pricing** — commit `9ed7b6a`. Botão "aplicar este preço em…" abre dropdown items kind=part, click PATCH com `metadata={source:'calculator_run', calculatorKey:'pricing', runId}`. Trilha auditável via `events.payload.metadata`. Schema `updateServiceOrderItemSchema` ganhou campo `metadata` opcional. 215/215 tests (+3 R20-c2).
- **R20-c3 histórico de runs** — commit `9830a47`. Collapsable footer no CalculatorsPanel mostra timestamp relativo + snippet por calculadora. Lê `useCalculatorRuns({relatedEntityType:'service_order', relatedEntityId: os.id, limit: 10})`.
- **R20-c4 polish + create-customer-always** — commits `6dd9210` + `b55dbe4`. CTA "cadastrar novo cliente" sempre visível no Step 1. KM Atual movido pro Step 2 (sub-step `VehicleConfirmKm` ao selecionar veículo existente). Step 3 advisor+mechanic viraram opcionais. CalculatorsPanel reduzido pra só Pricing. FinancialSummaryCard ganhou linha "Margem" auto-calculada com pill semáforo.
- **R21 adiantamento** — commit `8943b6c`. Migration 0009 (`advance_payment_cents INTEGER nullable`), service idempotente, rota POST `/api/service-orders/:id/advance-payment`, AdvancePaymentCard com 3 estados (sem registro / sem adiantamento confirmado / valor recebido), event `service_order_advance_paid` com payload `{previousCents, newCents}`. 221/221 tests (+6 R21).
- **R24 checklist UI completa** — commit `2d2d084`. Schema/service/rota PATCH `/checklist` já existiam desde R9. ChecklistCard novo entre Diagnóstico e Items: toggle done, edit inline, add/remove, contador done/total, read-only quando !canWrite. Zero backend, 221/221 mantido.

Tudo verde no `pnpm check` (tsc nos 3 packages). Anna logou na UI sem tela preta (vide `scripts/fix-anna-link.mjs` corrigindo `supabase_user_id` nulo).

## O que NÃO funcionou (e por quê)

- **`pnpm import:excel customers ./data/...` na 1ª tentativa** — falhou com `arquivo não encontrado: ./data/aios-import-customers.xlsx (resolvido para C:\THALES\DAP4.0\dap-aios\server\data\...)`. Razão: `pnpm --filter @aios/server` muda cwd pra `server/`. **Correção:** importer agora resolve via `process.env.INIT_CWD ?? process.cwd()` (commit R17). Path relativo funciona.
- **Zod rejeitando `email: null` no createCustomer durante import** — `insertCustomerSchema` tem refinement em email que aceita só `string email` ou `""`. NormalizeEmail retornava `null`. **Correção:** helper `stripNulls` no importer remove keys com null/undefined antes de chamar service — Drizzle aplica default da coluna.
- **Migration 0008 com `PRAGMA foreign_keys = OFF` dentro da migration** — NO-OP. SQLite ignora PRAGMA dentro de transação multi-statement. Drizzle migrator usa `BEGIN/COMMIT` explícito (verifiquei em `node_modules/.../sqlite-core/dialect.js:657`). **Correção:** wrapper externo em `db-helpers.ts` (`applyMigrations`) e `scripts/migrate.ts` desliga PRAGMA antes do migrate e religa depois.
- **`parseMileage('-100')` retornando 100** — strip non-digit removia o sinal `-`. **Correção:** detect leading minus ANTES do strip, retorna null. (Bug detectado por teste auto-redigido R17.)
- **Anna login dava 403 mesmo com senha certa** — `users.supabase_user_id` era `null` no DB local; backend não encontrava localUser via supabase_user_id. **Correção:** `server/scripts/fix-anna-link.mjs` (one-shot script idempotente) provisionou + linkou. Anna ID Supabase: `680906ea-91e7-4bed-be91-99be27a3e894`.
- **Print `cadastrar novo veiuclo.png` mostra campo "Como nos encontrou?"** — não existe no código atual (`NewVehicleForm.tsx`). Briefing R18 pedia remover; documentei que é mockup conceitual ainda não implementado, ignoramos.
- **Tag "Promoção Revisão VW" no `confirmaçao_Os.png`** — mockup conceitual. Sem schema, sem componente. Decisão R19: implementar como `promotion_tag TEXT` livre em rodada futura (R27).
- **R25 (validar Kanban ↔ OS Detail sync) virou noop** — sync já funciona via `useUpdateCommercialStatus` invalidando `['service-orders']` que cascateia. 8 etapas `COMMERCIAL_STATUS_ORDER` batem com `COMMERCIAL_TRANSITIONS`. Branch deletada sem commit.

## O que ainda não foi tentado

- **R22 múltiplas datas no Pátio** (entrada/promessa entrega/pedido peças/início serviço) pra alimentar Gantt — schema novo + UI
- **R23 tabela `resources`** (elevadores/boxes em vez de free-text `resource_label`) — schema + service + dropdown Step 3
- **R26 botões Aprovar/Reprovado da OS como package** — precisa decidir semântica (snapshot do estado aprovado? ou só transição commercial_status='aprovado' que já existe?)
- **R27 `promotion_tag TEXT` livre** — pequeno, sem urgência
- **R28 auto-update `vehicles.last_revision_*`** quando OS com `is_revision=true` é entregue — médio, especulativo (sem OS de revisão entregue ainda pra calibrar)
- **API placa → dados do veículo** (FIPE? InfoSimples? Sinesp?) — decisão de provider, não dev
- **Push das branches pro GitHub** — 8 branches local, zero remote. Risco se HD pifar.
- **Importar os outros 7-10 customers reais do Thales** — importer pronto, falta planilha
- **E2E Playwright do fluxo wizard → criar OS → calculadora → aplicar → fechar** — sem cobertura E2E ainda
- **R20-c5 aplicar Labor em items kind=labor.costCents** — pulei pq dois targets ambíguos (qty=hours ou costCents). Esperar feedback de uso real.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `packages/types/src/schema/consultor.ts` | Completo | R16.5: archivedAt + FK restrict |
| `packages/types/src/schema/core.ts` | Completo | R16.5: action enum +'delete' |
| `packages/types/src/schema/events.ts` | Completo | R16.5 + R21: actions novas |
| `packages/types/src/schema/service-orders.ts` | Completo | R21: advance_payment_cents |
| `packages/types/src/schema/service-order-items.ts` | Completo | R20-c2: metadata schema |
| `server/migrations/0008_absent_loa.sql` | Completo | R16.5 recreate-table-pattern vehicles |
| `server/migrations/0009_happy_miracleman.sql` | Completo | R21 ALTER ADD advance_payment_cents |
| `server/scripts/import-from-excel.ts` | Completo | R17 importer com INIT_CWD + stripNulls |
| `server/scripts/migrate.ts` | Completo | R16.5 PRAGMA wrapper |
| `server/scripts/seed.ts` | Completo | R16.5 perm granular customers |
| `server/scripts/fix-anna-link.mjs` | Completo (untracked) | One-shot: provisiona+linka Anna no Supabase. NÃO commitar — operacional |
| `server/src/lib/importers/notesPrefixParser.ts` | Completo | R17 parser tier/acquisition/CEP |
| `server/src/lib/importers/importNormalizers.ts` | Completo | R17 CPF/phone/plate/year/mileage/date |
| `server/src/services/customerService.ts` | Completo | R16.5: delete/archive + resolveByExternalId |
| `server/src/services/serviceOrderItemService.ts` | Completo | R20-c2 metadata trail |
| `server/src/services/serviceOrderService.ts` | Completo | R21 setAdvancePayment |
| `server/src/routes/customers.ts` | Completo | R16.5 DELETE/archive/unarchive |
| `server/src/routes/service-orders.ts` | Completo | R21 POST /advance-payment |
| `server/test/integration/*.test.ts` | Completo | 221/221 verdes |
| `server/test/lib/notesPrefixParser.test.ts` | Completo | R17 (+9) |
| `server/test/lib/importNormalizers.test.ts` | Completo | R17 (+27) |
| `client/src/shared/components/FormField.tsx` | Completo | R18 shared field com erro inline |
| `client/src/modules/consultor/components/NewServiceOrderModal.tsx` | Completo | R18+R20-c4: 4 steps refeitos, KM no Step 2, advisor/mecânico opcionais |
| `client/src/modules/consultor/components/NewCustomerForm.tsx` | Completo | R18: FormField + showError |
| `client/src/modules/consultor/components/NewVehicleForm.tsx` | Completo | R18: FormField + showError |
| `client/src/modules/consultor/components/os-detail/CalculatorsPanel.tsx` | Completo | R20-c4: só Pricing |
| `client/src/modules/consultor/components/os-detail/CalculatorHistory.tsx` | Completo | R20-c3 snippet semântico |
| `client/src/modules/consultor/components/os-detail/FinancialSummaryCard.tsx` | Completo | R20-c4: margem auto-calc |
| `client/src/modules/consultor/components/os-detail/NavigationCard.tsx` | Completo | R18: renomeada de QuickActionsCard |
| `client/src/modules/consultor/components/os-detail/AdvancePaymentCard.tsx` | Completo | R21 novo |
| `client/src/modules/consultor/components/os-detail/ChecklistCard.tsx` | Completo | R24 novo |
| `client/src/modules/consultor/hooks/useSetChecklist.ts` | Completo | R24 |
| `client/src/modules/consultor/pages/ServiceOrderDetailPage.tsx` | Completo | Pluga AdvancePayment + Checklist na sidebar/coluna |
| `client/src/modules/consultor/pages/CustomersPage.tsx` | Completo | R16.5 toggle arquivados |
| `client/src/modules/consultor/pages/CustomerDetailPage.tsx` | Completo | R16.5 badge ARQUIVADO read-only |
| `CLAUDE.md` (raiz) | Completo | R16.5 seção 5 "Integridade cliente-veículo" |
| `handoff-r18-wizard-os-refactor.md` | Completo | Mudanças cosméticas R18 |
| `handoff-r19-decisoes-arquiteturais.md` | Completo | 5 decisões + interpretação calculadoras |
| `handoff-aios-rodada16-5-integrity-customer-vehicle.md` | Completo | R16.5 |
| `handoff-aios-rodada17-importer-excel.md` | Completo | R17 |

## Decisões tomadas

- **R16.5 — vehicles FK cascade → restrict** — razão: cliente com veículos não pode ser deletado, só arquivado. Soft delete via `archived_at` é a mecânica natural. Hard delete fica exclusivo de gestor/admin.
- **R16.5 — `customers:delete` granular separado de `manage`** — razão: consultor perde poder destrutivo, gestor ganha. Antes era implícito via `manage`.
- **R17 — parser de notes no importer** — razão: dado real do Thales já está nesse formato (`Acquisition: X | Tier: Y | Endereço: Z`). Bloquear até template novo atrasaria import.
- **R17 — `import-cache.json` em `./data/`** — razão: persiste mapping `_external_id ↔ customer.id` entre 2 comandos (`customers` depois `vehicles`). Sem isso, vehicles falhariam com CUSTOMER_NOT_FOUND.
- **R19 — calculadoras interpretação C (mantendo `calculator_runs` table existente)** — razão: módulo já implementado desde R7. Briefing original assumia que era do zero. Aceitar realidade > redesenhar.
- **R20-c2 — `metadata` no PATCH item ao invés de tabela nova** — razão: trilha vai pro payload do event `service_order_item_updated`. Query auditável via `json_extract(payload,'$.metadata.source')='calculator_run'`. Sem migration, sem schema novo.
- **R20-c4 — Margem virou auto-cálculo no FinancialSummary, não calculadora** — razão: margem é diagnóstica (sempre fresh, semafórica), não prescritiva. Sem botão "calcular" e sem event spam. Calculadora que sobrou (Pricing) é prescritiva — calcula sob demanda + aplica em item.
- **R20-c4 — KM Atual no Step 2 ao selecionar veículo (não Step 3)** — razão (opção B confirmada pelo Thales): consultor lê hodômetro toda visita. Veículo novo já capturou no NewVehicleForm; existente ganha sub-step `VehicleConfirmKm` editável pré-populado.
- **R20-c4 — Step 3 advisor/mechanic opcionais** — razão: atribuição pode ser pós-criação na OS Detail. Não bloqueia abertura de OS.
- **R21 — null vs 0 no `advance_payment_cents`** — razão: 3 estados distintos. null = nunca tocado, 0 = "sem adiantamento confirmado", >0 = valor real. Sem ambiguidade ao analisar.
- **R24 — checklist como JSON em `service_orders`, não tabela separada** — razão (mantida da R9): items são por OS, não compartilhados. JSON suficiente. Migrar pra tabela só quando virar template reusável.
- **R25 — noop, branch deletada** — razão: sync já funciona via query invalidation cascade. Sem trabalho real.

## Bloqueios & perguntas abertas

- **Push das branches pro GitHub** — eu não fiz porque CLAUDE.md exige confirmação explícita pra push. Thales não autorizou nesta sessão. **8 branches local sem remote**: `feat/r165-customer-vehicle-integrity` `feat/r17-importer-excel` `feat/r18-wizard-os-calculators` `feat/r20-c2-apply-calculator-result` `feat/r20-c3-calculator-history` `feat/r20-c4-create-customer-always` `feat/r21-advance-payment` `feat/r24-checklist-ui`. Risco se HD pifar.
- **Aprovar/Reprovar OS package (R26)** — semântica não decidida. Opção A: transição `commercial_status='aprovado'` (já existe). Opção B: snapshot do estado aprovado em coluna nova. Thales mencionou "no radar".
- **API placa → dados** — qual provider? FIPE é grátis mas só preço, não dados completos. InfoSimples/Sinesp são pagos. Decisão de produto pendente.
- **R28 auto-update revisão** — falta primeiro veículo entregue como revisão pra calibrar regra (`is_revision` flag manual ou inferir do complaint?).
- **Bug R15 "consultor não atua"** — marcado como fechado por implicit fix. Anna logou OK nesta sessão. Se reaparecer, ressuscitar.

## Próximo passo exato

**Decidir entre 3 caminhos:**

1. **Push pras branches** — `git push -u origin feat/r165-customer-vehicle-integrity feat/r17-importer-excel feat/r18-wizard-os-calculators feat/r20-c2-apply-calculator-result feat/r20-c3-calculator-history feat/r20-c4-create-customer-always feat/r21-advance-payment feat/r24-checklist-ui` — sobe 8 branches, cria PRs (não exige dev novo, é seguro).

2. **Validar com dados reais** — Thales abre `http://localhost:5050`, loga Anna (`anna@doctorautoprime.com` / `T060925@`), navega `/consultor/os/pD9k9a9SDFS5v7YMc7s65` (OS da Vilma) e exercita o fluxo completo: edita checklist, marca itens, calcula Pricing, aplica preço, registra adiantamento. Identifica próximo gap real.

3. **Próxima rodada R22 ou R23** — múltiplas datas Pátio (Gantt) ou tabela resources (elevadores/boxes). Ambas são médias (schema novo + UI).

**Recomendação pessoal:** caminho 1 (push) primeiro pq é seguro e elimina risco de HD; depois caminho 2 (validar) por uma sessão pra descobrir gaps reais; depois R22 ou R23 conforme prioridade que emergir do uso.

## Setup / comandos úteis

```bash
# Localhost dev (já rodando em background ID bz0onh140 nesta sessão; matar se sair)
cd C:/THALES/DAP4.0/dap-aios && pnpm dev   # localhost:5050

# Aplicar migrations local (R21 0009)
pnpm db:setup        # generate (no-op se sem schema change) + migrate
pnpm db:seed         # NÃO RODAR — apaga supabase_user_id da Anna

# Importar Excel real
pnpm import:excel customers ./data/aios-import-customers.xlsx
pnpm import:excel vehicles  ./data/aios-import-vehicles.xlsx

# Re-linkar Anna se supabase_user_id zerar
cd server && node scripts/fix-anna-link.mjs

# Tests + check
pnpm check && pnpm test    # 221/221 esperados

# Branches local atuais
git log --oneline -12
# HEAD: 2d2d084 feat(r24): checklist técnico UI completa
# Branch ativa: feat/r24-checklist-ui

# 3 customers + 3 vehicles reais no banco
node -e "const db=require('better-sqlite3')('C:/THALES/DAP4.0/dap-aios/data/aios.db',{readonly:true}); console.log(db.prepare('SELECT name, document, tier FROM customers WHERE archived_at IS NULL').all())"
```

**Credenciais:** Anna: `anna@doctorautoprime.com` / `T060925@` (hardcoded em `scripts/provision-anna.mjs:20`, NÃO secret de prod).

**Backend rodando em:** `http://localhost:5050` (Anna logada via Supabase Auth real, R10).

**Branch ativa ao salvar este handoff:** `feat/r24-checklist-ui`.
