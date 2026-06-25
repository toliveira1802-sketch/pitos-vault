# Mapeamento: O que existe vs. O que falta

## JÁ EXISTE E FUNCIONA
- Sophia Hub (Vercel): Agente Ana com loop agêntico + 5 tools
- Integração Kommo CRM: leitura de leads, criação de tasks, atualização de campos
- Crons automáticos: Vigilante (5min), Analista (10min), Reativador (8h), Lembretes (18h), Relatório (19h)
- Supabase: tabelas ana_conversas, ana_logs, ana_campanhas
- Frontend React: terminal de chat com 3 agentes (sophia, simone, ana)
- Protótipo Python (main.py): LangGraph + Gradio (alternativo, não consolidado)
- Scripts Cohere: RAG Engine, LLM Orchestrator, CRM Bot (PoC separada)
- Duas unidades: Doctor Auto Prime (João/Pedro) e Doctor Auto Bosch (Roniela/Antônio)

## PRECISA DE CORREÇÃO IMEDIATA
- Loop agêntico sem limite de iterações (risco de custo infinito)
- Webhook /api/ana sem validação de segurança
- package.json com credencial Supabase exposta no arquivo
- pescar_ids.py sem import os
- IDs de campos Kommo hardcoded (966001, 966003, 966005, 966007)
- Protótipo Python (main.py) concorrendo com stack Node.js

## FALTA CONSTRUIR
- Motor RAG integrado ao Sophia Hub (Ana responder dúvidas técnicas com base em manuais)
- Interface de gestão da oficina (as 12 telas do Plano Mestre)
- Área do cliente (acompanhamento de serviço, aprovação de orçamento)
- Dashboard executivo real (hoje o relatório vai só pro Slack)
- Sistema de OS (Ordem de Serviço) digital
- Agenda inteligente e Pátio Digital
- Módulo financeiro
- Upload de manuais e tabelas de preço para alimentar o RAG
- Conexão WhatsApp real (hoje depende do Kommo como ponte)
