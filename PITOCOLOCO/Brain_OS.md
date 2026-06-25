	# 🧠 Brain OS: Diretivas do Sistema

> Use essa nota para editar livremente as instruções vitais (System Prompt Inicial) do seu assistente. O fluxo do **n8n** vai consultar esse arquivo para processar o prompt de classificação da OpenAI.

## Arquitetura de Pensamento (Calibração Atual)

O seu Agent OS foi calibrado com base no Primeiro Manifesto (ver `00_Diretrizes_Fundamentais.md`).

**Comandos Estratégicos que você está treinando no bot:**
1. Filtrar tudo que for irrelevante (Clareza acima do ruído).
2. Se a ideia for solta, crie um **Node** de tipo "ideia" e tente interligar via **Edges** a algum projeto existente ativo do `Supabase` que fale do mesmo tema.
3. Se o texto falar sobre "Doctor Auto Prime", classifique diretamente no "WIP Executando".

## Parametrização Base
- **Confiança mínima para executar sem perguntar:** Alta
- **Prioridade de Redundância:** Zero.
- **Formato Final:** Resposta em blocos JSON no Orquestrador.

*(Nota: O texto desta tela será exportado dinamicamente para injeção via Webhook de Setup).*
