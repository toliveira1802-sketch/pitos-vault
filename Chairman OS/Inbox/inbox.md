# Inbox — Chairman OS

> Capturas brutas (timestamped). Triadas semanalmente (domingo noite). Na Fase 0.1 o preenchimento é manual; na Fase 0.2 vira automático via C2 WhatsApp.

## 2026-04-14
(vazio — primeira entrada aparecerá aqui)

## 2026-04-15

### 🌙 Pra revisar no /noite — Sophia agente pessoal

Sessão de arrumação (AM) parou aqui. Retomar à noite.

**Feito hoje:**
- [x] Criado `PITOS/Agentes/` — MOC + Chairman + Pitoco + Sophia
- [x] Dossiê Sophia construído (esposa, freio por acolhimento, vocabulário Pitoco/more macho/Thales)
- [x] Board Miro: https://miro.com/app/board/uXjVGiXDiHU=/?moveToWidget=3458764667868943285
- [x] `thales-agent`: ThalesBrain → SophiaBrain (alias mantido). Persona carregada do vault (`Agentes/Sophia.md`).
- [x] Nova tool `vault_mental_note` — salva foto original em `10 Quick Notes/Mentais/attachments/` + nota com checkboxes de feedback
- [x] Playground de calibração: `C:\Users\docto\sophia-playground.html`

**Pra fazer (em ordem):**
- [ ] Brincar no playground até a voz dela soar 100% fiel
- [ ] `python -m core.cli` em `C:\dev\thales-agent` — primeira conversa real
- [ ] Iterar `Agentes/Sophia.md` no vault até calibrar (CLI → edita vault → reinicia CLI)
- [ ] Ligar WhatsApp local (bridge Baileys + FastAPI) pra testar com mídia real
- [ ] Deploy VPS `76.13.170.42` — Sophia 24/7 no bolso
- [ ] Fase 2 notas mentais: embeddings ChromaDB, comparação semântica
- [ ] Fase 3: feedback loop `#valeu` / `#lixo` / `#virou-projeto`
- [ ] Fase 4: relatório semanal de padrão (sexta, WhatsApp)

**Frente paralela aberta — NÃO esquecer:**
- [ ] Pesquisar best practices Anthropic (session hygiene, cache, hooks, skills) → consolidar em `PITOS/Knowledge/Claude/`
- [ ] 4 travas de configuração do Claude (anti-deriva, âncora de sessão, semântica DAP, hook shutdown)
