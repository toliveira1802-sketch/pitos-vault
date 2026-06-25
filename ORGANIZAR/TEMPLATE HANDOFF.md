	
Implemente a tarefa abaixo.

Objetivo:
...

Escopo:
...

Restrições:
...

Critérios de aceite:
...

Validação esperada:
- rodar testes
- lint
- build
- checar comportamento X

Antes de editar, resuma o plano em 5 bullets.
Depois implemente em etapas pequenas e valide localmente.


regra global - Antigravity = decide, organiza, documenta, prioriza, prepara o fluxo Claude Code = usa ferramenta, implementa, integra, testa, executa

	regra global - Antigravity = decide, organiza, documenta, prioriza, prepara o fluxo Claude Code = usa ferramenta, implementa, integra, testa, executa 1) Ferramentas de execução técnica - integração, scripts, APIs, automações, refatoração, terminal, MCP tools. - CTO - Claude 2) Ferramentas de pesquisa, síntese, base de conhecimento -NotebookLM, docs, material de referência, benchmark, insumos para decisão. - **Antigravity** define o que precisa descobrir - **a ferramenta especializada** gera os insumos - **Antigravity** consolida isso em plano, decisão e artifact -NotebookLM não entra como “executor de código”; entra como **fonte de contexto**. 3) Ferramentas visuais / prototipação / composição -Stitch, design-to-code, protótipo, UI exploration. - **Antigravity** define objetivo, fluxo e critério de aceite - **Stitch** ajuda a gerar/estruturar o visual - **Claude Code** pega isso e transforma em implementação real Na Sophia, o prompt deve ser de **orquestração**. - Antigravity Exemplo: > Estruture a solução, defina arquitetura, quebre em etapas, diga o que vai para Stitch, o que vai para NotebookLM e o que vai para Claude Code. Gere handoff executável. “Direto no Thales” - Claude Code **Pra uso operacional de ferramenta, quase sempre sim.** Especialmente quando a ferramenta participa da execução.

Modelo mental bom

Antigravity pergunta:

o que estamos construindo?

por quê?

qual o melhor fluxo?

quais ferramentas entram?

qual a ordem?

qual o critério de sucesso?

Claude Code pergunta:

qual tarefa exata vou executar?

quais arquivos, APIs ou comandos mexer?

como validar que funcionou?