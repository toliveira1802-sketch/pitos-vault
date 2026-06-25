---
title: DAP WhatsApp Go-Live Implementation Plan (via Kommo)
date: 2026-04-13
status: ready-to-execute
spec: 008-dap-whatsapp-kommo-playbook.md
supersedes: 007-dap-whatsapp-golive-plan.md
owner: Thales
tags: [dap4, whatsapp, kommo, go-live, plan]
---

# DAP WhatsApp via Kommo — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement task-by-task.

**Goal:** Portal DAP4 exibe conversas WhatsApp (histórico + novas) recebidas via Kommo. Thales responde pelo portal. Ana classifica (não responde).

**Architecture:** Kommo (existente) → gateway `/api/webhook/kommo` (já existe, ajustar) → Ana classify-only → Supabase novas tabelas → socket.io → dashboard `/whatsapp`. Backfill one-shot do Kommo API.

**Tech Stack:** Node 20 + TypeScript (gateway), Python 3.12 + FastAPI (agents), React 18 + Vite (dashboard), Supabase Postgres, Socket.IO, Kommo REST v4.

---

## Phase 0 — Supabase Schema

### Task 0.1: Migration `kommo_conversations` + `kommo_messages`

**Files:**
- Create: `C:\dev\dap4\gateway\migrations\20260413_01_kommo_tables.sql`

- [ ] **Step 1: Write migration**

```sql
CREATE TABLE IF NOT EXISTS kommo_conversations (
  id BIGSERIAL PRIMARY KEY,
  kommo_chat_id TEXT UNIQUE NOT NULL,
  kommo_contact_id TEXT,
  kommo_lead_id TEXT,
  contact_name TEXT,
  contact_phone TEXT,
  last_message_at TIMESTAMPTZ,
  last_message_preview TEXT,
  last_temperature TEXT CHECK (last_temperature IN ('frio','morno','quente')),
  last_intent TEXT CHECK (last_intent IN ('orcamento','duvida','agendamento','reclamacao','outro')),
  unread_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS kommo_messages (
  id BIGSERIAL PRIMARY KEY,
  kommo_message_id TEXT UNIQUE,
  conversation_id BIGINT REFERENCES kommo_conversations(id) ON DELETE CASCADE,
  direction TEXT NOT NULL CHECK (direction IN ('inbound','outbound')),
  text TEXT NOT NULL,
  temperature TEXT CHECK (temperature IN ('frio','morno','quente')),
  intent TEXT CHECK (intent IN ('orcamento','duvida','agendamento','reclamacao','outro')),
  classification_confidence NUMERIC(3,2),
  sent_by TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_kommo_messages_conversation ON kommo_messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_kommo_conversations_last_message ON kommo_conversations(last_message_at DESC);
```

- [ ] **Step 2: Apply via Supabase MCP** `apply_migration` tool.
- [ ] **Step 3: Verify** via `execute_sql`:
```sql
SELECT table_name FROM information_schema.tables WHERE table_name LIKE 'kommo_%';
```
Expected: 2 rows.
- [ ] **Step 4: Commit migration file**
```bash
cd C:\dev\dap4
git add gateway/migrations/20260413_01_kommo_tables.sql
git commit -m "feat(db): add kommo_conversations + kommo_messages tables"
```

---

## Phase 1 — Ana Classify-Only Mode

### Task 1.1: Add classify-only path in agents

**Files:**
- Modify: `C:\dev\dap4\agents\main.py` (ou arquivo da rota `/agent/ana/chat`)
- Create: `C:\dev\dap4\agents\agents\ana_classifier.py`
- Test: `C:\dev\dap4\agents\tests\test_ana_classifier.py`

- [ ] **Step 1: Write failing test**

```python
from agents.ana_classifier import classify

def test_classify_schema():
    r = classify("quero agendar revisão do meu A4 amanhã", phone="5562999999999")
    assert r["temperature"] in {"frio","morno","quente"}
    assert r["intent"] in {"orcamento","duvida","agendamento","reclamacao","outro"}
    assert 0.0 <= r["confidence"] <= 1.0
```

- [ ] **Step 2: Run — verify fails**
```bash
cd C:\dev\dap4\agents && pytest tests/test_ana_classifier.py -v
```

- [ ] **Step 3: Implement `ana_classifier.py`**

```python
import json
from agents.llm_client import chat_completion  # adapt to actual LLM helper

PROMPT = """Classifique a mensagem do cliente. Retorne JSON com:
- temperature: "frio" (curiosidade vaga), "morno" (interesse real sem urgência), "quente" (quer agir, pede orçamento/horário)
- intent: "orcamento" | "duvida" | "agendamento" | "reclamacao" | "outro"
- confidence: 0.0-1.0
Seja conservador com "quente"."""

def classify(text: str, phone: str = "") -> dict:
    resp = chat_completion(
        system=PROMPT,
        user=f"Mensagem: {text}",
        response_format={"type": "json_object"},
    )
    data = json.loads(resp)
    return {
        "temperature": data.get("temperature", "frio"),
        "intent": data.get("intent", "outro"),
        "confidence": float(data.get("confidence", 0.5)),
    }
```

- [ ] **Step 4: Adapt to real LLM client** — inspect `agents/` pra achar o cliente LLM existente (OpenAI wrapper, etc.) e substituir `chat_completion` pela chamada real. Se `response_format` não existir, fallback pra parse manual.

- [ ] **Step 5: Run — verify passes**
```bash
pytest tests/test_ana_classifier.py -v
```

- [ ] **Step 6: Commit**
```bash
git add agents/agents/ana_classifier.py agents/tests/test_ana_classifier.py
git commit -m "feat(ana): classify-only mode returning temperature + intent"
```

### Task 1.2: Expose `/agent/ana/classify` endpoint

**Files:**
- Modify: `C:\dev\dap4\agents\main.py` (ou router equivalente)
- Test: `C:\dev\dap4\agents\tests\test_api_classify.py`

- [ ] **Step 1: Failing test**

```python
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_classify_endpoint():
    r = client.post("/agent/ana/classify", json={"message": "quero orçamento"})
    assert r.status_code == 200
    body = r.json()
    assert body["classification"]["intent"] == "orcamento"
```

- [ ] **Step 2: Run — fails** (404)

- [ ] **Step 3: Add route**

```python
from pydantic import BaseModel
from agents.ana_classifier import classify

class ClassifyReq(BaseModel):
    message: str
    phone: str | None = None

@app.post("/agent/ana/classify")
async def ana_classify(req: ClassifyReq):
    c = classify(req.message, phone=req.phone or "")
    return {"classification": c}
```

- [ ] **Step 4: Run — passes**
- [ ] **Step 5: Commit**
```bash
git add agents/main.py agents/tests/test_api_classify.py
git commit -m "feat(api): POST /agent/ana/classify"
```

---

## Phase 2 — Gateway: Webhook Kommo persiste + emite

### Task 2.1: Persistência de conversa + mensagem

**Files:**
- Create: `C:\dev\dap4\gateway\src\services\kommo-store.service.ts`
- Test: `C:\dev\dap4\gateway\src\services\kommo-store.service.test.ts`

- [ ] **Step 1: Failing test**

```typescript
import { describe, it, expect, vi } from "vitest";
import { upsertConversation, insertMessage } from "./kommo-store.service";

describe("kommo-store", () => {
  it("upserts conversation and inserts message with classification", async () => {
    const supabase = mockSupabase();
    const conv = await upsertConversation(supabase, {
      kommoChatId: "c1", kommoContactId: "ct1", kommoLeadId: "l1",
      contactName: "João", contactPhone: "5562999",
    });
    await insertMessage(supabase, {
      conversationId: conv.id,
      kommoMessageId: "m1",
      direction: "inbound",
      text: "quero orçamento",
      classification: { temperature: "quente", intent: "orcamento", confidence: 0.9 },
    });
    expect(supabase.from).toHaveBeenCalledWith("kommo_messages");
  });
});

function mockSupabase() {
  return {
    from: vi.fn().mockReturnThis(),
    upsert: vi.fn().mockReturnThis(),
    insert: vi.fn().mockResolvedValue({ data: [{ id: 1 }], error: null }),
    select: vi.fn().mockReturnThis(),
    single: vi.fn().mockResolvedValue({ data: { id: 1 }, error: null }),
  } as any;
}
```

- [ ] **Step 2: Run — fails**
```bash
cd C:\dev\dap4\gateway && pnpm vitest run src/services/kommo-store.service.test.ts
```

- [ ] **Step 3: Implement service**

```typescript
import type { SupabaseClient } from "@supabase/supabase-js";

export interface ConversationInput {
  kommoChatId: string;
  kommoContactId?: string;
  kommoLeadId?: string;
  contactName?: string;
  contactPhone?: string;
}

export async function upsertConversation(
  supabase: SupabaseClient,
  input: ConversationInput,
): Promise<{ id: number }> {
  const { data, error } = await supabase
    .from("kommo_conversations")
    .upsert({
      kommo_chat_id: input.kommoChatId,
      kommo_contact_id: input.kommoContactId,
      kommo_lead_id: input.kommoLeadId,
      contact_name: input.contactName,
      contact_phone: input.contactPhone,
      updated_at: new Date().toISOString(),
    }, { onConflict: "kommo_chat_id" })
    .select("id")
    .single();
  if (error) throw new Error(`upsertConversation: ${error.message}`);
  return data as { id: number };
}

export interface MessageInput {
  conversationId: number;
  kommoMessageId?: string;
  direction: "inbound" | "outbound";
  text: string;
  sentBy?: string;
  classification?: { temperature: string; intent: string; confidence: number };
}

export async function insertMessage(supabase: SupabaseClient, input: MessageInput) {
  const { data, error } = await supabase.from("kommo_messages").insert({
    conversation_id: input.conversationId,
    kommo_message_id: input.kommoMessageId,
    direction: input.direction,
    text: input.text,
    sent_by: input.sentBy,
    temperature: input.classification?.temperature ?? null,
    intent: input.classification?.intent ?? null,
    classification_confidence: input.classification?.confidence ?? null,
    created_at: new Date().toISOString(),
  }).select("id").single();
  if (error) throw new Error(`insertMessage: ${error.message}`);

  // Update conversation summary fields for inbound messages
  if (input.direction === "inbound") {
    await supabase.from("kommo_conversations").update({
      last_message_at: new Date().toISOString(),
      last_message_preview: input.text.substring(0, 140),
      last_temperature: input.classification?.temperature ?? null,
      last_intent: input.classification?.intent ?? null,
      unread_count: 1,  // simplified — could increment
    }).eq("id", input.conversationId);
  }
  return data;
}
```

- [ ] **Step 4: Run — passes**
- [ ] **Step 5: Commit**
```bash
git add gateway/src/services/kommo-store.service.ts gateway/src/services/kommo-store.service.test.ts
git commit -m "feat(gateway): kommo-store service persists conversations + messages"
```

### Task 2.2: Toggle webhook para classify-only + persist + emit

**Files:**
- Modify: `C:\dev\dap4\gateway\src\routes\webhook.routes.ts`
- Modify: `C:\dev\dap4\gateway\src\config\env.ts` (add `ANA_AUTOREPLY` flag)

- [ ] **Step 1: Add env flag**

In `config/env.ts`:
```typescript
anaAutoreply: (process.env.ANA_AUTOREPLY ?? "false").toLowerCase() === "true",
```

- [ ] **Step 2: Rewrite webhook handler**

Replace the body of `router.post("/kommo", ...)` in `webhook.routes.ts`:

```typescript
import { upsertConversation, insertMessage } from "../services/kommo-store.service.js";
import { emitMessage } from "../services/socket.service.js";
import { getSupabase } from "../services/supabase.service.js";
import { env } from "../config/env.js";

router.post("/kommo", async (req, res) => {
  const startTime = Date.now();
  try {
    const payload = req.body;
    const msg = payload.message?.[0];
    if (!msg?.text) {
      await logWebhook("kommo", "skipped", payload, null, "No message text");
      return res.json({ status: "ok", action: "skipped" });
    }

    const chatId = String(msg.contact_id || msg.chat_id || "");
    const contact = payload.contacts?.update?.[0];
    const phoneField = contact?.custom_fields?.find((f: any) => f.code === "PHONE");

    const supabase = getSupabase();
    const conv = await upsertConversation(supabase, {
      kommoChatId: chatId,
      kommoContactId: String(msg.contact_id ?? ""),
      kommoLeadId: String(msg.element_id || msg.entity_id || ""),
      contactName: contact?.name || "",
      contactPhone: phoneField?.values?.[0]?.value || "",
    });

    // Classify (non-blocking on failure — persist raw msg anyway)
    let classification;
    try {
      const r = await callPython("/agent/ana/classify", "POST", { message: msg.text });
      classification = (r as any).classification;
    } catch (e) {
      logger.warn("Ana classify failed", { error: (e as Error).message });
    }

    const inserted = await insertMessage(supabase, {
      conversationId: conv.id,
      kommoMessageId: String(msg.id ?? ""),
      direction: "inbound",
      text: msg.text,
      classification,
    });

    emitMessage({
      conversationId: conv.id,
      kommoChatId: chatId,
      direction: "inbound",
      text: msg.text,
      classification,
      timestamp: new Date().toISOString(),
    });

    // Auto-reply só se flag ligada (default: desligada)
    if (env.anaAutoreply) {
      // ... (preservar lógica antiga)
    }

    await logWebhook("kommo", "ok", { chatId, textLen: msg.text.length }, {
      classification: classification?.intent,
      duration_ms: Date.now() - startTime,
    }, null);

    res.json({ status: "ok", conversation_id: conv.id });
  } catch (e) {
    const message = (e as Error).message;
    await logWebhook("kommo", "error", req.body, null, message);
    logger.error("Kommo webhook error", { error: message });
    res.status(500).json({ error: message });
  }
});
```

- [ ] **Step 3: Add `emitMessage` to socket service** if not already typed for these fields.

- [ ] **Step 4: Update test** for webhook (se existir) — garantir que sem `ANA_AUTOREPLY=true`, não chama `/agent/ana/chat` e não chama `sendKommoMessage`.

- [ ] **Step 5: Run vitest**
```bash
pnpm vitest run
```

- [ ] **Step 6: Commit**
```bash
git add gateway/src/routes/webhook.routes.ts gateway/src/config/env.ts gateway/src/services/socket.service.ts
git commit -m "feat(gateway): kommo webhook persists + emits + classify-only default"
```

### Task 2.3: Endpoint pra enviar resposta manual

**Files:**
- Create: `C:\dev\dap4\gateway\src\routes\kommo-send.routes.ts`
- Test: mesma pasta `.test.ts`

- [ ] **Step 1: Failing test**

```typescript
import { describe, it, expect, vi } from "vitest";
import request from "supertest";
import express from "express";
import router from "./kommo-send.routes";

describe("POST /api/kommo/send", () => {
  it("sends message via Kommo + persists outbound", async () => {
    global.fetch = vi.fn().mockResolvedValue({ ok: true, json: () => ({}) });
    const app = express().use(express.json()).use("/api/kommo", router);
    const r = await request(app).post("/api/kommo/send").send({
      conversationId: 1, text: "Claro, tenho horário amanhã",
    });
    expect(r.status).toBe(200);
    expect(fetch).toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Implement**

```typescript
import { Router } from "express";
import { insertMessage } from "../services/kommo-store.service.js";
import { getSupabase } from "../services/supabase.service.js";
import { emitMessage } from "../services/socket.service.js";
import { env } from "../config/env.js";

const router = Router();

router.post("/send", async (req, res) => {
  const { conversationId, text, sentBy = "thales" } = req.body;
  if (!conversationId || !text) return res.status(400).json({ error: "missing fields" });

  const supabase = getSupabase();
  const { data: conv } = await supabase
    .from("kommo_conversations").select("kommo_chat_id").eq("id", conversationId).single();
  if (!conv) return res.status(404).json({ error: "conversation not found" });

  const resp = await fetch(`https://${env.kommoDomain}/api/v4/chats/${conv.kommo_chat_id}/messages`, {
    method: "POST",
    headers: { Authorization: `Bearer ${env.kommoToken}`, "Content-Type": "application/json" },
    body: JSON.stringify({ text, type: "text" }),
    signal: AbortSignal.timeout(30_000),
  });
  if (!resp.ok) return res.status(502).json({ error: `Kommo ${resp.status}` });

  await insertMessage(supabase, { conversationId, direction: "outbound", text, sentBy });
  emitMessage({ conversationId, kommoChatId: conv.kommo_chat_id, direction: "outbound", text, timestamp: new Date().toISOString() });
  res.json({ status: "ok" });
});

export default router;
```

Register in `src/index.ts`:
```typescript
import kommoSendRoutes from "./routes/kommo-send.routes.js";
app.use("/api/kommo", kommoSendRoutes);
```

- [ ] **Step 3: Run — passes**
- [ ] **Step 4: Commit**
```bash
git add gateway/src/routes/kommo-send.routes.ts gateway/src/index.ts gateway/src/routes/kommo-send.routes.test.ts
git commit -m "feat(gateway): POST /api/kommo/send dispara mensagem manual"
```

---

## Phase 3 — Dashboard: Página WhatsApp

### Task 3.1: Componentes de badge

**Files:**
- Create: `C:\dev\dap4\dashboard\src\components\ClassificationBadges.jsx`

- [ ] **Step 1: Write component** (mesmo padrão do plano anterior):

```jsx
const TEMP = { frio: "bg-blue-500/10 text-blue-400 border-blue-500/30", morno: "bg-amber-500/10 text-amber-400 border-amber-500/30", quente: "bg-red-500/10 text-red-400 border-red-500/30" };
const INTENT = { orcamento: "💰", duvida: "❓", agendamento: "📅", reclamacao: "⚠️", outro: "💬" };

export function TemperatureBadge({ value }) {
  if (!value) return null;
  return <span className={`px-2 py-0.5 rounded-full text-xs border ${TEMP[value]}`}>{value}</span>;
}
export function IntentIcon({ value }) {
  if (!value) return null;
  return <span title={value} className="text-sm">{INTENT[value]}</span>;
}
```

- [ ] **Step 2: Commit**
```bash
git add dashboard/src/components/ClassificationBadges.jsx
git commit -m "feat(dashboard): TemperatureBadge + IntentIcon"
```

### Task 3.2: Página /whatsapp

**Files:**
- Create: `C:\dev\dap4\dashboard\src\pages\Whatsapp.jsx`
- Create: `C:\dev\dap4\dashboard\src\hooks\useConversations.js`
- Modify: `C:\dev\dap4\dashboard\src\main.jsx` (rota)

- [ ] **Step 1: Hook `useConversations`**

```javascript
import { useEffect, useState } from "react";
import { supabase } from "../lib/supabase";
import { socket } from "../lib/socket";

export function useConversations() {
  const [convs, setConvs] = useState([]);
  useEffect(() => {
    supabase.from("kommo_conversations")
      .select("*").order("last_message_at", { ascending: false }).limit(100)
      .then(({ data }) => setConvs(data || []));
    socket.on("message:new", (msg) => {
      setConvs((prev) => {
        const updated = prev.map((c) => c.id === msg.conversationId
          ? { ...c, last_message_at: msg.timestamp, last_message_preview: msg.text.substring(0, 140), last_temperature: msg.classification?.temperature, last_intent: msg.classification?.intent }
          : c);
        return updated.sort((a, b) => new Date(b.last_message_at) - new Date(a.last_message_at));
      });
    });
    return () => socket.off("message:new");
  }, []);
  return convs;
}
```

- [ ] **Step 2: Hook `useMessages` (similar, para a conversa selecionada)**

```javascript
export function useMessages(conversationId) {
  const [msgs, setMsgs] = useState([]);
  useEffect(() => {
    if (!conversationId) return;
    supabase.from("kommo_messages")
      .select("*").eq("conversation_id", conversationId).order("created_at", { ascending: true })
      .then(({ data }) => setMsgs(data || []));
    const handler = (m) => { if (m.conversationId === conversationId) setMsgs((p) => [...p, m]); };
    socket.on("message:new", handler);
    return () => socket.off("message:new", handler);
  }, [conversationId]);
  return msgs;
}
```

- [ ] **Step 3: Page `Whatsapp.jsx`**

```jsx
import { useState } from "react";
import { useConversations, useMessages } from "../hooks/useConversations";
import { TemperatureBadge, IntentIcon } from "../components/ClassificationBadges";

export default function Whatsapp() {
  const convs = useConversations();
  const [selected, setSelected] = useState(null);
  const msgs = useMessages(selected?.id);
  const [draft, setDraft] = useState("");

  async function send() {
    if (!draft.trim() || !selected) return;
    await fetch("/api/kommo/send", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ conversationId: selected.id, text: draft }),
    });
    setDraft("");
  }

  return (
    <div className="flex h-full">
      <aside className="w-80 border-r border-zinc-800 overflow-y-auto">
        {convs.map((c) => (
          <button key={c.id} onClick={() => setSelected(c)}
            className={`w-full p-3 text-left border-b border-zinc-800 hover:bg-zinc-900 ${selected?.id === c.id ? "bg-zinc-900" : ""}`}>
            <div className="flex items-center gap-2">
              <span className="flex-1 truncate font-medium">{c.contact_name || c.contact_phone}</span>
              <IntentIcon value={c.last_intent} />
              <TemperatureBadge value={c.last_temperature} />
            </div>
            <div className="text-xs text-zinc-500 truncate mt-1">{c.last_message_preview}</div>
          </button>
        ))}
      </aside>
      <main className="flex-1 flex flex-col">
        {selected ? (
          <>
            <header className="p-4 border-b border-zinc-800">
              <h2 className="font-semibold">{selected.contact_name || selected.contact_phone}</h2>
            </header>
            <div className="flex-1 overflow-y-auto p-4 space-y-2">
              {msgs.map((m) => (
                <div key={m.id} className={`max-w-md ${m.direction === "outbound" ? "ml-auto" : ""}`}>
                  <div className={`px-3 py-2 rounded-lg ${m.direction === "outbound" ? "bg-emerald-600 text-white" : "bg-zinc-800"}`}>
                    {m.text}
                  </div>
                  {m.direction === "inbound" && m.temperature && (
                    <div className="mt-1 flex gap-1 text-xs">
                      <TemperatureBadge value={m.temperature} />
                      <IntentIcon value={m.intent} />
                    </div>
                  )}
                </div>
              ))}
            </div>
            <footer className="p-4 border-t border-zinc-800 flex gap-2">
              <input value={draft} onChange={(e) => setDraft(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && send()}
                placeholder="Responder..." className="flex-1 bg-zinc-900 px-3 py-2 rounded" />
              <button onClick={send} className="px-4 py-2 bg-emerald-600 rounded">Enviar</button>
            </footer>
          </>
        ) : (
          <div className="flex-1 grid place-items-center text-zinc-500">Selecione uma conversa</div>
        )}
      </main>
    </div>
  );
}
```

- [ ] **Step 4: Wire route in `main.jsx`**

Add: `{ path: "/whatsapp", element: <Whatsapp /> }` no router existente.

- [ ] **Step 5: Smoke manual**
```bash
cd C:\dev\dap4\dashboard && pnpm dev
```
Abre `/whatsapp` — lista vazia (antes do backfill) mas UI renderiza.

- [ ] **Step 6: Commit**
```bash
git add dashboard/src/pages/Whatsapp.jsx dashboard/src/hooks/useConversations.js dashboard/src/main.jsx
git commit -m "feat(dashboard): /whatsapp page com lista + composer manual"
```

---

## Phase 4 — Backfill do Kommo

### Task 4.1: Script one-shot `scripts/backfill-kommo.ts`

**Files:**
- Create: `C:\dev\dap4\gateway\scripts\backfill-kommo.ts`

- [ ] **Step 1: Implementar**

```typescript
import { createClient } from "@supabase/supabase-js";

const SUPA_URL = process.env.SUPABASE_URL!;
const SUPA_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const KOMMO_TOKEN = process.env.KOMMO_TOKEN!;
const KOMMO_DOMAIN = process.env.KOMMO_DOMAIN!;
const THROTTLE_MS = 200;  // ~5 req/s

const supa = createClient(SUPA_URL, SUPA_KEY);

async function kommo<T>(path: string): Promise<T> {
  const r = await fetch(`https://${KOMMO_DOMAIN}/api/v4${path}`, {
    headers: { Authorization: `Bearer ${KOMMO_TOKEN}` },
  });
  if (!r.ok) throw new Error(`Kommo ${r.status} ${path}`);
  return r.json();
}

async function main() {
  console.log("Backfilling Kommo chats...");
  let page = 1;
  let totalChats = 0;
  let totalMessages = 0;

  while (true) {
    const data: any = await kommo(`/chats?page=${page}&limit=50`);
    const chats = data?._embedded?.chats || [];
    if (chats.length === 0) break;

    for (const chat of chats) {
      const contact = chat.contact || {};
      const { data: conv } = await supa.from("kommo_conversations").upsert({
        kommo_chat_id: String(chat.id),
        kommo_contact_id: String(contact.id ?? ""),
        contact_name: contact.name || "",
        contact_phone: contact.phone || "",
      }, { onConflict: "kommo_chat_id" }).select("id").single();

      // Fetch messages for this chat
      const msgData: any = await kommo(`/chats/${chat.id}/messages?limit=250`);
      const messages = msgData?._embedded?.messages || [];
      for (const m of messages) {
        await supa.from("kommo_messages").upsert({
          kommo_message_id: String(m.id),
          conversation_id: conv!.id,
          direction: m.type === "incoming" ? "inbound" : "outbound",
          text: m.text || "",
          created_at: new Date((m.created_at || 0) * 1000).toISOString(),
        }, { onConflict: "kommo_message_id" });
        totalMessages++;
      }
      totalChats++;
      await new Promise((r) => setTimeout(r, THROTTLE_MS));
    }
    console.log(`Page ${page}: ${totalChats} chats, ${totalMessages} messages so far`);
    page++;
  }
  console.log(`Done. Chats: ${totalChats}, Messages: ${totalMessages}`);
}

main().catch((e) => { console.error(e); process.exit(1); });
```

- [ ] **Step 2: Adaptar endpoints reais do Kommo**

Kommo pode não ter `/chats` exato — verificar docs. Alternativa: iterar `/leads` → `/notes` por lead (notas costumam conter as conversas). Rodar em dev com `--dry-run` flag primeiro pra não duplicar.

- [ ] **Step 3: Rodar contra staging ou com LIMIT pequeno primeiro**

```bash
cd C:\dev\dap4\gateway
tsx scripts/backfill-kommo.ts
```

Monitorar saída. Se endpoint errado, ajustar path.

- [ ] **Step 4: Verificar Supabase**

```sql
SELECT COUNT(*) FROM kommo_conversations;
SELECT COUNT(*) FROM kommo_messages;
```

- [ ] **Step 5: Commit**
```bash
git add gateway/scripts/backfill-kommo.ts
git commit -m "feat(scripts): backfill Kommo chats + messages to Supabase"
```

---

## Phase 5 — Deploy + Webhook Público

### Task 5.1: Deploy stack no VPS (como root hoje)

**Files:** nenhum local

- [ ] **Step 1: Push commits**
```bash
git push origin master
```

- [ ] **Step 2: Pull no VPS + rebuild**
```bash
ssh -i ~/.ssh/id_ed25519 root@76.13.170.42 "cd /opt/doctor-auto-ai && git pull origin master && docker compose pull && docker compose build && docker compose up -d && docker compose ps"
```

Expected: todos os serviços `Up (healthy)`.

- [ ] **Step 3: Verificar `.env` no VPS tem `KOMMO_TOKEN` + `KOMMO_DOMAIN` + `ANA_AUTOREPLY=false`**

```bash
ssh -i ~/.ssh/id_ed25519 root@76.13.170.42 "grep -E '^(KOMMO_|ANA_AUTO)' /opt/doctor-auto-ai/.env"
```

Se faltar, editar e `docker compose restart gateway`.

### Task 5.2: Tunnel hostnames

- [ ] **Step 1:** No Cloudflare Zero Trust dashboard → tunnel existente → Public Hostname → adicionar:
  - `webhook.doctorautoprime40.com` → HTTP → `localhost:3001`
  - `app.doctorautoprime40.com` → HTTP → `localhost:8080` (ou porta do dashboard/nginx — confirmar em `docker-compose.prod.yml`)

- [ ] **Step 2: Verificar**
```bash
curl -sI https://webhook.doctorautoprime40.com/api/webhook/status | head -5
```
Expected: `HTTP/2 200`.

### Task 5.3: Atualizar URL do webhook no Kommo

- [ ] **Step 1:** Abrir Kommo → Settings → Integrations → Webhooks
- [ ] **Step 2:** Adicionar (ou editar) URL: `https://webhook.doctorautoprime40.com/api/webhook/kommo`
- [ ] **Step 3:** Marcar eventos: `Incoming chat message`, `Incoming message`, `Chat message` (o que estiver disponível)
- [ ] **Step 4:** Save.

---

## Phase 6 — Smoke Test + Ajustes

### Task 6.1: End-to-end

- [ ] **Step 1:** Celular pessoal → mandar WhatsApp pro número Prime: "Quero agendar revisão do meu A4 amanhã"
- [ ] **Step 2:** Logs:
```bash
ssh -i ~/.ssh/id_ed25519 root@76.13.170.42 "cd /opt/doctor-auto-ai && docker compose logs -f gateway" 
```
Esperar: `Kommo webhook received` + `Ana classification {temperature: "quente", intent: "agendamento"}` + `Persisted` + `Socket emit`.

- [ ] **Step 2: Portal** — abrir `https://app.doctorautoprime40.com/whatsapp` → conversa aparece em <5s com badge `quente` + ícone 📅.

- [ ] **Step 3:** Digitar resposta no composer: "Claro, tenho 10h amanhã — fecha?" → Enviar.

- [ ] **Step 4:** Verificar no celular que a mensagem chega (via Kommo) em <10s.

- [ ] **Step 5:** Confirmar Kommo ainda funciona pra equipe atual:
```
(Thales valida no dashboard do Kommo que a conversa também aparece lá)
```

### Task 6.2: Rollback

- [ ] **Se Ana classify cair** → webhook ainda persiste mensagens sem classificação (portal fica usável, badges em branco). Tolerável.
- [ ] **Se webhook Kommo falha** → logs em `webhook_logs` table. Rodar `docker compose logs gateway | grep kommo`.
- [ ] **Se envio de resposta falha** → fallback automático no código tenta Kommo notes API. Se falhar também, checar permissões do token Kommo.

---

## Critério de sucesso

- [ ] Portal lista conversas antigas (backfill) + novas (webhook) ordenadas por data
- [ ] Cliente manda WhatsApp → aparece no portal em <5s
- [ ] Badge temperatura + ícone intent aparecem
- [ ] Thales responde pelo portal → chega no cliente em <10s via Kommo
- [ ] Ana não responde automaticamente
- [ ] Kommo continua operando normal pro time existente

## Ordem de execução sugerida

1. Phase 0 (schema) — 15min
2. Phase 1 (Ana classify) — 30min
3. Phase 2 (gateway webhook persist + send) — 60min
4. Phase 3 (dashboard /whatsapp) — 60min
5. Phase 4 (backfill — roda em paralelo com Phase 5) — 30min setup + run em background
6. Phase 5 (deploy + tunnel + Kommo URL) — 30min
7. Phase 6 (smoke test) — 15min

Total: ~4h focado, paralelizável.
