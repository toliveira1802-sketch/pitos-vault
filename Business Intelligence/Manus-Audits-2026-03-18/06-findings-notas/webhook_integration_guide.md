# Guia de Integração: Sophia Hub → Dashboard de Comando

Este documento descreve como configurar o Sophia Hub para enviar eventos automaticamente ao Dashboard de Comando da Doctor Auto Prime via webhook.

---

## Visão Geral

O Dashboard expõe um endpoint POST seguro que aceita eventos do Sophia Hub. Cada requisição é autenticada via HMAC-SHA256 usando uma chave secreta compartilhada entre os dois sistemas. O Dashboard processa o evento e atualiza o banco de dados em tempo real, refletindo as mudanças automaticamente na interface (polling a cada 30 segundos).

---

## Endpoint

| Campo | Valor |
|-------|-------|
| **URL** | `https://<seu-dominio>/api/webhook/sophia` |
| **Método** | `POST` |
| **Content-Type** | `application/json` |
| **Autenticação** | HMAC-SHA256 via header `x-webhook-signature` |

---

## Autenticação

Cada requisição deve incluir o header `x-webhook-signature` contendo a assinatura HMAC-SHA256 do corpo JSON da requisição, usando a chave secreta compartilhada (`WEBHOOK_SECRET`).

O formato da assinatura é `sha256=<hex_digest>`.

### Exemplo em JavaScript (Node.js)

```javascript
import { createHmac } from "crypto";

function signPayload(body, secret) {
  const hmac = createHmac("sha256", secret)
    .update(JSON.stringify(body), "utf8")
    .digest("hex");
  return `sha256=${hmac}`;
}

// Uso no Sophia Hub
const payload = {
  event: "lead.created",
  timestamp: new Date().toISOString(),
  data: {
    name: "João Silva",
    phone: "11999887766",
    vehicle: "BMW 320i",
    stage: "Novo Lead",
    unit: "Prime",
    value: "3500.00",
    source: "sophia-hub"
  }
};

const signature = signPayload(payload, process.env.WEBHOOK_SECRET);

await fetch("https://<seu-dominio>/api/webhook/sophia", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "x-webhook-signature": signature,
  },
  body: JSON.stringify(payload),
});
```

---

## Formato do Payload

Todos os eventos seguem a mesma estrutura base:

```json
{
  "event": "<tipo_do_evento>",
  "timestamp": "2026-03-19T12:00:00.000Z",
  "data": { ... }
}
```

---

## Eventos Suportados

### 1. `ping` — Teste de Conectividade

Usado para verificar se o webhook está funcionando. Retorna `200 OK` sem efeito colateral.

```json
{
  "event": "ping",
  "timestamp": "2026-03-19T12:00:00Z",
  "data": {}
}
```

---

### 2. `lead.created` — Novo Lead no CRM Interno

Cria um novo lead no CRM Interno do dashboard.

```json
{
  "event": "lead.created",
  "timestamp": "2026-03-19T12:00:00Z",
  "data": {
    "name": "João Silva",
    "phone": "11999887766",
    "email": "joao@email.com",
    "vehicle": "BMW 320i 2022",
    "stage": "Novo Lead",
    "unit": "Prime",
    "value": "3500.00",
    "source": "sophia-hub",
    "notes": "Veio pelo Instagram"
  }
}
```

| Campo | Tipo | Obrigatório | Valores Aceitos |
|-------|------|-------------|-----------------|
| `name` | string | Sim | — |
| `phone` | string | Não | — |
| `email` | string | Não | — |
| `vehicle` | string | Não | — |
| `stage` | string | Não | `Novo Lead`, `Em Negociação`, `Agendado`, `Na Oficina`, `Pós-Venda` |
| `unit` | string | Não | `Prime`, `Bosch` |
| `value` | string | Não | Valor decimal como string (ex: `"3500.00"`) |
| `source` | string | Não | — |
| `notes` | string | Não | — |

---

### 3. `lead.updated` — Atualização de Lead

Atualiza campos de um lead existente. Apenas os campos enviados serão atualizados.

```json
{
  "event": "lead.updated",
  "timestamp": "2026-03-19T12:00:00Z",
  "data": {
    "id": 42,
    "stage": "Agendado",
    "value": "4200.00"
  }
}
```

| Campo | Tipo | Obrigatório |
|-------|------|-------------|
| `id` | number | **Sim** |
| Demais campos | — | Não (apenas os enviados são atualizados) |

---

### 4. `lead.deleted` — Remoção de Lead

Remove um lead do CRM Interno.

```json
{
  "event": "lead.deleted",
  "timestamp": "2026-03-19T12:00:00Z",
  "data": {
    "id": 42
  }
}
```

---

### 5. `lead.moved_to_lago` — Lead Movido para o Lago

Remove o lead do CRM Interno e cria uma entrada no Lago de Leads (CRM Externo).

```json
{
  "event": "lead.moved_to_lago",
  "timestamp": "2026-03-19T12:00:00Z",
  "data": {
    "leadId": 42,
    "name": "João Silva",
    "phone": "11999887766",
    "vehicle": "BMW 320i",
    "temperature": "morno",
    "score": 65,
    "reason": "Achou caro, pediu para retornar em 30 dias",
    "source": "sophia-hub"
  }
}
```

| Campo | Tipo | Obrigatório | Valores Aceitos |
|-------|------|-------------|-----------------|
| `leadId` | number | Não | ID do lead no CRM Interno (será deletado) |
| `name` | string | Sim | — |
| `temperature` | string | Não | `quente`, `morno`, `frio` |
| `score` | number | Não | 0-100 |
| `reason` | string | Não | Motivo da não conversão |

---

### 6. `lago.created` — Novo Lead Direto no Lago

Cria um lead diretamente no Lago de Leads sem passar pelo CRM Interno.

```json
{
  "event": "lago.created",
  "timestamp": "2026-03-19T12:00:00Z",
  "data": {
    "name": "Maria Santos",
    "phone": "11988776655",
    "vehicle": "Audi A3",
    "temperature": "frio",
    "score": 20,
    "source": "campanha-instagram"
  }
}
```

---

### 7. `lago.updated` — Atualização de Lead no Lago

```json
{
  "event": "lago.updated",
  "timestamp": "2026-03-19T12:00:00Z",
  "data": {
    "id": 15,
    "temperature": "quente",
    "score": 85,
    "notes": "Respondeu campanha de revisão preventiva"
  }
}
```

---

### 8. `ana.action` — Ação da IA Ana

Registra uma ação executada pela Ana no feed de atividades do dashboard.

```json
{
  "event": "ana.action",
  "timestamp": "2026-03-19T12:00:00Z",
  "data": {
    "action": "Enviou orçamento de revisão completa",
    "lead": "João Silva",
    "tool": "send_message",
    "result": "sucesso"
  }
}
```

| Campo | Tipo | Obrigatório | Valores Aceitos |
|-------|------|-------------|-----------------|
| `action` | string | Sim | Descrição da ação |
| `lead` | string | Não | Nome do lead envolvido |
| `tool` | string | Não | `send_message`, `search_catalog`, `create_note`, `schedule`, etc. |
| `result` | string | Não | `sucesso`, `erro`, `pendente` |

---

### 9. `agent.heartbeat` — Status do Agente IA

Atualiza o status de um agente IA na barra de status do dashboard. Recomendado enviar a cada 5 minutos.

```json
{
  "event": "agent.heartbeat",
  "timestamp": "2026-03-19T12:00:00Z",
  "data": {
    "name": "Ana",
    "status": "online",
    "costToday": "1.25",
    "totalCalls": 42
  }
}
```

| Campo | Tipo | Obrigatório | Valores Aceitos |
|-------|------|-------------|-----------------|
| `name` | string | Sim | `Ana`, `Pescadora`, `Vigilante`, `Analista`, `Reativador`, `Relatório` |
| `status` | string | Não | `online`, `idle`, `error`, `offline` |
| `costToday` | string | Não | Custo em USD como string decimal |
| `totalCalls` | number | Não | Total de chamadas de API no dia |

---

### 10. `campaign.created` / `campaign.updated` — Campanhas

```json
{
  "event": "campaign.created",
  "timestamp": "2026-03-19T12:00:00Z",
  "data": {
    "name": "Revisão Preventiva Março",
    "type": "revisao_preventiva",
    "status": "ativa"
  }
}
```

```json
{
  "event": "campaign.updated",
  "timestamp": "2026-03-19T12:00:00Z",
  "data": {
    "id": 3,
    "leadsAlcancados": 150,
    "respostas": 28,
    "conversoes": 8
  }
}
```

---

### 11. `financial.update` — Atualização Financeira

```json
{
  "event": "financial.update",
  "timestamp": "2026-03-19T12:00:00Z",
  "data": {
    "period": "2026-03",
    "receitaMes": "87400.00",
    "receitaMesAnterior": "72000.00",
    "receitaPrime": "52400.00",
    "receitaBosch": "35000.00",
    "ticketMedio": "2180.00",
    "osAbertas": 8,
    "osFechadas": 34
  }
}
```

---

### 12. `bay.update` — Atualização de Box do Pátio

```json
{
  "event": "bay.update",
  "timestamp": "2026-03-19T12:00:00Z",
  "data": {
    "id": 3,
    "status": "ocupado",
    "vehicle": "Mercedes C200",
    "service": "Troca de pastilhas",
    "progress": 45
  }
}
```

| Campo | Tipo | Obrigatório | Valores Aceitos |
|-------|------|-------------|-----------------|
| `id` | number | **Sim** | ID do box no banco |
| `status` | string | Não | `ocupado`, `livre`, `manutencao` |
| `vehicle` | string | Não | — |
| `service` | string | Não | — |
| `progress` | number | Não | 0-100 |

---

## Respostas do Webhook

| Status | Significado | Corpo |
|--------|-------------|-------|
| `200` | Evento processado com sucesso | `{ "ok": true, "processed": true, "event": "..." }` |
| `400` | Payload inválido (campo `event` ausente) | `{ "error": "Missing event field" }` |
| `401` | Assinatura inválida ou ausente | `{ "error": "Invalid signature" }` |
| `422` | Erro ao processar o evento (ex: ID ausente) | `{ "error": "..." }` |
| `500` | WEBHOOK_SECRET não configurado no servidor | `{ "error": "Webhook not configured" }` |

---

## Implementação no Sophia Hub

Para integrar, adicione a seguinte função utilitária ao seu projeto Sophia Hub (ex: em `api/cron/_utils.js`):

```javascript
import { createHmac } from "crypto";

const DASHBOARD_WEBHOOK_URL = process.env.DASHBOARD_WEBHOOK_URL;
const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET;

export async function sendToDashboard(event, data) {
  if (!DASHBOARD_WEBHOOK_URL || !WEBHOOK_SECRET) {
    console.warn("[Dashboard] Webhook not configured, skipping");
    return;
  }

  const payload = {
    event,
    timestamp: new Date().toISOString(),
    data,
  };

  const body = JSON.stringify(payload);
  const signature = `sha256=${createHmac("sha256", WEBHOOK_SECRET).update(body, "utf8").digest("hex")}`;

  try {
    const res = await fetch(DASHBOARD_WEBHOOK_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-webhook-signature": signature,
      },
      body,
    });

    if (!res.ok) {
      console.error(`[Dashboard] Webhook failed: ${res.status}`, await res.text());
    }
    return res.ok;
  } catch (err) {
    console.error("[Dashboard] Webhook error:", err.message);
    return false;
  }
}
```

### Exemplo de uso no `ana.js`:

```javascript
import { sendToDashboard } from "./cron/_utils.js";

// Após a Ana executar uma ação:
await sendToDashboard("ana.action", {
  action: "Enviou orçamento para cliente",
  lead: leadName,
  tool: "send_message",
  result: "sucesso",
});

// Quando um lead muda de etapa:
await sendToDashboard("lead.updated", {
  id: leadId,
  stage: "Agendado",
});
```

### Variáveis de ambiente necessárias no Sophia Hub:

```env
DASHBOARD_WEBHOOK_URL=https://<seu-dominio>/api/webhook/sophia
WEBHOOK_SECRET=<mesma_chave_configurada_no_dashboard>
```

---

## Teste Rápido com cURL

```bash
# Gerar assinatura
BODY='{"event":"ping","timestamp":"2026-03-19T12:00:00Z","data":{}}'
SECRET="sua-chave-secreta"
SIG=$(echo -n "$BODY" | openssl dgst -sha256 -hmac "$SECRET" | awk '{print $2}')

# Enviar requisição
curl -X POST https://<seu-dominio>/api/webhook/sophia \
  -H "Content-Type: application/json" \
  -H "x-webhook-signature: sha256=$SIG" \
  -d "$BODY"
```

Resposta esperada: `{"ok":true,"processed":true,"event":"ping"}`
