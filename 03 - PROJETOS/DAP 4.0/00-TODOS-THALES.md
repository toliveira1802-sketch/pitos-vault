---
title: TO-DOs do Thales — o que depende de mim
date: 2026-06-04
status: vivo
scope: ações e decisões que só o Thales pode executar
relacionado: "[[00-MAPA-ECOSSISTEMA]] · [[000-CANON]]"
---

# TO-DOs do Thales — o que depende de mim

> Itens que **bloqueiam** o avanço ou que **só você** pode fazer/decidir.
> Gerado na sessão de 2026-06-04 (subdomínios + consolidação do vault).
> Marca `[x]` ao concluir.

---

## 🔴 Segurança — urgente

- [ ] **Revogar o CF API token** usado hoje (`cfut_7tIK…`). Já fiz tudo que precisava com ele; expira sozinho em 2026-06-05, mas revoga em **dash.cloudflare.com/profile/api-tokens** pra não deixar ativo.

- [ ] **Rotacionar as 29 chaves** (sessão dedicada). Checklist completo e mascarado em `Infra/_secrets/KEY-INVENTORY.md`. Prioridade:
  - [ ] **Anthropic API key** (`sk-ant-api03-…`) — exposta no OneDrive + git. Revogar no console.anthropic.com + gerar nova.
  - [ ] **Kommo** — token longo + key-secret (expostos no `KEYS.md`).
  - [ ] **Senha da conta Kommo** (`KOMMO_PASSWORD` em texto puro no `dap4/tools/kommo-scraper/.env`) — trocar a senha da conta no Kommo.
  - [ ] **Supabase** — 2 service_role keys + senha do Postgres (DATABASE_URL).
  - [ ] ⚠️ **Avisar o Claude** quando rotacionar Supabase/Postgres — ele atualiza o `.env` do `aios-staging` na VPS e reinicia (senão o portal quebra com chave velha).

- [ ] **Deletar o `KEYS.md` do backup** (`C:\THALES\DAP4.0\_backups\…\STACKS\KEYS.md`) — tem cópia dos segredos live. Fazer **depois** de rotacionar (mantém referência até lá).

---

## 🟡 Decisões / aprovações

- [ ] **Aprovar + mergear o PR #40** (routing por subdomínio). Está **verde** em todos os checks; a branch protection exige tua review. Link: github.com/toliveira1802-sketch/dap40-perple-claude/pull/40. → Depois o Claude faz `git reset --hard origin/main` na VPS pra limpar o drift.

- [ ] **Branch de 30 commits** (`feat/ai-sprint4b-anna-shadow-ui`) — decisão de produto: esse trabalho (cancelar OS, cadastro de cliente, gestão dashboard, marketing calendar, mudanças de auth) **vai pra prod?** Se sim → sessão dedicada (tem **migrations de banco** contra o Supabase de prod = alto risco, precisa de plano).

- [ ] **App DAP Gestão standalone (`:5003`)** — ficou **órfão de subdomínio** (o `gestao.*` agora aponta pro módulo AIOS). Decidir: **aposentar** o app ou dar **outro subdomínio** pra ele.

---

## 🟢 Quando quiser (não bloqueia)

- [ ] **Provisionar contas dos colaboradores** — hoje só você tem login. Pra a equipe usar consultor/gestao/mecanico, criar usuários Supabase + role. (O Claude executa quando você passar nome+email de cada um.)

- [ ] **Descritivos das unidades** (`Ecossistema/*/README.md`) — 12 pastas com stub no template. Preencher oferta/mercado/RAG quando for trabalhar cada frente. Frente paralela.

- [ ] **Camada A (lacunas pequenas)** — wirar testes do `client` no CI + threshold de coverage + runbook de deploy reproduzível.

- [ ] **Camada B (agentes)** — roster de subagentes, hooks, quality gates. Esforço próprio, quando retomar a Fundação.

---

## ✅ Feito nesta sessão (referência)

- Vault consolidado (duplicata de sync resolvida) + árvore do ecossistema + canon v1.1.
- `KEY-INVENTORY.md` — 29 segredos mapeados.
- **3 portais no ar por subdomínio:** `consultor.*`, `mecanico.*`, `gestao.*` (→ módulo AIOS).
- PR #40 aberto e verde (routing em git).
