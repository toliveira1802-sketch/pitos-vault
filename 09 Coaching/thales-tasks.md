---
tags: [thales-agent, cronjobs, scheduler]
aliases: ["Tasks do Agente", "Cronjobs"]
description: Arquivo de tarefas scheduled lido pelo thales-agent/scheduler/watcher.py. Formato Obsidian checklist com horário/intervalo no início.
---

# Thales Tasks — Cronjobs do agente pessoal

> [!info] Como funciona
> O `thales-agent/scheduler/watcher.py` lê este arquivo e agenda cada linha como um cronjob.
>
> - `- [ ]` = task ativa, será executada
> - `- [x]` = task desabilitada, ignorada pelo scheduler
>
> **Formato:** `- [ ] <horário_ou_intervalo> <comando ou descrição da ação>`
>
> Horários aceitos: `09:00`, `18:30`, `*/2h` (a cada 2h), `*/30min`, etc.

---

## Cronjobs

> Vazio por padrão. Adicione tasks conforme a rotina for estabilizando.

- [ ] 20:00 lembrete: rotacionar API keys Anthropic + OpenAI (thales-agent/.env) — flag da Phase 1 Operação Limpeza 09/04

### Rituais diários — Sophia proativa

- [ ] 07:30 /sophia-manha         — Sophia abre o dia no WhatsApp
- [ ] 08:00 /sophia-insist-manha  — insiste 30min depois se Pitoco não respondeu
- [ ] 22:00 /sophia-noite         — Sophia fecha o dia no WhatsApp
- [ ] 22:30 /sophia-insist-noite  — insiste 30min depois se Pitoco não respondeu


---

## Exemplos (desabilitados pra referência)

- [x] 09:00 /skill-resumo-email             — exemplo: resumo de email de manhã
- [x] 18:00 /briefing-diario                — exemplo: briefing do dia às 18h
- [x] */2h pesquisa mercado automotivo      — exemplo: a cada 2 horas
- [x] 08:30 check agenda do dia             — exemplo: verificar agenda matinal

---

**Criado:** 2026-04-09 (Phase 1 da Operação Limpeza)
**Lido por:** `thales-agent/scheduler/watcher.py`
