# PSBilingue 3D — Mundo do Pietro

Projeto educativo **Godot 4 Standard / GDScript**, independente do Android Studio. Uso pessoal, sem monetização e sem chamadas externas de IA.

## Implementado nesta entrega

- Mundo 3D gerado em tempo de execução, com 12 edifícios coloridos, iluminação, árvores, caminhos, personagem Pietro estilizado e câmera que o acompanha.
- Movimento por teclado (WASD/setas) e botões na tela; interação por espaço perto dos edifícios; seleção direta de atividades.
- **Memória:** 10 níveis, dimensões 2×2, 2×2, 4×4, 4×4, 6×6, 6×6, 8×8, 8×8, 10×10, 10×10; 50 pares no último nível; comparação real de pares, contagem de erros e vitória.
- **Sudoku:** tabuleiros 4×4, 6×6 e 9×9, casas editáveis, teclado numérico e validação real de linhas, colunas e blocos. Não há botão de vitória automática.
- **10 modalidades de quiz:** Inglês, Matemática, Lógica, Português, Ciências, Geografia, Animais, Cores, Frases e Soletração; 10 níveis, 10 questões por nível. Algumas questões são geradas com variações; categorias factuais reutilizam bancos pequenos. Não são 100 perguntas únicas em todas as categorias.
- Progressão e estrelas salvas localmente em `user://psbilingue_progress.json`.

## Como abrir

1. Extraia o ZIP.
2. No Godot 4 Standard, escolha **Importar** e selecione `project.godot`.
3. Pressione F5.
4. No mundo, caminhe com setas/WASD ou escolha uma atividade no menu inferior.

## Limitações conhecidas / pendências importantes

- **Não foi compilado nem executado no Godot neste ambiente**. É necessária validação no editor e no Android antes de considerar o projeto estável.
- Pietro é um personagem 3D geométrico, não um modelo profissional com animação esquelética.
- Os tabuleiros 8×8 e 10×10 podem exigir rolagem ou adaptação adicional em telas pequenas.
- Sudoku utiliza construção de solução válida com remoção de pistas, **sem verificador de solução única**; deve receber um gerador com checagem de unicidade para ser considerado completo.
- Os quizzes de Ciências, Geografia, Português e Animais usam bancos pequenos com repetição; a modalidade Soletração é de múltipla escolha, não digitação livre.
- Não há reconhecimento de voz, áudio narrado, contas online ou sincronização entre dispositivos.
- Os jogos ainda precisam de testes funcionais e de acessibilidade, especialmente no celular.

## Estrutura

- `scenes/main.tscn`: cena principal.
- `scripts/world.gd`: mundo 3D, personagem e navegação.
- `scripts/games.gd`: interface e regras dos jogos.
- `scripts/content.gd`: perguntas e conteúdo educativo.
- `scripts/progress.gd`: progresso local.

O projeto não contém credenciais nem serviços externos. A progressão é local ao dispositivo.
