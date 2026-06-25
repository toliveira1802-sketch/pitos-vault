---
title: RAG Seed — DAP 4.0 knowledge base (alemães premium)
date: 2026-04-14
brand: all
topic: index
tags: [dap4, rag-seed, index, ingestion-ready]
---

# RAG Seed — Primeiro passe do knowledge base DAP 4.0

Base de conhecimento curada para ingestão no ChromaDB do DAP 4.0. Foco: 4 marcas alemãs premium (BMW, Audi, Mercedes-Benz, VW). 5 tópicos por marca = **20 notas**.

## Voz

Técnico sem arrogância. Confiante sem petulância. Premium e acessível. Números reais, exemplos concretos de modelos (F30, B9, W205, Mk7.5). Nenhum valor de garantia/SLA inventado — sempre faixa ou "depende da OS".

## Estrutura

```
rag-seed/
├── README.md                ← este arquivo
├── bmw/
│   ├── bmw-01-revisao-por-km.md
│   ├── bmw-02-problemas-comuns.md
│   ├── bmw-03-ecu-tcu-remap.md
│   ├── bmw-04-pecas-originais-vs-paralelas.md
│   └── bmw-05-faq-cliente.md
├── audi/
│   ├── audi-01-revisao-por-km.md
│   ├── audi-02-problemas-comuns.md
│   ├── audi-03-ecu-tcu-remap.md
│   ├── audi-04-pecas-originais-vs-paralelas.md
│   └── audi-05-faq-cliente.md
├── mercedes/
│   ├── mercedes-01-revisao-por-km.md
│   ├── mercedes-02-problemas-comuns.md
│   ├── mercedes-03-ecu-tcu-remap.md
│   ├── mercedes-04-pecas-originais-vs-paralelas.md
│   └── mercedes-05-faq-cliente.md
└── vw/
    ├── vw-01-revisao-por-km.md
    ├── vw-02-problemas-comuns.md
    ├── vw-03-ecu-tcu-remap.md
    ├── vw-04-pecas-originais-vs-paralelas.md
    └── vw-05-faq-cliente.md
```

## Inventário + status

| # | Arquivo | Tópico | Status |
|---|---------|--------|--------|
| 01 | bmw/bmw-01-revisao-por-km.md | revisao | pronto pra ingestão |
| 02 | bmw/bmw-02-problemas-comuns.md | defeitos | pronto pra ingestão |
| 03 | bmw/bmw-03-ecu-tcu-remap.md | remap | pronto pra ingestão |
| 04 | bmw/bmw-04-pecas-originais-vs-paralelas.md | pecas | pronto pra ingestão |
| 05 | bmw/bmw-05-faq-cliente.md | faq | pronto pra ingestão |
| 06 | audi/audi-01-revisao-por-km.md | revisao | pronto pra ingestão |
| 07 | audi/audi-02-problemas-comuns.md | defeitos | pronto pra ingestão |
| 08 | audi/audi-03-ecu-tcu-remap.md | remap | pronto pra ingestão |
| 09 | audi/audi-04-pecas-originais-vs-paralelas.md | pecas | pronto pra ingestão |
| 10 | audi/audi-05-faq-cliente.md | faq | pronto pra ingestão |
| 11 | mercedes/mercedes-01-revisao-por-km.md | revisao | pronto pra ingestão |
| 12 | mercedes/mercedes-02-problemas-comuns.md | defeitos | pronto pra ingestão |
| 13 | mercedes/mercedes-03-ecu-tcu-remap.md | remap | pronto pra ingestão |
| 14 | mercedes/mercedes-04-pecas-originais-vs-paralelas.md | pecas | pronto pra ingestão |
| 15 | mercedes/mercedes-05-faq-cliente.md | faq | pronto pra ingestão |
| 16 | vw/vw-01-revisao-por-km.md | revisao | pronto pra ingestão |
| 17 | vw/vw-02-problemas-comuns.md | defeitos | pronto pra ingestão |
| 18 | vw/vw-03-ecu-tcu-remap.md | remap | pronto pra ingestão |
| 19 | vw/vw-04-pecas-originais-vs-paralelas.md | pecas | pronto pra ingestão |
| 20 | vw/vw-05-faq-cliente.md | faq | pronto pra ingestão |

## Metadata pra ingestão no Chroma

Cada nota tem frontmatter YAML com: `title`, `date`, `brand`, `topic`, `tags`. Parse recomendado:

- **collection_name:** `dap_kb_alemaes_v1`
- **chunking:** por H2 (200–500 tokens por chunk)
- **embedding:** `text-embedding-3-small` ou `bge-m3` multilíngue
- **metadata por chunk:** brand, topic, file_path, heading_path

## Gaps conhecidos (próximo passe)

- Falta: elétricos/híbridos (BMW iX, Audi e-tron, EQE/EQS, id.4/id.Buzz) — manutenção bateria HV, refrigeração, carregador.
- Falta: garantia/SLA **específicos DAP** (preço fixo, prazo fixo, política de retorno) — proposital; Thales define internamente.
- Falta: diesel profundo (Amarok foi tangenciado; faltam Touareg TDI, ML350 CDI, E250 CDI específicos).
- Falta: funilaria/pintura (fora do escopo atual, entra quando DAP Funilaria abrir).
- Falta: linha sport extrema (M5 F90, RS6 C8, E63 S W213, Porsche 911/Macan — Porsche não é VW AG premium mas aparece).
- Valores R$ são faixas médias 2026 BR — precisam revisão trimestral com compras.

## Próximos passos sugeridos

1. Ingestão Chroma com script em `C:\dev\dap4\backend` ou serviço FastAPI.
2. Validação com Sophia/Ana: rodar 20 perguntas típicas, medir recall.
3. Fase 2: expandir pra elétricos/híbridos + diesel premium.
4. Fase 3: adicionar PDFs técnicos (TIS, ETK, SSP) processados.
5. Fase 4: conteúdo dual-purpose — virar minicurso Hotmart / YouTube roteiro.
