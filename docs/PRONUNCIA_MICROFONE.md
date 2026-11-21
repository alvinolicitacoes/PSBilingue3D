# Pronúncia bilíngue — GDVOSK offline

O jogo usa a extensão compilada em `addons/gdvosk/` e o script `scripts/pronunciation.gd`.

## Instalar os modelos (obrigatório)

O carregador oficial do GDVOSK espera **arquivos ZIP renomeados para .vosk** (não pastas extraídas). Os ZIPs oficiais contêm uma pasta raiz com o mesmo nome do modelo; preserve essa estrutura.

1. Baixe `vosk-model-small-en-us-0.15.zip` e `vosk-model-small-pt-0.3.zip` do site oficial Vosk.
2. Copie os ZIPs para `assets/speech/`.
3. Renomeie **somente a extensão** dos arquivos, sem descompactar:
   - `assets/speech/vosk-model-small-en-us-0.15.vosk`
   - `assets/speech/vosk-model-small-pt-0.3.vosk`
4. Confirme que o Windows não acrescentou `.zip` oculto no final. Ative Exibir > Extensões de nomes de arquivo no Explorador.
5. Abra o Godot 4.7 e aguarde a importação. O GDVOSK extrai o modelo no diretório `user://gdvosk/models/` ao carregá-lo pela primeira vez.

**Atenção:** os modelos não estão incluídos no repositório nesta atualização. Sem eles, a correção por microfone não funciona. Para incluí-los no GitHub, use Git LFS caso necessário e considere a cota disponível.

## Testar no Windows

1. Permita o microfone em Configurações > Privacidade e segurança > Microfone.
2. Abra a cena principal (F5), entre em **🎤 Pronúncia**, selecione inglês ou português e um nível.
3. Ouça a frase, toque em **Começar gravação**, fale e toque em **Parar gravação**.
4. Toque em **Corrigir minha fala**. O texto reconhecido e a correspondência de palavras aparecerão na tela.
5. Repita a frase e confira se a melhor pontuação foi preservada após reiniciar o jogo.

## Android

Habilite `RECORD_AUDIO` na exportação Android e teste em aparelho físico. A presença dos binários ARM64 no repositório não comprova que o APK foi exportado e testado com sucesso.

## O que a pontuação significa

A porcentagem é **correspondência de palavras transcritas**, não precisão fonética. Sotaques, ruído, idade e características do microfone podem influenciar a transcrição. Não use essa porcentagem para diagnosticar dificuldades de fala.

## API usada

O código usa a API de transcrição estática do GDVOSK: `VoskRecognizer.setup(model, sample_rate, null)`, `accept_stream(AudioStreamWAV)` e `get_final_result()`. A extensão aceita modelos como ZIP com extensão `.vosk`, conforme `VoskModelResourceLoader.cpp` do projeto oficial.
