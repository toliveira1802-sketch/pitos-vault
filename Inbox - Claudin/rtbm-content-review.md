---
type: review
date: 2026-04-18
project: DAP4.0
topic: RTBM content review DAP Prime + Bosch pré-deploy Anna live
tags: [review, rtbm, content, dap4, anna, pre-deploy]
---

# RTBM Content Review — DAP Prime + DAP Bosch

Review de `dap_prime.md` e `dap_bosch.md` em `C:\dev\dap4\agents\config\rtbm\` antes de serem injetados no system prompt da Anna em produção via `rtbm_loader.py`.

---

## 1. Resumo executivo

| Arquivo | Verdict | Completude estimada |
|---|---|---|
| `dap_prime.md` | **BLOCK** | ~20% |
| `dap_bosch.md` | **BLOCK** | ~25% |

Ambos os arquivos são **esqueletos explicitamente marcados como `TODO Thales`** pelo próprio autor, com o disclaimer `"Template inicial. Thales escreve as regras reais aqui."` no topo. Injetar isso no prompt da Anna hoje = Anna sem voz, sem produtos, sem FAQ, sem handoff objetivo. Ela vai improvisar, e improviso em WhatsApp de lead premium quebra a marca na primeira interação.

**Nenhum dos arquivos é shippable.** Seções críticas (Persona, Produtos, Casos de entrada, Exemplos de resposta, FAQ, Handoff) **não existem** — só há um rascunho de "Escopo da marca" + "Regras" + "Linguagem" + `## TODO Thales`.

---

## 2. DAP Prime — review seção-por-seção

### 2.1 Estrutura esperada vs. atual

| Seção esperada | Presente? | Status |
|---|---|---|
| Persona | Parcial (2 linhas em "Linguagem") | Gap crítico |
| Produtos e serviços | **Ausente** | Gap crítico |
| Casos comuns de entrada | **Ausente** | Gap crítico |
| Exemplos de resposta | **Ausente** (listado como TODO) | Gap crítico |
| FAQ técnica | **Ausente** | Gap crítico |
| Handoff rules | **Ausente** (há "Gatilhos de escalada imediata" remetendo ao código) | Gap crítico |

### 2.2 O que existe

- **Escopo da marca** (linhas 6-10): enxuto, concreto — marcas atendidas, WhatsApp, pipeline Kommo. OK.
- **Regras que a Anna precisa honrar** (linhas 12-19): três regras bem desenhadas e objetivas ("nunca preço sem valor", "nunca prazo sem inspeção", "nunca parecer sem ver carro"). Alta qualidade, mas insuficiente como manual de conversa.
- **Linguagem** (linhas 21-25): direção boa ("terceira via entre formal e informal", "nunca 'vc'", "nome na primeira linha"). Mas é meia dúzia de linhas pra marca premium — precisa de muito mais específico.
- **Gatilhos de escalada** (linhas 27-30): delegado a `anna-inbox.worker.ts` via `matchesGuardrailKeyword`. Está bem arquiteturalmente (DRY, fonte única) — mas o arquivo precisa referenciar qual keyword dispara o quê, pra Anna saber **antecipar** escalação e não apenas reagir depois que o worker corta.

### 2.3 Gaps críticos + edits sugeridos

**Gap: Persona editorial "Lobo Estrategista diluído" não aparece.**

A referência do Thales é tom editorial, autoridade técnica, cinematográfico (CLAUDE.md). Hoje o doc só diz "terceira via entre formal e informal". Isso é genérico — poderia ser qualquer oficina de classe média.

Edit sugerido (exemplo, a validar com Thales):

```markdown
## Persona

Anna Prime é a voz da Doctor Auto Prime no WhatsApp. Fala como uma
consultora sênior de carro alemão: calma, confiante, técnica na
medida. Nunca vendedora. Nunca submissa.

- Domina o vocabulário BMW/Audi/Mercedes/VW/Porsche — cita modelos,
  motores (B48, B58, EA888, M276), sistemas (DSG, ZF 8HP, xDrive)
  com naturalidade quando o cliente cita.
- Pergunta antes de afirmar. "Qual o modelo e ano?" vem antes de
  qualquer diagnóstico.
- Não usa diminutivo ("carrinho", "problemazinho") nem exclamação
  dupla. Emoji: no máximo um por mensagem, e só quando faz sentido.
- Trata o cliente pelo nome desde a primeira resposta.
```

**Gap: Produtos e serviços não listados.**

Anna não sabe o que a Prime vende. Edit:

```markdown
## Produtos e serviços Prime

- Manutenção preventiva programada (revisão 10k/20k/40k/60k km)
- Diagnóstico eletrônico multimarca (ISTA, VCDS, XENTRY)
- Troca de óleo + filtros com peças OE/OEM
- Correntes de comando, bombas d'água, juntas de tampa de válvula
- Suspensão: amortecedores OE, buchas, bieletas, rolamentos
- Freios: pastilhas, discos, sensores
- Caixa DSG/ZF 8HP: troca de óleo especializada
- Retrofit de módulos, codificação, adaptações

Serviços fora de escopo Prime (redirecionar): funilaria, vidros,
estética, elétrica pesada.
```

**Gap: Casos comuns de entrada.**

Sem isso Anna não sabe reconhecer intenção. Edit:

```markdown
## Casos comuns de entrada (WhatsApp)

1. "Quanto é a revisão do meu BMW 320i 2019?"
2. "Tá fazendo um barulho no motor quando acelera"
3. "Meu mecânico disse que precisa trocar a corrente, vcs fazem?"
4. "Vi vocês no Instagram, queria um orçamento"
5. "Vcs trabalham com Porsche Macan?"
6. "Levei em outra oficina e não resolveram, queria uma segunda opinião"
7. "Quanto tempo o carro fica aí?"
8. "Aceita cartão em quantas vezes?"
9. "Qual o endereço?"
10. "Vcs dão garantia?"

Para cada um, Anna segue o roteiro de qualificação em 3 turnos
(ver próxima seção).
```

**Gap: Exemplos de resposta.**

Hoje zero. Listado como TODO. Precisa de Q&A pareados mostrando:
- Como redirecionar pedido de preço sem soltar número
- Como fazer qualificação em 3 turnos (modelo/ano → sintoma/histórico → agendamento)
- Como escalar pro Thales (+5511967291822) quando fora do escopo da Anna

**Gap: FAQ técnica.**

Horário, endereço, formas de pagamento, tempo médio, garantia — **nada**. Anna vai inventar ou dizer "consulte nossa equipe", que é exatamente o anti-padrão.

**Gap: Handoff rules.**

"Gatilhos de escalada imediata (mantido pelo código)" é bom arquiteturalmente, mas a Anna ainda precisa de regras **dentro do RTBM** pra decidir quando:
- escalar pro Thales (qual número, qual horário, qual mensagem de handoff)
- marcar visita (qual link de agenda? Calendly? planilha?)
- encerrar conversa (polidez premium, não corte seco)

---

## 3. DAP Bosch — review seção-por-seção

### 3.1 Estrutura esperada vs. atual

Mesmo esqueleto do Prime. Todas as 6 seções esperadas ausentes ou parciais.

### 3.2 O que existe

- **Escopo da marca Bosch** (linhas 6-12): WhatsApp, pipeline Kommo, diferencial comunicacional declarado ("rapidez, custo-benefício, revisão confiável"). **Ponto forte:** explicita "NÃO usar tom editorial Prime" — diferenciação intencional.
- **Regras que a Anna precisa honrar** (linhas 14-21): três regras boas. Diferencial positivo vs. Prime: aqui **permite faixa de preço** ("revisão varia entre X e Y") desde que condicionada à inspeção. Isso é realista pro público Bosch.
- **Linguagem** (linhas 23-26): "mais direta e prática que Prime, coloquial-profissional, destacar selo Bosch". Direção clara.

### 3.3 Gaps críticos + edits sugeridos

**Gap: Persona Bosch.**

Hoje só existe contraposição negativa ("não usar tom Prime"). Precisa de persona positiva. Edit:

```markdown
## Persona

Anna Bosch é técnica, rápida e confiável. Fala como consultora de
uma autorizada Bosch Car Service que entende que o cliente tá
comparando 3 oficinas via WhatsApp e quer resposta clara.

- Objetiva. Uma resposta, uma decisão. Sem rodeio.
- Usa "a gente", não "nós". Coloquial mas profissional.
- Cita o selo Bosch Car Service nas duas primeiras respostas —
  é o principal diferencial de confiança.
- Dá faixa de preço quando insistem, condicionada à inspeção.
- Não promete nada antes do carro entrar.
```

**Gap: Produtos Bosch.**

Precisa listar o que a autorizada Bosch atende. Marcas populares (GM, VW, Fiat, Hyundai, Toyota)? Diesel? Injeção? Freios ABS? Arrefecimento? Sem isso Anna filtra errado.

**Gap: Casos de entrada Bosch.**

Perfis diferentes do Prime. Exemplos esperados: "Minha revisão tá atrasada, quanto é?", "Tá acendendo a luz do motor", "Preciso de um laudo pra vender o carro". Adicionar 8-10.

**Gap: Exemplos de resposta.**

Zero. Listado como TODO. Especialmente crítico o caso "cliente comparando 3 oficinas" — Thales explicitamente pediu isso na linha 40-41. Precisa de 3-5 Q&A canônicos.

**Gap: FAQ técnica.**

Horário, endereço, marcas atendidas, formas de pagamento, tempo médio — nada.

**Gap: Handoff rules.**

Mesma lacuna do Prime. Pra onde escalar? Mesmo Thales ou equipe Bosch dedicada?

---

## 4. Voice comparison lado-a-lado

**Hoje os dois docs soam mais como irmãos gêmeos do que como marcas distintas**, porque ambos são esqueletos quase idênticos em formato. A diferenciação está declarada em *uma frase* ("NÃO usar o tom editorial Prime") mas não demonstrada em nenhum exemplo.

Snippets paralelos:

| Dimensão | Prime (atual) | Bosch (atual) |
|---|---|---|
| Linguagem | "Terceira via entre formal e informal. Nunca 'vc' ou 'blz'. Nunca 'prezado senhor'." | "Mais direta e prática que Prime. Coloquial-profissional." |
| Preço | "Nunca soltar preço sem antes construir valor." | "Sem preço sem diagnóstico... pode dar faixa (ex: revisão varia entre X e Y)." |
| Prazo | "Nunca prometer prazo sem inspeção." | "1 dia útil pra revisão simples. Nunca prometer 'hoje'." |

**Diagnóstico:** a regra de diferenciação está bem pensada (Prime = construir valor; Bosch = faixa OK com ressalva), mas a **voz em si não está escrita** em nenhum dos dois. Sem exemplos de resposta lado a lado, a Anna vai colapsar os dois tons num único "robô de oficina" — exatamente o anti-padrão que o Thales quer evitar.

**Teste decisivo:** peça pra Anna responder "bom dia, quanto é a revisão?" nos dois tenants e leia as duas respostas em voz alta. Se um leigo não conseguir dizer qual é Prime e qual é Bosch, o RTBM falhou. Hoje, falha.

---

## 5. Dados críticos faltando

Anna **precisa saber e hoje não sabe**:

- **Endereço físico** da Prime e da Bosch (são o mesmo endereço? duas unidades?).
- **Horário de atendimento** (seg-sex? sábado? fechamento almoço?).
- **Formas de pagamento** aceitas (Pix, cartão, parcelamento em quantas vezes, sem juros até quando, cheque não?).
- **Política de orçamento** (orçamento é gratuito? cobra diagnóstico? quando vira crédito na OS?).
- **Garantia** (quanto tempo, cobre o quê, peça OEM vs. paralelo muda garantia?).
- **Tempo médio de permanência** (revisão simples = 1 dia? overhaul = 3-5 dias? retém cliente pra estimar).
- **Como marcar visita** (link Calendly? WhatsApp direto? planilha interna? quem confirma?).
- **Marcas atendidas Bosch** (lista explícita — diesel? elétricos? híbridos?).
- **Limites de escalação** (quando Anna escala pro Thales? +5511967291822 conforme memory, mas com qual frase? em qual horário?).
- **Serviços fora de escopo** (funilaria, estética, elétrica pesada, retrofit de som — redirecionar pra onde? DAP Estética/Funilaria ainda é futuro).
- **Promoções vigentes** (ou "sem campanhas de preço, Prime não desconta" como política explícita).
- **Número oficial de apresentação** (Anna se apresenta como "Anna da Doctor Auto Prime" ou "Anna do time da Doctor Auto"? Singular vs. plural).
- **Diferencial Prime explícito** (dinamômetro? ECU tuning? retrofit? — justificar o ticket maior).
- **Como lidar com lead que já é cliente** (reconhecer histórico na Kommo? saudação diferente?).

Sem isso Anna responde com "entre em contato com a equipe" — o anti-padrão que o Thales vetou.

---

## 6. Top 5 edits priority antes do deploy

Ordem de execução, ranked por impacto × facilidade de capturar:

### 1. Sentar 45 min com Thales e preencher FAQ técnica dos dois docs

Endereço, horário, pagamento, garantia, tempo médio, política de orçamento. São dados operacionais factuais — tabela, 30 minutos. Sem isso, Anna é um call center genérico. **Impacto: maior.** **Custo: mínimo.**

### 2. Escrever 5 Exemplos de resposta canônicos por tenant (10 no total)

Priorizar os casos: pedido de preço direto, sintoma vago ("fazendo barulho"), cliente comparando oficinas, fora de escopo, lead frio do Instagram. Q&A pareado com Q do cliente + A ideal da Anna + racional do por quê daquele tom. É aqui que o Prime vs. Bosch vira marca, não regra.

### 3. Listar Produtos e serviços concretos

Prime: motor alemão, DSG, suspensão OE, diagnóstico ISTA/VCDS/XENTRY. Bosch: marcas populares + lista Bosch Car Service padrão. Sem isso Anna filtra lead errado e manda Porsche Cayenne V8 biturbo pra pipeline Bosch.

### 4. Definir Handoff rules objetivas dentro do próprio RTBM

Matriz: **se** {condição objetiva, ex: "lead fala em Porsche + ano < 2018" ou "valor estimado > R$15k"} **então** {ação, ex: "agendar com Thales via +5511967291822, horário comercial"}. Condições objetivas, nunca "se for difícil". Isso destrava a escalação pro Thales sem depender de julgamento do LLM em runtime.

### 5. Escrever Persona em 8-12 bullets por tenant, com exemplos do que NUNCA dizer

Hoje são 4 linhas de "Linguagem". Precisa virar Persona com voz, vocabulário, cadência, emoji, tratamento, e uma lista negativa concreta ("nunca dizer: 'vamos dar um jeitinho', 'fica tranquilo', 'é rapidinho', 'com certeza resolve'"). Lista negativa é o que protege a marca quando o LLM improvisa.

---

## Recomendação final

**Não faça deploy da Anna em produção com esses dois arquivos como estão.** O `rtbm_loader.py` vai injetar um system prompt que diz literalmente "preencher com... TODO Thales" pra Anna — e ela vai herdar essa vacuidade na conversa com lead real.

Fluxo sugerido:
1. Thales reserva 2h (pode ser comigo no ClickUp agendado).
2. Expandimos os 5 edits acima, nessa ordem.
3. Rodamos teste cego: 10 mensagens WhatsApp reais de leads passados da Kommo, vistas pela Anna com o RTBM novo, revisadas por Thales uma a uma.
4. Só depois: deploy em Phase 1a.

Sem esse gate, a Anna vai queimar leads premium antes do fim da primeira semana.
