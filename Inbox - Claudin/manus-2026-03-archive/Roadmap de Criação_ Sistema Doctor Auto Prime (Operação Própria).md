# Roadmap de Criação: Sistema Doctor Auto Prime (Operação Própria)

**Autor:** Manus AI
**Data:** 18 de Março de 2026

Este documento detalha o plano de ação prático e direto para colocar o sistema **Doctor Auto Prime** no ar, focado exclusivamente na sua operação (unidades Prime e Bosch). O objetivo é transformar o código atual (Sophia Hub) em uma ferramenta de trabalho diária para a sua equipe, sem as complexidades de um modelo SaaS para milhares de oficinas.

## Visão Geral do Cronograma

O roadmap está dividido em 5 Sprints sequenciais. O foco inicial é corrigir as vulnerabilidades do código atual, seguido pela integração do conhecimento técnico (RAG) e, por fim, a construção das telas de gestão da oficina.

![Cronograma do Roadmap](https://private-us-east-1.manuscdn.com/sessionFile/iABq7zKZQqzJxzrxKgHkXb/sandbox/9HXypjoqHOWhAyZVlKpcVW-images_1773867055152_na1fn_L2hvbWUvdWJ1bnR1L2RvY3Mvcm9hZG1hcF9zaXN0ZW1hX2dhbnR0.png?Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9wcml2YXRlLXVzLWVhc3QtMS5tYW51c2Nkbi5jb20vc2Vzc2lvbkZpbGUvaUFCcTd6S1pRcXpKeHpyeEtnSGtYYi9zYW5kYm94LzlIWHlwam9xSE9XaEF5WlZsS3BjVlctaW1hZ2VzXzE3NzM4NjcwNTUxNTJfbmExZm5fTDJodmJXVXZkV0oxYm5SMUwyUnZZM012Y205aFpHMWhjRjl6YVhOMFpXMWhYMmRoYm5SMC5wbmciLCJDb25kaXRpb24iOnsiRGF0ZUxlc3NUaGFuIjp7IkFXUzpFcG9jaFRpbWUiOjE3OTg3NjE2MDB9fX1dfQ__&Key-Pair-Id=K2HSFNDJXOU9YS&Signature=EWgV1h4XrvEZw1JVIEzRKPMl7CbHm9yndSJ8XHBGecv1LSMw7XIJA9ZJOQ0PsVFmwlsVMjm2~xYdMA-k~Ekp-hOGhNRN0GVmqrdTMrtJnO315JLYVxX8TiBAMse5FucBBFJQPlnOvm0PUEh7nSkTg3SnviTXKU2S83Q73x-SoZ4KBH9rz5ryT3Ce4bdpO4hYo3lBJtF9VKkGvYd~3OkTUNUrxEeobB-pJ9WrX7cdqRBWCEO0RPsJdzsnmlCa3gd-0WbVBkUJPVnz6WRU9VqbWwP8lIuhNEn3N0lxRkYVo6nGptCkVlvg81kLANOCa~iAqrQNNTLu~LIwLs5hrFU7mg__)

## Mapeamento de Status: O que temos vs. O que falta

Antes de iniciar o desenvolvimento, é crucial entender o estado atual do ecossistema. O diagrama abaixo ilustra o que já está funcionando, o que precisa de correção imediata e o que ainda precisa ser construído para atingir a visão do Plano Mestre.

![Status do Sistema](https://private-us-east-1.manuscdn.com/sessionFile/iABq7zKZQqzJxzrxKgHkXb/sandbox/9HXypjoqHOWhAyZVlKpcVW-images_1773867055152_na1fn_L2hvbWUvdWJ1bnR1L2RvY3Mvc3RhdHVzX3Npc3RlbWE.png?Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9wcml2YXRlLXVzLWVhc3QtMS5tYW51c2Nkbi5jb20vc2Vzc2lvbkZpbGUvaUFCcTd6S1pRcXpKeHpyeEtnSGtYYi9zYW5kYm94LzlIWHlwam9xSE9XaEF5WlZsS3BjVlctaW1hZ2VzXzE3NzM4NjcwNTUxNTJfbmExZm5fTDJodmJXVXZkV0oxYm5SMUwyUnZZM012YzNSaGRIVnpYM05wYzNSbGJXRS5wbmciLCJDb25kaXRpb24iOnsiRGF0ZUxlc3NUaGFuIjp7IkFXUzpFcG9jaFRpbWUiOjE3OTg3NjE2MDB9fX1dfQ__&Key-Pair-Id=K2HSFNDJXOU9YS&Signature=RnFBL-JrMmW0MI5fGhp9JzHt6CNUsjfRunQlXbiE8FSMD3EnMd83geaxrtfS1Iq0v~niB5OEgtQ6-8gYzJQwmrs09z34JbBVvaAOQccyUEeKgSozudVSPZGafdugoAtnVN1IDGBV-WJBhl157T8GcUXq9uDE9dxMZlW895B-l6P99huz13OlMyvW9aW3tYwWvHxMZnFQAWnT7PgQvaKadrQKwpA5huLYbSXJ1PtVy3ywjLk9l0LRU1nN~LViXPk1XUW4JLR0PLNrgYDLknY5bve-BkxzQ8DGzcqsmHLxuCMj1S8l5o8mqvnu8ahCBCvScjiVVEXuZ37zjEx08iqCEw__)

---

## Detalhamento dos Sprints

### SPRINT 0 — Correções Urgentes (Semana 1)
**Objetivo:** Estabilizar o código atual do Sophia Hub para que ele possa rodar em produção sem gerar custos infinitos ou riscos de segurança.

*   **Trava de Segurança na IA:** O agente Ana atualmente roda em um loop infinito (`while(true)`). É imperativo adicionar um limite (ex: `max_steps = 3`) para evitar que a IA consuma todos os créditos da API da Anthropic em caso de erro.
*   **Segurança do Webhook:** O endpoint que recebe as mensagens do Kommo CRM (`/api/ana`) está aberto. É necessário implementar a validação de assinatura (HMAC) para garantir que apenas o seu Kommo possa enviar mensagens para a Ana.
*   **Limpeza de Credenciais:** Remover a chave do Supabase que está exposta no arquivo `package.json` e garantir que todas as senhas estejam apenas nas variáveis de ambiente da Vercel.
*   **Foco na Stack Principal:** Descontinuar oficialmente o protótipo em Python (`main.py`) e focar 100% dos esforços na arquitetura Node.js/Vercel, que já está muito mais madura.

### SPRINT 1 — IA Operacional e Conhecimento Técnico (Semanas 2-4)
**Objetivo:** Fazer a Ana parar de depender apenas de instruções básicas e passar a consultar os manuais reais da sua oficina.

*   **Mapeamento Definitivo do Kommo:** Substituir os IDs genéricos no código pelos IDs reais dos campos customizados do seu Kommo CRM (ex: o campo de data de agendamento usado no cron de Lembretes).
*   **Ativação do Banco Vetorial:** Ligar a extensão `pgvector` no seu Supabase atual.
*   **Migração do Motor RAG:** Pegar a lógica excelente que foi feita nos scripts da Cohere (`rag_engine.py`) e reescrevê-la para Node.js dentro da Vercel.
*   **Upload de Conhecimento:** Subir os PDFs de manuais técnicos, tabelas de preços e políticas da Doctor Auto para o Supabase.
*   **Nova Ferramenta para a Ana:** Criar a tool `consultar_base_tecnica`. Assim, quando um cliente perguntar "Qual o óleo ideal para o Jetta 2018?", a Ana vai ler o manual antes de responder.

### SPRINT 2 — Gestão da Oficina (Semanas 5-8)
**Objetivo:** Construir a interface web (Frontend) para a sua equipe usar no dia a dia, reduzindo a dependência exclusiva da tela do Kommo CRM.

*   **Dashboard Executivo:** Uma tela web simples que consome os dados do cron de Relatório Diário, mostrando leads novos, agendamentos e conversões em tempo real.
*   **Agenda Inteligente e Pátio Digital:** Uma visualização em calendário e kanban para os responsáveis (João/Pedro na Prime, Roniela/Antônio na Bosch) controlarem os boxes e os mecânicos.
*   **Abertura e Gestão de OS:** O formulário digital para registrar a entrada do veículo, checklist inicial e alocação do serviço.
*   **Diagnóstico e Orçamento Visual:** A tela onde o mecânico insere as peças necessárias e a mão de obra, gerando um orçamento claro e profissional.

### SPRINT 3 — Experiência do Cliente (Semanas 9-11)
**Objetivo:** Encantar o cliente com transparência e facilidade de aprovação.

*   **Aprovação Digital de Orçamento:** O cliente recebe um link no WhatsApp (enviado pela Ana), abre uma página web bonita com o orçamento detalhado e clica em "Aprovar Serviço".
*   **Acompanhamento de Serviço:** Uma página onde o cliente pode ver o status do carro ("Em diagnóstico", "Aguardando peças", "Em execução") com fotos e vídeos anexados pela equipe.
*   **Ritual de Entrega Digital:** Automação que avisa o cliente que o carro está pronto, enviando o checklist final de qualidade.

### SPRINT 4 — Financeiro e Go-Live (Semanas 12-14)
**Objetivo:** Fechar o ciclo do serviço e colocar a operação completa para rodar.

*   **Módulo Financeiro Simplificado:** Registro de pagamentos, controle de receitas por unidade (Prime vs. Bosch) e comissões.
*   **Histórico Completo do Cliente:** Uma visão unificada de todas as passagens do veículo pela oficina, essencial para o cron de "Reativador" oferecer serviços preventivos no futuro.
*   **Testes Integrados:** Simular o fluxo completo: Lead entra via WhatsApp -> Ana atende e agenda -> Carro chega na oficina -> OS é aberta -> Orçamento aprovado via link -> Serviço executado -> Pagamento registrado.
*   **Go-Live:** Virada de chave oficial para o novo sistema.

---

Este roadmap foi desenhado para ser executado por um desenvolvedor Full Stack (ou uma pequena equipe ágil), focando no que traz retorno imediato para a operação da Doctor Auto Prime e Doctor Auto Bosch.
