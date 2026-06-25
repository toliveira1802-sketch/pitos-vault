# Roadmap de Criação: Doctor Auto Prime (Estratégia CRM Duplo)

**Autor:** Manus AI
**Data:** 18 de Março de 2026

Este documento detalha o plano de ação prático para colocar o sistema **Doctor Auto Prime** no ar, focado na operação própria (unidades Prime e Bosch). A grande inovação desta versão é a implementação da **Estratégia de CRM Duplo**, separando a operação ativa do "lago de leads" e utilizando uma IA intermediária (o "Bote") para pescar oportunidades.

## 1. A Estratégia do CRM Duplo

O problema atual é que leads quentes (que vão fechar serviço) se misturam com leads frios (que disseram "não agora"), poluindo o funil de vendas. A solução é dividir o ecossistema em três partes:

1.  **CRM Interno (Operação Ativa):** Onde a mágica acontece. Leads que estão em negociação, agendados, com o carro na oficina ou em pós-venda recente. A agente **Ana** opera aqui, junto com a equipe da oficina.
2.  **CRM Externo (Lago de Leads):** Um banco de dados massivo (no Supabase) para leads que não fecharam, clientes antigos, contatos de campanhas e indicações. Eles recebem um *score* (Quente, Morno, Frio).
3.  **O Bote (IA Pescadora):** Uma IA que roda em background (ex: segundas e quintas às 9h). Ela analisa o Lago de Leads, cruza com campanhas ativas (ex: "Revisão de Férias") e manda mensagens personalizadas. Se o lead responder positivamente, o Bote o "pesca" e o joga de volta no CRM Interno para a Ana fechar a venda.

### Fluxo de Vida do Lead

O diagrama abaixo ilustra como o lead transita entre os dois CRMs, garantindo que nenhuma oportunidade seja perdida.

![Fluxo de Vida do Lead](https://private-us-east-1.manuscdn.com/sessionFile/iABq7zKZQqzJxzrxKgHkXb/sandbox/1ZyI1viTLColKpGDXiWb9T-images_1773873772508_na1fn_L2hvbWUvdWJ1bnR1L2RvY3MvZmx1eG9fbGVhZF9saWZlY3ljbGU.png?Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9wcml2YXRlLXVzLWVhc3QtMS5tYW51c2Nkbi5jb20vc2Vzc2lvbkZpbGUvaUFCcTd6S1pRcXpKeHpyeEtnSGtYYi9zYW5kYm94LzFaeUkxdmlUTENvbEtwR0RYaVdiOVQtaW1hZ2VzXzE3NzM4NzM3NzI1MDhfbmExZm5fTDJodmJXVXZkV0oxYm5SMUwyUnZZM012Wm14MWVHOWZiR1ZoWkY5c2FXWmxZM2xqYkdVLnBuZyIsIkNvbmRpdGlvbiI6eyJEYXRlTGVzc1RoYW4iOnsiQVdTOkVwb2NoVGltZSI6MTc5ODc2MTYwMH19fV19&Key-Pair-Id=K2HSFNDJXOU9YS&Signature=Fo5ZrUxiUBLAhfVPTNHZYI6V9GZCAB-cnPOQNOTpbp4WZoPCopmvorobI5mBJnI0qoQdoFTQZ6OZn3zgysVSCyBjnDHuL7~~sb7ZnN-hb5S9txKEmvV6eJsVC~p1nmkgZ1kgOUfIbdqhdJxy4AkoKvWzIQnRuYfy~1NAMJEawincpFymV4sCgsi8qGKbWbq1RvtCkmKAPqf5d3k9uraSl746KJpcS~YStNdXh9hcSI7ztVIpEgVlZascQsH5kspnf-A~cSxSrSqj2KWGhxYE390spdUfykdUrjMlrgGjwCC~BAGwSGmJrDzd2lvmuS~u9uS3fF4MXKluMgulxV84SA__)

---

## 2. Visão Geral do Cronograma

O roadmap está dividido em 5 Sprints sequenciais, totalizando aproximadamente 16 semanas de desenvolvimento.

![Cronograma do Roadmap](https://private-us-east-1.manuscdn.com/sessionFile/iABq7zKZQqzJxzrxKgHkXb/sandbox/1ZyI1viTLColKpGDXiWb9T-images_1773873772508_na1fn_L2hvbWUvdWJ1bnR1L2RvY3Mvcm9hZG1hcF9jcm1fZHVwbG9fZ2FudHQ.png?Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9wcml2YXRlLXVzLWVhc3QtMS5tYW51c2Nkbi5jb20vc2Vzc2lvbkZpbGUvaUFCcTd6S1pRcXpKeHpyeEtnSGtYYi9zYW5kYm94LzFaeUkxdmlUTENvbEtwR0RYaVdiOVQtaW1hZ2VzXzE3NzM4NzM3NzI1MDhfbmExZm5fTDJodmJXVXZkV0oxYm5SMUwyUnZZM012Y205aFpHMWhjRjlqY20xZlpIVndiRzlmWjJGdWRIUS5wbmciLCJDb25kaXRpb24iOnsiRGF0ZUxlc3NUaGFuIjp7IkFXUzpFcG9jaFRpbWUiOjE3OTg3NjE2MDB9fX1dfQ__&Key-Pair-Id=K2HSFNDJXOU9YS&Signature=LsLXkEY9Gg17BA2kRfnZT5eWP~95ABshBX0GpdNuU5Aw0XTsVbuiQzY6dUVDVD5aC8zgLNOpSN7OZMRgp8VvULcVm6kXaAOpJ9vPCo2c7pXfULrBr6MDBxu5e68~AK1SNzD67vcgejmMb3ZDnjycYm6ZbR0VQ0utQ7C6lzGBE-vGhlFJwdA28~YnlspSEX5Mf0U8Ip~ndfpkCjPop~hqfRtCDe3QQ4Ts0JqyRbARCvS0qlAnOg-VSGlCYFoeflDpd0BMbVpGkn3KZ5j-lNGP7Mn7ZWqCk307vcio8b8VPfz1KZfmwsmVWkOp3awCtPfZdSQZfL3GwS0XCm0ufDhuDA__)

---

## 3. Detalhamento dos Sprints

### SPRINT 0 — Blindagem e Correções (Semana 1)
**Objetivo:** Estabilizar o código atual do Sophia Hub para que ele possa rodar em produção sem gerar custos infinitos ou riscos de segurança.

*   **Trava de Segurança na IA:** Adicionar um limite (`max_steps = 3`) no loop agêntico da Ana para evitar consumo infinito de tokens da Anthropic em caso de erro.
*   **Segurança do Webhook:** Implementar validação de assinatura (HMAC) no endpoint `/api/ana` para garantir que apenas o seu Kommo possa enviar mensagens.
*   **Limpeza de Credenciais:** Remover a chave do Supabase exposta no arquivo `package.json`.
*   **Foco na Stack Principal:** Descontinuar oficialmente o protótipo em Python (`main.py`) e focar 100% na arquitetura Node.js/Vercel.

### SPRINT 1 — CRM Interno e Conhecimento Técnico (Semanas 2-4)
**Objetivo:** Configurar o CRM Interno para a operação diária e dar inteligência técnica para a Ana.

*   **Modelagem do CRM Interno:** Mapear os IDs definitivos do Kommo e configurar o funil ativo (Negociação → Agendado → Na Oficina → Pós-Venda).
*   **Ativação do Banco Vetorial:** Ligar a extensão `pgvector` no Supabase.
*   **Migração do Motor RAG:** Reescrever a lógica de vetorização (`rag_engine.py`) para Node.js.
*   **Upload de Conhecimento:** Subir os PDFs de manuais técnicos e tabelas de preços para o Supabase.
*   **Nova Ferramenta para a Ana:** Criar a tool `consultar_base_tecnica`, permitindo que a Ana leia os manuais antes de responder dúvidas mecânicas.

### SPRINT 2 — CRM Externo e a IA Pescadora (Semanas 5-8)
**Objetivo:** Construir o "Lago de Leads" e o "Bote" para reativar contatos frios automaticamente.

*   **Modelagem do Lago de Leads:** Criar a tabela `lago_leads` no Supabase com campos para histórico, motivo de perda e *score* de temperatura.
*   **Regra de Transição:** Programar a automação: se um lead no CRM Interno não fechar após X dias, a Ana o move para o Lago de Leads com uma tag (ex: "achou caro").
*   **Criação da IA Pescadora:** Desenvolver o cron job que roda duas vezes por semana. Ele deve analisar o Lago, escolher os melhores leads e gerar mensagens baseadas em campanhas (ex: Revisão Preventiva, Sazonal, Upsell).
*   **Ponte IA-IA:** Criar o protocolo onde a Pescadora passa o contexto para a Ana quando um lead "morde a isca" e volta para o CRM Interno.

### SPRINT 3 — Gestão da Oficina (Semanas 9-12)
**Objetivo:** Construir a interface web (Frontend) para a equipe usar no dia a dia.

*   **Dashboard Executivo:** Tela web consumindo os dados do cron de Relatório Diário.
*   **Agenda Inteligente e Pátio Digital:** Visualização em calendário e kanban para controle de boxes e mecânicos nas unidades Prime e Bosch.
*   **Abertura e Gestão de OS:** Formulário digital para registro de entrada e checklist.
*   **Diagnóstico e Orçamento Visual:** Tela para inserção de peças e mão de obra, gerando orçamentos profissionais.

### SPRINT 4 — Experiência do Cliente (Semanas 13-15)
**Objetivo:** Encantar o cliente com transparência e facilidade.

*   **Aprovação Digital de Orçamento:** Link web enviado via WhatsApp para o cliente aprovar o serviço com um clique.
*   **Acompanhamento de Serviço:** Página de status do carro com fotos e vídeos anexados pela equipe.
*   **Ritual de Entrega Digital:** Automação que avisa o cliente que o carro está pronto, enviando o checklist final de qualidade.

### SPRINT 5 — Financeiro e Go-Live (Semanas 16-17)
**Objetivo:** Fechar o ciclo do serviço e colocar a operação completa para rodar.

*   **Módulo Financeiro Simplificado:** Registro de pagamentos e controle de receitas por unidade.
*   **Histórico Completo do Cliente:** Visão unificada de todas as passagens do veículo, essencial para alimentar o Lago de Leads com dados precisos.
*   **Testes Integrados:** Simular o fluxo completo, desde a entrada do lead até o pagamento e posterior reativação pela Pescadora.
*   **Go-Live:** Virada de chave oficial para o novo sistema.
