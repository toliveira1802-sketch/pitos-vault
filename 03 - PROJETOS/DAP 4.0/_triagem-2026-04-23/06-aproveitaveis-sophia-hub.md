# 06 — Aproveitáveis do Sophia Hub

Triagem 2026-04-23. Fonte: `C:\Users\docto\Downloads\Evaluate These Documents\`.
A arquitetura Sophia Hub (Vercel + MySQL Drizzle + CRM Duplo + Cohere) **não vai ser absorvida**. Este doc isola as **peças com valor real** — snippet bruto + veredicto curto.

---

## 0. Nota importante sobre o bundle

O arquivo `ana.js` entregue está **truncado**: começa no meio da função `vigilanteVerificar` (linha 1 é um `return` órfão) e referencia `ANA_TOOLS` (linha 220) e `ANA_SYSTEM_PROMPT` (linha 219) que **não estão no bundle**. As 5 tools aparecem na `switch` do executor (linhas 185-194), mas os **JSON schemas e o system prompt da Ana** ficaram fora. Busca grep confirmada: nenhum arquivo do ZIP contém `input_schema` nem `name: "vigilante_verificar"`.

**Ação:** se precisar dos schemas, pedir o `ana.js` completo (ou o arquivo onde `ANA_TOOLS` é definido). O que está aqui é **só implementação** das tools + loop agêntico.

---

## 1. Tools da Ana — implementações (ana.js)

Cinco handlers: `vigilante_verificar` (truncado), `analista_qualificar`, `reativador_engajar`, `vendas_suporte`, `agendador_confirmar`. Executor na linha 185.

### 1.1 `analistaQualificar` — scoring + classificação de lead (ana.js:5-44)

```javascript
async function analistaQualificar({ lead_id, contexto, veiculo, servico_interesse }) {
  const res = await claude.messages.create({
    model: "claude-haiku-4-5-20251001",
    max_tokens: 500,
    messages: [{
      role: "user",
      content: `Você é um especialista em qualificação de leads para oficina automotiva.
Analise este lead e retorne APENAS um JSON válido:

Lead ID: ${lead_id}
Contexto: ${contexto}
Veículo: ${veiculo || "não informado"}
Serviço de interesse: ${servico_interesse || "não informado"}

Retorne:
{
  "nota": (0-100),
  "classificacao": ("A" | "B" | "C"),
  "funil": ("isca" | "upsell" | "projeto" | "pos_venda" | "war_room"),
  "urgencia": ("alta" | "media" | "baixa"),
  "proxima_acao": "descrição da próxima ação recomendada",
  "potencial_ticket": ("alto" | "medio" | "baixo"),
  "justificativa": "breve explicação da nota"
}`,
    }],
  });
  // fallback em caso de parse falhar: nota 50, B, isca, media...
}
```

**Veredicto:** framework de scoring (0-100, A/B/C, 5 funis) **está alinhado** com o `project_framework_leads_novos.md` que já rodou (5 eixos, 0-100, 4 tiers). Refatorar p/ usar o framework oficial em vez desse enum mais frouxo. **Reaproveitar:** o padrão de Haiku 4.5 c/ max_tokens 500 + JSON regex extract + fallback mudo. Útil como prompt-base pro qualificador da Anna em prod.

### 1.2 `reativadorEngajar` — estratégia por funil (ana.js:46-97)

```javascript
const estrategias = {
  isca: "Relembre o benefício inicial, ofereça algo novo, seja leve e curioso",
  upsell: "Mencione que o serviço está disponível, urgência suave",
  projeto: "Pergunte se ainda faz sentido avançar, mostre disponibilidade",
  pos_venda: "Check-in genuíno sobre a experiência, solicite feedback",
  war_room: "Abordagem direta, oferta especial limitada, última tentativa",
};

const contextoExtra = campanha
  ? `\nCampanha ativa: "${campanha.nome}" — inspire-se na mensagem base: "${campanha.mensagem_base || ""}"`
  : "";

const res = await claude.messages.create({
  model: "claude-haiku-4-5-20251001",
  max_tokens: 300,
  messages: [{
    role: "user",
    content: `Crie uma mensagem de reativação para WhatsApp/Kommo.

Contexto:
- Funil: ${funil}
- Estratégia: ${estrategias[funil]}
- Último contato: ${ultimo_contato || "desconhecido"}
- Motivo parada: ${motivo_parada || "desconhecido"}
- Negócio: Doctor Auto (oficina automotiva premium)${contextoExtra}

Regras:
- Máximo 3 linhas
- Natural, não robótico
- Não mencione que é IA
- Não force venda direta (exceto war_room)
- Termine com pergunta aberta

Retorne APENAS a mensagem, sem explicações.`,
  }],
});
```

**Veredicto:** **ouro puro.** O dicionário `estrategias` + as 5 "regras" de estilo (3 linhas, não robótico, não-IA, pergunta aberta, sem venda direta exceto war_room) são **transcreveis direto** para o `guardrails-ana-v0` e/ou system prompt da Anna em prod. Guardar como **base canônica** para qualquer prompt de reativação futuro.

### 1.3 `vendasSuporte` — tratamento de objeção + escalação (ana.js:99-139)

```javascript
async function vendasSuporte({ lead_id, servico, veiculo, objecao, preco_ofertado }) {
  const res = await claude.messages.create({
    model: "claude-sonnet-4-20250514",
    max_tokens: 600,
    messages: [{
      role: "user",
      content: `Você é um especialista em vendas de serviços automotivos premium.

Situação:
- Serviço: ${servico}
- Veículo: ${veiculo || "não informado"}
- Objeção do cliente: ${objecao}
- Preço ofertado: ${preco_ofertado ? `R$ ${preco_ofertado}` : "não informado"}

Política da Doctor Auto:
- Margem: 35-120%
- Desconto: NUNCA sem autorização
- Posicionamento: premium, qualidade superior, garantia

Retorne JSON:
{
  "argumento_principal": "argumento mais forte para usar agora",
  "argumentos_secundarios": ["argumento 2", "argumento 3"],
  "upsell_sugerido": "serviço complementar que faz sentido oferecer (ou null)",
  "desconto_recomendado": false,
  "escalar_para_sophia": (true se a situação precisar de aprovação),
  "mensagem_sugerida": "mensagem pronta para mandar ao cliente"
}`,
    }],
  });
}
```

**Veredicto:** **reaproveitar a política ("Margem: 35-120%", "Desconto: NUNCA sem autorização", "premium/qualidade/garantia")** como bloco reutilizável em todos os prompts de venda. O padrão `escalar_para_sophia: bool` é útil para a escalação humana (hoje Thales, no futuro Sophia/Conselho). Modelo é Sonnet 4 — preço mais alto, mas justificado para venda/objeção. Refatorar p/ usar o model atual (Sonnet 4.6 ou Haiku 4.5 dependendo da criticidade).

### 1.4 `agendadorConfirmar` — Kommo tasks + mensagens por ação (ana.js:141-179)

```javascript
async function agendadorConfirmar({ acao, lead_id, data_hora, unidade, servico, observacoes }) {
  const KOMMO_TOKEN = process.env.KOMMO_TOKEN;
  const KOMMO_DOMAIN = process.env.KOMMO_DOMAIN;
  const responsaveis = { prime: "João ou Pedro", bosch: "Roniela ou Antônio" };

  try {
    await fetch(`https://${KOMMO_DOMAIN}/api/v4/tasks`, {
      method: "POST",
      headers: { Authorization: `Bearer ${KOMMO_TOKEN}`, "Content-Type": "application/json" },
      body: JSON.stringify([{
        text: `[${acao.toUpperCase()}] ${servico || "Serviço"} — ${data_hora || "A confirmar"}\nResponsável: ${responsaveis[unidade]}\n${observacoes || ""}`,
        complete_till: data_hora ? Math.floor(new Date(data_hora).getTime() / 1000) : null,
        task_type_id: 1,
        entity_id: parseInt(lead_id),
        entity_type: "leads",
      }]),
    });
  } catch (e) { console.error("Erro ao criar task no Kommo:", e); }

  if (acao === "marcar") {
    const campanhas = await buscarCampanhasAtivas();
    for (const c of campanhas) await atualizarCampanha(c.id, { agendados: 1 });
  }

  const msgs = {
    marcar: `Agendamento confirmado! Venha falar com ${responsaveis[unidade]} na unidade ${unidade === "prime" ? "Doctor Auto Prime" : "Doctor Auto Bosch"}. Te esperamos! 🔧`,
    reagendar: `Reagendamento confirmado! Anotado aqui para ${data_hora}. Qualquer dúvida é só chamar!`,
    cancelar: `Cancelamento registrado. Quando quiser reagendar é só me chamar. Até logo!`,
    lembrete: `Só passando pra lembrar do seu agendamento amanhã na Doctor Auto! Qualquer imprevisto me avisa.`,
    ritual_entrega: `Seu carro está pronto! A equipe preparou um checklist completo. ${responsaveis[unidade]} vai te mostrar tudo na entrega. Nos vemos em breve! 🎉`,
  };
  return { sucesso: true, acao, lead_id, unidade, responsavel: responsaveis[unidade], mensagem_cliente: msgs[acao], data_hora: data_hora || null };
}
```

**Veredicto:** **só referência.** O endpoint Kommo (`POST /api/v4/tasks` com `entity_type: "leads"`, `task_type_id: 1`, `complete_till` em epoch segundos) é a **receita correta** pra criar task no lead. As 5 mensagens canônicas (`marcar`, `reagendar`, `cancelar`, `lembrete`, `ritual_entrega`) valem como **templates de saída** da Anna. Error handling é fraco (só console.error) — refatorar com retry/DLQ em prod.

### 1.5 Loop agêntico + executor (ana.js:183-244)

```javascript
async function executarTool(nome, input) {
  switch (nome) {
    case "vigilante_verificar": return await vigilanteVerificar(input);
    case "analista_qualificar": return await analistaQualificar(input);
    case "reativador_engajar":  return await reativadorEngajar(input);
    case "vendas_suporte":      return await vendasSuporte(input);
    case "agendador_confirmar": return await agendadorConfirmar(input);
    default: return { erro: `Tool desconhecida: ${nome}` };
  }
}

export async function rodarAna(leadId, novaMsg, leadNome = null) {
  const historico = await carregarHistorico(leadId);
  const messages = [...historico, { role: "user", content: novaMsg }];
  let resposta = null;

  while (true) {
    const res = await claude.messages.create({
      model: "claude-sonnet-4-20250514",
      max_tokens: 1024,
      system: ANA_SYSTEM_PROMPT,       // <-- NÃO ENTREGUE NO BUNDLE
      tools: ANA_TOOLS,                 // <-- NÃO ENTREGUE NO BUNDLE
      messages,
    });

    if (res.stop_reason === "tool_use") {
      const toolUse = res.content.find((b) => b.type === "tool_use");
      messages.push({ role: "assistant", content: res.content });
      const resultado = await executarTool(toolUse.name, toolUse.input);
      messages.push({
        role: "user",
        content: [{ type: "tool_result", tool_use_id: toolUse.id, content: JSON.stringify(resultado) }],
      });
      continue;
    }

    resposta = res.content.find((b) => b.type === "text")?.text;
    break;
  }

  messages.push({ role: "assistant", content: resposta });
  await salvarHistorico(leadId, leadNome, messages);
  return { resposta };
}
```

**Veredicto:** loop agêntico **canônico Anthropic SDK** — `stop_reason === "tool_use"` → push `tool_use` + `tool_result` → continue até `end_turn`. **Reaproveitar o shape.** Hoje o gateway dap4 faz isso em Python/FastAPI; se for portar pra Node algum dia, esse é o template. Persistência de histórico (`carregarHistorico`/`salvarHistorico`) é o mecanismo certo — já temos equivalente via `ana_conversas` no Supabase.

---

## 2. Tool schemas (JSON) — NÃO ENTREGUES

Os schemas Anthropic-style `{ name, description, input_schema: { type: "object", properties, required } }` das 5 tools **não estão no bundle**. Referência esperada (reconstruir a partir dos handlers):

| Tool | Input observado no handler |
|---|---|
| `vigilante_verificar` | (truncado — handler não recuperável do bundle) |
| `analista_qualificar` | `lead_id`, `contexto`, `veiculo?`, `servico_interesse?` |
| `reativador_engajar` | `lead_id`, `funil` (enum: isca\|upsell\|projeto\|pos_venda\|war_room), `ultimo_contato?`, `motivo_parada?` |
| `vendas_suporte` | `lead_id`, `servico`, `veiculo?`, `objecao`, `preco_ofertado?` |
| `agendador_confirmar` | `acao` (enum: marcar\|reagendar\|cancelar\|lembrete\|ritual_entrega), `lead_id`, `data_hora?`, `unidade` (enum: prime\|bosch), `servico?`, `observacoes?` |

**Ação:** se for recriar os schemas, puxar desses inputs + padronizar com o framework oficial de lead scoring. Não vale pedir o arquivo original — reconstruir é mais rápido.

---

## 3. Prompts técnicos (PromptsPage.tsx, dbPrompts.ts)

**PromptsPage.tsx** é **apenas UI de CRUD** (tRPC + Drizzle) para prompts persistidos no DB — sem conteúdo de prompt hardcoded. O que vale guardar:

### 3.1 Taxonomia de categorias + tons (PromptsPage.tsx:16-31)

```typescript
const CATEGORIES = [
  { value: "system", label: "System" },
  { value: "atendimento", label: "Atendimento" },
  { value: "vendas", label: "Vendas" },
  { value: "pos-venda", label: "Pós-venda" },
  { value: "reativacao", label: "Reativação" },
  { value: "operacional", label: "Operacional" },
  { value: "custom", label: "Custom" },
] as const;

const TONES = [
  { value: "profissional", label: "Profissional & Cordial" },
  { value: "casual", label: "Casual & Amigável" },
  { value: "tecnico", label: "Técnico & Direto" },
  { value: "premium", label: "Premium & Exclusivo" },
] as const;
```

**Veredicto:** **usar assim** — boa taxonomia mínima para organizar a Sala do Conselho Dify e o banco de prompts no Supabase. 7 categorias × 4 tons = matriz razoável. Adicionar ao `sala-do-conselho-dify-dap4.md`.

### 3.2 CRUD + versionamento (dbPrompts.ts:39-73)

O padrão `version: int default 1` + `duplicatePrompt()` que cria cópia inativa com `version: 1` e nome "(cópia)" é **padrão certo** pra prompt lifecycle. A página faz `version: selectedPrompt.version + 1` no save (linha 122). **Reaproveitar como referência** para qualquer editor de prompts que formos construir.

---

## 4. HMAC webhook (webhook.ts:50-74)

**Pattern corretíssimo — guardar como referência canônica pra todo webhook futuro.**

```typescript
import { createHmac, timingSafeEqual } from "crypto";

/**
 * Verifies the HMAC-SHA256 signature of the webhook payload.
 * Signature format: sha256=<hex_digest>
 */
export function verifySignature(
  rawBody: string,
  signature: string | undefined,
  secret: string
): boolean {
  if (!signature || !secret) return false;

  const prefix = "sha256=";
  if (!signature.startsWith(prefix)) return false;

  const receivedHex = signature.slice(prefix.length);
  const expectedHex = createHmac("sha256", secret)
    .update(rawBody, "utf8")
    .digest("hex");

  // Timing-safe comparison to prevent timing attacks
  try {
    const receivedBuf = Buffer.from(receivedHex, "hex");
    const expectedBuf = Buffer.from(expectedHex, "hex");
    if (receivedBuf.length !== expectedBuf.length) return false;
    return timingSafeEqual(receivedBuf, expectedBuf);
  } catch {
    return false;
  }
}
```

**Checklist do que está certo:**
- Usa `node:crypto` nativo, zero deps externas.
- Prefixo `sha256=` (padrão GitHub/Stripe/Kommo).
- **`timingSafeEqual`** em vez de `===` — previne timing attacks.
- Valida **comprimento antes** de comparar buffers (timingSafeEqual joga exception se tamanhos diferem).
- `try/catch` em volta do `Buffer.from(receivedHex, "hex")` — hex inválido não crasha o handler.
- Early returns para ausência de signature/secret/prefix.
- Body bruto como string UTF-8 (importante: nunca comparar sobre o JSON re-serializado).

**Veredicto:** **copiar exato** pra qualquer webhook novo em Node (Kommo webhook no Bosch, Meta Cloud API, etc.). Em Python/FastAPI, o análogo é `hmac.compare_digest(hmac.new(secret.encode(), body, sha256).hexdigest(), received_hex)` — já em uso no gateway dap4. **Usar este trecho como teste de sanidade** do handler Python (mesmo vector de teste de entrada deve bater).

**Observação crítica de segurança que o webhook.ts tem errado (linha 289):**
```typescript
const rawBody = JSON.stringify(req.body);  // ❌ WRONG
```
O `req.body` é o body **já parseado pelo middleware** — re-serializar pode alterar ordem de keys, whitespace e escape de caracteres. **A assinatura nunca vai bater** se o sender não usar exatamente o mesmo serializer JS. **Corrigir:** usar `express.raw({ type: 'application/json' })` no middleware da rota e ler `req.body.toString('utf8')` antes do parse. Isso é um bug latente — deixar registrado pra não repetir.

---

## 5. Schema Drizzle (schema.ts) — listar estrutura

Tabelas no schema.ts / dbExtended.ts (MySQL via Drizzle). Apenas listar — **NÃO migrar** para as 27 tabelas Supabase existentes. Referência de o que o Sophia Hub modelava.

### 5.1 Core (schema.ts)

| Tabela | Colunas-chave | Uso |
|---|---|---|
| `users` | id, openId, email, role (user\|admin) | Auth |
| `agents` | name, status (online/idle/error/offline), costToday, totalCalls, lastHeartbeat | Registry legado dos agentes |
| `leads` | id, name, phone, email, vehicle, stage (Novo Lead/Em Negociação/Agendado/Na Oficina/Pós-Venda), unit (Prime/Bosch), value, persona, channel, closureStatus, crmScore, crmTemperature, daysSinceContact, npsScore, referredBy | **CRM Interno** (leads ativos) |
| `lago_leads` | name, phone, vehicle, temperature (quente/morno/frio), score, lastContactDate, reason, notes | **CRM Externo / Lago** (leads frios ou dormentes) |
| `bays` | name, unit (Prime/Bosch), status (ocupado/livre/manutencao), vehicle, service, progress (0-100), revenueToday, hoursWorked | **Pátio digital** (9 elevadores) |
| `campaigns` | name, type, status (ativa/pausada/finalizada), targetPersona, leadsAlcancados, respostas, conversoes, startDate, endDate | Campanhas de ataque |
| `ana_actions` | action, lead, tool, result (sucesso/erro/pendente), sentiment (positivo/neutro/negativo), escalated, escalationReason, timestamp | Activity feed da Ana |
| `weekly_metrics` | date, leadsNovos, agendamentos, conversoes, weekOf | Agregação semanal |
| `financials` | period, receitaMes, receitaMesAnterior, receitaPrime, receitaBosch, ticketMedio, osAbertas, osFechadas | DRE mensal |

### 5.2 Extended (50 implementações)

`personas`, `persona_journey_steps`, `economy_metrics` (ROI da IA), `funnel_bottlenecks`, `upsell_suggestions`, `objections`, `sales_scripts`, `referrals`, `goals` (categoria: receita\|leads\|conversao\|nps\|economia\|os), `escalation_rules`, `seasonal_triggers`, `monthly_efficiency`, `ia_decision_log`, `revenue_forecast`, `crm_health_snapshots`.

### 5.3 Prompts & RAG & Agent configs

`prompts` (name, category enum, content, isActive, version, agentTarget, variables JSON, tone), `rag_documents`, `rag_knowledge_bases`, `agent_configs` (agentType enum: ia\|bot\|rag; model, maxTokens, tools JSON, systemPromptId FK, channel, unit, flows JSON, knowledgeBaseIds JSON, embeddingModel, chunkSize, chunkOverlap, uptime, avgResponseTime, actionsToday, tokensUsed, messagesDay, responseRate).

**Veredicto sobre o schema inteiro:**
- **`agent_configs`** é o que mais vale a pena refletir no Supabase — hoje nosso `agents` table é mais fraco; aqui há campos operacionais (`uptime`, `avgResponseTime`, `tokensUsed`, `actionsToday`, `messagesDay`, `responseRate`) + config-as-data (`tools`, `flows`, `systemPromptId`, `knowledgeBaseIds`, `chunkSize`, `chunkOverlap`).
- **`crm_health_snapshots`** (overallScore 0-100 + 4 sub-scores + leadsWithoutPhone/followUp + staleLeads + suggestions JSON) é **métrica de higiene de CRM** útil — vale reproduzir no dashboard Sophia Hub interno.
- **`funnel_bottlenecks`** (fromStage, toStage, avgDaysStuck, leadsStuck, lostValue, suggestion) — aproveitar a estrutura para o diagnóstico de gargalos já identificados pelo Manus (avaliar).
- **`ia_decision_log`** (agentName, decision, reasoning, outcome, confidence) — **copiar esse padrão** pro Parliament. Hoje não temos log estruturado das decisões dos diretores; isso é um gap.
- **CRM Duplo (leads vs lago_leads)** — a separação de leads ativos vs frios via tabela distinta (não via coluna de status) é uma escolha razoável; no Supabase hoje misturamos tudo em `leads`. Não migrar, mas considerar: uma **view filtrada** por temperatura pode dar o mesmo efeito sem duplicar tabela.
- **Enums inline via `mysqlEnum`** — no Supabase/Postgres usar `CHECK` ou `enum type`. O schema está fortemente tipado, o que é bom.

---

## 6. Estratégias de reativação por funil

Já citado em 1.2. Resumo operacional:

| Funil | Estratégia (prompt da Ana) | Uso típico |
|---|---|---|
| `isca` | Relembre o benefício inicial, ofereça algo novo, seja leve e curioso | Lead entrou mas não avançou |
| `upsell` | Mencione que o serviço está disponível, urgência suave | Cliente atual que pode comprar mais |
| `projeto` | Pergunte se ainda faz sentido avançar, mostre disponibilidade | Projeto em negociação parado |
| `pos_venda` | Check-in genuíno sobre a experiência, solicite feedback | Cliente após entrega |
| `war_room` | Abordagem direta, oferta especial limitada, última tentativa | Lead quase perdido, última cartada |

**Veredicto:** **guardar literal no guardrails-ana-v0.** Os 5 funis cobrem o ciclo completo (aquisição → negociação → projeto → retenção → recuperação). Alinhar com o framework de lead scoring (QUENTE/MORNO/FRIO/DESCARTÁVEL) — podem virar dimensões ortogonais: score × fase do funil.

---

## 7. Roteamento de responsáveis (ana.js:144)

```javascript
const responsaveis = { prime: "João ou Pedro", bosch: "Roniela ou Antônio" };
```

**Veredicto:** **dado operacional canônico.** Usar na Anna em prod pra todas as mensagens que mencionam o responsável da unidade. Guardar na config da Anna (`config/tenants/dap.yaml` se o Parliament tenant tiver uma entrada `humans:`, ou em tabela `unit_responsaveis` no Supabase). **Não hardcodar** no prompt — puxar da config para permitir rotação de time sem redeploy.

---

## 8. Lógica de campanhas (ana.js + webhook.ts + schema.ts)

### 8.1 Incremento de contadores

```javascript
// ana.js:89 — reativador_engajar incrementa total_leads
if (campanha) await atualizarCampanha(campanha.id, { total_leads: 1 });

// ana.js:163-166 — agendador_confirmar com acao=marcar incrementa agendados em TODAS campanhas ativas
if (acao === "marcar") {
  const campanhas = await buscarCampanhasAtivas();
  for (const c of campanhas) await atualizarCampanha(c.id, { agendados: 1 });
}
```

### 8.2 Campos no schema (schema.ts:118-131)

```typescript
export const campaigns = mysqlTable("campaigns", {
  id: int("id").autoincrement().primaryKey(),
  name: varchar("name", { length: 200 }).notNull(),
  type: varchar("type", { length: 100 }).notNull(),
  status: mysqlEnum("status", ["ativa", "pausada", "finalizada"]).default("ativa").notNull(),
  targetPersona: varchar("targetPersona", { length: 50 }),
  leadsAlcancados: int("leadsAlcancados").default(0).notNull(),
  respostas: int("respostas").default(0).notNull(),
  conversoes: int("conversoes").default(0).notNull(),
  startDate: timestamp("startDate"),
  endDate: timestamp("endDate"),
  ...
});
```

### 8.3 Update via webhook (webhook.ts:216-225)

```typescript
async function processCampaignUpdated(data: Record<string, unknown>) {
  const id = Number(data.id);
  if (!id) throw new Error("campaign.updated requires data.id");
  const updateData: Record<string, unknown> = {};
  if (data.status !== undefined) updateData.status = data.status;
  if (data.leadsAlcancados !== undefined) updateData.leadsAlcancados = Number(data.leadsAlcancados);
  if (data.respostas !== undefined) updateData.respostas = Number(data.respostas);
  if (data.conversoes !== undefined) updateData.conversoes = Number(data.conversoes);
  await updateCampaign(id, updateData);
}
```

**Observação crítica:** ana.js chama `atualizarCampanha(id, { total_leads: 1 })` e `{ agendados: 1 }`, mas o schema Drizzle tem `leadsAlcancados` e não tem `agendados`. Há **desalinhamento nome de coluna** entre o handler JS e o schema TS — provavelmente `atualizarCampanha` faz algum mapping ou a tabela MySQL real tem colunas diferentes do schema entregue. **Só referência.** Refatorar: nome canônico único em todo o pipeline.

**Veredicto:** **o modelo é certo (3 KPIs: alcance, resposta, conversão) + status lifecycle + janela temporal + targetPersona.** Reaproveitar como **estrutura de `campaigns`** no Supabase. O incremento via chamada inline dos handlers é **frágil** (corrida, double-count em replay) — refatorar pra event-sourced: cada `ana.action` grava `agent_name, lead_id, campaign_id, event_type` e uma **view agrega** os contadores on-demand. Contador incremental direto na tabela é armadilha.

---

## 9. Event taxonomy do webhook (webhook.ts:20-33)

```typescript
export type WebhookEventType =
  | "lead.created" | "lead.updated" | "lead.deleted" | "lead.moved_to_lago"
  | "lago.created" | "lago.updated"
  | "ana.action" | "agent.heartbeat"
  | "campaign.created" | "campaign.updated"
  | "financial.update" | "bay.update"
  | "ping";
```

**Veredicto:** **usar assim.** `namespace.verb` (ex: `lead.created`) é padrão consolidado (GitHub, Stripe). O `ping` no-op como smoke test é boa prática. O `lead.moved_to_lago` modela a **transição entre CRM interno e lago de leads frios** (schema.ts separa as tabelas — ver §5.3). Se adotarmos o bus interno entre Kommo → gateway → Parliament, essa taxonomia dá um **header start**.

---

## 10. Índice rápido do que vale levar

| # | Peça | Valor | Destino sugerido |
|---|---|---|---|
| 1.2 | `estrategias` por funil + "Regras de estilo" (3 linhas, não-IA, pergunta aberta) | **ALTO** | `guardrails-ana-v0-rascunho.md` |
| 1.3 | Política Doctor Auto (margem 35-120%, desconto nunca sem autorização) | **ALTO** | Bloco reutilizável em todos prompts de vendas |
| 1.5 | Loop agêntico Anthropic SDK (tool_use → tool_result) | **MÉDIO** | Referência se portarmos gateway p/ Node |
| 3.1 | Categorias (7) + tons (4) de prompts | **ALTO** | `sala-do-conselho-dify-dap4.md` |
| 4 | Pattern HMAC com `timingSafeEqual` | **ALTO** | Template de webhook verifier (Node + paridade Python) |
| 4 | Bug do `JSON.stringify(req.body)` para HMAC | **ALTO** (anti-padrão) | Guardar como lição |
| 5.2 | `ia_decision_log` (decision, reasoning, outcome, confidence) | **ALTO** | Parliament — log estruturado de decisões |
| 5.2 | `crm_health_snapshots` (overallScore + sub-scores) | **MÉDIO** | Métricas de higiene do CRM Supabase |
| 5.3 | Campos operacionais de `agent_configs` (uptime, tokensUsed, actionsToday, messagesDay, responseRate) | **MÉDIO** | Tabela `agent_configs` no Supabase |
| 6 | 5 funis (isca/upsell/projeto/pos_venda/war_room) | **ALTO** | Dimensão ortogonal ao lead scoring |
| 7 | `responsaveis = { prime, bosch }` | **ALTO** | Config da Anna (`config/tenants/dap.yaml`) |
| 8 | Estrutura `campaigns` (3 KPIs + status lifecycle + targetPersona) | **MÉDIO** | Tabela `campaigns` no Supabase (refatorada pra event-sourced) |
| 9 | Event taxonomy `namespace.verb` (12 eventos + ping) | **ALTO** | Bus interno se/quando existir |
| 1.4 | Kommo API `POST /api/v4/tasks` (entity_type: leads, task_type_id: 1, complete_till epoch) | **ALTO** | Receita canônica para criar task em lead |

## 11. O que NÃO levar

- Schema Drizzle MySQL (usar Supabase/Postgres)
- CRM Duplo via tabela separada (usar view filtrada por temperatura)
- `PromptsPage.tsx` UI (Dify já resolve melhor)
- Incremento inline de contadores de campanha (event-sourced > imperative)
- `JSON.stringify(req.body)` para HMAC (anti-padrão bloqueante)
- Dependência de Vercel (stack roda em VPS 76.13.170.42)
- Cohere RAG (ChromaDB já está em prod)

---

**FIM.** Fonte bruta em `C:\Users\docto\Downloads\Evaluate These Documents\`. Arquivos canônicos: `ana.js` (272 linhas, truncado no topo), `webhook.ts` (315 linhas), `schema.ts` (555 linhas), `dbExtended.ts` (443 linhas), `dbPrompts.ts` (290 linhas), `PromptsPage.tsx` (507 linhas).
