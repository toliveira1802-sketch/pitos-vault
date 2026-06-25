# ⚔️ Atualização Neural: CFOs Modo "War Room" & WhatsApp Webhook

## A Matriz DRE e a Lógica de Margem de 35%
Agora, qualquer número reportado (ex: "faturamos 50k e gastei 20 nas peças", ou num áudio longo), o **Francisco** (GPT) vai estripar esse relato e jogar num DRE mental estruturado:
1. Receita Bruta (Peças vs Mão de Obra)
2. Custos Variáveis (Impostos, Custo mercadoria vendida)
3. Margem de Contribuição
4. Despesas Fixas
5. EBITDA / Lucro Líquido Real

A meta da "Doctor Auto Prime" é 35% de Lucro Líquido.

## O Protocolo "Plano de Guerra" 
O **Chico (Claude)** é especializado no "Plano de Guerra". Se a margem está sangrando ou abaixo de 15%:
- **Foco Máximo em Caixa Rápido e Marketing:** Propõe **Campanhas de Ataque (MKT Direto)**. Instruirá onde colocar a verba de marketing que sobrou pra gerar tráfego pago focado em OS de alta margem.
- Acionamento do braço de Inteligência Comercial (ex: Anna e Davi Gatuno) para resgatar orçamentos congelados.

## Arquitetura do Sistema Atual (Visão Excalidraw / Mermaid)
O fluxo neural de como as requisições transitam no Hub de WhatsApp:

```mermaid
graph TD
    classDef user fill:#1d4ed8,stroke:#60a5fa,stroke-width:2px,color:#fff
    classDef router fill:#374151,stroke:#9ca3af,stroke-width:2px,color:#f3f4f6
    classDef twins fill:#064e3b,stroke:#34d399,stroke-width:2px,color:#fff
    classDef sophia fill:#4c1d95,stroke:#a78bfa,stroke-width:2px,color:#fff
    classDef ext fill:#7f1d1d,stroke:#f87171,stroke-width:2px,color:#fff
    classDef db fill:#0f172a,stroke:#38bdf8,stroke-width:2px,color:#fff

    A["📱 WhatsApp do Chefe"]:::user -->|Envia: Áudio / Texto| B{"🛡️ Webhook (api_hub.py)\nValidar ALLOW_LIST"}:::router
    B -->|Não Autorizado| C["🛑 DROP SILENCIOSO"]:::ext
    B -->|Autorizado| D["🎙️ Motor Oculto\n(Base64 -> Transcrição Whisper)"]:::router
    D --> E{"🔀 WhatsApp Router"}:::router
    
    E -->|Prefixo: 'Sophia:' ou 's:'| F["🧠 SOPHIA (Inbox Central)"]:::sophia
    F -->|Salva| G[("O_TOME_DA_SOPHIA.md")]:::db
    
    E -->|Assunto: Finanças| H{"👔 CFO Twins"}:::twins
    H -->|Modo Francisco (GPT)| I["📊 Francisco\n(DRE, Tabelas, Margem 35%)"]:::twins
    H -->|Modo Chico (Claude)| J["📈 Chico\n(Plano de Guerra, Marketing de Ataque)"]:::twins
    H -->|Modo Conjunto| K["⚔️ Operação Turnaround\nFrancisco (Tabulação) + Chico (Guerra)"]:::twins

    F -.-> L["🔊 TTS Opcional (Voz da Sophia)"]:::sophia
    H -.-> M["🔊 TTS CFO (Voz Onyx)"]:::twins
    
    L --> N["📨 Retorna Resposta p/ o Zap"]:::user
    M --> N
```
