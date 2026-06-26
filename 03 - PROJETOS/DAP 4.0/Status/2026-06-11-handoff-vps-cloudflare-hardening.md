# Handoff — Auditoria + Hardening VPS/Cloudflare DAP4.0

**Data:** 2026-06-11 · **Autor:** Claude (sessão Thales) · **Host:** `76.13.170.42` (srv1303948)
**Escopo:** auditoria completa da VPS + Cloudflare e remediação de segurança/infra.
**Mover para:** vault `…/CHAIRMAN/PITOS/03 - PROJETOS/DAP 4.0/Status/` (não estava montado local nesta sessão).

---

## 1. Resumo executivo

A infra saiu de **🟡 6/10** (estável, mas com vulnerabilidade real + landmines de restart + zero observabilidade) para um estado **sólido e observável**. Tudo verificado de fora (curl nos hostnames) e de dentro (ss/iptables/systemd/docker). **Zero downtime nos portais públicos** durante toda a sessão (servidos pelo `aios-staging`, que não foi tocado nas mudanças do backend).

**Maior achado:** três "landmines" silenciosos onde a config em disco divergia do que rodava — qualquer `docker restart`/`compose up` derrubaria produção ou sumiria o RAG. Todos defusados.

---

## 2. O que foi implementado (em ordem)

1. **Limpeza Docker** — `docker builder prune` liberou **51,84 GB** (imagens 61→14,7 GB); container `chapapiuro` parado removido.
2. **Landmine Caddy defusado** — bind-mount de arquivo único com inode preso: o container subiu 04/06 com a config certa, mas o arquivo em disco foi sobrescrito 5h depois com versão obsoleta (`portal`/`dap`). Restart carregaria a errada e derrubaria consultor/gestao/aios/mecanico. Sincronizado disco↔running.
3. **nginx host fantasma desativado** — `systemctl disable --now nginx`. Servia só `dap.*` (sem DNS) e `srv1303948.hstgr.cloud:443` (borda bloqueia); túnel nunca passou por ele.
4. **Subdomínios de lixo deletados** (DNS + ingress do túnel + rotas Caddy): `aios-staging`, `staging-operacao`, `chapapiuro`, `webhook`.
5. **ChromaDB fechado pra fora** — `0.0.0.0:8100` → `127.0.0.1:8100` (recreate em 0.6.3). Era o único risco de segurança ativo (RAG sem auth exposto).
6. **Composes pinados em 0.6.3** nos 3 arquivos (defusou downgrade landmine: o deploy documentado faria `0.6.3→0.5.23`, quebrando o volume).
7. **Kernel atualizado** — reboot `6.17.0-23` → `6.17.0-35`. Recuperação automática 100% (~30s downtime).
8. **SSH endurecido** — `PasswordAuthentication no` + `PermitRootLogin prohibit-password` (key-only). Testado: key OK, senha rejeitada. fail2ban + unattended-upgrades já estavam ativos.
9. **cloudflared** `2026.3.0` → `2026.6.0`.
10. **Reconciliação dos composes** — stack unificado em `docker-compose.unified.yml` (Opção A: mantém nomes vivos, só Caddy recria). **Landmine R2 defusado:** o `prod.yml` documentado apontava ChromaDB pra volume VAZIO (`doctor-auto-ai_chroma_data`) enquanto o RAG vivo está em `dap4_chroma` + subiria `portal-familia` fantasma. Antigos movidos pra `_decom/`.
11. **Observabilidade no ar** — Prometheus + node-exporter + cAdvisor + Loki + Promtail + Grafana em `/opt/monitoring/`, tudo bind `127.0.0.1`, sem exposição pública (acesso por túnel SSH).

---

## 3. Arquivos criados/alterados

**Na VPS:**
- `/opt/doctor-auto-ai/docker-compose.unified.yml` — fonte única do stack (novo).
- `/opt/doctor-auto-ai/DEPLOY.md` — deploy canônico atual (novo).
- `/opt/doctor-auto-ai/_decom/` — composes antigos aposentados.
- `/opt/doctor-auto-ai/docker-compose.yml` (base, antes do decom): `chroma:latest`→`0.6.3`, `8100`→`127.0.0.1:8100`.
- `/opt/doctor-auto-ai/infra/docker-compose.prod.yml` (antes do decom): `0.5.23`→`0.6.3`.
- `/opt/doctor-auto-ai/infra/Caddyfile` — rotas órfãs removidas; disco==container.
- `/opt/monitoring/*` — stack de observabilidade completo (compose, prometheus, loki, promtail, grafana provisioning + dashboard).
- `/etc/ssh/sshd_config` — hardening (backup em `/root/cf-backup-2026-06-11/`).
- nginx: `systemctl disable --now`.

**No repo (`C:\THALES\DAP4.0\dap4`):**
- `infra/README.md` — nota de que `prod.yml` foi superseded por `unified.yml` (⚠️ não commitado ainda).

**Cloudflare:** 4 DNS deletados, ingress do túnel limpo (5 portais + catch-all).

**Backups (VPS):** `/root/cf-backup-2026-06-11/` (tunnel, dns, caddy, nginx, sshd, composes) + `/root/backups/dap4_chroma-2026-06-11.tgz` (volume RAG).

---

## 4. Estado atual da topologia

**Subdomínios ativos (DNS proxied + ingress):** `consultor`, `gestao`, `operacao`, `aios`, `mecanico` + `www`/raiz.
- raiz/www → origin externo `2.57.91.91` (NÃO é a VPS; landing à parte).
- portais → cloudflared (systemd) → Caddy `:80` (ou `:5001`) → `aios-staging:5050`.

**Containers (stack DAP4):** chromadb (0.6.3, 127.0.0.1:8100, vol `dap4_chroma`), agents, gateway, dap4-caddy (rede `doctor-auto-ai_default`), aios-staging (ponte `_default`+`_internal`, vem de `/opt/dap-aios/src`).

**Observabilidade:** `monitoring-*` (6 containers), tudo `127.0.0.1`.

---

## 5. Como rodar / acessar

**Deploy do stack:**
```bash
cd /opt/doctor-auto-ai
docker compose -f docker-compose.unified.yml up -d           # adota stack vivo
docker compose -f docker-compose.unified.yml up -d --build    # só p/ rebuildar agents/gateway
```

**Grafana (sem exposição pública):**
```bash
ssh -i ~/.ssh/id_ed25519 -L 3000:localhost:3000 root@76.13.170.42
# navegador: http://localhost:3000  · user admin · senha em /opt/monitoring/.env (cat via SSH)
```

---

## 6. Testes/verificações executadas

- 5 portais públicos + raiz = **HTTP 200** (após cada mudança crítica).
- ChromaDB: heartbeat 200, `ss` confirma só `127.0.0.1:8100`, volume `dap4_chroma` montado.
- Gateway `/api/health` 200, agents healthy.
- SSH: conexão nova com key OK, senha = `Permission denied (publickey)`.
- Reboot: 9 containers voltaram healthy, cloudflared/dap-aios active, nginx inactive.
- Observabilidade: Prometheus 3 targets UP, Loki ready + recebendo logs, Grafana 2 datasources.
- Reconciliação: dry-run antes de aplicar; só caddy/chromadb/agents recriaram, gateway intacto.

---

## 7. Riscos / pendências

- 🔴 **Revogar token Cloudflare `cfut_…`** — recebeu permissão de escrita e ficou no histórico do chat. (Thales sinalizou que revogou — CONFIRMAR.)
- 🟡 **Repo ↔ VPS drift** — `dap4/CLAUDE.md` e `infra/README.md` descrevem modelo antigo (cloudflared container `--profile prod`, dashboard:80) ≠ realidade (cloudflared systemd, aios-staging serve portais). Sync amplo pendente + commit do README já editado.
- 🟡 **Stack `chapapiuro-*`** ainda roda (4 containers) sem subdomínio — parar se o projeto foi largado.
- 🟡 **Rede `_internal`** mantida só porque o compose do `aios-staging` a referencia como `external` — consolidar no futuro.
- 🟡 **Observabilidade sem exposição pública** — falta rota `metrics.*` (precisa token CF de escrita + Cloudflare Access). Plano pronto em `/opt/monitoring/DEPLOY-PLAN.md`.

---

## 8. Próxima rodada sugerida

1. Expor Grafana em `metrics.doctorautoprime40.com` (Caddy route + ingress CF + Cloudflare Access) — passos prontos no DEPLOY-PLAN.
2. Sync amplo da doc do repo dap4 com a realidade da VPS + commit.
3. Decisão chapapiuro (manter/parar).
4. Alertmanager + regras (container down, cert expiry, disco) no Prometheus.
5. Consolidar `aios-staging` numa rede só (remover `_internal`).

**Paraleliza bem:** preparo de cada item (autoria de config/plano) roda em subagentes paralelos; o *apply* na VPS é sempre serial (um writer por vez no Docker). Nesta sessão usei 2 agentes paralelos pra desenhar observabilidade + plano de reconciliação — funcionou.

---

## 9. Doc viva
Detalhe técnico completo (com md5s, comandos, divergências) na memória: `~/.claude/projects/C--THALES-DAP4-0/memory/vps-cloudflare-audit.md`.
