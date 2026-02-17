# MedGemma auf deutschem Server (geplant)

Für iPhones mit 4 GB RAM (z.B. iPhone 13) ist eine **Server-Version** geplant. Kunden wählen dann zwischen:
- **Lokal** (6 GB+ RAM) – MedGemma 4B auf dem Gerät
- **Server** (4 GB RAM) – MedGemma auf deutschem Server

---

Die App kann MedGemma auf einem **externen Server** nutzen – ideal für die beste Variante (27B) ohne Speicherlimit auf dem iPhone.

## Server-Anforderungen

**OpenAI-kompatible API** unter `/v1/chat/completions`:

- **llama.cpp Server** (empfohlen)
- **vLLM**
- **Ollama** (mit OpenAI-kompatibler API)
- **text-generation-webui** (OpenAI-API-Erweiterung)

## llama.cpp Server starten (Beispiel)

```bash
# MedGemma 27B (beste Qualität) oder 4B
./llama-server -m medgemma-27b-text-it-Q4_K_M.gguf \
  --host 0.0.0.0 --port 8080 \
  -c 4096 -ngl 99
```

## In der App konfigurieren

1. **Einstellungen** (Zahnrad im Chat) öffnen
2. **Server-URL** eintragen, z.B.:
   - `https://dein-server.de:8080`
   - `http://192.168.1.100:8080` (lokales Netz)
3. **Fertig** – der Chat nutzt nun den Remote-Server

## DSGVO

- Server in Deutschland hosten (z.B. Hetzner, IONOS)
- Keine Daten an US-Clouds
- Optional: HTTPS + API-Key für Zugriffskontrolle
