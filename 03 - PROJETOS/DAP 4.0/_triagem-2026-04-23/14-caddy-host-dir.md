# 14 — Caddyfile host=dir (pendência pós-cutover)

**Data:** 2026-04-23
**Origem:** memory `project_dap4_cutover_2026_04_23.md` — "Caddyfile host=dir (pendência)"
**Escopo:** análise, sem tocar VPS.

---

## 1. Estado atual (evidência VPS)

`/opt/doctor-auto-ai/Caddyfile` em 23/04:

```caddyfile
{ auto_https off }

:80 {
  @api path /api/* /socket.io/*
  handle @api {
    request_header Authorization "Bearer <API_SECRET>"
    reverse_proxy gateway:3001
  }
  handle {
    root * /srv/dashboard
    try_files {path} /index.html
    file_server
  }
}
```

**Observações:**

- Site único `:80` — **zero host matcher**. Qualquer Host header cai no mesmo bloco.
- `auto_https off` → TLS é 100% Cloudflare edge; Caddy fala HTTP plaintext dentro do Tunnel.
- Roteamento só por **path** (API vs SPA), não por **tenant**.
- Cloudflared roda como systemd (`/usr/local/bin/cloudflared --token ...`) — **não há `config.yml` local**; todas rotas (public hostnames) vivem em `one.dash.cloudflare.com → Zero Trust → Networks → Tunnels → dap4`.
- `config/tenants/` só tem `dap.yaml` (um tenant). Bosch/Prime hoje são distinguidos via `pipeline_id` do Kommo no runtime do Parliament, **não por host HTTP**.

**Leitura da pendência:** "host=dir" = quando plugar um 2º tenant com UI/webhook próprios (ex.: bosch.doctorautoprime40.com, prime.doctorautoprime40.com, parceiro.doctorautoprime40.com), o Caddyfile atual não sabe distinguir host e todo mundo cai no mesmo `/srv/dashboard`. Falta roteamento por host → diretório/upstream.

---

## 2. Padrões Caddyfile que resolvem

### 2a. Um Caddyfile, múltiplos sites (canônico Caddy)

```caddyfile
{ auto_https off }

(api_proxy) {
  @api path /api/* /socket.io/*
  handle @api {
    request_header Authorization "Bearer {$API_SECRET}"
    reverse_proxy gateway:3001
  }
}

http://dap.doctorautoprime40.com, http://doctorautoprime40.com {
  import api_proxy
  handle { root * /srv/dashboard/dap; try_files {path} /index.html; file_server }
}

http://bosch.doctorautoprime40.com {
  import api_proxy
  handle { root * /srv/dashboard/bosch; try_files {path} /index.html; file_server }
}

http://prime.doctorautoprime40.com {
  import api_proxy
  handle { root * /srv/dashboard/prime; try_files {path} /index.html; file_server }
}
```

Snippet `api_proxy` (DRY) + um site por host. Upstream compartilha o mesmo gateway — tenant é decidido pelo `Host` forwarded + payload/pipeline_id.

### 2b. Named matchers com `host`

Quando preferir **um bloco só** e ramificar internamente:

```caddyfile
:80 {
  @bosch host bosch.doctorautoprime40.com
  @prime host prime.doctorautoprime40.com
  @dap   host dap.doctorautoprime40.com doctorautoprime40.com

  handle @bosch { root * /srv/dashboard/bosch; file_server }
  handle @prime { root * /srv/dashboard/prime; file_server }
  handle @dap   { root * /srv/dashboard/dap;   file_server }
}
```

Mais compacto mas menos legível quando sobem >3 tenants.

### 2c. `import sites/*.caddy` (modular)

```caddyfile
# /opt/doctor-auto-ai/Caddyfile
{ auto_https off }
(api_proxy) { ... }
import sites/*.caddy
```

Um arquivo por tenant em `sites/bosch.caddy`, `sites/prime.caddy`, `sites/dap.caddy`. Adicionar tenant = adicionar arquivo + reload. **Escala sem editar master.**

### 2d. Caddy JSON API (runtime)

`POST /load` em `localhost:2019` substitui config sem reload visível. Útil pra automação (Parliament detecta novo tenant → gera JSON → push). Overkill hoje.

### 2e. Template com `{http.request.host.labels.0}`

```caddyfile
:80 {
  map {host} {tenant} {
    bosch.doctorautoprime40.com bosch
    prime.doctorautoprime40.com prime
    default dap
  }
  root * /srv/dashboard/{tenant}
  file_server
}
```

Elegante mas frágil — falha silenciosamente se o dir não existe. Prefira allowlist explícita.

---

## 3. Trade-offs

| Abordagem | Prós | Contras | Quando usar |
|---|---|---|---|
| **2a — sites múltiplos** | legível, idiomático, fail-loud | master cresce linear | 2-5 tenants |
| **2b — named matchers** | compacto | difícil auditar | MVP de 2 |
| **2c — `import sites/*`** | escala, git-friendly por tenant | 2 lugares pra olhar | **≥3 tenants ou parceiros externos** |
| **2d — JSON API** | dinâmico, sem reload | complexidade alta, debug ruim | SaaS com onboarding programático |
| **2e — map + template** | DRY extremo | magia implícita, 404 estranho | nunca em prod crítico |

**Geração a partir de `config/tenants/dap.yaml`:** hoje só existe 1 yaml, então gerar Caddyfile via script é YAGNI. Virará natural quando subir o 2º yaml — script lê `config/tenants/*.yaml`, emite `sites/<tenant>.caddy`. Casa com 2c.

---

## 4. Cloudflare Tunnel — multi-host

Tunnel `dap4` já roda com token remoto (sem config.yml local). Duas formas de adicionar hosts:

**Via Dashboard (atual, recomendado manter):**
Zero Trust → Networks → Tunnels → dap4 → Public Hostnames → Add:
- `bosch.doctorautoprime40.com` → Service `http://caddy:80`
- `prime.doctorautoprime40.com` → Service `http://caddy:80`

Todos apontam pro **mesmo Caddy**, que roteia por Host. Zero reboot do tunnel.

**Via config.yml (se migrar pra tunnel local):**
```yaml
tunnel: df082b0d-aa0b-4dd8-8274-c5f2ed61e561
credentials-file: /etc/cloudflared/creds.json
ingress:
  - hostname: bosch.doctorautoprime40.com
    service: http://caddy:80
  - hostname: prime.doctorautoprime40.com
    service: http://caddy:80
  - service: http_status:404
```

**Não misture os dois modelos.** Token-based ignora config.yml. Hoje é token — mantenha dashboard como source of truth **ou** migre inteiro pra config.yml versionado em git (mais world-class, mas exige re-provisionar o tunnel).

---

## 5. TLS — cenário atual e alvo

- **Hoje:** CF edge faz TLS público (cert Universal CF). Tunnel cifra CF↔VPS. Caddy escuta `:80` plaintext interno. `auto_https off` está **correto pro modelo tunnel**.
- **Impacto de adicionar subdomínios:** CF emite cert automaticamente pra qualquer hostname sob `doctorautoprime40.com` assim que o hostname é adicionado no tunnel. **Zero trabalho em Caddy.**
- **Se um dia sair do tunnel** (e.g. expor direto na 443): ligar `auto_https on`, abrir 443 no firewall, remover `request_header Authorization` do header spoof (inseguro em edge pública). **Não é a recomendação** — mantenha tunnel.

---

## 6. Proposta canônica

**Caminho 2c (`import sites/*.caddy`) + CF Dashboard pra hostnames.**

Razões:
- Cada tenant vira 1 arquivo versionado em git → audit trail claro.
- Onboarding de parceiro = PR com novo `sites/<tenant>.caddy` + 1 clique no CF dashboard. Reversível.
- Não exige tocar no `cloudflared.service` nem rotacionar tunnel token.
- Preserva o modelo "Caddy só reverse proxy + static, TLS no CF".

### Passos (quando 2º tenant existir)

1. Criar `/opt/doctor-auto-ai/sites/` e mover bloco atual pra `sites/dap.caddy` (com host explícito `dap.doctorautoprime40.com, doctorautoprime40.com`).
2. Reescrever `Caddyfile` raiz pra:
   ```caddyfile
   { auto_https off }
   (api_proxy) { @api path /api/* /socket.io/*; handle @api { request_header Authorization "Bearer {$API_SECRET}"; reverse_proxy gateway:3001 } }
   import sites/*.caddy
   ```
3. Adicionar `sites/bosch.caddy` com `root * /srv/dashboard/bosch`.
4. Build do dashboard precisa emitir `dist/bosch/` e `dist/dap/` (ou montar volumes separados). Ajuste no `dashboard/Dockerfile` + Vite `base`.
5. `docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile` antes de reload.
6. `docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile` (zero downtime).
7. CF dashboard: add public hostname `bosch.doctorautoprime40.com` → `http://caddy:80`.
8. Smoke test: `curl -H "Host: bosch.doctorautoprime40.com" https://bosch.doctorautoprime40.com/api/health`.

### Bônus — versionar tunnel

Segunda fase, fora do escopo desta pendência: migrar `cloudflared` de token pra `config.yml` em git. Elimina "CF dashboard é source of truth invisível".

---

## 7. Riscos

| Risco | Mitigação |
|---|---|
| **Downtime durante reload** | `caddy reload` é hot; valide antes com `caddy validate`. |
| **Cache CF servindo versão antiga** | Purge cache do hostname após deploy; usar cache-control nas assets. |
| **Cert não emitido pro novo subdomínio** | CF gera automático em ~60s; se falhar, verificar se zone tem DNS wildcard ou criar CNAME explícito `bosch → <tunnel-id>.cfargotunnel.com`. |
| **Vazar API_SECRET no Caddyfile público** | Já usa `{$API_SECRET}` via env; garantir que `sites/*.caddy` não hardcoda. Rotacionar secret se exposto. |
| **Dashboard build não separa tenants** | Antes do cutover do 2º tenant, validar que Vite `build --base=/bosch/` gera paths corretos; senão SPA quebra no refresh. |
| **Host spoofing** (cliente forja Host header interno) | Caddy confia no Host forwarded pelo tunnel — **mas** cloudflared só aceita hostnames registrados no tunnel. Cadeia é segura. Não aceitar `Host: *` em site default (use `handle_errors` ou bloco catch-all que retorna 404). |
| **Dois modelos de tunnel (token + config.yml)** | Decidir UM. Hoje é token — não adicionar config.yml sem migrar inteiro. |

---

## 8. Resumo executivo

- Pendência é real: Caddyfile atual tem roteamento por path, não por host. Escala travado em 1 tenant visível.
- Fix canônico: **`import sites/*.caddy` + CF dashboard hostnames**. Modular, versionável, zero downtime.
- Não urgente — só precisa existir antes do **2º tenant com UI/webhook próprio**. Bosch+Prime hoje compartilham UI e se distinguem por `pipeline_id`; pendência só materializa quando parceiro externo entrar (DAP Performance white-label, p.ex.).
- **Acionável agora:** criar `sites/dap.caddy` e o skeleton `import sites/*.caddy` no repo — prepara o terreno sem mudar comportamento. Commit pequeno, review fácil.
