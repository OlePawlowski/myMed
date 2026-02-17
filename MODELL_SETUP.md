# MedGemma 4B – Modell-Setup

## Modell herunterladen

Das Modell **medgemma-4b-instruct.Q4_K_M.gguf** muss separat bezogen werden:

1. **Hugging Face**: Suche nach `medgemma-4b-instruct` oder `google/medgemma-4b-it` und konvertiere zu GGUF Q4_K_M
2. **Oder** nutze ein bereits quantisiertes GGUF von der [llama.cpp Model-Liste](https://huggingface.co/models?search=medgemma%20gguf)

## Modell einbinden

### Option A: In den App-Bundle (Xcode)

1. Die Datei `medgemma-4b-instruct.Q4_K_M.gguf` (oder `medgemma-4b-instruct.gguf`) in das Xcode-Projekt ziehen
2. Unter "Add to targets" → **MyMed** auswählen
3. "Copy items if needed" aktivieren

### Option B: In Documents (On-Device)

Die App sucht auch unter:
```
Documents/medgemma-4b-instruct.gguf
```

(z.B. per iTunes/Finder-Dateifreigabe oder Files-App)

## llama.cpp XCFramework bauen

**Vor dem ersten Build** muss das llama.cpp XCFramework erstellt werden.

**Nur iOS (empfohlen, ~5–10 Min):**
```bash
cd llama.cpp
./build-xcframework-ios-only.sh
```

**Alle Plattformen (~30 Min):**
```bash
cd llama.cpp
./build-xcframework.sh
```

**Voraussetzungen:**
- Xcode mit iOS SDK (nicht nur Command Line Tools)
- CMake 3.28+ (`brew install cmake`)

Das Skript erzeugt `build-apple/llama.xcframework`, das der MyMed-Build automatisch findet.

## Voraussetzungen

**iPhone mit 6 GB+ RAM** (ab iPhone 14). Geräte mit 4 GB (z.B. iPhone 13) werden nicht unterstützt – dafür ist eine spätere Server-Version geplant.

## Größe & Performance

| Modell | Größe | RAM | iPhone 15 Pro |
|--------|------|-----|---------------|
| Q4_K_M | ~2.3 GB | 6 GB+ | 10–20 tok/s (Metal) |

Erstes Laden: 2–5 Sekunden.
