# XHumanX Control

Aplicación nativa de Windows para iniciar **Claude Code** y **Codex CLI** usando el puente local LiteLLM + FreeLLMAPI + Ollama.

## Instalación rápida

1. Descarga `XHumanX-Control-Setup-*.exe` desde [Releases](https://github.com/humanx123/xhumanx-control/releases).
2. Ejecuta el instalador y acepta la preparación del puente.
3. Abre **XHumanX Control** desde el escritorio; la primera apertura prepara autom?ticamente las dependencias.
4. Abre `⚙ API CONFIG`, pega tu clave unificada de FreeLLMAPI y pulsa **Añadir**.
5. Espera a que el monitor muestre el sistema listo y pulsa **Claude Code** o **Codex CLI**. Si falta una dependencia, el mensaje aparece dentro de la GUI.

El instalador prepara `%LOCALAPPDATA%\ClaudeOllamaBridge`, descarga FreeLLMAPI portable, crea el entorno de LiteLLM e intenta instalar Ollama, Claude Code y Codex CLI. La GUI vuelve a ejecutar esta preparaci?n si la instalaci?n inicial fue interrumpida. La primera instalación necesita Internet y puede tardar varios minutos.

## Requisitos

- Windows 10/11 de 64 bits.
- PowerShell 5.1.
- Node.js LTS para el alta de proveedores desde la GUI.
- Python 3.10+ para LiteLLM; el instalador intenta instalarlo con `winget`.
- Ollama, Claude Code y Codex CLI se instalan por separado según sus licencias y cuentas.

## Uso

- **Claude Code**: inicia FreeLLMAPI, LiteLLM y Claude con `ANTHROPIC_BASE_URL=http://127.0.0.1:4000`.
- **Codex CLI**: inicia el mismo puente con `OPENAI_BASE_URL=http://127.0.0.1:4000/v1`.
- **Monitor**: verifica FreeLLMAPI en `31415` y LiteLLM en `4000`.
- **Configuración**: permite agregar Groq, Google, Gemini, Cerebras, Mistral, OpenRouter, Hugging Face, Cohere, Cloudflare, LLM7, NVIDIA NIM y otros proveedores soportados.
- Las claves se gestionan localmente por FreeLLMAPI; no subas archivos de configuración, tokens ni claves al repositorio.

## Desarrollo

```powershell
npm install
npm run build
npm run desktop
```

Para construir el instalador:

```powershell
npm run dist:win
```

El resultado queda en `release/`.

## Limitaciones

El instalador no crea cuentas ni obtiene claves de proveedores automáticamente. Usa los enlaces de la ventana de configuración para solicitar las claves con cada proveedor. FreeLLMAPI y sus proveedores mantienen sus propias condiciones, límites y políticas.

Hecho por **XHumanX & IA**.
