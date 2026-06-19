$ErrorActionPreference = "Stop"

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$luaScript = Join-Path $scriptPath "run-unit-tests.lua"
$workspaceRoot = Split-Path (Split-Path $scriptPath -Parent) -Parent
$luaExe = if ($env:EMOF_LUA_EXE) { $env:EMOF_LUA_EXE } else { Join-Path $workspaceRoot "lua-5.2.1\lua52.exe" }

if (-not (Test-Path $luaExe)) {
  throw "Lua executable not found: $luaExe. Set EMOF_LUA_EXE or install lua at workspace\lua-5.2.1\lua52.exe"
}

& $luaExe $luaScript
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
