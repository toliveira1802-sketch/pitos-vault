---
type: handoff-perplexity
date: 2026-05-13
project: DAP 4.0 / 5-dap-operacao (Portal Consultor)
branch: feat/sidebar-consultor-apex-chassis
status: implementação concluída, em auditoria
goal: encontrar bugs, regressões, inconsistências e quebras antes de mergear para master
---

# Handoff para Perplexity · Auditoria da Rodada 5 — Portal Consultor / Operação

## TL;DR — o que eu preciso de você

Audite a implementação descrita abaixo (Rodada 5 do portal consultor `5-dap-operacao` no monorepo DAP 4.0). Procure:

1. **Bugs reais** — código que vai quebrar em runtime (não só "code smell").
2. **Regressões** — funcionalidades que existiam e podem ter sido afetadas pelas mudanças (especialmente rotas legacy, o drawer/wizard antigo removidos do CRM, e fluxos de OS).
3. **Inconsistências de UX** — links que apontam para lugar errado, headers que dizem uma coisa e a página entrega outra, breadcrumbs descasados.
4. **Type safety** — tsc passa, mas pode ter `any` implícito, narrowing errado, ou tipos errados em runtime.
5. **Edge cases** — id inválido, cliente sem veículo, OS sem cliente, listas vazias, erros 404/500 da API.
6. **Quebras de pattern do projeto** — code que destoa de convenções existentes (vide seção "Padrões do projeto" abaixo).

**Formato do retorno que eu preciso:**

Lista numerada de achados. Cada achado:
- **arquivo:linha** específico (ou múltiplas linhas)
- **severidade**: CRITICAL / HIGH / MEDIUM / LOW
- **descrição**: o problema em 1-3 linhas
- **repro**: passo a passo se aplicável
- **fix sugerido**: snippet ou direção (não precisa código completo)

Não precisa explicar coisas que estão corretas. Foco no que está errado ou questionável.

---

## 1. Contexto do projeto

### Stack
- **Frontend**: React 18 + TypeScript + Vite + Tailwind + shadcn/ui + lucide-react
- **Router**: wouter v3 com `useHashLocation` (URLs em hash `#/...`)
- **Data**: TanStack Query v5 + Supabase JS client (DB Supabase DOCTOR PRIME, schema `oficina`)
- **Backend**: Express + drizzle-orm/PostgreSQL (mesmo repo, em `server/`)
- **Auth**: Supabase Auth via `useAuth()` hook (em `client/src/lib/auth.tsx`). JWT injetado por `queryClient` default queryFn em todas requests.
- **Testing**: vitest (configurado apenas para backend `tests/**`, sem infraestrutura client-side)
- **Locale**: PT-BR. Money em centavos inteiros (cents). Moeda formatada como BRL.

### Onde vive
- Repo: `C:/THALES/DAP4/5-dap-operacao` (Windows, Git Bash). Cliente em `client/src`, server em `server/`, schema compartilhado em `shared/schema.ts`.
- Branch desta rodada: `feat/sidebar-consultor-apex-chassis`. **NÃO foi mergeado em master.**
- Portal companion: `C:/THALES/DAP4/3-dap-aios/client/src/modules/consultor/components/ConsultorLayout.tsx` (mock visão consultor no AIOS — espelho da sidebar real).

### O que o portal é
Portal "DAP Operação" — interface do consultor para atendimento. Hoje tem:
- Dashboard, Pátio Kanban, Agenda, Linha do Tempo (timeline)
- Clientes (CRM), Ordens de Serviço (OS), Financeiro
- Subsistemas Comercial (CRM, Leads, Adormecidos) e mocks de Portais
- Auth real Supabase (RLS habilitado em ADR-001 Fase 10)

---

## 2. O spec da Rodada 5 (o que era pra fazer)

### Sidebar pedida pelo Thales
```
DAP·4.0
├── Institucional
├── Dashboard
├── + Nova OS                      ← CTA direto na sidebar
├── Pátio
├── Linha do Tempo
├── Agenda
├── Cadastros
│   ├── OS
│   │   ├── Lista                  ← apenas OS abertas/em andamento
│   │   └── Histórico              ← OS encerradas/canceladas
│   └── Clientes
│       ├── CRM                    ← visão card-based
│       └── Cadastro               ← formulário novo cliente
├── Relatórios                     ← placeholder
├── Meu DAP        [em construção]
├── Comercial      [em construção]
├── Tools          [em construção]
├── Thales · admin
└── Sair
```

### Rotas exigidas
```
/consultor                              → Dashboard
/consultor/dashboard                    → Dashboard
/consultor/institucional                → Institucional (placeholder)
/consultor/patio                        → Pátio
/consultor/linha-do-tempo               → Timeline
/consultor/agenda                       → Agenda
/consultor/cadastros/os                 → OS Lista (abertas)
/consultor/cadastros/os/nova            → Form Nova OS
/consultor/cadastros/os/historico       → OS Histórico
/consultor/cadastros/os/:id             → Detalhe OS
/consultor/cadastros/clientes           → CRM
/consultor/cadastros/clientes/novo      → Form Novo Cliente
/consultor/cadastros/clientes/:id       → Ficha do Cliente
/consultor/cadastros/clientes/:id/editar → Form Editar Cliente
```

### Restrições explícitas
- Não recriar `customers`, `vehicles`, `service_orders` (tabelas/módulos existentes).
- Não fazer auth real (mantém o que já tem).
- Não usar cookies/sessionStorage/localStorage.
- Não quebrar `/consultor` (AIOS mock) ou `/mecanico` (portal companheiro).
- Manter rotas legacy (`/`, `/orders`, `/customers`, etc) funcionando para retro-compat de deep-links.

---

## 3. O que foi implementado (commits desta rodada)

**Branch**: `feat/sidebar-consultor-apex-chassis` no repo `5-dap-operacao`. 14 commits acima de master:

```
065187f  fix(os-detail): match new /consultor/cadastros/os/:id route + update copy-link URL
3095175  docs(handoff): Rodada 5 — Portal Consultor / Operação · 2026-05-13
8cc4dc8  feat(consultor): Rodada 5 — nova hierarquia de sidebar + rotas /consultor + páginas dedicadas
f255624  fix(os): use queryFn default in detail/drawer/wizard/attachments
90390d2  chore(sidebar): remove legacy AppSidebar after V2 cutover
4bcf8fd  chore(github): add PR template with AIOS sync checklist
db0cd78  feat(shell): wire AppSidebarV2 + AppTopbar + routes (Apex × Chassis)
dc54b7f  feat(topbar): AppTopbar with breadcrumb + sino (Apex × Chassis)
93c8eee  feat(sidebar): AppSidebarV2 (Apex × Chassis) with CTA, groups, WIP
4893959  feat(placeholder): ConstructionPlaceholder + 4 placeholder pages
27b3e73  feat(topbar): NotificationsBell component (Apex × Chassis)
aa2aceb  feat(hooks): useNotifications stub (MVP) for consultor topbar
10cd445  feat(styles): add Space Grotesk/Caveat + wire dap design-system tokens
bf83918  feat(design-system): copy Apex × Chassis primitives from AIOS
```

**Diff stat global** (vs master): 26 arquivos, +2867 / -497 linhas.

**Branch companheira (AIOS mock)**: `feat/aios-nucleo-consultor` no repo `3-dap-aios`, 1 commit (`640df20`).

---

## 4. Arquivos novos e modificados (detalhe que importa)

### 4.1 Sidebar nova — `client/src/components/app-sidebar-v2.tsx` (NEW, 448 linhas)

Substitui `app-sidebar.tsx` (deletado). Implementa a hierarquia da seção 2 acima usando tipos discriminated union:

```ts
type NavEntry = NavLeaf | NavCta | NavWip | NavSection;

interface NavSection {
  kind: "section";
  label: string;
  icon: LucideIcon;
  roles: Role[];
  groups: Array<{
    label: string;
    items: Array<{ href: string; label: string; roles: Role[] }>;
  }>;
}
```

`Cadastros` é uma `NavSection` com dois `groups` (OS e Clientes), cada um com 2 items. Render: header de seção mono-uppercase + sub-label do grupo + items com `·` bullet vermelho.

CTA `+ Nova OS` linka para `/consultor/cadastros/os/nova`.

WIP sections (Meu DAP, Comercial, Tools) ainda apontam para rotas root-level (`/meu-dap`, `/comercial`, `/tools` — não `/consultor/meu-dap`). **Pergunta**: isso é inconsistente? Os WIP sections deveriam estar sob `/consultor/*` também?

Visual: paper bg `#F4F0E8`, ink `#141414`, accent red `#D8272A`, mono uppercase em labels. Sidebar de 224px fixed.

Active state: background ink + paper text + border-left red. Hover (em items não-active) muda border-left para red 2px.

### 4.2 Topbar — `client/src/components/app-topbar.tsx` (NEW)

Breadcrumb dinâmico baseado em `useLocation()`. Tabela `TITLES` mapeia regex/test → label. Renderiza `DAP · OPERAÇÃO · {label}` em mono uppercase. À direita: `<NotificationsBell />`.

Ordem dos matchers importa (testes mais específicos primeiro). Pergunta: `/^\/consultor\/cadastros\/os\/\d+/` vai matchar `/consultor/cadastros/os/nova` antes do test `l === "/consultor/cadastros/os/nova"`? **Não** — o test do path exato `=== "/consultor/cadastros/os/nova"` está listado primeiro, então pega antes da regex. Confirme.

### 4.3 NotificationsBell — `client/src/components/notifications-bell.tsx` (NEW)

Botão Bell + dropdown popover. Usa `useNotifications` (hook stub que retorna array vazio). Empty state mostra "SEM PENDÊNCIAS · TUDO EM DIA". Click-outside via `useEffect` + `mousedown`. **Stub MVP**, não conecta a backend ainda.

### 4.4 Hook stub — `client/src/lib/hooks/use-notifications.ts` (NEW)

```ts
export function useNotifications(): NotificationsResult {
  const queryClient = useQueryClient();
  const { data = [] } = useQuery({
    queryKey: ["consultor-notifications"],
    queryFn: async (): Promise<Notification[]> => [],
    staleTime: 60_000,
    refetchInterval: 5 * 60_000,
  });
  const unreadCount = data.filter((n) => !n.read).length;
  const markAllRead = () => {
    queryClient.setQueryData<Notification[]>(["consultor-notifications"], (old) =>
      (old ?? []).map((n) => ({ ...n, read: true })),
    );
  };
  return { items: data, unreadCount, markAllRead };
}
```

Próxima rodada vai trocar `queryFn` por leitura de view Supabase. Sem teste por enquanto (vitest do projeto é só backend).

### 4.5 ConstructionPlaceholder — `client/src/components/construction-placeholder.tsx` (NEW)

Componente compartilhado para páginas em construção. Usado por Institucional, Meu DAP, Tools, Orders/New (placeholders), Relatórios (inline em App.tsx), Comercial root (inline em App.tsx).

Renderiza eyebrow "Em construção" red + h1 grande Space Grotesk + descrição opcional + wordmark `DAP·4.0` + linha mono "roadmap · TBD".

### 4.6 Novo Cliente — `client/src/pages/customer-new.tsx` (NEW)

Form com 5 campos required: nome, telefone, marca, modelo, placa.
Fluxo:
1. `POST /api/customers` → recebe customer com `id`
2. `await` resolve, depois `POST /api/vehicles` com `customerId: customer.id`
3. Invalida queries `/api/customers` e `/api/vehicles`
4. `setLocation("/consultor/cadastros/clientes/" + customer.id)`

**Possíveis falhas**:
- Se POST customers OK mas POST vehicles falha → cliente criado órfão, sem veículo. UI mostra toast de erro mas estado fica inconsistente. Não tem rollback.
- Validação client-side é só `length >= N`. Server pode rejeitar (zod schema mais estrito).
- Placa é uppercased antes de POST (`form.plate.trim().toUpperCase()`) — server pode ter constraint diferente.

### 4.7 Ficha do Cliente — `client/src/pages/customer-detail.tsx` (NEW)

Usa `useRoute<{ id: string }>("/consultor/cadastros/clientes/:id")` para pegar id. Faz `GET /api/customers/:id/context` que retorna `{ customer, vehicles, serviceOrders }`. Renderiza card principal + grid de veículos + lista das 10 OS mais recentes (ordenadas por id desc).

queryFn manual aqui:
```ts
queryFn: async () => {
  const res = await fetch(`/api/customers/${id}/context`, { credentials: "include" });
  if (!res.ok) throw new Error("not found");
  return res.json();
},
```

**Pergunta crítica**: o resto do projeto usa **queryClient default queryFn** que injeta `Authorization: Bearer` JWT. Esse `fetch` direto com apenas `credentials: "include"` NÃO injeta JWT. Vai voltar 401 do backend.

Isso é o mesmo bug que estava no `service-order-detail.tsx` antes (commit `f255624` recuperou esse fix). Reintroduzi o bug aqui.

**Fix esperado**: remover o `queryFn` custom e deixar o default. Para isso a queryKey precisa ser `["/api/customers", id, "context"]` formato URL-segmentável que o default queryFn aceita. Confirma como o queryClient default monta a URL.

### 4.8 Editar Cliente — `client/src/pages/customer-edit.tsx` (NEW)

Similar ao customer-detail. Pega id via useRoute. **Mesmo bug do fetch direto**:

```ts
queryFn: async () => {
  const res = await fetch(`/api/customers/${id}`, { credentials: "include" });
  if (!res.ok) throw new Error("not found");
  return res.json();
},
```

Também sem JWT. 401 esperado.

Mutation usa `apiRequest("PATCH", ...)` que respeita auth — ok.

### 4.9 Nova OS — `client/src/pages/orders-new.tsx` (REWRITE — substituiu o placeholder antigo)

Form em 3 steps:
1. Busca cliente (`useQuery /api/customers`) ou link "Criar cliente" → `/consultor/cadastros/clientes/novo` (interrompe fluxo, perde state)
2. Seleção de veículo do cliente selecionado (filtra `/api/vehicles` por `customerId`)
3. Descrição + custo estimado + adiantamento → `POST /api/service-orders` → redirect `/consultor/cadastros/os/${id}`

Valida client-side: customerId não-null, vehicleId não-null, description trim length > 3.

**Possíveis falhas**:
- Se cliente não tiver veículo → mostra alerta amber e link para a ficha. Mas se o usuário criar veículo na ficha e voltar (browser back), state do form de Nova OS está perdido.
- `parseBRLInput` usado em estimatedCost/advancePayment — input pode ter vírgula brasileira. Se input vazio, retorna null. Confirmar.
- Toast de sucesso aparece DEPOIS do redirect? `onSuccess` corre antes do `setLocation`? Verificar ordem.

### 4.10 Lista de OS / Histórico — `client/src/pages/orders.tsx` (REFACTOR)

Aceita prop `statusGroup?: "open" | "closed"`. Filtragem:

```ts
const OPEN_STATUSES: ServiceOrderStatus[] = [
  "diagnostico", "aguardando_aprovacao", "aprovado",
  "em_execucao", "aguardando_peca", "pronto",
];
const CLOSED_STATUSES: ServiceOrderStatus[] = ["entregue", "cancelado"];
```

Header dinâmico:
- `statusGroup="open"` → "OS · Lista"
- `statusGroup="closed"` → "OS · Histórico"
- `undefined` → "Ordens de Serviço"

Detail link dinâmico:
- `statusGroup === undefined` (legacy `/orders`) → `/orders/:id`
- senão → `/consultor/cadastros/os/:id`

Modal Dialog de criar OS REMOVIDO. Botão "Nova OS" agora é `<Link href="/consultor/cadastros/os/nova">`.

Busca expandida para procurar em: description, #OS, customer.name, vehicle.plate.

**Pergunta**: o status filter dropdown agora mostra apenas os status do `groupStatuses` (ou MAIN_STATUS_FLOW completo se sem statusGroup). Isso é coerente — em Histórico, só faz sentido filtrar entre entregue/cancelado. Confirme se está certo.

**Possível regressão**: na rota legacy `/orders` (sem statusGroup), a página mostra TODAS as OS. Era assim antes da rodada também. OK.

### 4.11 CRM Clientes — `client/src/pages/customers.tsx` (REWRITE)

Mudanças:
- Card click NÃO abre mais drawer — agora `setLocation("/consultor/cadastros/clientes/" + id)`.
- Botão "Novo workflow" → trocou por `<Link>` para `/consultor/cadastros/clientes/novo`. (Wizard combinado cliente+veículo+OS foi removido).
- Editar (icon button) → trocou para `<Link>` para `/consultor/cadastros/clientes/:id/editar`. Removido o dialog inline.
- Imports removidos: `CustomerWorkflowWizard`, `CustomerDetailDrawer`, `Dialog`, `Textarea`.
- Imports mantidos: `AlertDialog` (confirmação de delete continua inline).

**Possível regressão**: o wizard combinado era usado para criar cliente + veículo + OS em sequência. Agora o usuário precisa fazer em 2 passos separados (criar cliente, depois ir em Nova OS). Thales aceitou no spec ("permitir criar cliente rápido sem abandonar a lógica do fluxo, se isso couber bem na base atual") — não couber, fluxo virou separado.

**Pergunta**: o componente `CustomerWorkflowWizard` continua existindo no codebase (`client/src/components/customer-workflow-wizard.tsx`), mas não é mais importado em nenhum lugar. Vale dead-code? Vou marcar.

Mesma coisa pro `CustomerDetailDrawer` — vivo no código, não importado por ninguém.

### 4.12 OS Detail — `client/src/pages/service-order-detail.tsx` (PATCH no commit f255624 + 065187f)

Bug original: `useRoute<{ id: string }>("/orders/:id")` — pattern hardcoded para rota legacy. Quando vinha pela rota nova `/consultor/cadastros/os/:id`, useRoute retornava `[false, null]` e `orderId` virava `NaN` → tela "id está errado".

Fix (commit `065187f`):
```ts
const [, paramsLegacy] = useRoute<{ id: string }>("/orders/:id");
const [, paramsConsultor] = useRoute<{ id: string }>("/consultor/cadastros/os/:id");
const params = paramsConsultor ?? paramsLegacy;
const orderId = params ? Number(params.id) : NaN;
```

Também: copy-link URL atualizada de `/#/orders/${id}` para `/#/consultor/cadastros/os/${id}`.

**Pergunta**: tem outros componentes do projeto usando `useRoute` hardcoded em pattern de rota só legacy? Veja `pages/customer-edit.tsx` e `pages/customer-detail.tsx` que usam apenas `/consultor/cadastros/clientes/:id*` — esses só funcionam vindo do path novo. Se alguém colar deep link `/customers/:id/editar` legacy (não existe rota legacy assim), não importa. Mas se houvesse, quebraria.

### 4.13 App.tsx — `client/src/App.tsx` (REFACTOR)

Adicionado: imports para 4 páginas novas (customer-new, customer-detail, customer-edit, orders-new).
Adicionado: bloco completo de rotas `/consultor/*` ANTES das rotas legacy.

**Ordem crítica das rotas** (wouter usa primeiro match no `<Switch>`):

```
/consultor/cadastros/os/nova        ← deve vir antes de /:id
/consultor/cadastros/os/historico   ← idem
/consultor/cadastros/os/:id
/consultor/cadastros/os

/consultor/cadastros/clientes/novo  ← deve vir antes de /:id e /:id/editar
/consultor/cadastros/clientes/:id/editar  ← deve vir antes de /:id (path mais longo)
/consultor/cadastros/clientes/:id
/consultor/cadastros/clientes
```

**Pergunta crítica**: wouter v3 matcha `/:id` contra qualquer segmento, incluindo "novo" ou "editar"? Se sim, ordem importa. Verificar.

A rota `/consultor` precisa vir DEPOIS das filhas (`/consultor/cadastros/...`) porque wouter pode matcar `/consultor` como prefixo? Não, wouter é segment-based estrito por default — `/consultor` só matcha `/consultor` exato. Mas confirme.

### 4.14 Sync com AIOS — `3-dap-aios/.../ConsultorLayout.tsx` (PATCH no commit 640df20)

Mock atualizado para refletir nova hierarquia: OS migrou de sub-item de Pátio para sub-grupo de Cadastros. Visual: nav horizontal com tags clicáveis (não é a sidebar dap real, é só mock para revisar arquitetura).

**Pergunta**: as rotas no mock (`/consultor/cadastros/os/nova`, etc) apontam para paths que NÃO existem no AIOS (só existem no `5-dap-operacao`). Clicando no mock vai dar NotFound no AIOS. Isso é proposital? Vou marcar.

---

## 5. Padrões do projeto (para você comparar)

### Auth
Todas requests devem passar pelo `queryClient` default (que injeta JWT via `getAccessToken`). NUNCA fazer `fetch` direto com só `credentials: "include"` — backend `requireAuth` retorna 401 sem Bearer token.

### Money
Inteiros em cents. `parseBRLInput("123,45")` → `12345`. `formatCentsBRL(12345)` → "R$ 123,45". Empty string → `null` (ou `undefined`?).

### Queries
queryKey usa formato URL-segmentável: `["/api/customers"]`, `["/api/customers", id]`, `["/api/customers", id, "context"]`. O queryClient default joins isso com `/` para montar a URL.

### Rotas wouter
Pattern `:id` matcha qualquer segmento. Pattern `:rest*` matcha multi-segmento. Switch pega o primeiro match.

### Componentes shadcn
Em `client/src/components/ui/*`. Use eles, não recrie. Buttons têm variants `default | destructive | outline | secondary | ghost`. **NÃO existe** `variant="link"`.

### Headers de páginas (shadcn)
Padrão: `<div className="p-6 space-y-4">` + header com h1 (text-xl font-semibold) + subtitle (text-xs text-muted-foreground).

### Testing
Vitest configurado APENAS para backend (`tests/**`, environment node). Sem `@testing-library/react` nem jsdom. Tests para client esperam por rodada própria de infra.

---

## 6. Cenários de teste sugeridos (foque a auditoria nisso)

### Fluxo 1 — Criar cliente novo
1. Login como admin
2. Sidebar → Cadastros → Clientes → Cadastro
3. URL deve ser `/consultor/cadastros/clientes/novo`
4. Preencher: nome, telefone, marca, modelo, placa → Salvar
5. Espera redirect para `/consultor/cadastros/clientes/{id-novo}`
6. Ficha deve mostrar cliente + 1 veículo + 0 OS

**Provável falha**: ficha não carrega (queryFn direto sem JWT → 401).

### Fluxo 2 — Criar Nova OS
1. Sidebar → + Nova OS
2. URL `/consultor/cadastros/os/nova`
3. Buscar cliente existente
4. Selecionar veículo
5. Descrição + custo estimado + adiantamento → Criar OS
6. Espera redirect para `/consultor/cadastros/os/{id-novo}`
7. Detalhe da OS abre normal

**Já corrigido**: detail page agora reconhece o pattern novo (commit 065187f).

### Fluxo 3 — Lista vs Histórico
1. Sidebar → Cadastros → OS → Lista
2. Espera ver apenas OS abertas (diagnostico, aguardando_*, aprovado, em_execucao, aguardando_peca, pronto)
3. Sidebar → Cadastros → OS → Histórico
4. Espera ver apenas entregue + cancelado
5. Filter dropdown deve ter apenas os status do grupo

### Fluxo 4 — CRM click
1. Sidebar → Cadastros → Clientes → CRM
2. Click num card
3. Espera ir para ficha dedicada (não abrir drawer)

**Provável falha**: ficha não carrega (mesmo bug JWT).

### Fluxo 5 — Editar cliente
1. CRM → icon Edit num card
2. URL `/consultor/cadastros/clientes/:id/editar`
3. Form pré-preenchido
4. Editar campos → Salvar
5. Redirect para ficha

**Provável falha**: form vem vazio (GET inicial 401 → data undefined → useEffect não preenche).

### Fluxo 6 — Retro-compat legacy
1. Acessar `localhost:5000/#/orders` direto (rota antiga)
2. Espera ver lista de TODAS as OS (sem statusGroup)
3. Click numa OS → URL vira `/orders/:id` (não `/consultor/...`)
4. Detalhe abre normal

### Fluxo 7 — Edge: cliente sem veículo
1. Criar cliente novo (suponha que crie só customer, vehicle falhe) — ou cliente legado sem veículo
2. Ir em Nova OS, buscar esse cliente
3. Espera alerta amber "Cliente sem veículo cadastrado"
4. Link "Abrir ficha do cliente →" leva pra `/consultor/cadastros/clientes/:id`

### Fluxo 8 — Sidebar role-based
1. Login como `tecnico` ou `recepcao` (não admin)
2. Verificar quais items aparecem
3. `Relatórios` está com `roles: ["admin"]` → não deve aparecer pra tecnico/recepcao
4. `Comercial` está com `roles: ["admin", "recepcao"]` → não aparece pra tecnico

---

## 7. O que eu já sei que tá fraco e quero confirmação

1. **customer-detail.tsx e customer-edit.tsx fazem `fetch` direto sem JWT** → muito provavelmente quebram em runtime. **Confirma**.
2. **CustomerWorkflowWizard e CustomerDetailDrawer ficaram dead code**. **Confirma + sugere se vale deletar ou esperar próxima rodada**.
3. **Mistura visual**: sidebar paper + páginas internas shadcn dark — proposital nesta rodada (Thales aceitou).
4. **Sem teste do client**: vitest só tem coverage de backend. **OK pra esta rodada**.
5. **Ordem dos matchers no topbar breadcrumb**: o `===` exato vem antes do regex `/^...\/\d+/`. **Confirma se a ordem garante o match certo em todos os casos**.

---

## 8. Como me devolver o resultado

Cole no chat do Claude (eu) um markdown nesse formato:

```
## Auditoria Rodada 5 — Achados

### CRITICAL
1. arquivo:linha — descrição (1-3 linhas)
   - repro: ...
   - fix: ...
2. ...

### HIGH
...

### MEDIUM
...

### LOW
...

### Observações gerais
- ...
```

Se quiser, anexa código-fix em snippets, mas não obrigado — só o ponteiro já basta. Vou aplicar aqui na sessão e responder fix por fix.

---

## 9. Anexo — paths importantes pra você navegar

### Repositório principal: `C:/THALES/DAP4/5-dap-operacao`

```
client/index.html
client/src/App.tsx
client/src/index.css
client/src/design-system/
  ├── tokens.css
  ├── dap-components.css
  ├── dap-components.tsx
  └── dap-page-frame.tsx
client/src/components/
  ├── app-sidebar-v2.tsx        ← NEW (substituiu app-sidebar.tsx)
  ├── app-topbar.tsx            ← NEW
  ├── notifications-bell.tsx    ← NEW
  ├── construction-placeholder.tsx ← NEW
  ├── customer-detail-drawer.tsx   ← legado, agora dead code
  ├── customer-workflow-wizard.tsx ← legado, agora dead code
  └── os/os-attachments-card.tsx   ← patched (queryFn fix)
client/src/lib/hooks/
  └── use-notifications.ts      ← NEW (stub)
client/src/pages/
  ├── institucional.tsx         ← NEW (placeholder)
  ├── meu-dap.tsx               ← NEW (placeholder)
  ├── tools.tsx                 ← NEW (placeholder)
  ├── customers.tsx             ← REWRITE
  ├── customer-new.tsx          ← NEW
  ├── customer-detail.tsx       ← NEW (potencial bug JWT)
  ├── customer-edit.tsx         ← NEW (potencial bug JWT)
  ├── orders.tsx                ← REFACTOR (statusGroup prop)
  ├── orders-new.tsx            ← REWRITE (substituiu placeholder)
  └── service-order-detail.tsx  ← PATCHED
server/routes/
  ├── customers.ts              ← intocado
  ├── vehicles.ts               ← intocado
  └── orders.ts                 ← intocado
shared/schema.ts                ← intocado
.github/pull_request_template.md ← NEW
docs/superpowers/specs/2026-05-13-sidebar-consultor-apex-chassis-design.md
docs/superpowers/plans/2026-05-13-sidebar-consultor-apex-chassis.md
docs/handoffs/2026-05-13-rodada-5-portal-consultor.html
```

### AIOS mock: `C:/THALES/DAP4/3-dap-aios/client/src/modules/consultor/components/ConsultorLayout.tsx`

Atualizado para refletir nova hierarquia. Aponta para rotas `/consultor/*` que vivem no portal real (mas mock — clicar não navega de verdade).

---

Fim. Volta com achados e a gente itera aqui.
