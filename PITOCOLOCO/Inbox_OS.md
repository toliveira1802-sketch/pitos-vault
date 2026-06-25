# 📥 Inbox Mental do Agent OS

> Despeje o seu cérebro abaixo. O formulário não recarregará a sua tela do Obsidian; ele envia diretamente o POST oculto para os robôs do **n8n**.

<div class="agent-inbox-container">
  <h3>⚡ Transferência de Consciência</h3>
  <p>Registre ideias, links, demandas soltas ou comandos diretos de execução.</p>
  
  <form action="http://localhost:5678/webhook-test/agent-inbox-test" method="POST" target="hidden_iframe">
    <textarea name="raw_input" placeholder="O que eu preciso processar para você agora?..." required></textarea>
    
    <div class="inbox-controls">
      <select name="input_type">
        <option value="auto">🤖 Classificar Sozinho (Cérebro Ligado)</option>
        <option value="ideia">💡 É apenas um Insight/Ideia</option>
        <option value="tarefa">✅ É estritamente uma Tarefa Corriqueira</option>
      </select>
      
      <button type="submit">Zerar Mente & Processar 🚀</button>
    </div>
  </form>
  
  <!-- O iframe oculto garante que, ao apertar Submit, a página atual do Obsidian não pisque ou tente redirecionar! -->
  <iframe name="hidden_iframe" style="display:none;"></iframe>
</div>

---
**Regra de Processamento:** Ao cair no n8n, o agente classifica usando a API de Responses da OpenAI, grava a entidade no Supabase e dá um push na API do Miro.
