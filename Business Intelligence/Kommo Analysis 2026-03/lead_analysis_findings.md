# Lead Analysis Findings

## Data Structure (122 rows, 12 columns)
- Col 0: Row number (1-122)
- Col 1: Score (72-99)
- Col 2: Temperature (🔥 QUENTE: 67, 🟡 MORNO: 55)
- Col 3: Name
- Col 4: Phone
- Col 5: Stage/Status
- Col 6: Vehicle (86.9% missing = 106 leads)
- Col 7: Always "-" (empty)
- Col 8: Date (DD/MM/YYYY)
- Col 9: Days since last contact (0-89)
- Col 10: Source (always "Atualização sistema")
- Col 11: Tags/Notes (truncated, contains vehicle info, status tags, etc.)

## Status Distribution
- potencial cliente: 58 (47.5%) - NEEDS RECLASSIFICATION
- entregue: 22 (18%) - CLOSED/DELIVERED
- Tentando AGENDAr: 12 (9.8%) - TRYING TO SCHEDULE
- AGENDAMENTO CONFIRMADO: 8 (6.6%) - SCHEDULED
- recuperados: 8 (6.6%) - RECOVERED
- em loja: 7 (5.7%) - IN SHOP
- primeiro atendimento: 4 (3.3%) - FIRST CONTACT
- Venda ganha: 2 (1.6%) - WON SALE
- follow up: 1 (0.8%) - FOLLOW UP

## Key Tags Found in Notes (Col 11)
### Vehicle Info Hidden in Tags:
- A35, Audi A3, BMW X1, JETTA 1.4, ONIX, TIGUAN RLINE, V4 | Nivus, VIRTUS, bmw 320i, c180, golf, mini cooper

### Status Tags:
- PV_NPS_ENVIADO = Pós-venda NPS enviado (CLOSED)
- PV_D10_OK = Pós-venda dia 10 OK (CLOSED)
- PV_PROMOTOR = Pós-venda promotor (CLOSED, happy customer)
- orçamento = Got a quote
- tentando agendar = Trying to schedule
- agendamento = Scheduled
- 1atend = First contact done
- potencial cliente = Potential client
- dezembro = From December campaign
- MOTOR = Engine service
- revisao = Revision service
- troca de oleo = Oil change
- freio eletrônico da sorento = Electronic brake Sorento

### People Tags:
- JOAO, PEDRO, pedro = Assigned to staff member

## Duplicates (6 phones appear twice)
- Same person with multiple entries (likely different service visits)

## What Needs to Be Done
1. Extract vehicle from tags when Col 6 is empty
2. Reclassify: "entregue" + "PV_NPS_ENVIADO" = FECHOU SERVIÇO
3. Reclassify: "Venda ganha" = FECHOU SERVIÇO
4. "potencial cliente" with "orçamento" = GOT QUOTE, DIDN'T CLOSE YET
5. "potencial cliente" with only "1atend, dezembro" = COLD, DIDN'T ENGAGE
6. Consolidate duplicates
