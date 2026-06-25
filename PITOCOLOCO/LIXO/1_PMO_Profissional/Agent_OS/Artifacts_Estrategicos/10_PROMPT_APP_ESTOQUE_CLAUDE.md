	# 📦 PROMPT MAGISTRAL: APP DE INVENTÁRIO INTELIGENTE (PITOCO LOCO CORP)

> **Endereçado a:** Claude (CTO)
> **Natureza da Tarefa:** Criação de Nova Funcionalidade / Micro-App
> **Contexto:** Módulo de controle de estoque inteligente para a oficina.

---

## 📌 1. A Missão Executiva
Claude, precisamos de um novo braço tecnológico na nossa operação: um **Mini-App de Inventário Inteligente**. 
O objetivo deste módulo é acabar com o controle manual cego de peças. A mecânica principal é simples, mas requer uma lógica de banco de dados muito bem estruturada.

## 📸 2. Funcionalidade Core (Scanner)
A interface deve possuir um componente de **Leitor/Scanner** (simulando a câmera do celular/tablet) para **tirar foto ou escanear o código da peça** que o mecânico tem em mãos no estoque.

Ao bater o código, a aplicação precisa realizar uma busca (query) instantânea na nossa base e retornar a ficha técnica e financeira daquela peça.

## 🗄️ 3. Estruturação da Database (Obrigatório)
Você vai modelar uma database local pequena (pode usar Supabase, SQLite, ou até um JSON-server fortificado inicialmente). A tabela `pecas_encontradas` precisa conter obrigatoriamente os seguintes campos:

1. `codigo_peca`: Hash ou String do código lido na foto (Identificador Único).
2. `tipo_peca`: Descrição técnica (Ex: *Bomba D'água, Filtro de Óleo, Pastilha de Freio*).
3. `carros_suportados`: Array ou Lista dos modelos de carros (e anos) que aceitam aquela peça.
4. `pecas_equivalentes`: Array com o "Cross-Reference" (quais outras peças de outras marcas servem para a mesma função).
5. `quantidade_estoque`: Int (Saldo físico que temos na prateleira).
6. `preco_medio_mercado`: Float (Preço cruzado do mercado para sabermos por quanto vender).

## 🏃 4. Seu Plano de Execução (CTO)
1. **Frontend:** Desenvolva o layout desse módulo (React/Next.js). Crie o botão/zona de "Tirar Foto do Código" e a Tabela/Grid de Resultados.
2. **Backend/Base:** Modele as tabelas exatamente com os 6 campos exigidos acima.
3. **Mock Data Realista:** Popule a base com 5 registros de **peças automotivas reais** (com carros reais e peças equivalentes reais) para que possamos testar a filtragem e a busca visual.
4. **Implementação:** Crie o componente, rode e valide. O design deve seguir nossa diretriz C-Level (Dark Mode, layout limpo e performático).
