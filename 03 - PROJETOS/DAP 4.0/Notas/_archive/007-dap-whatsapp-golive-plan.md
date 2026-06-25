---
title: DAP WhatsApp Go-Live Implementation Plan (Prime) — SUPERSEDED
date: 2026-04-13
status: superseded
superseded_by: 009-dap-whatsapp-kommo-plan.md
spec: 006-dap-whatsapp-golive-playbook.md
owner: Thales
tags: [dap4, whatsapp, meta, go-live, plan, superseded]
---

# DAP WhatsApp Go-Live — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Coloca o WhatsApp da linha Prime operante hoje — Thales atende clientes reais pelo dashboard DAP4 na VPS Hostinger, com Ana classificando temperatura e intenção de cada mensagem.

**Architecture:** Meta Cloud API → Cloudflare Tunnel (`webhook.doctorautoprime40.com`) → gateway (HMAC verify + parse) → agents (Ana modo classify-only) → Supabase (persist classificação) → Socket.IO → dashboard (badges visuais + Thales responde manualmente).

**Tech Stack:** Ubuntu 25.10 VPS, Docker Compose, Node 20 + TypeScript (gateway), Python 3.12 + FastAPI (agents), React 18 + Vite (dashboard), Supabase Postgres, Socket.IO, Cloudflare Tunnel, Meta WhatsApp Cloud API v19.

---

## Phase 0 — VPS SSH Unblock + Hardening

### Task 0.1: Diagnose SSH `dap4` block

**Files:** none (VPS commands)

- [ ] **Step 1: SSH as root and inspect sshd config**

```bash
ssh -i ~/.ssh/dap4_ed25519 root@76.13.170.42
grep -i 'AuthorizedKeysFile\|AllowUsers\|PubkeyAuth\|PasswordAuth' \
  /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null
```

Expected: shows whether `AuthorizedKeysFile` points to custom path, whether `AllowUsers` restricts to root, and whether PubkeyAuthentication is `yes`.

- [ ] **Step 2: Inspect dap4 authorized_keys**

```bash
ls -la /home/dap4/.ssh/
cat /home/dap4/.ssh/authorized_keys | head -3
stat -c '%a %U %G' /home/dap4/.ssh /home/dap4/.ssh/authorized_keys
```

Expected: `.ssh` = 700 dap4, `authorized_keys` = 600 dap4. If not, perms are the issue.

- [ ] **Step 3: Extract laptop pubkey**

On laptop (Git Bash):
```bash
cat ~/.ssh/dap4_ed25519.pub
```

Copy the single line output.

### Task 0.2: Fix SSH `dap4`

- [ ] **Step 1: Install pubkey in dap4 authorized_keys**

On VPS (as root):
```bash
mkdir -p /home/dap4/.ssh
echo "<paste laptop pubkey line here>" >> /home/dap4/.ssh/authorized_keys
chown -R dap4:dap4 /home/dap4/.ssh
chmod 700 /home/dap4/.ssh
chmod 600 /home/dap4/.ssh/authorized_keys
```

- [ ] **Step 2: If AllowUsers restricted, add dap4**

```bash
grep -l 'AllowUsers' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null
# If a file matches, edit it to include: AllowUsers root dap4
systemctl reload sshd
```

- [ ] **Step 3: Verify from laptop**

```bash
ssh -i ~/.ssh/dap4_ed25519 -o IdentitiesOnly=yes dap4@76.13.170.42 "whoami && groups"
```

Expected: `dap4` and groups include `sudo docker`.

- [ ] **Step 4: Commit ops note to vault** (manual — no git commit needed on VPS)

### Task 0.3: Finalize Phase 1 hardening — disable root login

- [ ] **Step 1: Edit sshd config**

On VPS (as root, still logged in via existing root session):
```bash
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
grep '^PermitRootLogin' /etc/ssh/sshd_config
```

Expected: `PermitRootLogin no`.

- [ ] **Step 2: DO NOT exit root session yet. Test dap4 + sudo in a NEW terminal first**

On laptop, new terminal:
```bash
ssh -i ~/.ssh/dap4_ed25519 dap4@76.13.170.42 "sudo -n true && echo OK"
```

Expected: `OK` (after sudo password prompt if sudoers doesn't allow NOPASSWD — if so, configure NOPASSWD or accept password prompts).

- [ ] **Step 3: Reload sshd and verify root is blocked**

In the still-open root session:
```bash
systemctl reload sshd
```

New terminal on laptop:
```bash
ssh -i ~/.ssh/dap4_ed25519 root@76.13.170.42
```

Expected: connection refused or "Permission denied".

- [ ] **Step 4: Confirm ufw + fail2ban still active**

As dap4:
```bash
sudo ufw status verbose
sudo systemctl status fail2ban --no-pager | head -10
```

Expected: ufw `Status: active` with 22/tcp, 80, 443 allowed; fail2ban `active (running)`.

---

## Phase 1 — Cloudflare Tunnel

### Task 1.1: Create tunnel in Cloudflare dashboard

**Files:** none (web UI)

- [ ] **Step 1:** Go to [one.dash.cloudflare.com](https://one.dash.cloudflare.com) → **Networks → Tunnels → Create a tunnel**.
- [ ] **Step 2:** Connector type `Cloudflared`, name `dap4-prod`, **Save**.
- [ ] **Step 3:** Skip install instructions. Copy the tunnel token (starts with `eyJ…`) — save as `CLOUDFLARE_TUNNEL_TOKEN`.
- [ ] **Step 4:** Add public hostname #1:
  - Subdomain: `webhook`
  - Domain: `doctorautoprime40.com`
  - Service: `HTTP` → `gateway:3001`
- [ ] **Step 5:** Add public hostname #2:
  - Subdomain: `app`
  - Domain: `doctorautoprime40.com`
  - Service: `HTTP` → `dashboard:80`

### Task 1.2: Deploy tunnel on VPS

**Files:**
- Modify: `/opt/doctor-auto-ai/.env` (create if missing)

- [ ] **Step 1: SCP `.env.example` → populate `.env` on VPS**

Laptop:
```bash
scp -i ~/.ssh/dap4_ed25519 C:/dev/dap4/.env.example dap4@76.13.170.42:/tmp/dap4.env
ssh -i ~/.ssh/dap4_ed25519 dap4@76.13.170.42
sudo mv /tmp/dap4.env /opt/doctor-auto-ai/.env
sudo chown dap4:dap4 /opt/doctor-auto-ai/.env
sudo chmod 600 /opt/doctor-auto-ai/.env
```

- [ ] **Step 2: Set CLOUDFLARE_TUNNEL_TOKEN in `.env`**

```bash
cd /opt/doctor-auto-ai
nano .env    # set CLOUDFLARE_TUNNEL_TOKEN=eyJ...
```

- [ ] **Step 3: Start tunnel service**

```bash
cd /opt/doctor-auto-ai
docker compose up -d cloudflared
docker compose logs -f cloudflared | head -30
```

Expected: `Registered tunnel connection` × 4 (one per edge location).

- [ ] **Step 4: Verify `HEALTHY` in Cloudflare dashboard**

Tunnels page shows `dap4-prod` → status `HEALTHY`.

---

## Phase 2 — Meta Business Setup (parallel with Phases 3-5)

### Task 2.1: Submit Display Name early (blocks on approval)

- [ ] **Step 1:** Remove número Prime do app WhatsApp Business no celular (Configurações → Conta → Excluir a minha conta).
- [ ] **Step 2:** Meta for Developers → WhatsApp app → **API Setup → Add phone number** → digite número Prime → verifique por SMS.
- [ ] **Step 3:** Display Name: `Doctor Auto` → Submit. Anote timestamp — Meta costuma aprovar em minutos mas pode levar horas.
- [ ] **Step 4:** Copiar `Phone number ID` (abaixo de "From") → salvar em cofre como `META_PHONE_NUMBER_ID`.
- [ ] **Step 5:** Copiar `WhatsApp Business Account ID` → salvar como `META_WABA_ID`.

### Task 2.2: Create permanent System User token

- [ ] **Step 1:** [business.facebook.com/settings](https://business.facebook.com/settings) → **Users → System Users → Add** → `dap4-system-user` → role `Admin`.
- [ ] **Step 2:** Click user → **Add Assets** → Apps: selecionar app DAP → `Full control`. WhatsApp Accounts: selecionar WABA Prime → `Full control`.
- [ ] **Step 3:** **Generate new token**:
  - App: DAP app
  - Expiration: `Never`
  - Permissions: `whatsapp_business_messaging`, `whatsapp_business_management`, `business_management`
- [ ] **Step 4:** Copy token → salvar como `META_ACCESS_TOKEN` (sobrescreve o temporário).

### Task 2.3: Coletar App Secret + gerar Verify Token

- [ ] **Step 1:** App dashboard → **App Settings → Basic → App Secret → Show** → copy → salvar como `META_APP_SECRET`.
- [ ] **Step 2:** Laptop:
```bash
openssl rand -hex 16
```
Save output as `META_VERIFY_TOKEN`.

---

## Phase 3 — Ana: Classify-Only Mode

### Task 3.1: Add classify-only flag to Ana

**Files:**
- Modify: `C:\dev\dap4\agents\config\prompts\ana.yaml`
- Modify: `C:\dev\dap4\agents\agents\ana.py`
- Test: `C:\dev\dap4\agents\tests\test_ana_classify_only.py` (create)

- [ ] **Step 1: Write the failing test**

Create `C:\dev\dap4\agents\tests\test_ana_classify_only.py`:
```python
import pytest
from agents.ana import handle_message

def test_classify_only_returns_no_reply():
    result = handle_message(
        text="Oi, quanto custa revisão do A4?",
        phone="5562999999999",
        mode="classify_only",
    )
    assert result["status"] == "ok"
    assert result["response"] is None  # no auto-reply
    assert result["classification"]["temperature"] in {"frio", "morno", "quente"}
    assert result["classification"]["intent"] in {
        "orcamento", "duvida", "agendamento", "reclamacao", "outro"
    }
```

- [ ] **Step 2: Run test — verify fails**

```bash
cd C:\dev\dap4\agents
pytest tests/test_ana_classify_only.py -v
```

Expected: FAIL — `handle_message` signature mismatch or missing `mode` param.

- [ ] **Step 3: Add `mode` handling to `ana.py`**

In `agents/agents/ana.py`, modify `_handle_chat` (or the top-level entrypoint) to branch on `mode`:

```python
def handle_message(text: str, phone: str, mode: str = "reply"):
    classification = _classify(text)  # wraps existing intent logic
    if mode == "classify_only":
        return {
            "status": "ok",
            "agent": "ana",
            "response": None,
            "classification": classification,
        }
    # existing reply path
    reply = _generate_reply(text, classification)
    return {
        "status": "ok",
        "agent": "ana",
        "response": reply,
        "classification": classification,
    }


def _classify(text: str) -> dict:
    raw = _llm_classify(text)  # existing call
    return {
        "temperature": _map_temperature(raw),  # frio | morno | quente
        "intent": _map_intent(raw),            # orcamento | duvida | agendamento | reclamacao | outro
        "confidence": raw.get("confidence", 0.0),
    }
```

- [ ] **Step 4: Update `ana.yaml` prompt to include temperature dimension**

Append to the system prompt section in `C:\dev\dap4\agents\config\prompts\ana.yaml`:
```yaml
classification_schema: |
  Retorne JSON com exatamente estes campos:
  - temperature: "frio" (curiosidade vaga), "morno" (interesse real, sem urgência), "quente" (quer agir agora, pede orçamento/horário)
  - intent: "orcamento" | "duvida" | "agendamento" | "reclamacao" | "outro"
  - confidence: float 0.0-1.0
  Seja conservador com "quente" — só quando há sinal explícito de decisão.
```

- [ ] **Step 5: Run test again — verify passes**

```bash
pytest tests/test_ana_classify_only.py -v
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
cd C:\dev\dap4
git add agents/agents/ana.py agents/config/prompts/ana.yaml agents/tests/test_ana_classify_only.py
git commit -m "feat(ana): add classify_only mode returning temperature + intent"
```

### Task 3.2: Expose classify-only via FastAPI

**Files:**
- Modify: `C:\dev\dap4\agents\api\routes.py` (or wherever Ana is exposed)
- Test: `C:\dev\dap4\agents\tests\test_api_classify.py` (create)

- [ ] **Step 1: Write failing API test**

Create `C:\dev\dap4\agents\tests\test_api_classify.py`:
```python
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_ana_classify_endpoint():
    r = client.post("/agents/ana/classify", json={
        "text": "quero agendar revisão pro meu BMW amanhã",
        "phone": "5562999999999",
    })
    assert r.status_code == 200
    body = r.json()
    assert body["classification"]["intent"] == "agendamento"
    assert body["response"] is None
```

- [ ] **Step 2: Run — verify fails (404)**

```bash
pytest tests/test_api_classify.py -v
```

- [ ] **Step 3: Add route**

In `agents/api/routes.py` (adapt to existing router prefix):
```python
from fastapi import APIRouter
from pydantic import BaseModel
from agents.ana import handle_message

router = APIRouter(prefix="/agents/ana")

class ClassifyReq(BaseModel):
    text: str
    phone: str

@router.post("/classify")
async def classify(req: ClassifyReq):
    return handle_message(text=req.text, phone=req.phone, mode="classify_only")
```

Register router in `main.py` if not already.

- [ ] **Step 4: Run — verify passes**

```bash
pytest tests/test_api_classify.py -v
```

- [ ] **Step 5: Commit**

```bash
git add agents/api/routes.py agents/main.py agents/tests/test_api_classify.py
git commit -m "feat(ana): POST /agents/ana/classify returns classification only"
```

---

## Phase 4 — Gateway: Persist Classification + Socket Emit

### Task 4.1: Supabase migration for classification columns

**Files:**
- Create: `C:\dev\dap4\gateway\migrations\20260413_01_meta_messages_classification.sql`

- [ ] **Step 1: Write migration**

```sql
-- Add classification columns to meta_messages
ALTER TABLE meta_messages
  ADD COLUMN IF NOT EXISTS temperature TEXT
    CHECK (temperature IN ('frio', 'morno', 'quente')),
  ADD COLUMN IF NOT EXISTS intent TEXT
    CHECK (intent IN ('orcamento', 'duvida', 'agendamento', 'reclamacao', 'outro')),
  ADD COLUMN IF NOT EXISTS classification_confidence NUMERIC(3,2);

CREATE INDEX IF NOT EXISTS idx_meta_messages_temperature
  ON meta_messages (temperature) WHERE temperature IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_meta_messages_intent
  ON meta_messages (intent) WHERE intent IS NOT NULL;
```

- [ ] **Step 2: Apply via Supabase MCP**

Use Supabase MCP `apply_migration` tool with the SQL above.

- [ ] **Step 3: Verify via MCP `execute_sql`**

```sql
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name = 'meta_messages' AND column_name IN ('temperature','intent','classification_confidence');
```

Expected: 3 rows.

- [ ] **Step 4: Commit migration file**

```bash
git add gateway/migrations/20260413_01_meta_messages_classification.sql
git commit -m "feat(db): add classification columns to meta_messages"
```

### Task 4.2: Persist classification in `insertInbound`

**Files:**
- Modify: `C:\dev\dap4\gateway\src\services\meta-messages.service.ts`
- Test: `C:\dev\dap4\gateway\src\services\meta-messages.service.test.ts` (create or extend)

- [ ] **Step 1: Write failing test**

Create `gateway/src/services/meta-messages.service.test.ts`:
```typescript
import { describe, it, expect, vi } from "vitest";
import { insertInbound } from "./meta-messages.service";

describe("insertInbound with classification", () => {
  it("persists temperature + intent when provided", async () => {
    const supabase = {
      from: vi.fn().mockReturnThis(),
      insert: vi.fn().mockResolvedValue({ data: [{ id: "m1" }], error: null }),
    } as any;
    await insertInbound(supabase, {
      metaMessageId: "wamid.x",
      conversationId: "5562999",
      phone: "5562999",
      text: "quero orçamento",
      classification: { temperature: "quente", intent: "orcamento", confidence: 0.92 },
    });
    expect(supabase.insert).toHaveBeenCalledWith(
      expect.objectContaining({
        temperature: "quente",
        intent: "orcamento",
        classification_confidence: 0.92,
      }),
    );
  });
});
```

- [ ] **Step 2: Run — verify fails**

```bash
cd C:\dev\dap4\gateway
pnpm vitest run src/services/meta-messages.service.test.ts
```

- [ ] **Step 3: Extend `insertInbound`**

In `meta-messages.service.ts`, modify `insertInbound` signature and body:
```typescript
export interface InboundPayload {
  metaMessageId: string;
  conversationId: string;
  phone: string;
  text: string;
  classification?: { temperature: string; intent: string; confidence: number };
}

export async function insertInbound(supabase: SupabaseClient, p: InboundPayload) {
  return supabase.from("meta_messages").insert({
    meta_message_id: p.metaMessageId,
    conversation_id: p.conversationId,
    phone: p.phone,
    text: p.text,
    direction: "inbound",
    temperature: p.classification?.temperature ?? null,
    intent: p.classification?.intent ?? null,
    classification_confidence: p.classification?.confidence ?? null,
    created_at: new Date().toISOString(),
  });
}
```

- [ ] **Step 4: Run — verify passes**

```bash
pnpm vitest run src/services/meta-messages.service.test.ts
```

- [ ] **Step 5: Commit**

```bash
git add gateway/src/services/meta-messages.service.ts gateway/src/services/meta-messages.service.test.ts
git commit -m "feat(gateway): persist classification on inbound meta messages"
```

### Task 4.3: Wire webhook to call Ana classify + emit over socket

**Files:**
- Modify: `C:\dev\dap4\gateway\src\routes\meta-webhook.routes.ts`
- Modify: `C:\dev\dap4\gateway\src\services\socket.service.ts` (or equivalent)

- [ ] **Step 1: Call Ana classify endpoint from webhook**

In `meta-webhook.routes.ts`, within the inbound message handler:
```typescript
const agentResp = await fetch(`${AGENTS_URL}/agents/ana/classify`, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ text: msg.text, phone: msg.from }),
});
const agentBody = await agentResp.json();
const classification = agentBody.classification;

await insertInbound(supabase, {
  metaMessageId: msg.id,
  conversationId: msg.from,
  phone: msg.from,
  text: msg.text,
  classification,
});

emitMessage({
  id: msg.id,
  conversationId: msg.from,
  text: msg.text,
  direction: "inbound",
  timestamp: new Date().toISOString(),
  classification,  // NEW field
});
```

- [ ] **Step 2: Update `emitMessage` type to include classification**

In `socket.service.ts`:
```typescript
export interface EmitMessagePayload {
  id: string;
  conversationId: string;
  text: string;
  direction: "inbound" | "outbound";
  timestamp: string;
  classification?: { temperature: string; intent: string; confidence: number };
}
```

- [ ] **Step 3: Add integration test (mocked)**

Create `gateway/src/routes/meta-webhook.routes.test.ts` with supertest, mock Ana fetch + Supabase. Assert emit payload contains `classification`. (Full code omitted for brevity — follow pattern in Task 4.2.)

- [ ] **Step 4: Run tests**

```bash
pnpm vitest run
```

- [ ] **Step 5: Commit**

```bash
git add gateway/src/routes/meta-webhook.routes.ts gateway/src/services/socket.service.ts gateway/src/routes/meta-webhook.routes.test.ts
git commit -m "feat(gateway): call Ana classify + emit classification over socket"
```

---

## Phase 5 — Dashboard: Conversation Badges

### Task 5.1: TemperatureBadge + IntentIcon components

**Files:**
- Create: `C:\dev\dap4\dashboard\src\components\leads\ClassificationBadges.jsx`

- [ ] **Step 1: Write component**

```jsx
const TEMP_COLORS = {
  frio: "bg-blue-500/10 text-blue-400 border-blue-500/30",
  morno: "bg-amber-500/10 text-amber-400 border-amber-500/30",
  quente: "bg-red-500/10 text-red-400 border-red-500/30",
};

const INTENT_ICONS = {
  orcamento: "💰",
  duvida: "❓",
  agendamento: "📅",
  reclamacao: "⚠️",
  outro: "💬",
};

export function TemperatureBadge({ value }) {
  if (!value) return null;
  return (
    <span className={`px-2 py-0.5 rounded-full text-xs border ${TEMP_COLORS[value]}`}>
      {value}
    </span>
  );
}

export function IntentIcon({ value }) {
  if (!value) return null;
  return <span title={value} className="text-sm">{INTENT_ICONS[value]}</span>;
}
```

- [ ] **Step 2: Commit**

```bash
git add dashboard/src/components/leads/ClassificationBadges.jsx
git commit -m "feat(dashboard): add TemperatureBadge + IntentIcon components"
```

### Task 5.2: Wire badges into ConversationItem

**Files:**
- Modify: `C:\dev\dap4\dashboard\src\components\leads\ConversationView.jsx`

- [ ] **Step 1: Import + render in ConversationItem**

At top of file:
```jsx
import { TemperatureBadge, IntentIcon } from "./ClassificationBadges";
```

Modify `ConversationItem` render (around line 128):
```jsx
<div className="flex items-center gap-2">
  <Avatar initial={pushName[0]} />
  <span className="flex-1 truncate">{pushName || phone}</span>
  <IntentIcon value={conversation.lastIntent} />
  <TemperatureBadge value={conversation.lastTemperature} />
  {unreadCount > 0 && <Badge>{unreadCount}</Badge>}
</div>
```

- [ ] **Step 2: Update `normalizeMetaRow` (line 44) to extract classification**

```jsx
function normalizeMetaRow(row) {
  return {
    // ... existing fields
    lastTemperature: row.temperature ?? null,
    lastIntent: row.intent ?? null,
  };
}
```

- [ ] **Step 3: Handle `classification` in socket listener**

Find the `message:new` socket handler in the page (likely `dashboard/src/pages/whatsapp.jsx` or hook). Update conversation state to set `lastTemperature` / `lastIntent` from `payload.classification`.

- [ ] **Step 4: Dev-run dashboard + manual smoke**

```bash
cd C:\dev\dap4\dashboard
pnpm dev
```

Open `http://localhost:5173/whatsapp`. Trigger fake message via gateway dev — badges render.

- [ ] **Step 5: Commit**

```bash
git add dashboard/src/components/leads/ConversationView.jsx dashboard/src/pages/whatsapp.jsx
git commit -m "feat(dashboard): show temperature + intent on conversation list"
```

---

## Phase 6 — Deploy + Webhook Register

### Task 6.1: Populate production `.env` with Meta credentials

**Files:**
- Modify: `/opt/doctor-auto-ai/.env` on VPS

- [ ] **Step 1: SSH as dap4, edit `.env`**

```bash
ssh -i ~/.ssh/dap4_ed25519 dap4@76.13.170.42
sudo nano /opt/doctor-auto-ai/.env
```

Set:
```
META_PHONE_NUMBER_ID=<from Task 2.1>
META_WABA_ID=<from Task 2.1>
META_ACCESS_TOKEN=<from Task 2.2>
META_APP_SECRET=<from Task 2.3>
META_VERIFY_TOKEN=<from Task 2.3>
AGENTS_URL=http://agents:8000
```

- [ ] **Step 2: Validate no secrets empty**

```bash
grep -E '^META_' /opt/doctor-auto-ai/.env | grep '=$'
```

Expected: zero lines (all filled).

### Task 6.2: Pull latest code + deploy

- [ ] **Step 1: Push all commits to master**

Laptop:
```bash
cd C:\dev\dap4
git push origin master
```

- [ ] **Step 2: Pull on VPS**

```bash
ssh -i ~/.ssh/dap4_ed25519 dap4@76.13.170.42
cd /opt/doctor-auto-ai
git pull origin master
```

- [ ] **Step 3: Rebuild + restart stack**

```bash
docker compose pull
docker compose build
docker compose up -d
docker compose ps
```

Expected: all services `Up (healthy)`.

- [ ] **Step 4: Tail gateway logs in split terminal**

```bash
docker compose logs -f gateway
```

Keep this terminal open for next task.

### Task 6.3: Register webhook at Meta

- [ ] **Step 1:** Meta app dashboard → **WhatsApp → Configuration → Webhook → Edit**.
- [ ] **Step 2:** Callback URL: `https://webhook.doctorautoprime40.com/api/meta/webhook`
- [ ] **Step 3:** Verify Token: (value of `META_VERIFY_TOKEN`)
- [ ] **Step 4:** Click **Verify and save**.

Expected in gateway logs: `Meta webhook GET verified` (HMAC passes, Meta saves).

- [ ] **Step 5:** Webhook fields → **Manage** → subscribe to `messages`.

### Task 6.4: Health check

- [ ] **Step 1: Call /api/meta/status**

Laptop:
```bash
curl -H "Authorization: Bearer $API_SECRET" \
  https://app.doctorautoprime40.com/api/meta/status | jq
```

Expected:
```json
{
  "connected": true,
  "configured": true,
  "config": {"hasToken": true, "hasPhone": true, "hasWaba": true, "hasVerify": true, "hasSecret": true}
}
```

---

## Phase 7 — Smoke Test

### Task 7.1: End-to-end manual test

- [ ] **Step 1:** Do celular pessoal do Thales → mandar mensagem de texto livre pro número Prime. Ex: "quero agendar revisão do meu A4".

- [ ] **Step 2:** Observar `docker compose logs -f gateway` — esperar:
```
Meta message received { from: "5562..." }
Ana classification { temperature: "quente", intent: "agendamento" }
Persisted inbound wamid...
Socket emit message:new
```

- [ ] **Step 3:** Abrir `https://app.doctorautoprime40.com/whatsapp` → conversa aparece com badge `quente` (vermelho) + ícone 📅.

- [ ] **Step 4:** No dashboard, digitar resposta manual: "Claro Thales, tenho horário amanhã 10h — fechou?" → Send.

- [ ] **Step 5:** Esperar mensagem chegar no WhatsApp do celular em <5s.

- [ ] **Step 6:** Conferir na Supabase MCP:
```sql
SELECT text, direction, temperature, intent
FROM meta_messages
ORDER BY created_at DESC LIMIT 4;
```

Expected: 2 linhas (1 inbound com classificação, 1 outbound sem).

### Task 7.2: Rollback plan (se algo der errado)

- [ ] **Se Display Name negado + passa das 18h sem aprovação:** remover número do Cloud API (WhatsApp → API Setup → Remove phone number) → registrar de volta no app WhatsApp Business pelo celular. Perde histórico do dia.
- [ ] **Se webhook verify falha persistente:** checar `META_VERIFY_TOKEN` exato no `.env` vs dashboard Meta (sem espaços/newline).
- [ ] **Se HMAC signature mismatch:** confirmar `META_APP_SECRET` do App Settings → Basic, não o temporário.

---

## Critério de sucesso (from spec)

- [ ] Thales manda mensagem do celular pro número Prime e vê ela no portal em <2s.
- [ ] Conversa mostra badge temperatura + ícone intent corretos.
- [ ] Thales responde pelo portal e chega no celular em <2s.
- [ ] `/api/meta/status` retorna `connected: true`.
- [ ] Tunnel Cloudflare `HEALTHY`.
- [ ] Root SSH desabilitado.

---

## Notas de execução

- **Paralelizar:** Phase 2 (Meta) pode rodar em paralelo com Phase 3-5 (código). SSH unblock + tunnel (Phase 0-1) são bloqueantes.
- **Templates 24h:** não é parte do plano de hoje. Adicionar depois, com approval Meta.
- **Funcionária:** não inclusa hoje. Próximo plano adiciona auth + conta.
- **Bosch:** próximo plano (repetir Phases 2 + 6 com credenciais novas).
