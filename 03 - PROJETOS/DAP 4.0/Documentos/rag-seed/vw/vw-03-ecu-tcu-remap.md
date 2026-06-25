---
title: VW — ECU/TCU Remap
date: 2026-04-14
brand: vw
topic: remap
tags: [dap4, rag-seed, vw, remap, golf-gti, golf-r, amarok, jetta-gli]
---

# Volkswagen — Remap ECU/TCU

A plataforma VW é referência mundial em tune. Mapas maduros, hardware turbo com folga, ECU acessível via OBD na maioria. Stage 1 em Golf GTI é praticamente "free lunch" quando bem feito.

## EA211 1.0 TSI (Polo, T-Cross, Nivus, Virtus 200 TSI)

- **Stage 1:** 116/128 → ~145 cv / 200 → ~240 Nm.
- **Turbo pequeno, não vai além.**

## EA211 1.4 TSI (Jetta TSI, Tiguan TSI antigo, Polo/Virtus GTS)

- **Stage 1:** 150 → ~185 cv / 250 → ~300 Nm.
- **Stage 1+:** ~200 cv com intake.

## EA888 Gen 3 2.0 TSI (Golf GTI Mk7/Mk7.5, Jetta GLI, Tiguan 350, Passat)

- **Stage 1:** 220/230 → ~285 cv / 350 → ~420 Nm.
- **Stage 2:** ~310 cv (downpipe, intake, intercooler).
- **Stage 3 (IS38 upgrade):** 380+ cv.

## EA888 Gen 3B 2.0 TSI evo4 (Golf R Mk7.5, Golf R Mk8)

- **Stage 1:** 310/320 → ~390 cv / 400 → ~520 Nm.
- **Stage 2:** ~420 cv (downpipe, FMIC).
- **Stage 3 (IS38+ / IS45):** 500+ cv.
- **Plataforma mais consagrada — idêntica ao S3 da Audi.**

## EA888 Gen 4 2.0 TSI (Tiguan R, Golf GTI Mk8, Arteon R)

- **Stage 1:** 245–320 → ~360/430 cv conforme variante.
- **Mapa ainda maturando, mas plataforma sólida.**

## V6 3.0 TDI (Amarok / Touareg)

- **Stage 1:** 224/258 → ~290 cv / 580 → ~720 Nm.
- **Ganho sentido em reboque, trilha, ultrapassagem.**
- **Cuidado:** DPF/Arla precisam estar 100% — mapa Stage 1 não mexe em emissões.

## TCU — DSG / S-Tronic (compartilhado Audi)

- **DQ200 (1.0/1.4 TSI seca):** tolerância limitada, cuidado com tune.
- **DQ250 (6 vel úmida GTI velho):** 600+ Nm com tune + embreagem OEM.
- **DQ381 (GTI Mk7.5/Mk8):** 500+ Nm tranquilo.
- **DQ500 (Golf R, Amarok V6):** 700+ Nm sem upgrade.

## Riscos

- Remap em carro flex com etanol de procedência ruim = knock. Usamos mapa dual (gasolina/etanol) quando possível.
- Carro com DSG nunca trocado fluido = troca antes.
- HPFP velha + Stage 2 = pane em autonomia em alta carga.
- Garantia VW perdida no trem de força, reversível.

## Flex BR — nuance

- Carros VW Brasil são flex, ECU reconhece mistura. Mapa DAP respeita safety margin de etanol ruim.
- E85 puro abre ganho maior, mas pede validação de injetor e HPFP.

## Validação

Dinamômetro, logs completos (boost, AFR, timing, knock), relatório e follow-up 1.000 km depois.
