# Roadmap de Criação: Doctor Auto Prime & Sophia Hub

**Autor:** Manus AI
**Data:** 18 de Março de 2026

Este documento detalha o plano de ação estratégico e técnico para transformar o ecossistema atual (Sophia Hub) na plataforma SaaS escalável descrita no Plano Mestre do Doctor Auto Prime. O roadmap está estruturado em fases sequenciais, priorizando a segurança e a fundação arquitetural antes da expansão de funcionalidades.

## Visão Geral do Cronograma

O roadmap está dividido em 6 fases principais, projetadas para levar o produto do estado atual (MVP avançado) até a escala de 10.000 oficinas.

![Cronograma do Roadmap](https://private-us-east-1.manuscdn.com/sessionFile/iABq7zKZQqzJxzrxKgHkXb/sandbox/2D5XcJuSu0K72ulwNrxZUP-images_1773866652670_na1fn_L2hvbWUvdWJ1bnR1L2RvY3Mvcm9hZG1hcF9nYW50dA.png?Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9wcml2YXRlLXVzLWVhc3QtMS5tYW51c2Nkbi5jb20vc2Vzc2lvbkZpbGUvaUFCcTd6S1pRcXpKeHpyeEtnSGtYYi9zYW5kYm94LzJENVhjSnVTdTBLNzJ1bHdOcnhaVVAtaW1hZ2VzXzE3NzM4NjY2NTI2NzBfbmExZm5fTDJodmJXVXZkV0oxYm5SMUwyUnZZM012Y205aFpHMWhjRjluWVc1MGRBLnBuZyIsIkNvbmRpdGlvbiI6eyJEYXRlTGVzc1RoYW4iOnsiQVdTOkVwb2NoVGltZSI6MTc5ODc2MTYwMH19fV19&Key-Pair-Id=K2HSFNDJXOU9YS&Signature=myfVDKrrFM1h7WRqDXtEeac0H86KWWAVU6~i7yUsi~ZSDSQLsEswFvCq~4t~SApH9g6JT3vtaueBNKx0hokdXd1yt6l8MhhO5pWicBevKfdCaUmbDVeIBeF32t0uJGTHfPRdtGv~ela8glEvydm4SKcgKeWyTY~vW6uKwj7sPo9AvTMTRs93x-rQTkDK5Z5Ki~Hd8YN0qnFuL0931U3RAXNL3GkI30-jYiyrNP9B4lb-kjlvvfQb6TQVCOQKrKAWN-6IvaCg1LPpJKRuXItZvZbf9C8bLlYZ373zFGnijKw8JTgGWMECi~fnVvDzaKBZ1TlC1~qHRsm-phxqu6OwLg__)

## Fluxo de Dependências

A execução das fases segue uma lógica estrita de dependências. A Fase 0 (Blindagem) é pré-requisito absoluto para a Fase 1 (Fundação SaaS), que por sua vez destrava o desenvolvimento do Motor RAG e da Plataforma visual.

![Fluxo de Dependências](https://private-us-east-1.manuscdn.com/sessionFile/iABq7zKZQqzJxzrxKgHkXb/sandbox/2D5XcJuSu0K72ulwNrxZUP-images_1773866652670_na1fn_L2hvbWUvdWJ1bnR1L2RvY3Mvcm9hZG1hcF9kZXBz.png?Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9wcml2YXRlLXVzLWVhc3QtMS5tYW51c2Nkbi5jb20vc2Vzc2lvbkZpbGUvaUFCcTd6S1pRcXpKeHpyeEtnSGtYYi9zYW5kYm94LzJENVhjSnVTdTBLNzJ1bHdOcnhaVVAtaW1hZ2VzXzE3NzM4NjY2NTI2NzBfbmExZm5fTDJodmJXVXZkV0oxYm5SMUwyUnZZM012Y205aFpHMWhjRjlrWlhCei5wbmciLCJDb25kaXRpb24iOnsiRGF0ZUxlc3NUaGFuIjp7IkFXUzpFcG9jaFRpbWUiOjE3OTg3NjE2MDB9fX1dfQ__&Key-Pair-Id=K2HSFNDJXOU9YS&Signature=uUXpaJ2vL8C3cFZpzMde9mVLdadeNM0g0Jwug-v9EBb5cVzUGSvr18wk7UpzHJ-tmq2BGPVDp~oYi0r9jO981W3-SEceuk1~u-Frn75nwJCYpe7sccv51fPAt35Vu2lfzPHd1ydV5rnygWJdINsMFfrSSAZA9gIiR4ZNkZWtRGInI1Igkk7AYIZOWX95nOmNCpcRZAmJksUGBNei8p9W0LnwB-1-uFJno7F1dcdixHkLTo5gGjLnu1colWe6dtS0FKH6JPCsfhAQ6AwdxMDdpkzw54hHuRZBaTQxSZsAo0C3waDL~ysYgJdNd0iuVoeF-X0bukC5zPhN3hPJqyK8~A__)

---

## Detalhamento das Fases

### FASE 0 — Blindagem da Infraestrutura (Semanas 1-2)
**Objetivo:** Proteger o código atual do Sophia Hub contra falhas em produção, vazamento de custos e ataques externos.

*   **Segurança de Webhooks (HMAC):** Implementar validação criptográfica no endpoint `/api/ana` para garantir que apenas o Kommo CRM possa acionar a IA [1].
*   **Limite de Iterações (Max Steps):** Adicionar um contador no loop `while(true)` do agente Ana. Se a IA falhar ao usar uma ferramenta 3 vezes seguidas, o loop deve ser interrompido para evitar *timeout* e consumo infinito de tokens da Anthropic [1].
*   **Rate Limiting e Monitoramento:** Configurar limites de requisição na Vercel e alertas de consumo de API.
*   **Testes Automatizados:** Criar suíte de testes unitários para as 5 *tools* da Ana e para os *crons* (Vigilante, Analista, Reativador).

### FASE 1 — Fundação SaaS Multi-Tenant (Semanas 3-6)
**Objetivo:** Preparar o banco de dados e a lógica de negócio para suportar múltiplas oficinas simultaneamente, sem vazamento de dados entre elas.

*   **Modelagem Multi-Tenant no Supabase:** Habilitar *Row Level Security* (RLS) no Supabase, garantindo que a Oficina A não consiga ler os leads ou logs da Oficina B [2].
*   **Tabela de Configuração Dinâmica:** Criar a tabela `tenant_config` para armazenar os tokens do Kommo, IDs de campos customizados e *System Prompts* específicos de cada oficina.
*   **Refatoração do Código:** Atualizar o `api/ana.js` e os crons para buscarem as credenciais dinamicamente no banco, eliminando o uso de variáveis de ambiente globais (hardcoding) [1].
*   **Onboarding Automatizado:** Criar o fluxo onde uma nova oficina se cadastra, conecta seu Kommo via OAuth e o sistema gera sua configuração inicial automaticamente.

### FASE 2 — Motor RAG e Conhecimento Técnico (Semanas 7-10)
**Objetivo:** Integrar a inteligência de manuais técnicos (desenvolvida na prova de conceito com Cohere) diretamente no agente Ana.

*   **Ativação do pgvector:** Configurar a extensão de banco de dados vetorial nativa do Supabase [3].
*   **Migração do RAG Engine:** Reescrever a lógica do `rag_engine.py` para Node.js, permitindo que a Vercel faça a ingestão e busca de vetores diretamente no Supabase.
*   **Interface de Upload:** Desenvolver uma tela simples onde o dono da oficina faz upload de PDFs (manuais, tabelas de preços).
*   **Nova Tool para a Ana:** Criar a ferramenta `consultar_base_tecnica`, permitindo que a IA busque informações precisas antes de responder dúvidas mecânicas complexas aos clientes.

### FASE 3 — Plataforma Visual (12 Telas) (Semanas 11-18)
**Objetivo:** Construir a interface web completa descrita no Plano Mestre, substituindo a dependência exclusiva do Kommo CRM.

*   **Área da Oficina (Frontend React/Vite):**
    *   Dashboard Executivo (consumindo os dados do cron de Relatório).
    *   Agenda Inteligente e Pátio Digital (gestão visual de vagas e mecânicos) [2].
    *   Abertura de OS, Diagnóstico Técnico e Orçamento Visual [2].
    *   Módulo Financeiro Simplificado.
*   **Área do Cliente (Web App):**
    *   Link de acompanhamento de serviço (status, fotos, vídeos).
    *   Aprovação digital de orçamentos com assinatura [2].

### FASE 4 — Escala e Comercialização (Semanas 19-24)
**Objetivo:** Lançar o produto no mercado e atingir a marca de 100 oficinas pagantes.

*   **Painel Administrativo (Super Admin):** Interface para a equipe da Doctor Auto gerenciar todas as oficinas clientes (suspender contas, ver métricas globais).
*   **Sistema de Billing:** Integração com Stripe para cobrança recorrente (SaaS) automatizada [2].
*   **Marketing e Vendas:** Lançamento de campanhas focadas em oficinas independentes, utilizando o próprio motor de SEO/Ahrefs desenvolvido na Fase 2 para atração de leads [3].

### FASE 5 — Marketplace e Ecossistema (Semanas 25-32)
**Objetivo:** Expandir o modelo de negócios além da mensalidade do software.

*   **Marketplace de Peças:** Conectar o módulo de orçamentos diretamente a fornecedores de autopeças, gerando comissão por venda [2].
*   **Serviços Financeiros:** Integrar opções de financiamento de serviços de alto ticket (ex: retífica de motor) diretamente na tela de aprovação do cliente [2].
*   **Meta Final:** Escalar a infraestrutura para suportar 10.000 oficinas ativas.

---

### Referências

[1] Manus AI. *Relatório Definitivo: Ecossistema Doctor Auto Prime & Sophia Hub*. Documento Markdown.
[2] Doctor Auto Prime. *Plano Mestre do Produto*. Documento PDF.
[3] Doctor Auto Prime. *Arquitetura do Ecossistema IA: RAG, CRM, Bots e LLMs*. Documento Markdown.
