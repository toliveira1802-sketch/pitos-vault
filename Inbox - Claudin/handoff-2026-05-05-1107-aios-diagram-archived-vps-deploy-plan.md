---
type: handoff
date: 2026-05-05
time: 11:07
project: dap-aios (P0 — hub C:\THALES\DAP4\)
topic: aios-diagram arquivado em dap-aios/docs/aios-diagram/, 4 commits pushados em feat/aios-nucleo-consultor; preview de deploy VPS rascunhado
tags: [handoff, claudin, dap-aios, aios-diagram, archive, vps-deploy-plan]
---

# Handoff — aios-diagram archived, dap-aios pushed, VPS deploy não iniciado

## Contexto

Continuação direta do handoff `2026-05-05-0852-dap4-hub-consolidado.md`. Naquele ponto: hub `C:\THALES\DAP4\` consolidado, 4 sub-projetos siblings (`dap-aios`, `dap-operacao`, `dap-tools`, `aios-diagram`), source `dap-operacao` ficou locked (sessão anterior).

Sessão atual: 4ª sub-projeto (`aios-diagram`) era artefato congelado MVP 1.0 (site estático D3+vanilla JS, mandala da Sala do Conselho), repo local-only sem remote. Decisão tomada: arquivar dentro do `dap-aios` como snapshot navegável, preservar histórico git num bundle no PITOS, deletar source. Hub passa a ter 3 sub-projetos.

Brainstorming → spec → plan → 10 tasks subagent-driven → push completo. ~2h.

## O que funcionou (com evidência)

- **Brainstorming convergiu em 5 perguntas** — opção A (archive como referência), path `dap-aios/docs/aios-diagram/`, sem runtime serving, bundle no PITOS, source deleted.
- **Spec `2026-05-05-aios-diagram-merge-design.md`** commit `2b9ab84` em `feat/aios-nucleo-consultor`. 202 linhas. Self-review fixou ambiguidade do `.gitignore`.
- **Plan `2026-05-05-aios-diagram-merge.md`** commit `a71e8b1`. 10 tasks atômicas, ~601 linhas. Self-review fixou contagem de HTMLs (11→14).
- **Subagent-driven execution** — 8 implementer subagents (sonnet) despachados via Task/Agent tool. Tarefa 1 (haiku) falhou com "Prompt is too long", retry com sonnet OK; padrão sonnet usado pro resto. Cada task auto-contido, instruções precisas, sem inheritance de contexto.
- **Bundle git verificado** — `git bundle create --all` + `git bundle verify` + sanity `git clone` num temp dir mostrou 5 commits do aios-diagram (incluindo MVP 1.0 tip `b4198b9 feat: add RAG page`). Bundle: 184K em `OneDrive/Documentos/CHAIRMAN/PITOS/Backups/aios-diagram-2026-04-24.bundle`.
- **Cópia de 41 arquivos** pra `dap-aios/docs/aios-diagram/` — 14 HTMLs (3 funcionais + 11 stubs) + 12 .js (scripts + vendor d3) + 8 .css + 4 .png debug + README + .gitignore + tests/.
- **Smoke automático HTTP-level** — Python http.server em background (PID 19144), 4/4 páginas (`/`, `agentes.html`, `parlamento.html`, `tests/test-runner.html`) retornaram 200 com fingerprints esperados. 26/26 referências (scripts+stylesheets+images) carregaram sem 404. Server killado limpo.
- **Commit principal `25b259e`** `docs(diagrams): import aios-diagram MVP 1.0 snapshot 2026-04-24` — 44 arquivos, 8069 inserções.
- **Source deletado limpo** — `Remove-Item -Recurse -Force C:\THALES\DAP4\aios-diagram` sem file lock (cwd estava em `C:\Users\docto`, não dentro do source). `Test-Path` confirmou `False`. Hub final: 3 dirs.
- **ARCHIVE-NOTES.md** dentro de `docs/aios-diagram/` — 2528 bytes, 3 code fences propriamente formatados, com banner snapshot frozen + path do bundle + comando pra reconstruir.
- **Specs/plans MVP 1.0 movidos** pra `dap-aios/docs/superpowers/{specs,plans}/` na convenção do dap-aios. Não duplicaram dentro de `docs/aios-diagram/`.
- **Memórias atualizadas:** `~/.claude/CLAUDE.md` (P0 perdeu `aios-diagram/` da lista de sub-projetos, ganhou nota "Histórico aios-diagram: consolidado em..."), `project_dap_portal_architecture.md` (frontmatter + corpo refletem 3 sub-projetos), `MEMORY.md` index (one-liner refeito).
- **Plan fixup commit `64c5dc9`** — durante execução, Task 1 achou 4 PNGs untracked (`_debug-*.png`); Step 3.2 do plan foi alargado pra "todos arquivos top-level exceto `.git/`" pra preservá-los. Plan editado in-flight, commit posterior pra registrar.
- **Push verde** — `git push origin feat/aios-nucleo-consultor` levou `d13382f..64c5dc9` (4 commits) pra GitHub `toliveira1802-sketch/doctor-aios`.

## O que NÃO funcionou (e por quê)

- **Haiku subagent rejeitou Task 1 com "Prompt is too long"** — modelo Haiku tem context window menor; somando system prompt + tool descriptions + meu prompt detalhado, estourou. Sonnet aceitou tudo igual. **Aprendizado:** pra subagent-driven com prompts ricos, default em sonnet desde o começo. Haiku só pra prompts muito enxutos (<2k tokens).
- **`npm run check` em dap-aios falha** com `Cannot find module 'C:\THALES\DAP4\dap-aios\node_modules\typescript\bin\tsc'`. **Causa:** symlinks de pnpm quebram quando o dir é movido com `Move-Item` (sessão de 08:52 fez exatamente isso). `node_modules/.pnpm/typescript@5.6.3/` existe mas o symlink em `node_modules/typescript/` não. **NÃO É causado por este merge** (zero arquivos TS tocados — todos os 46 arquivos estão sob `docs/`). **Fix pendente separado:** `cd C:\THALES\DAP4\dap-aios && pnpm install` antes de qualquer trabalho de código novo. Documentar como bug conhecido (já bate com `feedback_native_modules_node24.md`).

## O que ainda não foi tentado

- **Smoke visual da mandala D3** — automação fez HTTP smoke (path resolução), mas Thales não abriu browser pra ver visualmente se mandala renderiza, 16 cards aparecem, parlamento timeline desenha. Risco: D3 pode falhar em runtime sem 404 (ex: erro JS silencioso). Comando pra rodar: `cd C:\THALES\DAP4\dap-aios\docs\aios-diagram && python -m http.server 8080` → `http://localhost:8080`.
- **`pnpm install`** pra restaurar `npm run check`. Issue documentada acima.
- **Final code review subagent** (skill `subagent-driven-development` recomenda) — pulado porque 100% das mudanças são docs/snapshot, sem código a revisar.
- **PR isolado dos 4 commits docs** — branch `feat/aios-nucleo-consultor` carrega Anna shadow + agora archive. Splitar em `docs/aios-diagram-archive` é fácil (cherry-pick atômico) mas decidi deixar junto até saber se algum dos workstreams vai virar PR.
- **Deploy do dap-aios na VPS** — não iniciado. Plano rascunhado abaixo.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `dap-aios/docs/superpowers/specs/2026-05-05-aios-diagram-merge-design.md` | Criado | Spec do merge, commit 2b9ab84 |
| `dap-aios/docs/superpowers/plans/2026-05-05-aios-diagram-merge.md` | Criado + editado | Plan, commits a71e8b1 + 64c5dc9 |
| `dap-aios/docs/aios-diagram/` (42 arquivos) | Criado | Snapshot navegável MVP 1.0 |
| `dap-aios/docs/superpowers/specs/2026-04-24-portal-aios-conselho-dap-design.md` | Movido | Spec original do aios-diagram |
| `dap-aios/docs/superpowers/plans/2026-04-24-portal-aios-conselho-dap.md` | Movido | Plan original do aios-diagram |
| `OneDrive/.../PITOS/Backups/aios-diagram-2026-04-24.bundle` | Criado | 184K, histórico completo |
| `C:\THALES\DAP4\aios-diagram\` | **DELETADO** | Source removido limpo |
| `~/.claude/CLAUDE.md` | Atualizado | P0 sub-projects sem aios-diagram, nota nova |
| `~/.claude/projects/.../memory/project_dap_portal_architecture.md` | Atualizado | Frontmatter + corpo refletem consolidação |
| `~/.claude/projects/.../memory/MEMORY.md` | Atualizado | Index one-liner |

## Decisões tomadas

- **Snapshot estático em vez de port pra React** — option A do brainstorming. aios-diagram é frozen MVP 1.0 (24/04), não codebase ativo. Reescrever em D3+React seria feature de port, fora do escopo de "consolidação".
- **Pure repo docs em vez de runtime serving** — option A da pergunta 2. Ninguém precisa abrir mandala em URL pública agora; quem quiser, sobe `python -m http.server` local. Express do dap-aios não vê esses arquivos.
- **Bundle no PITOS Backups, não subtree no log** — option A da pergunta 3. Log do dap-aios fica limpo (não polui com 30+ commits de site estático); histórico recuperável via `git clone <bundle>` se precisar um dia.
- **Path `dap-aios/docs/aios-diagram/`** — preserva identidade do nome (memória + handoffs todos referenciam esse nome), `docs/` é convenção universal.
- **Source deletado, não freezed** — opção A da pergunta 5. Ponto do merge é consolidação; manter source = continuar com 2 fontes a confundir. Bundle no PITOS é a salvaguarda.
- **PNGs debug preservados no snapshot** — durante Task 1 achei 4 untracked `_debug-*.png` no source. Calou pra incluir tudo top-level (não só HTMLs+MD+gitignore) na cópia. PNGs viraram parte do snapshot 2026-04-24 oficial.
- **Subagent-driven com sonnet padrão** — haiku falhou em Task 1 por context limit. Sonnet usado em 8 tasks restantes sem issue.
- **Deixar 4 commits docs juntos com Anna shadow em `feat/aios-nucleo-consultor`** — splitar pra branch `docs/aios-diagram-archive` é fácil quando precisar; fragmentar agora pra PR hipotético = overhead negativo.
- **Push imediato** — Thales falou "RODA". Branch já tinha sido pushada antes (Anna shadow). 4 commits novos foram pra `origin/feat/aios-nucleo-consultor`.

## Bloqueios & perguntas abertas

1. **Smoke visual da mandala** — automação cobriu HTTP+refs; faltou abrir browser. Vale 5 min em algum momento.
2. **`pnpm install` pendente** em dap-aios — `npm run check` quebrado desde o `Move-Item` da sessão anterior. Bloqueia trabalho de código novo, não bloqueia docs.
3. **PR ou não-PR** — branch carrega Anna shadow + archive; nenhum claramente pronto pra master. Decisão do Thales no momento certo.
4. **Anna shadow ativação** — `feat/aios-nucleo-consultor` ainda preserva Anna shadow não-ativada. Decisão pendente: ativar quando? Como?
5. **Deploy VPS do dap-aios** — não iniciado. Veja seção dedicada abaixo.

## Próximo passo exato

Não tem "próximo passo único". 3 caminhos paralelos possíveis dependendo de prioridade:

### Caminho A — fechar débito técnico do dap-aios

```powershell
cd C:\THALES\DAP4\dap-aios
pnpm install              # restaurar symlinks node_modules
npm run check             # confirmar tsc verde
npm run build             # confirmar build pipeline funcional
```

Esperado: `pnpm install` recria symlinks; `npm run check` passa; `npm run build` produz `dist/public` + `dist/index.cjs`. Se algo quebrar aqui, é diferente do caso "Move-Item lambeu symlinks" — investigar.

### Caminho B — smoke visual do archive

```powershell
cd C:\THALES\DAP4\dap-aios\docs\aios-diagram
python -m http.server 8080
# Abrir http://localhost:8080/ no Chrome — mandala D3 visível?
# Abrir /agentes.html — 16 cards aparecem?
# Abrir /parlamento.html — 6 timelines?
# Abrir /tests/test-runner.html — verde?
# Ctrl+C
```

Se algo visual quebrou que o HTTP smoke não pegou, é hora de saber. Risco baixo (refs todas resolvem) mas D3 pode ter erro de runtime silencioso.

### Caminho C — começar deploy VPS do dap-aios (longo)

Veja seção a seguir.

## Plano de deploy VPS — dap-aios

**STATUS: planejamento, NÃO executado.** Marcado como roadmap pra próxima sessão de deploy.

### Estado atual

- **Repo:** `toliveira1802-sketch/doctor-aios` no GitHub, branch `feat/aios-nucleo-consultor` (HEAD `64c5dc9`)
- **Build artifact:** `dist/public/` (client SPA) + `dist/index.cjs` (server bundle, esbuild CJS)
- **Runtime:** `node dist/index.cjs`, escuta em `PORT` (default 5000), `0.0.0.0`, `reusePort: true`
- **DB:** `data.db` SQLite local (gitignored), recriado via `npm run db:push` (drizzle)
- **Stack VPS hoje:** P1 (`/opt/doctor-auto-ai/`) — diferente projeto, **não compartilha infra automaticamente**

### Pendências bloqueantes pra deploy

1. **Decidir auth strategy.** dap-aios CLAUDE.md proíbe autenticação sem aprovação. Pra produção pública precisa de gate. Opções:
   - Cloudflare Access (zero-trust SSO) — provavelmente o caminho, alinha com tunnel já presente
   - Auth dentro do app (passport/lucia/auth.js + Drizzle) — mais trabalho
   - Basic auth no Cloudflare — temporário, fraco
   - **Recomendado: Cloudflare Access** com email allowlist (Thales + parceiros)

2. **Decidir Node version na VPS.** Memória `feedback_native_modules_node24.md` diz Node 24 quebra better-sqlite3 sem prebuilt + sem VS Build Tools. Pra Linux VPS a história é diferente (Linux costuma ter prebuilds), mas testar antes. **Recomendado: Node 22 LTS** (alinha com tooling testado, evita risk).

3. **Decidir path persistence do SQLite.** Hoje `data.db` é relativo ao cwd. Em produção:
   - Opção A: arquivo em `/opt/dap-aios/data.db` (bare-metal)
   - Opção B: volume Docker persistente
   - Opção C: migrar pra PostgreSQL (Supabase do P1)
   - **Recomendado pra MVP: Opção A**, simples. Migrar pra Supabase só se precisar de multi-instance.

4. **Decidir subdomain.** `aios.doctorautoprime40.com`? `chairman.doctorautoprime40.com`? Configurar via Cloudflare Tunnel (já tem `dap4` tunnel rodando — basta adicionar rota nova).
   - **Recomendado:** `aios.doctorautoprime40.com` (curto, semântico, alinha com nome interno).

5. **Decidir process manager.** PM2 já está na home (`.pm2/`), VPS provavelmente também. Ou systemd service. Ou Docker.
   - **Recomendado: PM2** (alinha com hábito local; `pm2 startup` + `pm2 save` cobre boot).

6. **R4 RBAC ativação.** Memory `project_dap_aios_r4_rbac.md` diz RBAC scaffolding está em `feat/aios-nucleo-consultor`. Precisa ser ativado em produção (não shadow). Decisão: ativar antes do deploy ou depois?

### Sequência sugerida (quando rodar)

```bash
# === PRÉ-DEPLOY (local) ===
cd C:\THALES\DAP4\dap-aios
pnpm install                           # 1. fix symlinks (caminho A acima)
npm run check                          # 2. confirma tsc verde
npm run build                          # 3. produz dist/

# Smoke local do build
NODE_ENV=production PORT=5001 node dist/index.cjs &
curl localhost:5001                    # SPA serve OK?
curl localhost:5001/api/health         # se houver endpoint de health

# === VPS PREP (SSH) ===
ssh root@76.13.170.42

# Confirmar Node version
node --version                         # esperado: v22.x.x (instalar via nvm se 24)

# Criar diretório dedicado
mkdir -p /opt/dap-aios
cd /opt/dap-aios

# Clone do GitHub (decidir branch — feat/aios-nucleo-consultor ou master?)
git clone https://github.com/toliveira1802-sketch/doctor-aios.git .
git checkout feat/aios-nucleo-consultor  # ou master, dependendo da decisão

# Install + build
npm install -g pnpm                    # se não tiver
pnpm install
npm run build
npm run db:push                        # criar data.db inicial

# === SERVICE ===
npm install -g pm2

# Criar ecosystem config
cat > /opt/dap-aios/ecosystem.config.cjs <<'EOF'
module.exports = {
  apps: [{
    name: 'dap-aios',
    script: 'dist/index.cjs',
    cwd: '/opt/dap-aios',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    }
  }]
};
EOF

pm2 start ecosystem.config.cjs
pm2 save
pm2 startup                            # systemd integration

# === CLOUDFLARE TUNNEL ===
# Editar /etc/cloudflared/config.yml na VPS, adicionar rota:
#   - hostname: aios.doctorautoprime40.com
#     service: http://localhost:5000
# Restart: systemctl restart cloudflared

# === CLOUDFLARE ACCESS ===
# No dashboard CF: Access → Applications → Add Application
# Hostname: aios.doctorautoprime40.com
# Policy: Email allowlist [toliveira1802@gmail.com, ...]

# === SMOKE PROD ===
curl -L https://aios.doctorautoprime40.com    # CF Access challenge esperado
# Login com email allowlisted → SPA carrega
```

### Entregáveis quando deploy rodar

- [ ] `aios.doctorautoprime40.com` resolvendo, gated por CF Access
- [ ] `/api/health` (se criado) retornando 200
- [ ] PM2 logs limpos (`pm2 logs dap-aios`)
- [ ] `data.db` criado em `/opt/dap-aios/`, sobrevive a restart do PM2
- [ ] SSH `root@76.13.170.42` mostra `pm2 status` com `dap-aios online`
- [ ] Memory `project_dap_aios.md` atualizada com URL prod + paths VPS
- [ ] Memory nova `project_dap_aios_vps_deploy.md` documentando o caminho seguido

### Decisões pendentes (Thales bate o martelo quando começar)

1. Branch a deployar: `feat/aios-nucleo-consultor` (atual) ou criar `production` em master separado?
2. Anna shadow: ativar pré-deploy ou ficar dormente em prod?
3. R4 RBAC: ativar no deploy ou depois?
4. Auth: CF Access (recomendado) ou outra?
5. DB: SQLite bare-metal MVP ou Postgres direto?

## Setup / comandos úteis

```powershell
# Estado da branch
cd C:\THALES\DAP4\dap-aios
git log --oneline origin/master..HEAD       # ver os 4+ commits ahead

# Bundle restore (se um dia precisar)
git clone "C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Backups\aios-diagram-2026-04-24.bundle" C:\tmp\aios-diagram-restored
cd C:\tmp\aios-diagram-restored
git log --oneline

# Smoke do archive
cd C:\THALES\DAP4\dap-aios\docs\aios-diagram
python -m http.server 8080
# http://localhost:8080/

# Quando voltar a tocar dap-aios (qualquer trabalho)
cd C:\THALES\DAP4\dap-aios
pnpm install                                 # restore symlinks pós Move-Item
npm run check                                # confirmar tsc verde
npm run build                                # confirmar pipeline OK
```

## Estado do remote (confirmado pós-push)

- `toliveira1802-sketch/doctor-aios` — `feat/aios-nucleo-consultor` em `64c5dc9`. Lista de commits ahead de master (mínimo 7):
  - `64c5dc9 docs(plan): widen Step 3.2 copy filter`
  - `25b259e docs(diagrams): import aios-diagram MVP 1.0`
  - `a71e8b1 docs(plan): add aios-diagram merge plan`
  - `2b9ab84 docs(spec): add aios-diagram merge design`
  - `d13382f docs(handoff): rodada 5 + anna canal master + sombra spec + dap4 auditoria + meta waba + mapa`
  - `ebdec48 chore(anna): build + env wiring for shadow spec`
  - `56d664d feat(anna): shadow spec — director page + chat lib + agent backend`
- `aios-diagram` repo — **deletado**, não existe mais. Histórico vive só no bundle do PITOS.
- VPS `76.13.170.42` — **não** afetada. P1 (`/opt/doctor-auto-ai/`) intocado. dap-aios nunca chegou na VPS.
