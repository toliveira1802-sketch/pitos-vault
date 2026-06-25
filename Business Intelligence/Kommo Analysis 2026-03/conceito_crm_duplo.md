# Conceito: Arquitetura CRM Duplo + Bote IA

## O Problema
Hoje o Kommo CRM mistura tudo: leads quentes que vão fechar serviço com leads frios que disseram "não agora". Quando o lead não fecha, ele fica poluindo o funil de vendas ativo. Mas esse lead NÃO está morto — ele tem carro, o carro vai precisar de manutenção, e ele já conhece a Doctor Auto.

## A Solução: Dois CRMs com uma IA Ponte

### CRM INTERNO (Operação)
- Onde: Supabase (tabelas próprias) ou Kommo com funil dedicado
- Quem mora aqui: Leads QUENTES — agendaram, estão em negociação, carro na oficina, pós-venda recente
- Quem opera: Ana (agente principal) + equipe da oficina
- Dados: OS, agendamentos, orçamentos, histórico de serviço, veículos
- Ciclo: Lead entra → Ana atende → Agenda → Serviço → Pós-venda → Sai do funil ativo

### CRM EXTERNO (Lago de Leads)
- Onde: Supabase (tabela separada) ou segundo pipeline no Kommo
- Quem mora aqui: Leads que NÃO fecharam + clientes antigos + leads de campanhas + indicações
- Volume: Muito maior que o interno (centenas/milhares de contatos)
- Dados: Nome, telefone, veículo, último contato, motivo de não fechar, interesse demonstrado, score
- Ciclo: Lead não fecha → vai pro lago → fica sendo nutrido → quando esquenta, volta pro interno

### O BOTE (IA Intermediária)
- Nome sugerido: "Pescadora" ou pode ser uma função da própria Ana
- Função: Pescar leads do lago externo e trazer pro CRM interno quando estiverem prontos
- Como funciona:
  1. Roda como cron (ex: toda segunda e quinta às 9h)
  2. Analisa o lago externo: quem tem carro com revisão vencendo? Quem demonstrou interesse em X?
  3. Cruza com campanhas ativas (ex: "Semana do Ar Condicionado")
  4. Gera mensagem personalizada via IA
  5. Se o lead responder positivamente → MOVE pro CRM interno e Ana assume
  6. Se não responder → atualiza score e tenta de novo no próximo ciclo

### Fluxo Bidirecional
- INTERNO → EXTERNO: Lead não fechou após X dias → Ana move pro lago com tag "motivo: preço" ou "motivo: não agora"
- EXTERNO → INTERNO: Bote identifica oportunidade → cria lead no CRM interno → Ana recebe e atende
- IA fala com IA: O Bote pode chamar a Ana via API interna passando contexto ("Este lead já veio 2x, gosta de BMW, última objeção foi preço")

## Tipos de "Ataque" no Lago Externo
1. Revisão preventiva (baseado no veículo e última visita)
2. Campanhas sazonais (ar condicionado no verão, pneus na chuva)
3. Reativação por tempo (não fala há 30/60/90 dias)
4. Upsell de serviço (fez troca de óleo, oferecer alinhamento)
5. Indicação premiada (cliente antigo indica amigo)
6. Conteúdo educativo (dica de manutenção → esquenta o lead)
