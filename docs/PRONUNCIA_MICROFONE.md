# Atividade Minha Pronúncia — microfone

O botão **🎤 Pronúncia** na cidade abre uma atividade com 3 níveis, 10 frases por nível, gravação local e reprodução.

## Windows
- Autorize o acesso ao microfone em Configurações > Privacidade e segurança > Microfone.
- No Godot, use F5 e abra **🎤 Pronúncia**.
- Ouça a frase, grave sua voz, pare e reproduza.

## Android
- Na predefinição de exportação Android do Godot, habilite a permissão **RECORD_AUDIO**.
- Confirme que o APK solicita e recebe permissão de microfone no aparelho.
- Teste com um dispositivo real; emuladores podem não ter microfone disponível.

## Limitação importante
Esta versão **não atribui nota de pronúncia**: grava e reproduz a voz para comparação, mas não reconhece automaticamente o que foi dito. Uma nota confiável exige integrar e validar um mecanismo de reconhecimento de fala e/ou avaliação fonética. Não use transcrição simples como se fosse uma avaliação fonética precisa.

## Áudio de referência
Os botões de ouvir usam o sistema de voz do projeto. Para funcionar offline em qualquer aparelho, gere e inclua os pacotes de áudio de `assets/voice/en` e `assets/voice/pt`.
