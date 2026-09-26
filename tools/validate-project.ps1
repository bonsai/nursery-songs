param(
  [Parameter(Mandatory = $true)][string]$Path,
  [string]$SchemaRef = "bonsai/video-editor packages/schema/project.schema.json"
)

$ErrorActionPreference = "Stop"

$fail = [System.Collections.Generic.List[string]]::new()

function Test-Num($v, [double]$min, [bool]$exclusive) {
  if ($null -eq $v) { return $false }
  if ($v -isnot [double] -and $v -isnot [int] -and $v -isnot [decimal] -and $v -isnot [long]) { return $false }
  if ($exclusive) { return ([double]$v -gt $min) }
  return ([double]$v -ge $min)
}

foreach ($p in (Get-ChildItem -LiteralPath $Path -Recurse -Filter "project.json")) {
  $rel = $p.FullName.Substring((Resolve-Path $Path).Path.Length).TrimStart('\')
  $j = Get-Content -LiteralPath $p.FullName -Raw -Encoding UTF8 | ConvertFrom-Json

  if ($null -eq $j.composition) { $fail.Add("$rel : missing 'composition' (required)") }
  else {
    if ($null -eq $j.composition.duration) { $fail.Add("$rel : composition.duration missing (required)") }
    elseif (-not (Test-Num $j.composition.duration 0 $false)) { $fail.Add("$rel : composition.duration must be number >= 0, got '$($j.composition.duration)'") }
    if ($null -eq $j.composition.fps) { $fail.Add("$rel : composition.fps missing (required)") }
    elseif (-not (Test-Num $j.composition.fps 0 $true)) { $fail.Add("$rel : composition.fps must be number > 0, got '$($j.composition.fps)'") }
  }

  if ($null -ne $j.effects) {
    $n = 0
    foreach ($e in @($j.effects)) {
      $n++
      if ($e.type -ne "effect") { $fail.Add("$rel : effects[$n].type must be 'effect', got '$($e.type)'") }
      if ([string]::IsNullOrEmpty($e.name)) { $fail.Add("$rel : effects[$n].name missing (required)") }
      if ($null -eq $e.start) { $fail.Add("$rel : effects[$n].start missing (required)") }
      elseif (-not (Test-Num $e.start 0 $false)) { $fail.Add("$rel : effects[$n].start must be number >= 0, got '$($e.start)'") }
      if ($null -eq $e.duration) { $fail.Add("$rel : effects[$n].duration missing (required)") }
      elseif (-not (Test-Num $e.duration 0 $true)) { $fail.Add("$rel : effects[$n].duration must be number > 0, got '$($e.duration)'") }
      if ($null -eq $e.params) { $fail.Add("$rel : effects[$n].params missing (required)") }
    }
  }

  if ($j.schemaRef -ne $SchemaRef) { $fail.Add("$rel : schemaRef should be '$SchemaRef', got '$($j.schemaRef)'") }
  if ($null -eq $j.meta.hook) { $fail.Add("$rel : meta.hook missing") }
  if (-not (Test-Num $j.meta.words 1 $false)) { $fail.Add("$rel : meta.words must be number >= 1, got '$($j.meta.words)'") }
}

if ($fail.Count -gt 0) {
  "INVALID ($($fail.Count))"
  $fail | ForEach-Object { "  $_" }
  exit 1
}

"OK: all project.json under $Path conform to the required shape of $SchemaRef"
