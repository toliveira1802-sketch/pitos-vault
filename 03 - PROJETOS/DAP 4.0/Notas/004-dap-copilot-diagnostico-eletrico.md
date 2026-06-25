# DAP Copilot — Diagnóstico Elétrico Inteligente
**Data:** 2026-04-10
**Status:** #conceito · #prioridade-alta
**Área:** DAP AI · DAP Dev · Produto

---

## O Problema que ele resolve

O mecânico usa o scanner, lê o código de erro — mas não sabe onde está o problema de verdade.

Por quê?

Porque cada nó do sistema elétrico tem uma **margem de corrente normal**. Quando a corrente sai dessa margem, tem algo errado naquele ponto. Mas sem saber qual é a margem certa de cada nó, o mecânico fica chutando:

- É a bateria?
- É o módulo?
- É a peça X?
- É a fiação?

Resultado: troca peça errada → cliente insatisfeito → prejuízo → reputação comprometida.

---

## O que o DAP Copilot faz

1. Mecânico mede a corrente em cada nó do sistema
2. Copilot sabe a **margem esperada** de cada ponto para cada modelo de veículo
3. Compara a medida real com a margem esperada
4. Aponta: **"o desvio está NESTE nó — aqui é o problema"**
5. Indica o que fazer passo a passo
6. **Cada caso resolvido alimenta o sistema** — fica mais inteligente continuamente

---

## Por que é uma propriedade exclusiva

Nenhuma oficina do Brasil tem um sistema assim.

O mercado usa scanner para ler código de erro e para por aí. O conhecimento de **microvariações de corrente por nó** existe na cabeça dos mecânicos sêniores — mas não está sistematizado em nenhum lugar.

O DAP vai ser o primeiro a sistematizar isso. É território completamente aberto.

---

## Como ele se retroalimenta

```
Carro entra com problema elétrico
        ↓
Mecânico mede corrente nos nós
        ↓
Copilot compara com margem esperada
        ↓
Diagnóstico correto → problema resolvido
        ↓
Caso documentado no RAG Técnico
        ↓
Sistema aprende mais um padrão
        ↓
Próximo carro com problema similar → diagnóstico mais preciso
        ↓
[loop infinito de aprendizado]
```

---

## Como se conecta ao ecossistema

- **RAG Técnico:** cada diagnóstico vira conhecimento estruturado
- **DAP Ensina:** vira aula no minicurso "Diagnóstico Elétrico de Importados"
- **DAP Studio:** vira vídeo no YouTube explicando o caso
- **DAP Dev:** interface do Copilot integrada ao sistema de OS
- **DAP AI SaaS:** produto vendável para outras oficinas do Brasil

---

## Próximos passos para desenvolver

- [ ] Mapear todos os nós elétricos dos veículos mais atendidos (BMW, Audi, Mercedes, VW)
- [ ] Documentar margens de corrente para cada nó por modelo
- [ ] Construir banco de dados de padrões de falha
- [ ] Desenvolver interface de input (mecânico insere medida → Copilot responde)
- [ ] Integrar ao RAG Técnico como fonte de dados
- [ ] Integrar ao DAP Dev na tela de OS

---

## Frase que resume

> "O scanner fala o sintoma. O Copilot fala a causa."

---

*DAP 4.0 · DAP Copilot · 2026-04-10*
