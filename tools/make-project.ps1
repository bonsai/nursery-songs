param(
  [Parameter(Mandatory = $true)][string]$In,
  [string]$Out,
  [double]$Wpm = 125,
  [int]$Fps = 30,
  [ValidateSet("deadpan", "wink", "lullaby")][string]$Register = "deadpan",
  [string]$Voice = "Microsoft Heera",
  [string]$Theme = ""
)

$ErrorActionPreference = "Stop"

$raw = Get-Content -LiteralPath $In -Raw -Encoding UTF8
$raw = $raw -replace "`r`n", "`n"
$raw = $raw -replace "^\uFEFF", ""
$raw = $raw -replace '(?s)^---.*?---\n', ''

$lyricsAt = [regex]::Match($raw, '(?m)^##\s*Lyrics\s*$')
if (-not $Theme) {
  $th = [regex]::Match($raw, '(?m)^>\s*\*\*Theme:\*\*\s*(.+?)\s*$')
  if ($th.Success) { $Theme = $th.Groups[1].Value.Trim() }
}
if ($lyricsAt.Success) {
  $start = $lyricsAt.Index + $lyricsAt.Length
  $rest = $raw.Substring($start)
  $next = [regex]::Match($rest, '(?m)^##\s')
  $raw = if ($next.Success) { $rest.Substring(0, $next.Index) } else { $rest }
}
$raw = $raw -replace '(?m)^#{1,6}\s.*$', ''
$raw = $raw -replace '\*+', ''
$raw = $raw -replace '(?m)^[|:\- ]{3,}$', ''

$blocks = @([regex]::Split($raw.Trim(), '\n\s*\n') | Where-Object { $_.Trim() -ne '' })

$spoken = [System.Collections.Generic.List[string]]::new()
$hook = ""
$chorusCount = 0
$verseCount = 0
$lastChorus = @()

$i = 0
while ($i -lt $blocks.Count) {
  $lines = @($blocks[$i] -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
  if ($lines.Count -eq 0) { $i++; continue }
  if ($lines[0] -match '^\(?\s*(chorus|refrain|repeat)\b') {
    $marker = $lines[0]
    $body = if ($lines.Count -gt 1) { @($lines[1..($lines.Count - 1)]) } else { @() }
    if ($body.Count -eq 0 -and $marker -notmatch '^\(') {
      if ($i + 1 -lt $blocks.Count) {
        $next = @($blocks[$i + 1] -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
        $take = $false
        if ($next.Count -gt 0) {
          $m1 = $next[0] -match '^\(?\s*(chorus|refrain|repeat|verse|intro|outro|bridge)\b'
          $m2 = $next[0] -match '^\(?\s*\d+\s*[\.\)]?\s*\)?\s*(\u2014.*)?$'
          $take = (-not $m1) -and (-not $m2)
        }
        if ($take) { $body = $next; $i++ }
      }
    }
    if ($body.Count -gt 0) { $lastChorus = $body }
    foreach ($l in $lastChorus) { $spoken.Add($l) }
    if (-not $hook -and $lastChorus.Count -gt 0) { $hook = $lastChorus[0] }
    $chorusCount++
  } else {
    $body = @($lines | Where-Object { $_ -notmatch '^\(?\s*\d+\s*[\.\)]?\s*\)?\s*(\u2014.*)?$' })
    if ($body.Count -eq 0) { $i++; continue }
    foreach ($l in $body) { $spoken.Add($l) }
    $verseCount++
  }
  $i++
}

$wordCount = 0
foreach ($l in $spoken) { $wordCount += ([regex]::Matches($l, "[A-Za-z0-9']+")).Count }
if ($wordCount -eq 0) { throw "No spoken words found in $In" }

$duration = [math]::Round(($wordCount / $Wpm) * 60.0, 1)

$slug = [IO.Path]::GetFileNameWithoutExtension($In) -replace '^(\d+)-', ''
$title = (Get-Content -LiteralPath $In -TotalCount 1 -Encoding UTF8)
$title = ($title -replace '^#+\s*', '').Trim()
if ([string]::IsNullOrWhiteSpace($title) -or $title.StartsWith('---')) {
  $title = $slug -creplace '\b[a-z]', { $_.Value.ToUpper() }
}
if (-not $Theme) { $Theme = "nonsense nursery rhyme" }

$stylePrompt = switch ($Register) {
  "deadpan" { "deadpan acoustic children's folk, ukulele, brushed snare, single female voice, 96 BPM, no backing vocals, no harmony stacks, no build, no big finish, no autotune, no strings" }
  "wink"    { "playful acoustic children's folk, ukulele, hand claps, single female voice, 104 BPM, no backing vocals, no big finish, no autotune" }
  "lullaby" { "lullaby, solo voice, felt piano, no drums, no percussion, 62 BPM, no backing vocals, no build, no big finish" }
}

$project = [ordered]@{
  composition = [ordered]@{ duration = $duration; fps = $Fps }
  effects     = @()
  schemaRef   = "bonsai/video-editor packages/schema/project.schema.json"
  meta        = [ordered]@{
    title     = $title
    slug      = $slug
    theme     = $Theme
    source    = (Split-Path -Leaf $In)
    words     = $wordCount
    verses    = $verseCount
    choruses  = $chorusCount
    hook      = $hook
    wpm       = $Wpm
  }
  audio       = [ordered]@{
    engine         = "windows-sapi"
    voice          = $Voice
    culture        = "en-IN"
    target_seconds = $duration
    skill          = "en-in"
    command        = "tts.ps1 -Text `"songs/$([IO.Path]::GetFileName($In))`" -Out `"video/$slug/narration.mp3`" -TargetSeconds $duration"
  }
  music       = [ordered]@{
    source = "suno"
    register = $Register
    style_prompt = $stylePrompt
    lyrics_ref = "suno/$slug.suno.txt"
  }
}

$json = $project | ConvertTo-Json -Depth 8

if ($Out) {
  $outDir = Split-Path -Parent $Out
  if ($outDir -and -not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
  [IO.File]::WriteAllText($Out, ($json.Trim() + "`n"), (New-Object Text.UTF8Encoding $false))
}

"SLUG=$slug WORDS=$wordCount VERSES=$verseCount CHORUSES=$chorusCount DURATION=${duration}s"
if ($Out) { "WROTE=$Out" }
