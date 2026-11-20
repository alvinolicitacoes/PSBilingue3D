# Vozes offline do PSBilingue 3D

O jogo usa arquivos WAV em `assets/voice/en/` quando disponíveis, e somente recorre à voz do sistema operacional quando não há uma gravação correspondente.

## Gerar o pacote de pronúncias (uma vez, antes do lançamento)

1. Instale Python 3.11+ no computador.
2. Execute: `python -m pip install piper-tts`
3. Baixe o modelo inglês e seu arquivo `.onnx.json` em:
   https://huggingface.co/rhasspy/piper-voices/tree/main/en/en_US/lessac/medium
4. Confira o `MODEL_CARD` da voz para os termos de uso e redistribuição.
5. Na pasta raiz do projeto, execute:
   `python tools/generate_voice_pack.py --model "C:/caminho/en_US-lessac-medium.onnx"`
6. Aguarde a geração dos WAVs e do `manifest.json`.
7. Inclua `assets/voice/en/` no GitHub e no pacote exportado do Godot.
8. Teste a pronúncia no Windows e em um APK Android, com TTS do sistema desativado ou indisponível.

O gerador extrai as frases de `scripts/npc.gd`, sem manter um segundo banco de conteúdo. Sempre que novas frases forem acrescentadas, execute novamente o comando para gerar somente os arquivos faltantes.

**Importante:** o gerador não é executado durante o jogo; os arquivos WAV precisam estar presentes antes da exportação. Não inclua os modelos ONNX no APK, apenas os áudios gerados.
