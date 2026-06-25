# DAP Prime V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

## Handoff prompt (para nova janela Claude Code)

Abra pasta vazia `C:\dev\dap-prime\` e inicie CC ali. Cole:

> Implemente o **DAP Prime V1** seguindo:
> - Spec: `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\DAP 4.0\Specs\2026-04-18-dap-prime-v1-design.md`
> - Plano: `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\DAP 4.0\Specs\2026-04-18-dap-prime-v1-plan.md`
>
> Use `superpowers:subagent-driven-development` — um subagent por task, review entre tasks. Execute **Milestone 0 sequencial**, depois **Milestones 1-3 em paralelo** (worktrees git), por fim **Milestone 4 sequencial**. Toda task termina em commit. Não pule TDD onde o plano pede.

---

**Goal:** Portal do consultor da Doctor Auto Prime — cadastro cliente/veículo, criação e gestão de OS, Kanban do pátio (6 colunas drag-drop), agendamentos com conversão em OS — deployado em Vercel + Supabase.

**Architecture:** SPA React 18 + Vite 7 em Vercel acessando Supabase direto (PostgREST + Auth). Schema `prime.*` no mesmo Supabase project do DAP 4.0 holding. Zero middleware custom. RLS com policy única `auth.role() = 'authenticated'`. Roteamento hash (Wouter). TanStack Query para cache/mutations.

**Tech Stack:** React 18, TypeScript, Vite 7, Tailwind v3, shadcn/ui, Wouter, TanStack Query v5, Zod, React Hook Form, @dnd-kit, Framer Motion, Supabase JS, Vitest, Playwright.

---

## Prerequisites (antes de começar)

- [ ] Node 20+ e pnpm 9+ instalados
- [ ] Pasta `C:\dev\dap-prime\` criada e vazia
- [ ] Credenciais Supabase do projeto DAP 4.0 disponíveis (URL + anon key + service role key) — copiar de `C:\dev\dap4\.env`
- [ ] Git configurado (`user.name`, `user.email`)
- [ ] Conta Vercel pronta (opcional: `pnpm add -g vercel`)

---

## File structure (entregue ao fim do V1)

```
dap-prime/
├── README.md
├── package.json
├── pnpm-lock.yaml
├── vite.config.ts
├── vitest.config.ts
├── playwright.config.ts
├── tsconfig.json
├── tsconfig.node.json
├── tailwind.config.ts
├── postcss.config.js
├── index.html
├── .env.example
├── .env.local                    (gitignored)
├── .gitignore
├── components.json               (shadcn)
├── eslint.config.js
│
├── supabase/
│   └── migrations/
│       ├── 001_prime_schema.sql
│       └── 002_prime_seed.sql
│
├── src/
│   ├── main.tsx                  entry
│   ├── App.tsx                   router + providers
│   ├── index.css                 tailwind + tokens
│   │
│   ├── lib/
│   │   ├── supabase.ts           client
│   │   ├── query-client.ts       tanstack config
│   │   ├── utils.ts              cn() helper
│   │   ├── format.ts             placa, CPF, data
│   │   └── validators.ts         zod schemas compartilhados
│   │
│   ├── auth/
│   │   ├── AuthProvider.tsx
│   │   ├── useAuth.ts
│   │   ├── AuthGuard.tsx
│   │   └── LoginPage.tsx
│   │
│   ├── components/
│   │   ├── ui/                   (shadcn: button, input, card, dialog,
│   │   │                          select, form, sonner, tabs, dropdown...)
│   │   ├── layout/
│   │   │   ├── AppShell.tsx      sidebar + topbar
│   │   │   ├── Sidebar.tsx
│   │   │   └── Topbar.tsx
│   │   └── common/
│   │       ├── EmptyState.tsx
│   │       ├── LoadingState.tsx
│   │       └── ErrorBoundary.tsx
│   │
│   ├── features/
│   │   ├── clientes/
│   │   │   ├── api.ts            queries + mutations
│   │   │   ├── hooks.ts          useClientes, useCliente, useCreateCliente...
│   │   │   ├── schema.ts         zod
│   │   │   ├── types.ts
│   │   │   ├── ClienteForm.tsx
│   │   │   ├── ClienteCard.tsx
│   │   │   ├── ClientesList.tsx
│   │   │   ├── ClienteDetail.tsx
│   │   │   └── pages/
│   │   │       ├── ClientesPage.tsx        /clientes
│   │   │       ├── NovoClientePage.tsx     /clientes/novo
│   │   │       └── ClienteDetailPage.tsx   /clientes/:id
│   │   │
│   │   ├── veiculos/
│   │   │   ├── api.ts
│   │   │   ├── hooks.ts
│   │   │   ├── schema.ts
│   │   │   ├── types.ts
│   │   │   ├── VeiculoForm.tsx
│   │   │   ├── VeiculoCard.tsx
│   │   │   ├── VeiculoDetail.tsx
│   │   │   └── pages/
│   │   │       ├── NovoVeiculoPage.tsx     /veiculos/novo
│   │   │       └── VeiculoDetailPage.tsx   /veiculos/:id
│   │   │
│   │   ├── ordens-servico/
│   │   │   ├── api.ts
│   │   │   ├── hooks.ts
│   │   │   ├── schema.ts
│   │   │   ├── types.ts
│   │   │   ├── status.ts                   enum + labels + cores
│   │   │   ├── OsForm.tsx
│   │   │   ├── OsCard.tsx
│   │   │   ├── OsList.tsx
│   │   │   ├── OsDetail.tsx
│   │   │   └── pages/
│   │   │       ├── OsListPage.tsx          /os
│   │   │       ├── NovaOsPage.tsx          /os/nova
│   │   │       └── OsDetailPage.tsx        /os/:id
│   │   │
│   │   ├── patio/
│   │   │   ├── KanbanBoard.tsx
│   │   │   ├── KanbanColumn.tsx
│   │   │   ├── KanbanCard.tsx
│   │   │   └── pages/
│   │   │       └── PatioPage.tsx           /patio
│   │   │
│   │   ├── agendamentos/
│   │   │   ├── api.ts
│   │   │   ├── hooks.ts
│   │   │   ├── schema.ts
│   │   │   ├── types.ts
│   │   │   ├── AgendamentoForm.tsx
│   │   │   ├── AgendamentoCard.tsx
│   │   │   ├── CalendarView.tsx
│   │   │   └── pages/
│   │   │       ├── AgendamentosPage.tsx        /agendamentos
│   │   │       └── NovoAgendamentoPage.tsx     /agendamentos/novo
│   │   │
│   │   └── dashboard/
│   │       └── pages/
│   │           └── DashboardPage.tsx       /
│   │
│   └── routes.tsx                mapeamento central
│
├── tests/
│   ├── unit/
│   │   ├── format.test.ts
│   │   ├── validators.test.ts
│   │   └── features/
│   │       └── ...
│   └── e2e/
│       ├── 01-login.spec.ts
│       ├── 02-clientes-veiculos.spec.ts
│       ├── 03-os-kanban.spec.ts
│       ├── 04-agendamento-conversao.spec.ts
│       └── 05-busca-placa.spec.ts
│
└── docs/
    ├── CLAUDE.md
    └── DEPLOY.md
```

---

## MILESTONE 0 — Agent 0: Scaffold + Schema (sequential gate)

> Bloqueia todos os outros milestones. **Nenhum Agent 1/2/3 começa antes deste terminar e commitar.**

### Task 0.1: Git init + package.json base

**Files:** Create `package.json`, `.gitignore`, `README.md`

- [ ] **Step 1 — init git:**
  ```bash
  cd C:\dev\dap-prime
  git init -b main
  ```

- [ ] **Step 2 — pnpm init e editar `package.json`:**
  ```json
  {
    "name": "dap-prime",
    "private": true,
    "version": "0.1.0",
    "type": "module",
    "scripts": {
      "dev": "vite",
      "build": "tsc -b && vite build",
      "preview": "vite preview",
      "typecheck": "tsc --noEmit",
      "lint": "eslint .",
      "test": "vitest run",
      "test:watch": "vitest",
      "test:e2e": "playwright test",
      "db:push": "supabase db push",
      "db:reset": "supabase db reset"
    },
    "engines": { "node": ">=20" }
  }
  ```

- [ ] **Step 3 — `.gitignore`:**
  ```
  node_modules
  dist
  dist-ssr
  .env
  .env.local
  .env.*.local
  .DS_Store
  *.log
  playwright-report
  test-results
  coverage
  .vercel
  ```

- [ ] **Step 4 — `README.md` placeholder (Agent 4 expande):**
  ```markdown
  # DAP Prime V1
  Portal do consultor — Doctor Auto Prime. WIP.
  ```

- [ ] **Step 5 — commit:**
  ```bash
  git add .
  git commit -m "chore: init dap-prime repo"
  ```

### Task 0.2: Instalar dependências

- [ ] **Step 1 — runtime:**
  ```bash
  pnpm add react react-dom wouter \
    @supabase/supabase-js \
    @tanstack/react-query \
    zod react-hook-form @hookform/resolvers \
    @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities \
    framer-motion lucide-react sonner \
    date-fns clsx tailwind-merge class-variance-authority \
    react-day-picker
  ```

- [ ] **Step 2 — dev deps:**
  ```bash
  pnpm add -D vite @vitejs/plugin-react \
    typescript @types/react @types/react-dom @types/node \
    tailwindcss postcss autoprefixer \
    vitest @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom \
    @playwright/test \
    eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin \
    eslint-plugin-react-hooks eslint-plugin-react-refresh
  ```

- [ ] **Step 3 — commit:**
  ```bash
  git add package.json pnpm-lock.yaml
  git commit -m "chore: install runtime + dev deps"
  ```

### Task 0.3: Config Vite + TS + Tailwind + PostCSS

**Files:** Create `vite.config.ts`, `vitest.config.ts`, `tsconfig.json`, `tsconfig.node.json`, `tailwind.config.ts`, `postcss.config.js`, `src/index.css`, `index.html`, `src/main.tsx`, `src/App.tsx`

- [ ] **Step 1 — `tsconfig.json`:**
  ```json
  {
    "compilerOptions": {
      "target": "ES2022",
      "useDefineForClassFields": true,
      "lib": ["ES2022", "DOM", "DOM.Iterable"],
      "module": "ESNext",
      "skipLibCheck": true,
      "moduleResolution": "bundler",
      "allowImportingTsExtensions": true,
      "resolveJsonModule": true,
      "isolatedModules": true,
      "noEmit": true,
      "jsx": "react-jsx",
      "strict": true,
      "noUnusedLocals": true,
      "noUnusedParameters": true,
      "noFallthroughCasesInSwitch": true,
      "baseUrl": ".",
      "paths": { "@/*": ["src/*"] },
      "types": ["vitest/globals", "@testing-library/jest-dom"]
    },
    "include": ["src", "tests"],
    "references": [{ "path": "./tsconfig.node.json" }]
  }
  ```

- [ ] **Step 2 — `tsconfig.node.json`:**
  ```json
  {
    "compilerOptions": {
      "composite": true,
      "skipLibCheck": true,
      "module": "ESNext",
      "moduleResolution": "bundler",
      "allowSyntheticDefaultImports": true,
      "strict": true,
      "types": ["node"]
    },
    "include": ["vite.config.ts", "vitest.config.ts", "playwright.config.ts", "tailwind.config.ts"]
  }
  ```

- [ ] **Step 3 — `vite.config.ts`:**
  ```ts
  import { defineConfig } from 'vite';
  import react from '@vitejs/plugin-react';
  import path from 'node:path';

  export default defineConfig({
    plugins: [react()],
    resolve: { alias: { '@': path.resolve(__dirname, './src') } },
    server: { port: 5174 }
  });
  ```

- [ ] **Step 4 — `vitest.config.ts`:**
  ```ts
  import { defineConfig } from 'vitest/config';
  import react from '@vitejs/plugin-react';
  import path from 'node:path';

  export default defineConfig({
    plugins: [react()],
    resolve: { alias: { '@': path.resolve(__dirname, './src') } },
    test: {
      globals: true,
      environment: 'jsdom',
      setupFiles: ['./tests/setup.ts'],
      coverage: { provider: 'v8', reporter: ['text', 'html'] }
    }
  });
  ```

- [ ] **Step 5 — `tailwind.config.ts`:** usar preset padrão shadcn (obter via `pnpm dlx shadcn@latest init` no passo seguinte, mas pré-criar placeholder vazio):
  ```ts
  import type { Config } from 'tailwindcss';
  export default {
    darkMode: 'class',
    content: ['./index.html', './src/**/*.{ts,tsx}'],
    theme: { extend: {} },
    plugins: []
  } satisfies Config;
  ```

- [ ] **Step 6 — `postcss.config.js`:**
  ```js
  export default {
    plugins: { tailwindcss: {}, autoprefixer: {} }
  };
  ```

- [ ] **Step 7 — `src/index.css`:**
  ```css
  @tailwind base;
  @tailwind components;
  @tailwind utilities;

  @layer base {
    :root { color-scheme: dark; }
    html, body, #root { height: 100%; }
    body { @apply bg-slate-950 text-slate-100 antialiased; }
  }
  ```

- [ ] **Step 8 — `index.html`:**
  ```html
  <!doctype html>
  <html lang="pt-br" class="dark">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>DAP Prime</title>
    </head>
    <body>
      <div id="root"></div>
      <script type="module" src="/src/main.tsx"></script>
    </body>
  </html>
  ```

- [ ] **Step 9 — `src/main.tsx`:**
  ```tsx
  import React from 'react';
  import ReactDOM from 'react-dom/client';
  import App from './App';
  import './index.css';

  ReactDOM.createRoot(document.getElementById('root')!).render(
    <React.StrictMode><App /></React.StrictMode>
  );
  ```

- [ ] **Step 10 — `src/App.tsx` (placeholder, Agent 0.6 expande com rotas):**
  ```tsx
  export default function App() {
    return <div className="p-8 text-2xl">DAP Prime — scaffold ok</div>;
  }
  ```

- [ ] **Step 11 — rodar e validar:**
  ```bash
  pnpm dev
  ```
  Expected: abre em `http://localhost:5174` mostrando "DAP Prime — scaffold ok".

- [ ] **Step 12 — commit:**
  ```bash
  git add .
  git commit -m "chore: configure vite, typescript, tailwind"
  ```

### Task 0.4: Instalar shadcn/ui + componentes base

- [ ] **Step 1 — rodar init:**
  ```bash
  pnpm dlx shadcn@latest init -d
  ```
  (resposta: style = new-york, base color = slate, css vars = yes)

- [ ] **Step 2 — instalar componentes essenciais:**
  ```bash
  pnpm dlx shadcn@latest add button input label card dialog form \
    select textarea tabs dropdown-menu sonner table badge \
    calendar popover separator
  ```

- [ ] **Step 3 — validar que `src/components/ui/` foi criado** com os arquivos acima.

- [ ] **Step 4 — commit:**
  ```bash
  git add .
  git commit -m "chore: install shadcn/ui base components"
  ```

### Task 0.5: Supabase migration + seed

**Files:** Create `supabase/migrations/001_prime_schema.sql`, `supabase/migrations/002_prime_seed.sql`, `.env.example`, `.env.local`

- [ ] **Step 1 — `supabase/migrations/001_prime_schema.sql`:** copiar o SQL exato do spec (seção "Schema") — tabelas `clientes`, `veiculos`, enum `os_status`, `ordens_servico`, `agendamentos`, índices, triggers, RLS policies.

- [ ] **Step 2 — `supabase/migrations/002_prime_seed.sql`:**
  ```sql
  -- Seed V1: dados mínimos para dev + E2E
  insert into prime.clientes (id, nome, cpf, telefone, email, cidade, estado) values
    ('11111111-1111-1111-1111-111111111111', 'João Silva', '123.456.789-00', '(11) 99999-1111', 'joao@example.com', 'São Paulo', 'SP'),
    ('22222222-2222-2222-2222-222222222222', 'Maria Santos', '987.654.321-00', '(11) 99999-2222', 'maria@example.com', 'São Paulo', 'SP'),
    ('33333333-3333-3333-3333-333333333333', 'Carlos Oliveira', '555.444.333-22', '(11) 99999-3333', null, 'São Paulo', 'SP');

  insert into prime.veiculos (id, cliente_id, placa, marca, modelo, ano, cor, km_atual) values
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', '11111111-1111-1111-1111-111111111111', 'ABC1D23', 'BMW',      '320i',       2020, 'Preto',   45000),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2', '11111111-1111-1111-1111-111111111111', 'XYZ9K88', 'Audi',     'A4',         2019, 'Branco',  67000),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1', '22222222-2222-2222-2222-222222222222', 'DEF4G56', 'Mercedes', 'C180',       2021, 'Prata',   28000),
    ('cccccccc-cccc-cccc-cccc-ccccccccccc1', '33333333-3333-3333-3333-333333333333', 'GHI7J89', 'VW',       'Golf GTI',   2018, 'Vermelho', 89000);

  insert into prime.ordens_servico (veiculo_id, cliente_id, status, motivo, valor_total, km_entrada) values
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', '11111111-1111-1111-1111-111111111111', 'em_execucao',          'Troca de óleo e filtros',    850.00, 45100),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1', '22222222-2222-2222-2222-222222222222', 'aguardando_aprovacao', 'Revisão 30.000 km',         2400.00, 28050);

  insert into prime.agendamentos (cliente_id, veiculo_id, data_hora, motivo) values
    ('33333333-3333-3333-3333-333333333333', 'cccccccc-cccc-cccc-cccc-ccccccccccc1', now() + interval '2 days', 'Diagnóstico ruído suspensão'),
    ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2', now() + interval '5 days', 'Revisão anual');
  ```

- [ ] **Step 3 — `.env.example`:**
  ```
  VITE_SUPABASE_URL=https://your-project.supabase.co
  VITE_SUPABASE_ANON_KEY=your-anon-key
  ```

- [ ] **Step 4 — `.env.local`** (copiar de `C:\dev\dap4\.env`, usar a mesma URL e anon key).

- [ ] **Step 5 — aplicar migrations** via Supabase Dashboard → SQL Editor (copiar e executar 001, depois 002). Alternativa: `supabase db push` se usar Supabase CLI.

- [ ] **Step 6 — validar no dashboard:** schema `prime` criado, 4 tabelas, 1 enum, 3 clientes + 4 veículos + 2 OS + 2 agendamentos.

- [ ] **Step 7 — commit:**
  ```bash
  git add supabase/ .env.example
  git commit -m "feat(db): prime schema + seed"
  ```

### Task 0.6: Supabase client + auth + routes

**Files:** Create `src/lib/supabase.ts`, `src/lib/query-client.ts`, `src/auth/AuthProvider.tsx`, `src/auth/useAuth.ts`, `src/auth/AuthGuard.tsx`, `src/auth/LoginPage.tsx`, `src/components/layout/AppShell.tsx`, `src/components/layout/Sidebar.tsx`, `src/components/layout/Topbar.tsx`, `src/routes.tsx`. Modify `src/App.tsx`.

- [ ] **Step 1 — `src/lib/supabase.ts`:**
  ```ts
  import { createClient } from '@supabase/supabase-js';

  const url = import.meta.env.VITE_SUPABASE_URL;
  const key = import.meta.env.VITE_SUPABASE_ANON_KEY;
  if (!url || !key) throw new Error('Missing Supabase env vars');

  export const supabase = createClient(url, key, {
    db: { schema: 'prime' },
    auth: { persistSession: true, autoRefreshToken: true }
  });
  ```

- [ ] **Step 2 — `src/lib/query-client.ts`:**
  ```ts
  import { QueryClient } from '@tanstack/react-query';
  export const queryClient = new QueryClient({
    defaultOptions: { queries: { staleTime: 30_000, retry: 1 } }
  });
  ```

- [ ] **Step 3 — `src/auth/AuthProvider.tsx`:**
  ```tsx
  import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
  import type { Session, User } from '@supabase/supabase-js';
  import { supabase } from '@/lib/supabase';

  type AuthCtx = { user: User | null; session: Session | null; loading: boolean };
  const Ctx = createContext<AuthCtx>({ user: null, session: null, loading: true });
  export const useAuthCtx = () => useContext(Ctx);

  export function AuthProvider({ children }: { children: ReactNode }) {
    const [session, setSession] = useState<Session | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
      supabase.auth.getSession().then(({ data }) => { setSession(data.session); setLoading(false); });
      const { data: sub } = supabase.auth.onAuthStateChange((_e, s) => setSession(s));
      return () => sub.subscription.unsubscribe();
    }, []);

    return <Ctx.Provider value={{ user: session?.user ?? null, session, loading }}>{children}</Ctx.Provider>;
  }
  ```

- [ ] **Step 4 — `src/auth/useAuth.ts`:**
  ```ts
  import { supabase } from '@/lib/supabase';
  import { useAuthCtx } from './AuthProvider';

  export function useAuth() {
    const ctx = useAuthCtx();
    return {
      ...ctx,
      signIn: (email: string, password: string) => supabase.auth.signInWithPassword({ email, password }),
      signOut: () => supabase.auth.signOut()
    };
  }
  ```

- [ ] **Step 5 — `src/auth/AuthGuard.tsx`:**
  ```tsx
  import { ReactNode } from 'react';
  import { Redirect } from 'wouter';
  import { useAuth } from './useAuth';

  export function AuthGuard({ children }: { children: ReactNode }) {
    const { user, loading } = useAuth();
    if (loading) return <div className="p-8">Carregando…</div>;
    if (!user) return <Redirect to="/login" />;
    return <>{children}</>;
  }
  ```

- [ ] **Step 6 — `src/auth/LoginPage.tsx`:** form com email/senha (React Hook Form + Zod + shadcn). Em sucesso, `window.location.hash = '/'`.

- [ ] **Step 7 — `src/components/layout/AppShell.tsx`:** layout com sidebar fixa + topbar + `<main>{children}</main>`.

- [ ] **Step 8 — `src/components/layout/Sidebar.tsx`:** navegação para `/`, `/clientes`, `/os`, `/patio`, `/agendamentos`. Ícones Lucide.

- [ ] **Step 9 — `src/components/layout/Topbar.tsx`:** mostra email do user + botão "Sair" (chama `signOut`).

- [ ] **Step 10 — `src/routes.tsx`:** exporta array de rotas. **Placeholders** para páginas que os Agents 1/2/3 criam (Agent 0 só cria stubs "WIP" para não quebrar navegação):
  ```tsx
  import { Route, Switch } from 'wouter';
  import { LoginPage } from '@/auth/LoginPage';
  import { AuthGuard } from '@/auth/AuthGuard';
  import { AppShell } from '@/components/layout/AppShell';

  const Stub = ({ name }: { name: string }) => <div className="p-8">WIP — {name}</div>;

  export function Routes() {
    return (
      <Switch>
        <Route path="/login" component={LoginPage} />
        <Route>
          <AuthGuard>
            <AppShell>
              <Switch>
                <Route path="/" component={() => <Stub name="Dashboard" />} />
                <Route path="/clientes" component={() => <Stub name="Clientes" />} />
                <Route path="/clientes/novo" component={() => <Stub name="Novo Cliente" />} />
                <Route path="/clientes/:id" component={() => <Stub name="Cliente" />} />
                <Route path="/veiculos/novo" component={() => <Stub name="Novo Veículo" />} />
                <Route path="/veiculos/:id" component={() => <Stub name="Veículo" />} />
                <Route path="/os" component={() => <Stub name="OS" />} />
                <Route path="/os/nova" component={() => <Stub name="Nova OS" />} />
                <Route path="/os/:id" component={() => <Stub name="OS Detail" />} />
                <Route path="/patio" component={() => <Stub name="Pátio" />} />
                <Route path="/agendamentos" component={() => <Stub name="Agendamentos" />} />
                <Route path="/agendamentos/novo" component={() => <Stub name="Novo Agendamento" />} />
              </Switch>
            </AppShell>
          </AuthGuard>
        </Route>
      </Switch>
    );
  }
  ```

- [ ] **Step 11 — atualizar `src/App.tsx`:**
  ```tsx
  import { QueryClientProvider } from '@tanstack/react-query';
  import { Router } from 'wouter';
  import { useHashLocation } from 'wouter/use-hash-location';
  import { Toaster } from 'sonner';
  import { AuthProvider } from '@/auth/AuthProvider';
  import { Routes } from '@/routes';
  import { queryClient } from '@/lib/query-client';

  export default function App() {
    return (
      <QueryClientProvider client={queryClient}>
        <AuthProvider>
          <Router hook={useHashLocation}>
            <Routes />
          </Router>
          <Toaster richColors />
        </AuthProvider>
      </QueryClientProvider>
    );
  }
  ```

- [ ] **Step 12 — validar:** `pnpm dev`, abrir `#/login`, criar user teste no Supabase Dashboard → Auth → Users (email `consultor@dap.local` + senha). Logar, deve ir ao Dashboard stub. Sidebar navega para todos stubs.

- [ ] **Step 13 — commit:**
  ```bash
  git add .
  git commit -m "feat(auth): supabase client + auth provider + routes + app shell"
  ```

### Task 0.6b: Tests setup

**Files:** Create `tests/setup.ts`, `playwright.config.ts`, `tests/e2e/smoke.spec.ts`

- [ ] **Step 1 — `tests/setup.ts`:**
  ```ts
  import '@testing-library/jest-dom';
  ```

- [ ] **Step 2 — `playwright.config.ts`:**
  ```ts
  import { defineConfig, devices } from '@playwright/test';
  export default defineConfig({
    testDir: './tests/e2e',
    fullyParallel: false,
    webServer: {
      command: 'pnpm dev',
      url: 'http://localhost:5174',
      reuseExistingServer: !process.env.CI
    },
    use: { baseURL: 'http://localhost:5174', trace: 'on-first-retry' },
    projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }]
  });
  ```

- [ ] **Step 3 — `tests/e2e/smoke.spec.ts`:**
  ```ts
  import { test, expect } from '@playwright/test';
  test('login page loads', async ({ page }) => {
    await page.goto('/#/login');
    await expect(page.getByRole('heading', { name: /entrar/i })).toBeVisible();
  });
  ```

- [ ] **Step 4 — rodar:**
  ```bash
  pnpm playwright install chromium
  pnpm test:e2e
  ```
  Expected: 1 test passa.

- [ ] **Step 5 — commit:**
  ```bash
  git add .
  git commit -m "test: setup vitest + playwright + smoke e2e"
  ```

### Task 0.7: CLAUDE.md do repo + gate final

**Files:** Create `docs/CLAUDE.md`

- [ ] **Step 1 — `docs/CLAUDE.md`** (conciso, pra subagents entenderem rapidamente):
  ```markdown
  # DAP Prime — CLAUDE.md

  Portal do consultor/admin da Doctor Auto Prime. SPA React + Vite em Vercel, Supabase direto.

  ## Stack
  React 18 + TS + Vite 7 + Tailwind + shadcn/ui + Wouter (hash) + TanStack Query + @dnd-kit + Supabase JS.

  ## Convenções
  - Features auto-contidas em `src/features/<nome>/` (api + hooks + schema + components + pages).
  - Supabase client em `src/lib/supabase.ts` (schema default `prime`).
  - Nunca mutar estado — TanStack Query `useMutation` com `onSuccess: invalidateQueries`.
  - Forms: React Hook Form + zodResolver.
  - Dark mode only em V1.
  - Toasts via sonner.
  - Rotas hash-based.

  ## Comandos
  - `pnpm dev` — dev server :5174
  - `pnpm test` — vitest
  - `pnpm test:e2e` — playwright
  - `pnpm build` — build produção

  ## Supabase
  Schema `prime` compartilhado com DAP 4.0 holding. RLS single-policy `auth.role() = 'authenticated'`.

  ## Spec + Plano
  - Spec: `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\DAP 4.0\Specs\2026-04-18-dap-prime-v1-design.md`
  - Plano: `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\DAP 4.0\Specs\2026-04-18-dap-prime-v1-plan.md`
  ```

- [ ] **Step 2 — rodar smoke completo:** `pnpm dev` + `pnpm test:e2e` + login manual no browser → navegar todas as rotas (stubs).

- [ ] **Step 3 — commit + tag:**
  ```bash
  git add docs/CLAUDE.md
  git commit -m "docs: repo CLAUDE.md"
  git tag milestone-0-scaffold
  ```

> **Gate:** Milestone 0 só é considerado completo quando `pnpm dev` sobe, login funciona, sidebar navega todos os stubs, `pnpm test:e2e` passa. Se algo falha, fix antes de abrir os paralelos.

---

## MILESTONE 1 — Agent 1: Clientes + Veículos (paralelo)

> Rodar em worktree `feat/clientes-veiculos`. Independente do Agent 2 e 3. Toca só `src/features/clientes/` e `src/features/veiculos/` + atualiza `src/routes.tsx` nos stubs correspondentes.

### Task 1.1: Types + Zod schemas

**Files:** Create `src/features/clientes/types.ts`, `src/features/clientes/schema.ts`, `src/features/veiculos/types.ts`, `src/features/veiculos/schema.ts`

- [ ] **Step 1 — `src/features/clientes/types.ts`:**
  ```ts
  export type Cliente = {
    id: string;
    nome: string;
    cpf: string | null;
    telefone: string;
    email: string | null;
    endereco: string | null;
    cidade: string | null;
    estado: string | null;
    cep: string | null;
    observacoes: string | null;
    created_at: string;
    updated_at: string;
  };
  export type ClienteInsert = Omit<Cliente, 'id' | 'created_at' | 'updated_at'>;
  export type ClienteUpdate = Partial<ClienteInsert>;
  ```

- [ ] **Step 2 — `src/features/clientes/schema.ts`:**
  ```ts
  import { z } from 'zod';
  export const clienteSchema = z.object({
    nome: z.string().min(2, 'Nome mínimo 2 caracteres'),
    cpf: z.string().regex(/^\d{3}\.\d{3}\.\d{3}-\d{2}$|^$/, 'CPF inválido').optional().or(z.literal('')),
    telefone: z.string().min(8, 'Telefone obrigatório'),
    email: z.string().email('Email inválido').optional().or(z.literal('')),
    endereco: z.string().optional().or(z.literal('')),
    cidade: z.string().optional().or(z.literal('')),
    estado: z.string().length(2).optional().or(z.literal('')),
    cep: z.string().optional().or(z.literal('')),
    observacoes: z.string().optional().or(z.literal(''))
  });
  export type ClienteFormValues = z.infer<typeof clienteSchema>;
  ```

- [ ] **Step 3 — `src/features/veiculos/types.ts`:**
  ```ts
  export type Veiculo = {
    id: string;
    cliente_id: string;
    placa: string;
    marca: string;
    modelo: string;
    ano: number | null;
    cor: string | null;
    combustivel: string | null;
    km_atual: number | null;
    observacoes: string | null;
    created_at: string;
    updated_at: string;
  };
  export type VeiculoInsert = Omit<Veiculo, 'id' | 'created_at' | 'updated_at'>;
  ```

- [ ] **Step 4 — `src/features/veiculos/schema.ts`:**
  ```ts
  import { z } from 'zod';
  const placaRegex = /^[A-Z]{3}\d[A-Z0-9]\d{2}$/;  // Mercosul + legado
  export const veiculoSchema = z.object({
    cliente_id: z.string().uuid(),
    placa: z.string().regex(placaRegex, 'Placa inválida (ex: ABC1D23)'),
    marca: z.string().min(1),
    modelo: z.string().min(1),
    ano: z.coerce.number().int().min(1980).max(new Date().getFullYear() + 1).optional().or(z.literal('')),
    cor: z.string().optional().or(z.literal('')),
    combustivel: z.string().optional().or(z.literal('')),
    km_atual: z.coerce.number().int().min(0).optional().or(z.literal('')),
    observacoes: z.string().optional().or(z.literal(''))
  });
  export type VeiculoFormValues = z.infer<typeof veiculoSchema>;
  ```

- [ ] **Step 5 — commit:**
  ```bash
  git add src/features/clientes src/features/veiculos
  git commit -m "feat(clientes,veiculos): types + zod schemas"
  ```

### Task 1.2: API layer (Supabase queries/mutations)

**Files:** Create `src/features/clientes/api.ts`, `src/features/veiculos/api.ts`

- [ ] **Step 1 — `src/features/clientes/api.ts`:**
  ```ts
  import { supabase } from '@/lib/supabase';
  import type { Cliente, ClienteInsert, ClienteUpdate } from './types';

  export async function listClientes(search?: string): Promise<Cliente[]> {
    let q = supabase.from('clientes').select('*').order('nome');
    if (search) q = q.or(`nome.ilike.%${search}%,cpf.ilike.%${search}%,telefone.ilike.%${search}%`);
    const { data, error } = await q;
    if (error) throw error;
    return data ?? [];
  }

  export async function getCliente(id: string): Promise<Cliente> {
    const { data, error } = await supabase.from('clientes').select('*').eq('id', id).single();
    if (error) throw error;
    return data;
  }

  export async function createCliente(payload: ClienteInsert): Promise<Cliente> {
    const { data, error } = await supabase.from('clientes').insert(payload).select().single();
    if (error) throw error;
    return data;
  }

  export async function updateCliente(id: string, patch: ClienteUpdate): Promise<Cliente> {
    const { data, error } = await supabase.from('clientes').update(patch).eq('id', id).select().single();
    if (error) throw error;
    return data;
  }

  export async function deleteCliente(id: string): Promise<void> {
    const { error } = await supabase.from('clientes').delete().eq('id', id);
    if (error) throw error;
  }
  ```

- [ ] **Step 2 — `src/features/veiculos/api.ts`:**
  ```ts
  import { supabase } from '@/lib/supabase';
  import type { Veiculo, VeiculoInsert } from './types';

  export async function listVeiculosByCliente(cliente_id: string): Promise<Veiculo[]> {
    const { data, error } = await supabase.from('veiculos').select('*').eq('cliente_id', cliente_id).order('created_at', { ascending: false });
    if (error) throw error;
    return data ?? [];
  }

  export async function searchVeiculos(q: string): Promise<Veiculo[]> {
    const { data, error } = await supabase.from('veiculos').select('*').ilike('placa', `%${q.toUpperCase()}%`).limit(10);
    if (error) throw error;
    return data ?? [];
  }

  export async function getVeiculo(id: string): Promise<Veiculo> {
    const { data, error } = await supabase.from('veiculos').select('*').eq('id', id).single();
    if (error) throw error;
    return data;
  }

  export async function createVeiculo(payload: VeiculoInsert): Promise<Veiculo> {
    const clean = Object.fromEntries(Object.entries(payload).map(([k, v]) => [k, v === '' ? null : v])) as VeiculoInsert;
    const { data, error } = await supabase.from('veiculos').insert(clean).select().single();
    if (error) throw error;
    return data;
  }

  export async function updateVeiculo(id: string, patch: Partial<VeiculoInsert>): Promise<Veiculo> {
    const clean = Object.fromEntries(Object.entries(patch).map(([k, v]) => [k, v === '' ? null : v]));
    const { data, error } = await supabase.from('veiculos').update(clean).eq('id', id).select().single();
    if (error) throw error;
    return data;
  }

  export async function deleteVeiculo(id: string): Promise<void> {
    const { error } = await supabase.from('veiculos').delete().eq('id', id);
    if (error) throw error;
  }
  ```

  > **Aplicar o mesmo `'' → null` sanitize em `clientes/api.ts` createCliente/updateCliente** (fix retroativo Task 1.2 step 1 — campos opcionais vazios do form quebram FK/UNIQUE se mandados como string vazia).

- [ ] **Step 3 — commit:**
  ```bash
  git commit -am "feat(clientes,veiculos): supabase api layer"
  ```

### Task 1.3: Hooks (TanStack Query)

**Files:** Create `src/features/clientes/hooks.ts`, `src/features/veiculos/hooks.ts`

- [ ] **Step 1 — `src/features/clientes/hooks.ts`:**
  ```ts
  import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
  import { toast } from 'sonner';
  import * as api from './api';
  import type { ClienteInsert, ClienteUpdate } from './types';

  export const useClientes = (search?: string) =>
    useQuery({ queryKey: ['clientes', { search }], queryFn: () => api.listClientes(search) });

  export const useCliente = (id: string | undefined) =>
    useQuery({ queryKey: ['cliente', id], queryFn: () => api.getCliente(id!), enabled: !!id });

  export function useCreateCliente() {
    const qc = useQueryClient();
    return useMutation({
      mutationFn: (p: ClienteInsert) => api.createCliente(p),
      onSuccess: (c) => { qc.invalidateQueries({ queryKey: ['clientes'] }); toast.success(`Cliente ${c.nome} criado`); },
      onError: (e: Error) => toast.error(e.message)
    });
  }

  export function useUpdateCliente() {
    const qc = useQueryClient();
    return useMutation({
      mutationFn: ({ id, patch }: { id: string; patch: ClienteUpdate }) => api.updateCliente(id, patch),
      onSuccess: (c) => {
        qc.invalidateQueries({ queryKey: ['clientes'] });
        qc.invalidateQueries({ queryKey: ['cliente', c.id] });
        toast.success('Cliente atualizado');
      },
      onError: (e: Error) => toast.error(e.message)
    });
  }
  ```

- [ ] **Step 2 — `src/features/veiculos/hooks.ts`:**
  ```ts
  import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
  import { toast } from 'sonner';
  import * as api from './api';
  import type { VeiculoInsert } from './types';

  export const useVeiculosByCliente = (cliente_id: string | undefined) =>
    useQuery({ queryKey: ['veiculos', { cliente_id }], queryFn: () => api.listVeiculosByCliente(cliente_id!), enabled: !!cliente_id });

  export const useSearchVeiculos = (q: string) =>
    useQuery({ queryKey: ['veiculos-search', q], queryFn: () => api.searchVeiculos(q), enabled: q.length >= 2 });

  export const useVeiculo = (id: string | undefined) =>
    useQuery({ queryKey: ['veiculo', id], queryFn: () => api.getVeiculo(id!), enabled: !!id });

  export function useCreateVeiculo() {
    const qc = useQueryClient();
    return useMutation({
      mutationFn: (p: VeiculoInsert) => api.createVeiculo(p),
      onSuccess: (v) => { qc.invalidateQueries({ queryKey: ['veiculos'] }); toast.success(`Veículo ${v.placa} criado`); },
      onError: (e: Error) => toast.error(e.message)
    });
  }

  export function useUpdateVeiculo() {
    const qc = useQueryClient();
    return useMutation({
      mutationFn: ({ id, patch }: { id: string; patch: Partial<VeiculoInsert> }) => api.updateVeiculo(id, patch),
      onSuccess: (v) => {
        qc.invalidateQueries({ queryKey: ['veiculos'] });
        qc.invalidateQueries({ queryKey: ['veiculo', v.id] });
        toast.success('Veículo atualizado');
      },
      onError: (e: Error) => toast.error(e.message)
    });
  }

  export function useDeleteVeiculo() {
    const qc = useQueryClient();
    return useMutation({
      mutationFn: (id: string) => api.deleteVeiculo(id),
      onSuccess: () => { qc.invalidateQueries({ queryKey: ['veiculos'] }); toast.success('Veículo removido'); },
      onError: (e: Error) => toast.error(e.message)
    });
  }
  ```

- [ ] **Step 3 — commit:**
  ```bash
  git commit -am "feat(clientes,veiculos): tanstack query hooks"
  ```

### Task 1.4: Unit test — validators

**Files:** Create `tests/unit/features/clientes.schema.test.ts`, `tests/unit/features/veiculos.schema.test.ts`

- [ ] **Step 1 — escrever testes que falham:** coverar placa válida/inválida, CPF válido/inválido/vazio, email válido/inválido/vazio, nome mínimo.
  ```ts
  import { describe, it, expect } from 'vitest';
  import { veiculoSchema } from '@/features/veiculos/schema';

  describe('veiculoSchema', () => {
    it('aceita placa Mercosul', () => {
      const r = veiculoSchema.safeParse({ cliente_id: '11111111-1111-1111-1111-111111111111', placa: 'ABC1D23', marca: 'BMW', modelo: '320i' });
      expect(r.success).toBe(true);
    });
    it('rejeita placa malformada', () => {
      const r = veiculoSchema.safeParse({ cliente_id: '11111111-1111-1111-1111-111111111111', placa: 'XXX', marca: 'X', modelo: 'Y' });
      expect(r.success).toBe(false);
    });
    it('rejeita ano futuro absurdo', () => {
      const r = veiculoSchema.safeParse({ cliente_id: '11111111-1111-1111-1111-111111111111', placa: 'ABC1D23', marca: 'BMW', modelo: '320i', ano: 2099 });
      expect(r.success).toBe(false);
    });
  });
  ```

- [ ] **Step 2 — `pnpm test`** — expected: testes passam (schemas já existem).

- [ ] **Step 3 — commit:**
  ```bash
  git add tests/
  git commit -m "test(clientes,veiculos): schema validation"
  ```

### Task 1.5: ClienteForm + VeiculoForm components

**Files:** Create `src/features/clientes/ClienteForm.tsx`, `src/features/veiculos/VeiculoForm.tsx`

- [ ] **Step 1 — `ClienteForm.tsx`:** React Hook Form com `zodResolver(clienteSchema)`. Fields: nome, cpf, telefone, email, endereco, cidade, estado (select UF), cep, observacoes. Props: `defaultValues?`, `onSubmit(values)`. Usar shadcn `<Form>`, `<FormField>`, `<Input>`, `<Textarea>`.

- [ ] **Step 2 — `VeiculoForm.tsx`:** similar. Fields: placa (uppercase automático), marca, modelo, ano, cor, combustivel (select: Gasolina/Etanol/Flex/Diesel/Híbrido/Elétrico), km_atual, observacoes. `cliente_id` é prop oculta.

- [ ] **Step 3 — commit:**
  ```bash
  git commit -am "feat(clientes,veiculos): form components"
  ```

### Task 1.6: ClienteCard, ClientesList, ClienteDetail

**Files:** Create `src/features/clientes/ClienteCard.tsx`, `src/features/clientes/ClientesList.tsx`, `src/features/clientes/ClienteDetail.tsx`

- [ ] **Step 1 — `ClienteCard.tsx`:** shadcn Card mostrando nome, telefone, cidade/UF. Click → `setLocation('/clientes/' + id)`.

- [ ] **Step 2 — `ClientesList.tsx`:** recebe `clientes: Cliente[]`, renderiza grid responsive de Cards. Mostra `EmptyState` se vazio.

- [ ] **Step 3 — `ClienteDetail.tsx`:** recebe `cliente: Cliente`. Mostra todos os campos em Card. Abaixo: lista de veículos (usa `useVeiculosByCliente`) + botão "+ Veículo" que navega para `/veiculos/novo?cliente_id=<id>`. Abaixo dos veículos: (placeholder) histórico de OS — Agent 2 pode estender depois, Agent 1 deixa um texto "Histórico de OS será mostrado aqui".

- [ ] **Step 4 — commit:**
  ```bash
  git commit -am "feat(clientes): card, list, detail components"
  ```

### Task 1.7: VeiculoCard, VeiculoDetail

- [ ] **Step 1 — `VeiculoCard.tsx`:** mostra placa (monospace grande), marca/modelo/ano, km. Click → `/veiculos/:id`.

- [ ] **Step 2 — `VeiculoDetail.tsx`:** recebe `veiculo: Veiculo`. Renderiza Card com todos os campos (placa monospace grande em destaque, marca/modelo/ano/cor, km_atual, combustivel, observacoes). Link para cliente via `useCliente(veiculo.cliente_id)`. Placeholder "Histórico de OS será mostrado aqui" (Agent 2 estende).

- [ ] **Step 3 — commit:**
  ```bash
  git commit -am "feat(veiculos): card + detail components"
  ```

### Task 1.8: Pages + wire routes

**Files:** Create `src/features/clientes/pages/ClientesPage.tsx`, `NovoClientePage.tsx`, `ClienteDetailPage.tsx`, `src/features/veiculos/pages/NovoVeiculoPage.tsx`, `VeiculoDetailPage.tsx`. Modify `src/routes.tsx`.

- [ ] **Step 1 — `ClientesPage.tsx`:** search bar (state local, debounce 300ms) + `useClientes(search)` + `<ClientesList>` + botão "+ Novo Cliente" (topbar).

- [ ] **Step 2 — `NovoClientePage.tsx`:** `<ClienteForm>` + `useCreateCliente()`. Em sucesso, `setLocation('/clientes/' + novo.id)`.

- [ ] **Step 3 — `ClienteDetailPage.tsx`:** lê `:id` via `useParams`, chama `useCliente(id)`, renderiza `<ClienteDetail>` + botão "Editar" (abre Dialog com `<ClienteForm>` + `useUpdateCliente`).

- [ ] **Step 4 — `NovoVeiculoPage.tsx`:** lê `?cliente_id=` da URL, passa como prop do `<VeiculoForm>`. Em sucesso, `setLocation('/clientes/' + cliente_id)`.

- [ ] **Step 5 — `VeiculoDetailPage.tsx`:** análogo ao `ClienteDetailPage`.

- [ ] **Step 6 — atualizar `src/routes.tsx`:** substituir os Stubs de clientes/veiculos pelas páginas reais.

- [ ] **Step 7 — smoke manual:** `pnpm dev`, logar, criar cliente, criar veículo pra ele, editar, ver detalhes.

- [ ] **Step 8 — commit:**
  ```bash
  git add .
  git commit -m "feat(clientes,veiculos): pages + routes wired"
  ```

### Task 1.9: E2E — Cadastro cliente + veículo

**Files:** Create `tests/e2e/02-clientes-veiculos.spec.ts`

- [ ] **Step 1 — escrever teste:**
  ```ts
  import { test, expect } from '@playwright/test';

  // Assume user fixture já logado (beforeEach login helper — criar em tests/e2e/helpers/auth.ts)
  test('cadastra cliente e veículo', async ({ page }) => {
    await page.goto('/#/clientes/novo');
    await page.getByLabel('Nome').fill('Teste E2E');
    await page.getByLabel('Telefone').fill('(11) 91234-5678');
    await page.getByRole('button', { name: /salvar/i }).click();
    await expect(page).toHaveURL(/#\/clientes\/[a-f0-9-]+$/);
    await page.getByRole('button', { name: /\+ veículo/i }).click();
    await page.getByLabel('Placa').fill('TST2E26');
    await page.getByLabel('Marca').fill('Teste');
    await page.getByLabel('Modelo').fill('E2E');
    await page.getByRole('button', { name: /salvar/i }).click();
    await expect(page.getByText('TST2E26')).toBeVisible();
  });
  ```

- [ ] **Step 2 — criar helper login:** `tests/e2e/helpers/auth.ts` com função que preenche login e espera redirect.

- [ ] **Step 3 — `pnpm test:e2e`** → passa.

- [ ] **Step 4 — commit + tag:**
  ```bash
  git add tests/
  git commit -m "test(e2e): cadastro cliente + veiculo"
  git tag milestone-1-clientes-veiculos
  ```

---

## MILESTONE 2 — Agent 2: OS + Kanban (paralelo)

> Worktree `feat/os-kanban`. Independente dos outros. Toca `src/features/ordens-servico/` e `src/features/patio/` + atualiza stubs correspondentes em `src/routes.tsx`.

### Task 2.1: Types + status map + schema

**Files:** Create `src/features/ordens-servico/types.ts`, `status.ts`, `schema.ts`

- [ ] **Step 1 — `types.ts`:**
  ```ts
  export type OsStatus = 'recepcao' | 'diagnostico' | 'aguardando_aprovacao' | 'em_execucao' | 'pronto' | 'entregue';

  export type OrdemServico = {
    id: string;
    numero_os: number;
    veiculo_id: string;
    cliente_id: string;
    status: OsStatus;
    motivo: string;
    diagnostico: string | null;
    valor_total: number;
    km_entrada: number | null;
    data_entrada: string;
    data_saida: string | null;
    observacoes: string | null;
    created_by: string | null;
    created_at: string;
    updated_at: string;
  };
  export type OsInsert = Omit<OrdemServico, 'id' | 'numero_os' | 'created_at' | 'updated_at' | 'data_entrada'> & { data_entrada?: string };
  export type OsWithRel = OrdemServico & {
    veiculos: { placa: string; marca: string; modelo: string };
    clientes: { nome: string };
  };
  ```

- [ ] **Step 2 — `status.ts`:**
  ```ts
  import type { OsStatus } from './types';
  export const STATUS_ORDER: OsStatus[] = ['recepcao','diagnostico','aguardando_aprovacao','em_execucao','pronto','entregue'];
  export const STATUS_LABEL: Record<OsStatus, string> = {
    recepcao: 'Recepção',
    diagnostico: 'Diagnóstico',
    aguardando_aprovacao: 'Aguardando aprovação',
    em_execucao: 'Em execução',
    pronto: 'Pronto',
    entregue: 'Entregue'
  };
  export const STATUS_COLOR: Record<OsStatus, string> = {
    recepcao: 'bg-slate-500',
    diagnostico: 'bg-blue-500',
    aguardando_aprovacao: 'bg-amber-500',
    em_execucao: 'bg-indigo-500',
    pronto: 'bg-emerald-500',
    entregue: 'bg-slate-700'
  };
  ```

- [ ] **Step 3 — `schema.ts`:**
  ```ts
  import { z } from 'zod';
  export const osSchema = z.object({
    veiculo_id: z.string().uuid(),
    cliente_id: z.string().uuid(),
    motivo: z.string().min(3, 'Motivo obrigatório'),
    km_entrada: z.coerce.number().int().min(0).optional().or(z.literal('')),
    diagnostico: z.string().optional().or(z.literal('')),
    valor_total: z.coerce.number().min(0).default(0),
    observacoes: z.string().optional().or(z.literal(''))
  });
  export type OsFormValues = z.infer<typeof osSchema>;
  ```

- [ ] **Step 4 — commit:**
  ```bash
  git commit -am "feat(os): types + status map + schema"
  ```

### Task 2.2: API + hooks

**Files:** Create `src/features/ordens-servico/api.ts`, `hooks.ts`

- [ ] **Step 1 — `api.ts`:** queries:
  - `listOrdensServico(filters?)` — select com join `veiculos(placa, marca, modelo), clientes(nome)`, ordem por `numero_os desc`.
  - `listOrdensServicoByStatus()` — retorna `Record<OsStatus, OsWithRel[]>` para Kanban.
  - `getOrdemServico(id)`, `createOrdemServico(payload)`, `updateOsStatus(id, status, data_saida?)`, `updateOrdemServico(id, patch)`, `listOrdensServicoByVeiculo(veiculo_id)`.

- [ ] **Step 2 — `hooks.ts`:** `useOrdensServico`, `useOrdemServico(id)`, `useKanbanOrdens()` (query `listOrdensServicoByStatus`, `refetchInterval: 30_000`), `useCreateOs`, `useUpdateOsStatus` (optimistic update com rollback), `useUpdateOs`, `useOrdensServicoByVeiculo(veiculo_id)`.

- [ ] **Step 3 — commit:**
  ```bash
  git commit -am "feat(os): api + hooks"
  ```

### Task 2.3: Unit test — status transitions + value formatting

**Files:** Create `tests/unit/features/os.status.test.ts`

- [ ] **Step 1 — teste:**
  ```ts
  import { describe, it, expect } from 'vitest';
  import { STATUS_ORDER, STATUS_LABEL } from '@/features/ordens-servico/status';

  describe('OS status', () => {
    it('tem 6 status na ordem correta', () => {
      expect(STATUS_ORDER).toEqual(['recepcao','diagnostico','aguardando_aprovacao','em_execucao','pronto','entregue']);
    });
    it('todo status tem label humano', () => {
      STATUS_ORDER.forEach(s => expect(STATUS_LABEL[s]).toBeTruthy());
    });
  });
  ```

- [ ] **Step 2 — `pnpm test`** passa.

- [ ] **Step 3 — commit:**
  ```bash
  git commit -am "test(os): status map"
  ```

### Task 2.4: OsForm, OsCard, OsList

**Files:** Create `src/features/ordens-servico/OsForm.tsx`, `OsCard.tsx`, `OsList.tsx`

- [ ] **Step 1 — `OsForm.tsx`:** primeiro campo = seleção de veículo (usa `useVeiculosByCliente`? melhor: um Combobox que busca por placa no backend — cria `searchVeiculos(q)` em `veiculos/api.ts`). Quando seleciona veículo, preenche `cliente_id` automático. Demais campos do `osSchema`.

- [ ] **Step 2 — `OsCard.tsx`:** para Kanban + listas. Compacto: numero_os, placa, marca/modelo, motivo (truncado 1 linha), badge status, tempo no pátio (ex: "há 2h").

- [ ] **Step 3 — `OsList.tsx`:** tabela (shadcn Table) com colunas: #OS, Veículo, Cliente, Status (badge), Motivo, Entrada. Filtros: status (multi-select), texto. Paginação client-side (se volume baixo) ou server-side (mais de 200 itens).

- [ ] **Step 4 — commit:**
  ```bash
  git commit -am "feat(os): form, card, list components"
  ```

### Task 2.5: OsDetail

- [ ] **Step 1 — `OsDetail.tsx`:** todos os campos + info do veículo/cliente + timeline simples (data_entrada até agora). Ações: editar (Dialog com OsForm), mudar status (dropdown com próximos status válidos).

- [ ] **Step 2 — commit:**
  ```bash
  git commit -am "feat(os): detail component"
  ```

### Task 2.6: KanbanBoard + dnd-kit

**Files:** Create `src/features/patio/KanbanBoard.tsx`, `KanbanColumn.tsx`, `KanbanCard.tsx`

- [ ] **Step 1 — `KanbanCard.tsx`:** wrapper de `OsCard` + `useDraggable` do dnd-kit. Props: `os: OsWithRel`.
  ```tsx
  import { useDraggable } from '@dnd-kit/core';
  import { OsCard } from '@/features/ordens-servico/OsCard';
  import type { OsWithRel } from '@/features/ordens-servico/types';

  export function KanbanCard({ os }: { os: OsWithRel }) {
    const { attributes, listeners, setNodeRef, transform, isDragging } = useDraggable({ id: os.id });
    const style = transform ? { transform: `translate3d(${transform.x}px, ${transform.y}px, 0)`, opacity: isDragging ? 0.5 : 1 } : undefined;
    return (
      <div ref={setNodeRef} style={style} {...attributes} {...listeners}>
        <OsCard os={os} />
      </div>
    );
  }
  ```

- [ ] **Step 2 — `KanbanColumn.tsx`:** container com `useDroppable`. Props: `status: OsStatus`, `ordens: OsWithRel[]`.
  ```tsx
  import { useDroppable } from '@dnd-kit/core';
  import { KanbanCard } from './KanbanCard';
  import { STATUS_LABEL, STATUS_COLOR } from '@/features/ordens-servico/status';
  import type { OsStatus } from '@/features/ordens-servico/types';

  export function KanbanColumn({ status, ordens }: { status: OsStatus; ordens: any[] }) {
    const { setNodeRef, isOver } = useDroppable({ id: status });
    return (
      <div ref={setNodeRef} className={`flex flex-col gap-2 p-3 rounded-lg bg-slate-900/50 min-w-[280px] ${isOver ? 'ring-2 ring-blue-500' : ''}`}>
        <div className="flex items-center gap-2 mb-2">
          <span className={`w-2 h-2 rounded-full ${STATUS_COLOR[status]}`} />
          <h3 className="font-medium">{STATUS_LABEL[status]}</h3>
          <span className="text-xs text-slate-400">({ordens.length})</span>
        </div>
        {ordens.map(os => <KanbanCard key={os.id} os={os} />)}
      </div>
    );
  }
  ```

- [ ] **Step 3 — `KanbanBoard.tsx`:** `DndContext` + `onDragEnd` chama `useUpdateOsStatus`. Handle especial para `entregue`: abre Dialog pedindo confirmação + `data_saida` antes de aplicar.
  ```tsx
  import { DndContext, type DragEndEvent } from '@dnd-kit/core';
  import { useState } from 'react';
  import { KanbanColumn } from './KanbanColumn';
  import { useKanbanOrdens, useUpdateOsStatus } from '@/features/ordens-servico/hooks';
  import { STATUS_ORDER } from '@/features/ordens-servico/status';
  import type { OsStatus } from '@/features/ordens-servico/types';

  export function KanbanBoard() {
    const { data: byStatus = {}, isLoading } = useKanbanOrdens();
    const update = useUpdateOsStatus();
    const [pendingDelivery, setPendingDelivery] = useState<string | null>(null);

    function handleDragEnd(e: DragEndEvent) {
      const osId = e.active.id as string;
      const newStatus = e.over?.id as OsStatus | undefined;
      if (!newStatus) return;
      if (newStatus === 'entregue') { setPendingDelivery(osId); return; }
      update.mutate({ id: osId, status: newStatus });
    }

    if (isLoading) return <div className="p-8">Carregando pátio…</div>;
    return (
      <>
        <DndContext onDragEnd={handleDragEnd}>
          <div className="flex gap-3 overflow-x-auto pb-4">
            {STATUS_ORDER.map(s => <KanbanColumn key={s} status={s} ordens={byStatus[s] ?? []} />)}
          </div>
        </DndContext>
        {/* Dialog confirmação entrega aqui: input data_saida + confirmar → update.mutate({ id, status: 'entregue', data_saida }) */}
      </>
    );
  }
  ```

- [ ] **Step 4 — commit:**
  ```bash
  git commit -am "feat(patio): kanban board with dnd-kit"
  ```

### Task 2.7: Pages OS + Pátio

**Files:** Create `src/features/ordens-servico/pages/OsListPage.tsx`, `NovaOsPage.tsx`, `OsDetailPage.tsx`, `src/features/patio/pages/PatioPage.tsx`. Modify `src/routes.tsx`.

- [ ] **Step 1 — `OsListPage.tsx`:** `<OsList>` com filtros.

- [ ] **Step 2 — `NovaOsPage.tsx`:** lê `?veiculo_id=` opcional; `<OsForm>` + `useCreateOs`. Em sucesso, `setLocation('/os/' + nova.id)`.

- [ ] **Step 3 — `OsDetailPage.tsx`:** `useOrdemServico(id)` → `<OsDetail>`.

- [ ] **Step 4 — `PatioPage.tsx`:** `<KanbanBoard />` dentro de um container full-height.

- [ ] **Step 5 — atualizar `routes.tsx`** trocando Stubs pelas páginas reais.

- [ ] **Step 6 — smoke:** abrir `/patio`, arrastar card entre colunas, ver status persistir após reload.

- [ ] **Step 7 — commit:**
  ```bash
  git add .
  git commit -m "feat(os,patio): pages + routes"
  ```

### Task 2.8: E2E — Criar OS → mover no Kanban → entregar

**Files:** Create `tests/e2e/03-os-kanban.spec.ts`

- [ ] **Step 1 — escrever teste:**
  ```ts
  import { test, expect } from '@playwright/test';

  test('criar OS + mover no Kanban até entregar', async ({ page }) => {
    // Pressupõe seed com veículo placa ABC1D23
    await page.goto('/#/os/nova');
    await page.getByLabel('Veículo').fill('ABC1D23');
    await page.getByRole('option', { name: /ABC1D23/ }).click();
    await page.getByLabel('Motivo').fill('E2E test');
    await page.getByRole('button', { name: /salvar/i }).click();
    await expect(page).toHaveURL(/#\/os\/[a-f0-9-]+$/);

    // Ir pro pátio, ver OS em recepção, arrastar
    await page.goto('/#/patio');
    const card = page.getByText(/E2E test/).first();
    await expect(card).toBeVisible();
    // Drag programático dnd-kit (simulado — usar helper ou key events se dnd-kit permitir)
    // Alternativa: clicar no card → dropdown status → selecionar "Em execução"
  });
  ```

  > Nota: drag-and-drop com dnd-kit em Playwright é complicado. Alternativa aceitável: o `OsDetail` oferece um dropdown de status — testar via dropdown cobre a lógica de negócio (`useUpdateOsStatus`), e o teste de drag fica manual/visual por ora.

- [ ] **Step 2 — `pnpm test:e2e`** passa.

- [ ] **Step 3 — commit + tag:**
  ```bash
  git add .
  git commit -m "test(e2e): os + kanban flow"
  git tag milestone-2-os-kanban
  ```

---

## MILESTONE 3 — Agent 3: Agendamentos (paralelo)

> Worktree `feat/agendamentos`. Independente. Toca `src/features/agendamentos/` + atualiza stubs correspondentes.

### Task 3.1: Types + schema + api + hooks

**Files:** Create `src/features/agendamentos/types.ts`, `schema.ts`, `api.ts`, `hooks.ts`

- [ ] **Step 1 — `types.ts`:**
  ```ts
  export type Agendamento = {
    id: string;
    cliente_id: string;
    veiculo_id: string;
    data_hora: string;
    motivo: string;
    observacoes: string | null;
    os_id: string | null;
    created_by: string | null;
    created_at: string;
    updated_at: string;
  };
  export type AgendamentoInsert = Omit<Agendamento, 'id' | 'created_at' | 'updated_at' | 'os_id'>;
  export type AgendamentoWithRel = Agendamento & {
    veiculos: { placa: string; marca: string; modelo: string };
    clientes: { nome: string; telefone: string };
  };
  ```

- [ ] **Step 2 — `schema.ts`:**
  ```ts
  import { z } from 'zod';
  export const agendamentoSchema = z.object({
    cliente_id: z.string().uuid(),
    veiculo_id: z.string().uuid(),
    data_hora: z.string().datetime(),
    motivo: z.string().min(3),
    observacoes: z.string().optional().or(z.literal(''))
  });
  export type AgendamentoFormValues = z.infer<typeof agendamentoSchema>;
  ```

- [ ] **Step 3 — `api.ts`:**
  - `listAgendamentos(range?: { from: string; to: string })` — select com join `veiculos + clientes`.
  - `listAgendamentosHoje()` — filtro data_hora do dia, `os_id is null`.
  - `getAgendamento(id)`, `createAgendamento(payload)`, `deleteAgendamento(id)`.
  - `convertToOs(agendamentoId)` — em um Postgres RPC (recomendado) OU client-side transaction (insert ordens_servico + update agendamentos set os_id). Se RPC: criar função em migration `003_prime_convert_agendamento.sql`.

- [ ] **Step 4 — migration `supabase/migrations/003_prime_convert_agendamento.sql`:**
  ```sql
  create or replace function prime.convert_agendamento_to_os(p_agendamento_id uuid)
  returns prime.ordens_servico
  language plpgsql
  security invoker
  as $$
  declare
    v_ag prime.agendamentos;
    v_os prime.ordens_servico;
  begin
    select * into v_ag from prime.agendamentos where id = p_agendamento_id;
    if not found then raise exception 'Agendamento não encontrado'; end if;
    if v_ag.os_id is not null then raise exception 'Agendamento já convertido'; end if;

    insert into prime.ordens_servico (veiculo_id, cliente_id, motivo, status)
    values (v_ag.veiculo_id, v_ag.cliente_id, v_ag.motivo, 'recepcao')
    returning * into v_os;

    update prime.agendamentos set os_id = v_os.id where id = p_agendamento_id;
    return v_os;
  end;
  $$;
  ```
  Aplicar via Dashboard SQL Editor.

- [ ] **Step 5 — `hooks.ts`:** `useAgendamentos(range)`, `useAgendamentosHoje()`, `useCreateAgendamento`, `useConvertAgendamentoOs` (chama `supabase.rpc('convert_agendamento_to_os', { p_agendamento_id: id })` + invalida queries de agendamentos E ordens_servico).

- [ ] **Step 6 — commit:**
  ```bash
  git commit -am "feat(agendamentos): types, schema, api, hooks + rpc migration"
  ```

### Task 3.2: Form + Card + Calendar

**Files:** Create `src/features/agendamentos/AgendamentoForm.tsx`, `AgendamentoCard.tsx`, `CalendarView.tsx`

- [ ] **Step 1 — `AgendamentoForm.tsx`:** seleção cliente (Combobox busca `searchClientes(q)`) → depois veículos do cliente (select) → data+hora (date + time pickers shadcn) → motivo + observações.

- [ ] **Step 2 — `AgendamentoCard.tsx`:** compacto. Mostra hora, cliente, placa, motivo. Badge "Convertido" se `os_id !== null`. Botão "Converter em OS" se não convertido.

- [ ] **Step 3 — `CalendarView.tsx`:** usa shadcn Calendar (mês). Dias com agendamentos exibem badge com contagem. Click num dia → mostra lista de agendamentos do dia ao lado.

- [ ] **Step 4 — commit:**
  ```bash
  git commit -am "feat(agendamentos): form + card + calendar"
  ```

### Task 3.3: Pages + routes

**Files:** Create `src/features/agendamentos/pages/AgendamentosPage.tsx`, `NovoAgendamentoPage.tsx`. Modify `src/routes.tsx`.

- [ ] **Step 1 — `AgendamentosPage.tsx`:** `<CalendarView>` + lista do dia selecionado.

- [ ] **Step 2 — `NovoAgendamentoPage.tsx`:** `<AgendamentoForm>` + `useCreateAgendamento`. Em sucesso, `setLocation('/agendamentos')`.

- [ ] **Step 3 — atualizar `routes.tsx`**.

- [ ] **Step 4 — commit:**
  ```bash
  git add .
  git commit -m "feat(agendamentos): pages + routes"
  ```

### Task 3.4: E2E — Agendamento + conversão em OS

**Files:** Create `tests/e2e/04-agendamento-conversao.spec.ts`

- [ ] **Step 1 — teste:**
  ```ts
  import { test, expect } from '@playwright/test';
  test('cria agendamento e converte em OS', async ({ page }) => {
    await page.goto('/#/agendamentos/novo');
    // Selecionar cliente seeded, veículo, motivo, data
    await page.getByLabel('Cliente').fill('João');
    await page.getByRole('option', { name: /João Silva/ }).click();
    await page.getByLabel('Veículo').selectOption({ label: /ABC1D23/ });
    await page.getByLabel('Motivo').fill('Agendamento E2E');
    // Data +3 dias — ajustar no picker
    await page.getByRole('button', { name: /salvar/i }).click();

    await page.goto('/#/agendamentos');
    const card = page.getByText(/Agendamento E2E/).first();
    await card.getByRole('button', { name: /converter em os/i }).click();
    await expect(page.getByText(/Convertido/)).toBeVisible();

    await page.goto('/#/patio');
    await expect(page.getByText(/Agendamento E2E/)).toBeVisible();
  });
  ```

- [ ] **Step 2 — `pnpm test:e2e`** passa.

- [ ] **Step 3 — commit + tag:**
  ```bash
  git commit -am "test(e2e): agendamento + conversao"
  git tag milestone-3-agendamentos
  ```

---

## MILESTONE 4 — Agent 4: Dashboard + E2E + Deploy (sequential gate)

> Roda depois dos 3 paralelos mergearem em `main`. Finaliza.

### Task 4.1: Merge dos 3 worktrees

- [ ] **Step 1** — em `main`, merge dos branches:
  ```bash
  git checkout main
  git merge feat/clientes-veiculos
  git merge feat/os-kanban
  git merge feat/agendamentos
  ```
  Resolver conflitos em `routes.tsx` (todos 3 agents editam esse arquivo): manter todas as páginas reais.

- [ ] **Step 2** — `pnpm typecheck && pnpm test && pnpm test:e2e` — tudo verde.

- [ ] **Step 3 — commit de merge e tag:**
  ```bash
  git commit -am "merge: milestones 1+2+3"
  git tag milestone-merge
  ```

### Task 4.2: Dashboard page

**Files:** Create `src/features/dashboard/pages/DashboardPage.tsx`. Modify `src/routes.tsx`.

- [ ] **Step 1 — `DashboardPage.tsx`:** 4 seções:
  1. **KPIs** (cards): OS ativas (status != entregue), OS entregues hoje, agendamentos hoje, clientes cadastrados.
  2. **Agendados hoje** (lista compacta) com botões "Converter em OS".
  3. **Kanban overview** (só coluna de counts por status + link "Abrir pátio").
  4. **Atalhos**: "+ Cliente", "+ OS", "+ Agendamento".

- [ ] **Step 2 — atualizar `routes.tsx`** trocar Stub Dashboard pela página real.

- [ ] **Step 3 — commit:**
  ```bash
  git add .
  git commit -m "feat(dashboard): home page with kpis + agendados hoje + atalhos"
  ```

### Task 4.3: E2E — Busca por placa + Login

**Files:** Create `tests/e2e/05-busca-placa.spec.ts`, update `tests/e2e/01-login.spec.ts`

- [ ] **Step 1 — `01-login.spec.ts`** (expandir smoke para cobrir login real):
  ```ts
  import { test, expect } from '@playwright/test';
  test('login com user válido redireciona pro dashboard', async ({ page }) => {
    await page.goto('/#/login');
    await page.getByLabel('Email').fill(process.env.E2E_USER_EMAIL!);
    await page.getByLabel('Senha').fill(process.env.E2E_USER_PASSWORD!);
    await page.getByRole('button', { name: /entrar/i }).click();
    await expect(page).toHaveURL(/#\/$/);
    await expect(page.getByText(/OS ativas/i)).toBeVisible();
  });
  ```

- [ ] **Step 2 — `05-busca-placa.spec.ts`:**
  ```ts
  test('busca veículo por placa abre detalhes', async ({ page }) => {
    await page.goto('/#/');
    await page.getByPlaceholder(/buscar/i).fill('ABC1D23');
    await page.getByRole('option', { name: /ABC1D23/ }).click();
    await expect(page).toHaveURL(/#\/veiculos\/[a-f0-9-]+$/);
  });
  ```
  (Requer busca global no topbar — se não foi implementada, criar: `Topbar` ganha um SearchCombobox que busca placas. Agent 1 pode já ter feito; se não, Agent 4 adiciona.)

- [ ] **Step 3 — `pnpm test:e2e`** — todos os 5 specs verdes.

- [ ] **Step 4 — commit:**
  ```bash
  git add .
  git commit -m "test(e2e): login + busca placa (5 golden paths complete)"
  ```

### Task 4.4: Polish UI

- [ ] **Step 1** — EmptyStates em todas as listas.
- [ ] **Step 2** — LoadingStates (skeleton shadcn) onde há fetch.
- [ ] **Step 3** — ErrorBoundary global.
- [ ] **Step 4** — Responsividade: Kanban rola horizontal em mobile, forms empilham.
- [ ] **Step 5** — Motion: Framer Motion em transições de rota (fade 150ms) e cards do Kanban (layout animation).
- [ ] **Step 6 — commit:**
  ```bash
  git commit -am "polish: empty states + loading + motion + responsive"
  ```

### Task 4.5: Deploy Vercel

**Files:** Create `vercel.json`, `docs/DEPLOY.md`

- [ ] **Step 1 — `vercel.json`:**
  ```json
  { "framework": "vite", "buildCommand": "pnpm build", "outputDirectory": "dist" }
  ```

- [ ] **Step 2 — criar projeto no Vercel:**
  ```bash
  pnpm dlx vercel
  ```
  Setar env vars `VITE_SUPABASE_URL` + `VITE_SUPABASE_ANON_KEY`.

- [ ] **Step 3 — deploy preview:**
  ```bash
  pnpm dlx vercel --prod=false
  ```
  Smoke test no URL de preview: login + criar cliente + ver Kanban.

- [ ] **Step 4 — `docs/DEPLOY.md`** com passo a passo para quem re-deploy (env vars, comando, smoke test).

- [ ] **Step 5 — promover a produção:**
  ```bash
  pnpm dlx vercel --prod
  ```

- [ ] **Step 6 — commit + tag v1:**
  ```bash
  git add .
  git commit -m "chore: deploy config + docs"
  git tag v1.0.0
  ```

### Task 4.6: README final

**Files:** Modify `README.md`

- [ ] **Step 1** — README com: propósito, stack, como rodar local, como deploy, link pro spec/plan no vault, tabela de rotas, badge de build.

- [ ] **Step 2 — commit:**
  ```bash
  git commit -am "docs: complete README"
  ```

> **Gate V1 completo:** tag `v1.0.0`, deploy em produção funcional, 5 E2E verdes, login + cadastro + OS + Kanban + agendamento funcionando end-to-end em prod.

---

## Métricas de aceite (copiar do spec)

| Métrica | Target |
|---------|--------|
| Cadastro cliente+veículo | < 2 min |
| Kanban com 100 OS ativas | sem lag |
| Zero 500 em 1h uso | ✅ |
| 5 E2E golden paths verdes | ✅ |
| Coverage unit `src/lib` e schemas | ≥ 80% |
| Deploy Vercel + Supabase end-to-end | ✅ |

---

## Riscos conhecidos

- **Drag-drop Playwright:** dnd-kit + PW tem atrito. Workaround: testar lógica de status via dropdown no OsDetail. Drag manual fica no smoke visual.
- **Conflito `routes.tsx` no merge:** inevitável, mas trivial de resolver (manter todas as rotas). Pode-se evitar se cada Agent editar arquivo separado `routes-clientes.tsx` etc, mas complica mais do que resolve.
- **Migration idempotente:** SQL dos schemas não usa `if not exists` em tudo. Se rodar 2x, quebra. OK pro V1 (rodamos 1x no Dashboard), mas Agent 0 pode adicionar guards.
- **CPF único na tabela:** se dois clientes com mesmo CPF (erro de digitação), migration falha. Aceitável pro V1.
- **Numero_os global:** bigserial é global no schema `prime`. Quando multi-empresa, trocar para `empresa_id + sequência por empresa`. Documentado no spec V2 backlog.
