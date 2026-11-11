# Open deck-builder-game in Godot with the environment the Godot AI MCP needs.
#
# %LOCALAPPDATA% must match the DSH mcp-godot-ai row, because the v4 capability
# record lives in <LOCALAPPDATA>\godot-ai\capabilities and is what lets the
# stdio bridge authenticate to the backend the editor spawns.
$ErrorActionPreference = 'Stop'

$env:APPDATA = 'D:\deepseek工作区\.godot-data'
$env:LOCALAPPDATA = 'D:\deepseek工作区\.godot-data\local'
$env:GODOT_AI_VENV_PYTHON = 'D:\deepseek工作区\godot-ai\.venv\Scripts\python.exe'
$env:GODOT_AI_DISABLE_TELEMETRY = 'true'

$godot = 'D:\deepseek工作区\Godot\Godot_v4.7.2-stable_win64.exe'
if (-not (Test-Path $godot)) {
    $godot = 'D:\deepseek工作区\Godot\Godot_v4.7.2-stable_win64_console.exe'
}

& $godot --path $PSScriptRoot --editor
