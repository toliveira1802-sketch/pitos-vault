# Veredicto Claudin — Pacote Manus 2026-03

**Data avaliação:** 2026-04-19
**Revisor:** Claude (sessão /brainstorming + /spawn autônomo)

## TL;DR

~30% ouro acionável, ~50% redundante ou conflitante com Sennin Protocol + DAP4 atual, ~20% código de outra arquitetura (Sophia Hub Vercel/Node) que não cabe aqui.

## O que extrair

1. **Análise Kommo 5.192 leads** → `/PITOS/Business Intelligence/Kommo Analysis 2026-03/`
2. **9 Personas reais** → alimentar RTBM Bosch/Prime + prompts Anna
3. **Observações técnicas:** HMAC webhooks, max_steps loop agêntico, pgvector migration

## O que DESCARTAR

- Sophia Hub Vercel/Node arch (não é nossa stack)
- 15 IAs com emoji (Simone 👑, Anna Laura 💰…) — conflita com Sennin 12 diretores
- Blueprint IA Mãe Athena — Sophia/0613-B já cobre
- Cohere como core LLM (vendor lock-in desnecessário)
- Frontend React/Vite proposto (DAP4 já tem frontend world-class)
- Drizzle schemas TS (Supabase migrations SQL é SSOT)

## O que arquivar

Roadmap 10k oficinas SaaS → considerar quando DAP AI virar produto.

## Tasks novas sugeridas pro master-todo

- [ ] Ingerir dataset Manus no RAG `ops_crm_insights` (Walter CKO)
- [ ] Auditoria segurança: HMAC em kommo-webhook + meta-webhook
- [ ] Implementar max_steps no loop Anna (se não tiver)
- [ ] Adicionar field `score` em crm_leads + tool Anna `compute_score`
- [ ] Atualizar RTBM Bosch/Prime com as 9 personas reais
