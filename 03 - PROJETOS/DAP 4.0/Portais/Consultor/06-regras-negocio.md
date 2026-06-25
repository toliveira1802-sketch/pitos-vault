---
parent: "[[03 - PROJETOS/DAP 4.0 1/dap-operacao/README]]"
tags:
  - dap40
  - regras-negocio
  - produto
---

# Regras de negócio — DAP Operação

> Documento vivo. Define o comportamento esperado de cada página e endpoint, quem pode fazer o quê, e que invariantes o sistema deve manter. Quando a regra não estiver expressa em código ainda, está marcada com `🟡 a-implementar`.

## Glossário rápido

| Termo                  | Significado                                                                  |
| ---------------------- | ---------------------------------------------------------------------------- |
| **OS**                 | Ordem de Serviço (`service_orders`)                                          |
| **Consultor**          | Role `admin` no sistema — atende cliente, abre/fecha OS, controla financeiro |
| **Técnico**            | Role `tecnico` — executa serviço, alimenta diagnóstico, fotos, checklist     |
| **Recepção**           | Role `recepcao` — atende cliente na chegada, faz checklist de entrada        |
| **Tier do cliente**    | Bronze → Prata → Ouro → Platina (segmentação de relacionamento)              |
| **Status da OS**       | 1 dos 8 estados do fluxo (ver [[02-schema#Status flow]])                    |
| **Sinal**              | Pagamento adiantado (`advance_payment`)                                      |

## Regras transversais (valem em toda página)

### R-T1 — Multi-tenant rigoroso
Toda leitura/escrita filtra por `req.session.organizationId`. Recurso de outro tenant retorna **404**, nunca 403 — não vazar a existência.

### R-T2 — Imutabilidade do histórico
Comments, telemetry e attachments **nunca** podem ser editados após criação. Pode ser deletado pelo dono ou admin, mas a edição em si não existe.

### R-T3 — Cents pra dinheiro
Todo valor monetário em DB e API trafega como `integer cents`. UI usa `formatCentsBRL()` pra exibir e `parseBrlInput()` pra ler. Nunca `float`.

### R-T4 — Auditabilidade
Toda mudança de status de OS gera linha em `telemetry` com `changedBy = userId`. Toda mudança de campo crítico (custos, diagnóstico) deve gerar comment com `category = system`. 🟡 a-implementar

### R-T5 — Fail closed em produção
Sem `BOOTSTRAP_ADMIN_PASSWORD`, app não sobe. Sem `SESSION_SECRET`, app não sobe. Sem `trust proxy`, cookies caem.

---

## Login (`/login`)

### Acesso
- Rota pública (a única).
- Disponível antes de autenticar.

### Regras
- **R-LOGIN-1**: Tentativa de login obedece rate limit de **5/min/IP**, contando apenas falhas (login bem-sucedido não consome quota).
- **R-LOGIN-2**: Mensagem de erro é **genérica** ("Credenciais inválidas") tanto pra usuário inexistente quanto pra senha errada — não vazar enumeração de users.
- **R-LOGIN-3**: Sucesso retorna user sem campo `password` e seta cookie `connect.sid` (HttpOnly, Secure em prod, SameSite=Lax, 24h).
- **R-LOGIN-4**: `organizationSlug` default = `"dap-prime"`. Quando houver mais de 1 org operando, login passa a exigir slug explícito. 🟡 a-implementar

---

## Dashboard (`/`)

### Acesso
- Todos os roles (admin, tecnico, recepcao).
- Tela de pouso após login.

### Regras
- **R-DASH-1**: KPIs visíveis dependem do role:
  - **admin** vê faturamento, ticket médio, margem, conversão de orçamento, tempo médio de permanência
  - **tecnico** vê OS abertas atribuídas a ele, status, próximas tarefas
  - **recepcao** vê agendamentos do dia, OS aguardando entrada, OS prontas pra entrega
- **R-DASH-2**: Métricas financeiras **nunca** aparecem pra `tecnico` ou `recepcao`. Mesmo agregadas. 🟡 enforcement no client + check server-side
- **R-DASH-3**: Período padrão = "este mês". Toggle pra "hoje | semana | mês | ano". Período fica na URL pra compartilhamento.
- **R-DASH-4**: Dados de "ontem/última semana" usam comparativos sazonais (mesmo dia da semana, não literal D-1).

### Próximos passos
- Conectar com `/api/stats` real (hoje devolve 200 mas não foi auditada a corretude do agregado)
- Cards comparativos com seta ↑↓ e variação percentual

---

## Linha do Tempo (`/timeline`)

### Acesso
- Todos os roles.

### Regras
- **R-TL-1**: Mostra **apenas** OS com status ≠ `entregue` E ≠ `cancelado`. OS finalizadas saem da timeline.
- **R-TL-2**: Barra realizada = de `createdAt` até agora, na cor do status atual. Barra prevista = continuação tracejada até "entregue", baseada em duração-padrão por etapa.
- **R-TL-3**: Duração-padrão por etapa (heurística v1):
  - Diagnóstico: 8 h
  - Aguardando aprovação: 12 h
  - Aprovado: 4 h
  - Em execução: 24 h
  - Aguardando peça: 48 h
  - Pronto: 4 h
- **R-TL-4**: Janela de visualização = ±3 / ±7 / ±14 dias relativos a "agora". Default = ±7d.
- **R-TL-5**: Hover na barra mostra início + previsão + status atual.
- **R-TL-6**: Empty state honesto se não houver OS ativa — não inventa dados.

### Próximos passos (v2)
- Ler `telemetry` por OS pra **segmentar** a barra realizada por etapa real (cores intercaladas, mostrando onde demorou)
- Calibrar duração prevista com a média histórica da própria oficina (substituir heurística)
- Endpoint agregado `GET /api/telemetry` (sem `:id`) pra evitar N+1
- Marcar gargalos (OS travada > X horas no mesmo status) com indicador vermelho

---

## Clientes (`/customers`)

### Acesso
- Todos os roles.

### Regras de criação
- **R-CLI-1**: Cliente exige minimamente `name` e `phone`. CPF, email, notes são opcionais.
- **R-CLI-2**: Phone é a chave de busca primária — toda criação verifica duplicata por phone. **Match exato bloqueia criação** com mensagem "Cliente já cadastrado: {nome}". 🟡 a-implementar (hoje permite duplicata)
- **R-CLI-3**: CPF, quando preenchido, deve passar validação de dígito + indexed pra busca rápida.
- **R-CLI-4**: Tier default = `bronze`. **Mudança de tier exige role `admin`**. 🟡 enforcement no server
- **R-CLI-5**: Wizard `customer-workflow-wizard` cria cliente + veículo + OS num fluxo só, mas cada step pode pular o resto.

### Regras de tier (segmentação comercial)
**Promoção automática** (computada via job, não manual): 🟡 a-implementar
- **Bronze**: padrão, < R$ 5k em OS pagas
- **Prata**: ≥ R$ 5k em OS pagas no último ano
- **Ouro**: ≥ R$ 20k em OS pagas no último ano OU ≥ 3 veículos cadastrados
- **Platina**: ≥ R$ 50k em OS pagas no último ano OU veículo > R$ 500k de mercado (BMW M, Audi RS, etc)

**Demoção** acontece após 18 meses sem OS paga (volta 1 tier).

**Override manual** sempre permitido por admin (registra log).

### Regras de exclusão
- **R-CLI-6**: Cliente com OS ativa **não pode ser deletado** — botão sai desabilitado, server retorna 409 Conflict. 🟡 a-implementar (hoje cascata via FK pode falhar com `restrict` em service_orders.customer_id)
- **R-CLI-7**: Cliente sem OS pode ser deletado por admin. Veículos cascateiam (cliente:N veículos, FK cascade).

---

## Veículos (`/customers/:id` drawer ou contexto)

### Regras
- **R-VEI-1**: Veículo sempre pertence a 1 cliente. Não existe veículo "solto".
- **R-VEI-2**: Placa exige formato Mercosul (`AAA1A23`) ou antigo (`AAA1234`). 🟡 validação a implementar
- **R-VEI-3**: KM é cumulativo — toda OS aprovada que envolve serviço deve atualizar `vehicle.km` (preenchido no checklist de saída). 🟡 a-implementar
- **R-VEI-4**: VIN, quando preenchido, deve ter 17 caracteres. 🟡 validação a implementar
- **R-VEI-5**: Marca é livre, mas com auto-complete enviesado pra alemães (BMW, Audi, Mercedes, VW, Porsche) — diferencial DAP Prime.

---

## Ordens de Serviço (`/orders`, `/orders/:id`)

### Acesso
- Todos os roles veem. Mas ações mudam por role:
  - **admin**: tudo (criar, editar, mudar status, deletar, aprovar item, lançar custo final, gerar PDF)
  - **tecnico**: ver tudo, mudar status (apenas em direção do fluxo, não retroceder), preencher diagnóstico, adicionar itens, anexar foto/vídeo, comentar
  - **recepcao**: ver, criar OS, fazer checklist, entregar (mover pra `entregue`), comentar

### Regras de criação
- **R-OS-1**: OS exige `customerId`, `vehicleId`, `description`. Status default = `diagnostico`.
- **R-OS-2**: `consultantId` = `req.session.userId` automaticamente quando criada por admin. 🟡 a-implementar (hoje não preenche)
- **R-OS-3**: ID exibido como `OS-00042` (5 dígitos zero-pad). Helper `formatOsNumber()`.
- **R-OS-4**: Numeração é sequencial **por organização**. 🟡 enforcement futuro

### Regras de transição de status

```
diagnostico → aguardando_aprovacao → aprovado → em_execucao → pronto → entregue
                                                      ↓
                                                aguardando_peca (loop)
                                              
[qualquer estado não-terminal] → cancelado
```

- **R-OS-5**: Transições permitidas (do → para):
  - `diagnostico` → `aguardando_aprovacao` (após salvar diagnóstico + items)
  - `aguardando_aprovacao` → `aprovado` ou `cancelado`
  - `aprovado` → `em_execucao`
  - `em_execucao` → `aguardando_peca` ou `pronto`
  - `aguardando_peca` → `em_execucao` (peça chegou) ou `cancelado`
  - `pronto` → `entregue` (recepção confirma entrega + pagamento)
  - **qualquer estado não-terminal** → `cancelado`
- **R-OS-6**: Tentativa de transição inválida retorna **409 Conflict** com mensagem do tipo "Não é possível mover de X pra Y". 🟡 enforcement no server
- **R-OS-7**: Toda mudança de status cria linha em `telemetry` com `changedBy`, `previousStatus`, `newStatus`, `createdAt`.
- **R-OS-8**: Mudança pra `entregue` exige:
  - Pelo menos 1 pagamento com `status = "pago"` cobrindo `final_cost` (ou marcação explícita de "entrega sem pagamento" pra cliente Platina). 🟡 a-implementar
  - Checklist preenchido (KM de saída, observações). 🟡 a-implementar
- **R-OS-9**: Mudança pra `cancelado` requer comentário explicativo (textarea obrigatória). 🟡 a-implementar
- **R-OS-10**: Apenas `admin` pode cancelar OS após `aprovado`. Antes, qualquer role pode.

### Regras financeiras da OS
- **R-OS-11**: `estimated_cost` = soma dos `unit_price * quantity` dos `service_items` com `status != "recusado"`. Recalculado em cada mudança de item. 🟡 a-implementar
- **R-OS-12**: `final_cost` é fixado quando OS vai pra `entregue`. Após isso, **não pode ser editado**. 🟡 a-implementar
- **R-OS-13**: Margem visível só pra admin = `final_cost - sum(items.cost * quantity)`.
- **R-OS-14**: Sinal (`advance_payment`) pode ser cobrado em qualquer momento ≥ `aguardando_aprovacao`. Vai pra `payments` automaticamente. 🟡 a-implementar

### Regras de items
- **R-ITM-1**: Item tem `type` (servico | peca | mao_de_obra) — define como aparece no PDF da OS.
- **R-ITM-2**: `complexity` (baixo | medio | alto) influencia tempo previsto + repasse pro técnico (tabela interna). 🟡 lógica a-definir
- **R-ITM-3**: Status do item:
  - `pendente`: criado, aguardando aprovação do cliente
  - `aprovado`: cliente OK
  - `recusado`: cliente recusou (item permanece registrado pra histórico, fica fora do `estimated_cost`)
- **R-ITM-4**: Aprovação/recusa de item move OS de `aguardando_aprovacao` → `aprovado` quando todos itens estão decididos E pelo menos 1 está aprovado. 🟡 a-implementar

### Regras de comentários
- **R-CMT-1**: Comment pode ser livre ou categorizado (`observacao` | `status_change` | `system`).
- **R-CMT-2**: `status_change` é gerado automaticamente em qualquer mudança de status. Texto auto: "{user.name} mudou de {prev} para {new}".
- **R-CMT-3**: `system` é gerado automaticamente em eventos críticos (criação, deleção de item, upload de foto). 🟡 a-implementar

### Regras de attachments
- **R-ATT-1**: Tipos aceitos: `image/jpeg|png|webp` + `video/mp4|webm`. Limite 15 MB por arquivo.
- **R-ATT-2**: Filename randomizado no disco (ataque de path traversal protegido).
- **R-ATT-3**: Servido via `/uploads/<filename>` — mesma origem, dentro do CSP.
- **R-ATT-4**: Atachments aparecem em ordem cronológica de upload, com nome do uploader e tag de OS-status no momento do upload. 🟡 a-implementar

---

## Pátio Kanban (`/patio`)

### Acesso
- Todos os roles.

### Regras
- **R-PT-1**: Mostra 5 colunas: `diagnostico`, `em_execucao`, `aguardando_peca`, `pronto`, `entregue`. Outros estados (`aguardando_aprovacao`, `aprovado`, `cancelado`) **não aparecem**.
- **R-PT-2**: Mudança de coluna = PATCH `/api/service-orders/:id/status`. Sujeita às mesmas regras de transição (R-OS-5).
- **R-PT-3**: Card mostra: nº OS, plate, brand+model, customer.name, custo final ou estimado.
- **R-PT-4**: Tempo no status atual visível em horas/dias (do último `telemetry.created_at`). Cor amarela > 24h, vermelha > 48h. 🟡 a-implementar
- **R-PT-5**: Filtro por consultor/técnico no topo (multi-select). 🟡 a-implementar

---

## Agenda (`/agenda`)

### Acesso
- Todos os roles.

### Regras
- **R-AG-1**: Slot = 1 hora. Janela de operação 8h–18h, segunda a sábado. Domingo bloqueado por default.
- **R-AG-2**: Capacidade = 9 elevadores em paralelo. Conflito quando 9 OS coincidem no slot. 🟡 a-implementar
- **R-AG-3**: Agendamento pode ter ou não `vehicle_id` (cliente pode agendar antes de cadastrar carro).
- **R-AG-4**: Status do appointment: `agendado | confirmado | atendido | nao_compareceu | cancelado`. 🟡 expandir além de "agendado" default
- **R-AG-5**: 24h antes do horário, dispara WhatsApp de confirmação automaticamente. 🟡 a-implementar (depende de WhatsApp Cloud API)
- **R-AG-6**: Quando o cliente chega, recepção transforma `appointment` em `service_order` com 1 click. Appointment fica vinculada à OS criada. 🟡 a-implementar

---

## Financeiro (`/financeiro`)

### Acesso
- **Apenas `admin`**. Outras roles veem 403.

### Regras
- **R-FIN-1**: Mostra agregados do período selecionado (default = mês corrente):
  - Faturamento bruto (sum `final_cost` das OS `entregue` no período)
  - Recebido (sum `payments.amount` com `status = pago`)
  - A receber (faturado - recebido)
  - Margem bruta (faturado - sum `service_items.cost * quantity`)
- **R-FIN-2**: Desconto não é uma entidade — é a diferença entre `estimated_cost` e `final_cost` quando final < estimated. Aparece como linha "Descontos concedidos" no relatório. 🟡 a-implementar
- **R-FIN-3**: Métodos de pagamento aceitos (livre, mas tabela canônica): `pix | dinheiro | cartao_credito | cartao_debito | transferencia | boleto`. 🟡 padronizar enum
- **R-FIN-4**: Pagamento parcial é permitido — múltiplas linhas em `payments` pra mesma OS. Soma dita o status (totalmente pago | parcial | aguardando).
- **R-FIN-5**: Ticket médio = faturamento / nº OS entregues no período.
- **R-FIN-6**: Tempo médio de permanência = média de (`updatedAt(entregue)` - `createdAt`) das OS do período. KPI crítico (gargalo identificado no CLAUDE.md).

---

## Comercial · AI (`/comercial/*`)

> Hoje: **WIP editorial honesto**. Páginas declaram o escopo sem inventar dados. Regras abaixo são pra v1.

### Acesso
- `/comercial/crm`: admin
- `/comercial/leads`: admin, recepcao
- `/comercial/adormecidos`: admin, recepcao

### Regras Avaliação CRM (v1)
- **R-CRM-1**: Score 0–100 calculado por consultor em janela de 30 dias.
- **R-CRM-2**: Componentes do score (peso entre parênteses):
  - Completude de cadastro (0,15): % de clientes do consultor com phone+email+CPF preenchidos
  - Tempo até 1º contato (0,20): mediana de horas entre lead criado e primeiro contato (alvo < 2h)
  - Follow-up em dia (0,20): % de leads sem contato há > 7 dias
  - Conversão orçamento → OS (0,30): % de orçamentos que viraram OS aprovada
  - NPS pós-entrega (0,15): nota média do cliente
- **R-CRM-3**: 3 ações sugeridas pela IA (gerados via prompt c/ contexto do consultor) — aparecem no topo. 🟡 depende de LLM key

### Regras Leads pra Ligar (v1)
- **R-LD-1**: Top 20 leads ranqueados todo dia às 7h. Job recalcula.
- **R-LD-2**: Score = `recencia × valor_potencial × encaixe_marca`.
- **R-LD-3**: Janela ideal de contato derivada do histórico do lead (se respondeu antes em horário X, sugerir X).
- **R-LD-4**: Botão "ligar" abre `tel:` no celular E loga `lead.last_contacted_at`.
- **R-LD-5**: Após call, escolher outcome: `agendado | sem_resposta | perdido | fechado`. Cada um tem fluxo:
  - `agendado`: cria appointment, sai da fila
  - `sem_resposta`: re-rankeia menos, fila mostra de novo em D+2
  - `perdido`: marca lead.lost, comment obrigatório
  - `fechado`: cria OS, sai da fila

### Regras Clientes Adormecidos (v1)
- **R-AD-1**: Adormecido = sem OS há > 180 dias (configurável por unidade). Default 180 pra Prime, 365 pra Performance.
- **R-AD-2**: Segmentação:
  - Top 10% por ticket histórico → mensagem premium personalizada
  - Próximos 30% → mensagem geral c/ promoção
  - Restante 60% → newsletter mensal (não personalizada)
- **R-AD-3**: Estimativa de receita potencial = `ticket_medio_historico * prob_reativacao` (prob_reativacao começa em 0,2 e aprende com outcomes).
- **R-AD-4**: Próximo serviço esperado vem de heurística por veículo (revisão a cada X km, troca de óleo a cada Y meses).
- **R-AD-5**: Disparo em lote via WhatsApp **não é automático** — admin revisa lista e aprova batch. Mensagem é gerada por IA por cliente, mas vai pra fila de aprovação manual antes de enviar. Antifragilidade > velocidade.
- **R-AD-6**: Tracking: aberto | respondido | agendado | fechado. Cliente que responde sai da fila.

---

## Users (`/users`)

### Acesso
- **Apenas `admin`**.

### Regras
- **R-USR-1**: Senha mínima: 12 caracteres. 🟡 enforcement
- **R-USR-2**: Senha hash bcrypt 10 rounds.
- **R-USR-3**: Username único por organização (constraint DB).
- **R-USR-4**: Admin não pode deletar a si mesmo (proteção contra lock-out).
- **R-USR-5**: Toda criação/deleção de user gera audit log. 🟡 a-implementar
- **R-USR-6**: Quando user é deletado, OSs que ele é `consultantId` ou `technicianId` ficam com FK = NULL (não deleta a OS).
- **R-USR-7**: Reset de senha: admin gera token de uso único, válido por 1h, enviado por WhatsApp. 🟡 a-implementar

---

## Mecânicos (gestão dentro de Users ou page própria)

### Regras
- **R-MEC-1**: Mecânico pode estar `active = 0` (afastado/desligado) — não aparece em dropdowns mas histórico preserva.
- **R-MEC-2**: Atribuição de OS a mecânico inativo bloqueada. 🟡 a-implementar
- **R-MEC-3**: Especialidade é livre, mas pode ter tabela canônica: `motor | suspensao | freios | eletrica | ecu | cambio | ar_condicionado | estetica | funilaria`. 🟡 a-padronizar

---

## Invariantes do sistema (testes que devem rodar SEMPRE)

1. Toda OS `entregue` tem `final_cost > 0`.
2. Toda OS `entregue` tem pelo menos 1 pagamento com `status = pago` somando ≥ `final_cost` (exceção: cliente Platina marcado).
3. Toda mudança de status em `service_orders.status` tem linha correspondente em `telemetry`.
4. Nenhum `service_items.unit_price` ou `service_orders.estimated_cost / final_cost / advance_payment` é negativo.
5. Nenhum `customer.phone` em branco.
6. Multi-tenant: queries de tenant A nunca retornam dados de tenant B.
7. Sessão expira em 24h (server side).

🟡 = essas invariantes precisam de **suite de testes property-based** rodando no CI. Hoje temos 18 testes vitest mas não cobrem todos.
