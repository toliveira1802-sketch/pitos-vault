---
type: handoff
date: 2026-04-15
time: 09:58
project: claude-code-config
topic: Criar comando /handoff pra salvar estado de sessão no vault Obsidian
tags: [handoff, claudin, claude-code, obsidian]
---

# Handoff — Criar comando /handoff

## Contexto

Thales pediu uma skill/comando pra rodar no fim (ou meio) de qualquer sessão do Claude Code que gere um MD com o estado atual e grave dentro do vault PITOS, pra conseguir retomar de onde parou — seja na mesma máquina, seja em outro device abrindo o Obsidian.

Já existia `/save-session` gravando em `~/.claude/session-data/` (local, não-portátil). Faltava a ponte pro vault — foi o que `/handoff` resolveu. Um é pra retomar no mesmo ambiente, outro é pra consultar de qualquer lugar.

## O que funcionou (com evidência)

- **Comando `/handoff` criado** — evidência: arquivo existe em `C:\Users\docto\.claude\commands\handoff.md`, e o próprio SessionStart do Claude Code já lista ele no catálogo de skills disponíveis ("handoff: Salva o estado da sessão num MD...")
- **Estrutura do MD validada** — evidência: esse arquivo que você está lendo agora foi gerado seguindo o formato definido no comando e foi gravado com sucesso no vault

## O que NÃO funcionou (e por quê)

Nada falhou. Primeiro shot funcionou.

## O que ainda não foi tentado

- Abrir esse handoff no Obsidian e confirmar que o frontmatter renderiza certo (tags, type, date)
- Rodar `/handoff` no fim de uma sessão real de trabalho técnico (ex: DAP4.0) pra ver se o formato cobre bem casos com muitos arquivos tocados
- Criar um `/resume-handoff <path>` espelhando o `/resume-session` — lê o MD mais recente do `Inbox - Claudin/` e hidrata o contexto da nova sessão
- Adicionar hook opcional no Stop do Claude Code pra sugerir `/handoff` quando a sessão for longa

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `C:\Users\docto\.claude\commands\handoff.md` | Completo | Comando criado, frontmatter + processo + formato + regras |
| `C:\Users\docto\OneDrive\...\Inbox - Claudin\handoff-2026-04-15-0958-criar-comando-handoff.md` | Completo | Esse arquivo — primeiro handoff de teste |

## Decisões tomadas

- **Destino no vault = `Inbox - Claudin/`** — razão: memória global já diz que canal Claudin↔Thales mora ali (`thread-XXX.md`); handoff é da mesma natureza, evita fragmentar em pasta nova
- **Nome do arquivo com `handoff-` prefix + timestamp + slug** — razão: distingue de `thread-XXX.md` existentes no mesmo diretório, ordena cronológico, slug dá contexto sem abrir
- **Comando (`~/.claude/commands/`) ao invés de skill (`~/.claude/skills/<name>/SKILL.md`)** — razão: paralelo direto com `/save-session` que já é comando; invocação via slash é mais natural pro fluxo "fim de sessão"
- **PT-BR no conteúdo do comando** — razão: alinhado com o CLAUDE.md global do Thales

## Bloqueios & perguntas abertas

- Sem bloqueios.

## Próximo passo exato

Abrir `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Inbox - Claudin\handoff-2026-04-15-0958-criar-comando-handoff.md` no Obsidian e confirmar renderização (frontmatter, tags clicáveis, headings). Se estiver ok, `/handoff` está validado e pronto pra uso em sessões reais.

## Setup / comandos úteis

- Invocar: `/handoff` em qualquer sessão
- Listar handoffs: `ls "C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Inbox - Claudin\" | grep ^handoff`
