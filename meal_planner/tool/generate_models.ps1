# Generate Supabase Dart models with Supadart.
# Requires SUPABASE_SERVICE_ROLE_KEY in meal_planner/.env (never commit real values).

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

$envFile = Join-Path $PWD ".env"
if (-not (Test-Path $envFile)) {
    Write-Error "Missing .env - copy .env.example and add SUPABASE_SERVICE_ROLE_KEY"
}

Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Item -Path "env:$name" -Value $value
    }
}

if (-not $env:SUPABASE_URL) {
    Write-Error "SUPABASE_URL not set in .env"
}
if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Error "SUPABASE_SERVICE_ROLE_KEY not set in .env (Supabase Dashboard > Settings > API)"
}

# Supadart reads SUPABASE_API_KEY; use service role only for this CLI step.
$env:SUPABASE_API_KEY = $env:SUPABASE_SERVICE_ROLE_KEY
Remove-Item Env:SUPABASE_ANON_KEY -ErrorAction SilentlyContinue

dart pub get
dart run supadart

$header = Join-Path $PWD "lib\core\supabase\models\supadart_header.dart"
if (Test-Path $header) {
    $content = Get-Content $header -Raw
    $content = $content -replace "get recipe-photos", "get recipe_photos"
    $content = $content -replace "(?ms)  static \w+ converter\(List<Map<String, dynamic>> data\) \{\r?\n    throw UnimplementedError\(\);\r?\n  \}\r?\n\r?\n  static \w+ converterSingle\(Map<String, dynamic> data\) \{\r?\n    throw UnimplementedError\(\);\r?\n  \}\r?\n", ""
    Set-Content -Path $header -Value $content.TrimEnd() -NoNewline
    Add-Content -Path $header -Value "`n"
}

dart fix --apply lib/core/supabase/models
