#!/usr/bin/env python3
"""Gera pronúncias offline com Piper, sem depender de voz instalada no Windows.
Uso: python tools/generate_voice_pack.py --model caminho/voz.onnx
Requer: pip install piper-tts
O script lê TODAS as frases inglesas de scripts/npc.gd, sem lista duplicada.
"""
import argparse
import ast
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NPC = ROOT / "scripts" / "npc.gd"
OUTPUT = ROOT / "assets" / "voice"

def phrase_id(text, lang):
    return hashlib.sha256((lang + ":" + text.strip()).encode("utf-8")).hexdigest()[:20]

def extract_phrases():
    source = NPC.read_text(encoding="utf-8")
    phrases = {"en": set(), "pt": set()}
    for lang in ("en", "pt"):
        for match in re.finditer(r'"' + lang + r'"\s*:\s*("(?:\\.|[^"\\])*")', source):
            phrases[lang].add(ast.literal_eval(match.group(1)))
    return {lang: sorted(items) for lang, items in phrases.items()}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-en", required=True, type=Path, help="English Piper .onnx")
    parser.add_argument("--model-pt", required=True, type=Path, help="Brazilian Portuguese Piper .onnx")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    for model in (args.model_en, args.model_pt):
        if not model.is_file():
            parser.error("Modelo de voz não encontrado: " + str(model))
    try:
        from piper import PiperVoice
    except ImportError:
        parser.error("Instale o gerador: python -m pip install piper-tts")
    import wave
    phrases = extract_phrases()
    for lang, model in (("en", args.model_en), ("pt", args.model_pt)):
        voice = PiperVoice.load(str(model))
        folder = OUTPUT / lang
        folder.mkdir(parents=True, exist_ok=True)
        items = phrases[lang]
        for index, phrase in enumerate(items, 1):
            path = folder / (phrase_id(phrase, lang) + ".wav")
            if path.exists() and not args.force:
                continue
            with wave.open(str(path), "wb") as wav:
                voice.synthesize_wav(phrase, wav)
            print(f"[{lang} {index}/{len(items)}] {phrase}")
        (folder / "manifest.json").write_text(
            json.dumps({"language": lang, "count": len(items),
                        "items": {phrase: phrase_id(phrase, lang) + ".wav" for phrase in items}},
                       ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Concluído: {len(items)} frases em {folder}")


if __name__ == "__main__":
    main()
