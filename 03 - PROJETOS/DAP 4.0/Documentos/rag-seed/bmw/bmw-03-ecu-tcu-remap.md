---
title: BMW — ECU/TCU Remap (Stage 1/2/3)
date: 2026-04-14
brand: bmw
topic: remap
tags: [dap4, rag-seed, bmw, remap, stage1, stage2, n55, b58, s55]
---

# BMW — Remap ECU/TCU

Potencial realista por plataforma. Foco em segurança mecânica e repetibilidade em dinamômetro. Não prometemos número que o motor não entrega.

## N20 (2.0T — 320i, 125i, X1 28i)

- **Stage 1:** 184 → ~235–250 cv / 290 → ~380 Nm. ECU only.
- **Stage 2:** ~260 cv com downpipe + intake. Corrente distribuição precisa estar ok.
- **Risco:** N20 é sensível em corrente e bomba d'água. Stage só em motor saudável.

## N55 (3.0T single turbo — 335i F30, 135i, M235i)

- **Stage 1:** 306 → ~360–380 cv / 400 → ~500 Nm.
- **Stage 2:** ~420 cv com downpipe + intercooler.
- **Stage 2+ (meth/e85):** ~480 cv.
- **Limite:** turbo de fábrica topa ~25–26 psi, teto físico.

## B58 (3.0T — M240i, 340i, 440i, X3 M40i, Toyota Supra)

- **Stage 1:** 340 → ~420–440 cv / 500 → ~620 Nm.
- **Stage 2:** ~500 cv com downpipe + FMIC + entrada.
- **Stage 3 (turbo upgrade):** 600+ cv.
- **Motor mais forte do portfólio BMW atual.** Block closed-deck, pistões e bielas toleram bem.

## S55 (M2C/M3 F80/M4 F82)

- **Stage 1:** 431 → ~520–540 cv.
- **Stage 2:** ~580 cv.
- **Pure/downpipes:** 650+.
- **Ponto crítico:** rod bearings — recomendamos troca preventiva a 80–100k antes de map agressivo.

## TCU — ZF 8HP (automática)

- Remap TCU recomendado junto com Stage 2+.
- Ganhos: troca mais rápida, lock-up mais cedo, torque limiter removido, launch control.
- Faixa: trocas 20–30% mais rápidas, feel esportivo.

## Riscos e honestidade

- Remap mal feito = pistão furado, turbo queimado, corrente estourada.
- Leitura log WBO2, MAP, timing, knock antes e depois.
- Garantia da BMW é perdida no motor/transmissão — nunca escondemos isso do cliente.
- Motor com manutenção atrasada **não** entra pra remap.

## Modelos que **não** fazemos Stage

- Motores com problema ativo (corrente N20 batendo, vazamento severo, bobina em falha).
- Carros com fluido ZF nunca trocado acima de 100k — trocar primeiro.
