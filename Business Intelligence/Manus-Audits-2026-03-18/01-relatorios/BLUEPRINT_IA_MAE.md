
                                                                  ---

                                                                  ## 9. STACK FINAL - CUSTO

                                                                  | Componente | Custo/mes | Justificativa |
                                                                  |---|---|---|
                                                                  | VPS Hostinger 8c/32GB | ja pago | Ja tem, roda Ollama + ChromaDB + Worker |
                                                                  | Ollama (Llama 3.1 + Mistral) | R$ 0 | Local na VPS, agentes de baixo custo |
                                                                  | Kimi 2.5 | ~R$ 125 ($25) | Ilimitado, conversacao e WhatsApp |
                                                                  | Claude API (Athena) | ~R$ 50-100 | Sonnet pra decisoes da Mae (uso moderado) |
                                                                  | ChromaDB | R$ 0 | Local na VPS |
                                                                  | Supabase | R$ 0 | Plano free do Lovable Cloud |
                                                                  | **TOTAL** | **~R$ 175-225/mes** | |

                                                                  ---

                                                                  ## 10. FASES DE IMPLEMENTACAO

                                                                  ### FASE A - KNOWLEDGE BASE (2-3 dias)
                                                                  - [ ] Criar METRICAS_NEGOCIO.md com dados reais da Doctor Auto
                                                                  - [ ] - [ ] Criar REGRAS_NEGOCIO.md com todas as regras
                                                                  - [ ] - [ ] Exportar dados das tabelas Supabase pra JSON
                                                                  - [ ] - [ ] Instalar ChromaDB na VPS
                                                                  - [ ] - [ ] Ingerir tudo no ChromaDB (vetorizacao)
                                                                  - [ ] - [ ] Executor: Voce (dados) + Claude Code (tecnico)
                                                                 
                                                                  - [ ] ### FASE B - CRIAR ATHENA (2-3 dias)
                                                                  - [ ] - [ ] Executar SQL das tabelas ia_knowledge_base e ia_mae_decisoes
                                                                  - [ ] - [ ] Inserir seed da Athena na ia_agents
                                                                  - [ ] - [ ] Criar worker athena.js na VPS (processo Node.js dedicado)
                                                                  - [ ] - [ ] Conectar Athena ao ChromaDB (RAG)
                                                                  - [ ] - [ ] Conectar Athena ao Supabase (leitura de dados)
                                                                  - [ ] - [ ] Testar: perguntar algo sobre a empresa e ver se responde com contexto
                                                                  - [ ] - [ ] Executor: Claude Code
                                                                 
                                                                  - [ ] ### FASE C - ATHENA NO COMMAND CENTER (1-2 dias)
                                                                  - [ ] - [ ] Criar AthenaChat.tsx no Command Center (chat direto com a Mae)
                                                                  - [ ] - [ ] Criar AthenaDashboard.tsx (decisoes pendentes, agentes criados, metricas)
                                                                  - [ ] - [ ] Integrar com ia_mae_decisoes (aprovar/rejeitar)
                                                                  - [ ] - [ ] Executor: Claude Code + Lovable
                                                                 
                                                                  - [ ] ### FASE D - ATHENA CRIANDO AGENTES (3-5 dias)
                                                                  - [ ] - [ ] Implementar funcao createAgent() no worker da Athena
                                                                  - [ ] - [ ] Athena gera spec JSON do agente -> insere em ia_agents
                                                                  - [ ] - [ ] Worker detecta novo agente -> instancia (Ollama ou Kimi)
                                                                  - [ ] - [ ] Testar: pedir pra Athena criar um agente simples
                                                                  - [ ] - [ ] Testar: Athena monitorar e ajustar agente
                                                                  - [ ] - [ ] Executor: Claude Code
                                                                 
                                                                  - [ ] ### FASE E - INTEGRACAO KOMMO (2-3 dias)
                                                                  - [ ] - [ ] Conectar Athena a API do Kommo (leads, pipeline, contatos)
                                                                  - [ ] - [ ] Alimentar knowledge base com dados do Kommo
                                                                  - [ ] - [ ] Athena cria primeiro agente real: Lead Responder
                                                                  - [ ] - [ ] Testar fluxo completo: lead entra -> agente responde
                                                                  - [ ] - [ ] Executor: Claude Code
                                                                 
                                                                  - [ ] ---
                                                                 
                                                                  - [ ] ## 11. COMO ISSO CONECTA COM O BLUEPRINT ANTERIOR
                                                                 
                                                                  - [ ] O BLUEPRINT_COMMAND_CENTER.md continua valido!
                                                                  - [ ] A diferenca e que agora:
                                                                 
                                                                  - [ ] - A IA Mae (Athena) SUBSTITUI a lista fixa de 19 agentes
                                                                  - [ ] - Os agentes Thales, Sophia, Simone, Anna Laura podem ser criados pela Athena
                                                                  - [ ] - Ou a Athena pode criar agentes DIFERENTES baseado no que ela acha melhor
                                                                  - [ ] - O Command Center continua sendo a interface
                                                                  - [ ] - As tabelas ia_agents, ia_logs, ia_tasks continuam as mesmas
                                                                  - [ ] - Adicionamos ia_knowledge_base e ia_mae_decisoes
                                                                 
                                                                  - [ ] ### Ordem de execucao:
                                                                  - [ ] 1. BLUEPRINT_COMMAND_CENTER.md Fases 1-4 (setup, preview, supabase, UI)
                                                                  - [ ] 2. BLUEPRINT_IA_MAE.md Fases A-B (knowledge base, criar Athena)
                                                                  - [ ] 3. BLUEPRINT_IA_MAE.md Fase C (Athena no Command Center)
                                                                  - [ ] 4. BLUEPRINT_IA_MAE.md Fases D-E (Athena criando agentes, Kommo)
                                                                  - [ ] 5. BLUEPRINT_COMMAND_CENTER.md Fases 5-7 (task manager, deploy, worker)
                                                                 
                                                                  - [ ] ---
                                                                 
                                                                  - [ ] ## 12. COMANDO PARA O CLAUDE CODE
                                                                 
                                                                  - [ ] Quando estiver pronto pra comecar a Fase A:
                                                                 
                                                                  - [ ] > "Leia os arquivos BLUEPRINT_COMMAND_CENTER.md e BLUEPRINT_IA_MAE.md.
                                                                  - [ ] > Entenda a arquitetura da IA Mae (Athena).
                                                                  - [ ] > Crie os arquivos METRICAS_NEGOCIO.md e REGRAS_NEGOCIO.md na raiz do projeto
                                                                  - [ ] > com templates para o Thales preencher com dados reais da Doctor Auto.
                                                                  - [ ] > Crie as migrations SQL para ia_knowledge_base e ia_mae_decisoes.
                                                                  - [ ] > Execute a FASE A do BLUEPRINT_IA_MAE."
                                                                 
                                                                  - [ ] ---
                                                                 
                                                                  - [ ] Documento vivo. Evolui conforme a Athena evolui.
                                                                  - [ ] Gerado em 16/02/2026 por Claude Opus 4.6 + Thales Oliveira.
                                                                  - [ ] Inspiracao: @tatagoncalvesof (Instagram) - OpenClaw + Claude Code.
