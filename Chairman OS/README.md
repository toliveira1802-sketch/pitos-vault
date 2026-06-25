# Chairman OS

> Personal OS do Thales · fundido com operação DAP · evidência > relato.

## Estrutura

- `Daily/` — notas diárias (abertura em `/manha`, fechamento em `/noite`)
- `Weekly/` — revisões semanais (fechadas sexta à noite)
- `Monthly/` — rollups mensais
- `Quarterly/` — rollups trimestrais + OKRs das unidades DAP
- `Inbox/` — capturas brutas (triagem semanal)
- `Decisions/` — log de decisões estratégicas
- `_templates/` — templates dos arquivos acima

## Como usar

- **Manhã:** rodar `/manha` no Claude Code (gera a daily note do dia)
- **Durante o dia:** (Fase 0.2+) capturar via WhatsApp
- **Noite:** rodar `/noite` (fecha a daily note + prepara amanhã)
- **Sexta noite:** `/noite` também fecha a weekly review
- **Domingo noite:** triagem da Inbox

## Princípios

1. Evidência > relato
2. Causa raiz > desculpa
3. Máximo 3 prioridades por dia
4. Silêncio OK

## Referências

- Spec: `../DAP 4.0/Specs/2026-04-14-chairman-os-design.md`
- Plano Fase 0.1: `../DAP 4.0/Specs/2026-04-14-chairman-os-fase0.1-plan.md`
