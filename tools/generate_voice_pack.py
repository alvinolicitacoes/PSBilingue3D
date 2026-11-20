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
OUTPUT = ROOT / "assets" / "voice" / "en"

def phrase_id(text):
    return hashlib.sha256(("en:" + text.strip()).encode("utf-8")).hexdigest()[:20]

def extract_phrases():
    source = NPC.read_text(encoding="utf-8")
    phrases = []
    for match in re.finditer(r'"en"\s*:\s*("(?:\\.|[^"\\])*")', source):
        phrases.append(ast.literal_eval(match.group(1)))
    return sorted(set(phrases))

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", required=True, type=Path, help="Piper .onnx")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    if not args.model.is_file():
        parser.error("Modelo de voz não encontrado: " + str(args.model))
    try:
        from piper import PiperVoice
    except ImportError:
        parser.error("Instale o gerador: python -m pip install piper-tts")
    voice = PiperVoice.load(str(args.model))
    OUTPUT.mkdir(parents=True, exist_ok=True)
    import wave
    phrases = extract_phrases()
    for index, phrase in enumerate(phrases, 1):
        path = OUTPUT / (phrase_id(phrase) + ".wav")
        if path.exists() and not args.force:
            continue
        with wave.open(str(path), "wb") as wav:
            voice.synthesize_wav(phrase, wav)
        print(f"[{index}/{len(phrases)}] {phrase}")
    (OUTPUT / "manifest.json").write_text(
        json.dumps({"language": "en", "count": len(phrases),
                    "items": {phrase: phrase_id(phrase) + ".wav" for phrase in phrases}},
                   ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Concluído: {len(phrases)} frases, em {OUTPUT}")

if __name__ == "__main__":
    main()
