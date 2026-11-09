# ==============================================================================
# SASHELP site builder
# ------------------------------------------------------------------------------
# Single source of truth : sashelp/site.json
# Generated into pages    : page header, left navigation, index tables,
#                           counts, base.css link, dependency ZIP links
# Derived from sources    : macro dependency closure parsed from
#                           codehub/macro/dev/**/*.sas headers (*Dependency /
#                           SubMacros) plus %macro( calls, taken transitively
#
# Dependency packages: sashelp/assets/macropackages/
#   Why  : one click downloads a macro together with everything it needs;
#          works from file:// with no server and no client-side ZIP script,
#          and the site never carries plain .sas source.
#   How  : per macro the closure above is zipped flat (original bytes) into
#          <macro>.zip; macrohub.zip holds every source file for the index.
#          A SHA1 fingerprint per package is kept in macropackages/manifest.json
#          so unchanged packages are not rewritten, and -Check reports
#          STALE-PACKAGE. codehub is only read, never modified.
#   Note : the folder is a build artifact - deleting it is safe, just rerun
#          this script; packages of removed macros are cleaned up automatically.
#
# Usage:
#   powershell -File build\build.ps1            build / update all pages
#   powershell -File build\build.ps1 -Check     verify only, exit 1 on drift
# ==============================================================================
param(
  [switch]$Check
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Root = Split-Path -Parent $PSScriptRoot
$Issues = New-Object System.Collections.ArrayList
$Warnings = New-Object System.Collections.ArrayList
$script:Changed = 0

$HeaderStart = '<!--#HEADER#-->'
$HeaderEnd   = '<!--/#HEADER#-->'
$NavStart    = '<!--#NAV#-->'
$NavEnd      = '<!--/#NAV#-->'
$TableStart  = '<!--#TABLE#-->'
$TableEnd    = '<!--/#TABLE#-->'

$HeaderAdopt = '(?s)<div id="header">.*?<div class="right">.*?</div>\s*</div>'
$NavAdopt    = '(?s)<div id="nav">\s*<ul>.*?</ul>\s*</div>'

function Read-Text([string]$Path) {
  return [System.IO.File]::ReadAllText($Path, $Utf8)
}

function Write-Text([string]$Path, [string]$Text) {
  $parent = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }
  [System.IO.File]::WriteAllText($Path, $Text, $Utf8)
}

function Save-File([string]$Path, [string]$Text) {
  $exists = Test-Path -LiteralPath $Path
  if ($exists -and ((Read-Text $Path) -eq $Text)) { return }
  if ($Check) {
    [void]$Issues.Add('OUT-OF-DATE: ' + $Path.Substring($Root.Length + 1))
    return
  }
  Write-Text $Path $Text
  $script:Changed++
}

function Escape-Html([string]$Text) {
  if ($null -eq $Text) { return '' }
  return $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')
}

function Get-Match-Inner([string]$Text, [string]$Pattern) {
  $m = [regex]::Match($Text, $Pattern)
  if (-not $m.Success) { return '' }
  return $m.Groups[1].Value
}

# ------------------------------------------------------------------ site model
$SitePath = Join-Path $Root 'site.json'
$Site = Get-Content -LiteralPath $SitePath -Raw -Encoding UTF8 | ConvertFrom-Json

$DevRoot = [System.IO.Path]::GetFullPath((Join-Path $Root $Site.macroSource))

$Macros = @{}
Get-ChildItem -LiteralPath $DevRoot -Recurse -Filter *.sas -File | ForEach-Object {
  $name = $_.BaseName.ToLower()
  $lines = (Read-Text $_.FullName) -split "`r?`n"
  $declared = @()
  $limit = [Math]::Min($lines.Count, 60)
  for ($i = 0; $i -lt $limit; $i++) {
    $line = $lines[$i]
    if ($line -match '^[\s*/]*[*/]\s*Dependency\s*:\s*(.+)$' -or
        $line -match '^\s*[*/]\s*SubMacros\s*:\s*(.+)$') {
      $val = $Matches[1]
      foreach ($hit in [regex]::Matches($val, '%([A-Za-z_][\w]*)')) {
        $declared += $hit.Groups[1].Value.ToLower()
      }
    }
  }
  # body calls: used to supplement a missing *Dependency declaration
  $bodyStart = 0
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*%macro\s') { $bodyStart = $i; break }
  }
  $called = @()
  for ($i = $bodyStart; $i -lt $lines.Count; $i++) {
    foreach ($hit in [regex]::Matches($lines[$i], '%([A-Za-z_][\w]*)\s*\(')) {
      $called += $hit.Groups[1].Value.ToLower()
    }
  }
  $deps = @($declared + $called | Sort-Object -Unique)
  $Macros[$name] = @{ Path = $_.FullName; Dir = $_.Directory.Name; Deps = $deps; Declared = $declared; Called = $called }
}

# keep only real macro names (drop %str, %eval, %scan and other SAS functions)
foreach ($k in @($Macros.Keys)) {
  $info = $Macros[$k]
  $info.Deps = @($info.Deps | Where-Object { $Macros.ContainsKey($_) -and $_ -ne $k } | Sort-Object -Unique)
  $info.Called = @($info.Called | Where-Object { $Macros.ContainsKey($_) -and $_ -ne $k } | Sort-Object -Unique)
}

function Get-Closure([string]$Name) {
  $seen = @{}
  $stack = New-Object System.Collections.Stack
  $stack.Push($Name.ToLower())
  while ($stack.Count -gt 0) {
    $n = $stack.Pop()
    if ($seen.ContainsKey($n)) { continue }
    $seen[$n] = $true
    $info = $Macros[$n]
    if ($null -eq $info) { continue }
    foreach ($d in $info.Deps) {
      if (-not $seen.ContainsKey($d)) { $stack.Push($d) }
    }
  }
  return @($seen.Keys | Sort-Object)
}

# Cross-check: a site macro that calls another known macro should also declare it.
# The call scan is already used to supplement the dependency set, so this is advisory.
function Test-UndeclaredDeps([string[]]$SiteSlugs) {
  foreach ($name in $SiteSlugs) {
    $info = $Macros[$name]
    if ($null -eq $info) { continue }
    foreach ($c in $info.Called) {
      if (@($info.Declared) -notcontains $c) {
        [void]$Warnings.Add("UNDECLARED-DEP: $name calls %$c but its header does not declare it")
      }
    }
  }
}

# ------------------------------------------------------------------- rendering
function Render-Header([string]$SectionName, [int]$Depth) {
  $s = $Site.sections.$SectionName
  $up = '../' * $Depth
  $brand = ('../' * ($Depth + 1)) + 'index.html'
  $links = ''
  foreach ($l in $s.headerLinks) {
    $href = $l.href
    if ($href -ne '' -and $null -ne $href) { $href = $up + $href }
    $links += ('<a href="' + $href + '">' + (Escape-Html $l.text) + '</a>' + "`r`n")
  }
  $html  = '<div id="header">' + "`r`n"
  $html += '<div class="left">' + "`r`n"
  $html += '<a href="' + $brand + '"><span style="color: #0070C0;">SAS</span>/<span style="color: #70AD47;">HELP</span></a>' + "`r`n"
  $html += '</div>' + "`r`n"
  $html += '<div class="right">' + "`r`n"
  $html += $links
  $html += '</div>' + "`r`n"
  $html += '</div>'
  return $html
}

function Render-Nav([string]$SectionName, [string]$Current) {
  $s = $Site.sections.$SectionName
  $html  = '<div id="nav">' + "`r`n"
  $html += '<ul>' + "`r`n"
  foreach ($cat in $s.categories) {
    $html += '<li class="nav-cat">' + (Escape-Html $cat.name) + '</li>' + "`r`n"
    foreach ($item in $cat.items) {
      $label = $item.slug
      if ($null -ne $item.label) { $label = $item.label }
      $cls = ''
      if ($Current -and ($Current -eq $item.slug)) { $cls = ' class="current"' }
      $html += '<li><a href="' + $item.slug + '.html"' + $cls + '>' + (Escape-Html $label) + '</a></li>' + "`r`n"
    }
  }
  $html += '</ul>' + "`r`n"
  $html += '</div>'
  return $html
}

function Apply-Block([string]$Text, [string]$Start, [string]$End, [string]$Block, [string]$AdoptPattern) {
  if ($Text.Contains($Start) -and $Text.Contains($End)) {
    $pattern = '(?s)' + [regex]::Escape($Start) + '.*?' + [regex]::Escape($End)
    $m = [regex]::Match($Text, $pattern)
    $replacement = $Start + "`r`n" + $Block + "`r`n" + $End
    return $Text.Substring(0, $m.Index) + $replacement + $Text.Substring($m.Index + $m.Length)
  }
  if (-not $AdoptPattern) { return $null }
  $m = [regex]::Match($Text, $AdoptPattern)
  if (-not $m.Success) { return $null }
  $replacement = $Start + "`r`n" + $Block + "`r`n" + $End
  return $Text.Substring(0, $m.Index) + $replacement + $Text.Substring($m.Index + $m.Length)
}

function Ensure-BaseCss([string]$Text, [int]$Depth) {
  if ($Text -match 'assets/base\.css') { return $Text }
  $href = ('../' * ($Depth + 1)) + 'assets/base.css'
  $link = '<link rel="stylesheet" type="text/css" href="' + $href + '" />'
  $m = [regex]::Match($Text, '<link[^>]*rel="stylesheet"[^>]*>')
  if (-not $m.Success) {
    [void]$Issues.Add('NO-STYLESHEET: page has no stylesheet link')
    return $Text
  }
  return $Text.Substring(0, $m.Index) + $link + "`r`n" + $Text.Substring($m.Index)
}

function Update-SummaryCount([string]$Text, [int]$Count) {
  $pattern = '(?s)(<p class="summary">[^0-9<]*)\d+'
  return [regex]::Replace($Text, $pattern, ('${1}' + $Count))
}

function Update-Table([string]$Text, [string]$TableClass, [string]$Rows) {
  if ($Text.Contains($TableStart) -and $Text.Contains($TableEnd)) {
    $pattern = '(?s)' + [regex]::Escape($TableStart) + '.*?' + [regex]::Escape($TableEnd)
    $m = [regex]::Match($Text, $pattern)
    $replacement = $TableStart + "`r`n" + $Rows + $TableEnd
    return $Text.Substring(0, $m.Index) + $replacement + $Text.Substring($m.Index + $m.Length)
  }
  $pattern = '(?s)<table class="' + $TableClass + '">.*?<tbody>(.*?)</tbody>'
  $m = [regex]::Match($Text, $pattern)
  if (-not $m.Success) {
    [void]$Issues.Add("NO-TABLE: table $TableClass not found")
    return $Text
  }
  $inner = $m.Groups[1]
  $replacement = "`r`n" + $TableStart + "`r`n" + $Rows + $TableEnd + "`r`n"
  return $Text.Substring(0, $inner.Index) + $replacement + $Text.Substring($inner.Index + $inner.Length)
}

# ---------------------------------------------------------------- section pass
function Invoke-Section([string]$SectionName) {
  $s = $Site.sections.$SectionName
  $dir = Join-Path $Root $SectionName
  $pages = @()
  $pages += @{ Path = (Join-Path $dir $s.home); Slug = $null; Depth = 0 }
  $items = @()
  foreach ($cat in $s.categories) {
    foreach ($item in $cat.items) {
      $pages += @{ Path = (Join-Path $dir ($item.slug + '.html')); Slug = $item.slug; Depth = 0; Cat = $cat.name }
      $items += @{ Slug = $item.slug; Cat = $cat.name; Label = $item.label }
    }
  }

  # orphan / missing page check
  $onDisk = Get-ChildItem -LiteralPath $dir -Filter *.html -File | ForEach-Object { $_.BaseName }
  foreach ($it in $items) {
    if ($onDisk -notcontains $it.Slug) {
      [void]$Issues.Add("MISSING-PAGE: $SectionName/$($it.Slug).html")
    }
  }
  $extras = @($s.extras)
  foreach ($n in $onDisk) {
    if ($n -ne 'index' -and $extras -notcontains $n -and -not ($items | Where-Object { $_.Slug -eq $n })) {
      [void]$Issues.Add("UNLISTED-PAGE: $SectionName/$n.html is not in site.json")
    }
  }

  foreach ($p in $pages) {
    if (-not (Test-Path -LiteralPath $p.Path)) { continue }
    $text = Read-Text $p.Path

    $header = Render-Header $SectionName $p.Depth
    $text = Apply-Block $text $HeaderStart $HeaderEnd $header $HeaderAdopt
    if ($null -eq $text) {
      [void]$Issues.Add('NO-HEADER: ' + $p.Path.Substring($Root.Length + 1))
      continue
    }

    $nav = Render-Nav $SectionName $p.Slug
    $text = Apply-Block $text $NavStart $NavEnd $nav $NavAdopt
    if ($null -eq $text) {
      [void]$Issues.Add('NO-NAV: ' + $p.Path.Substring($Root.Length + 1))
      continue
    }

    $text = Ensure-BaseCss $text $p.Depth
    Save-File $p.Path $text
  }
  return $items
}

function Invoke-Index([string]$SectionName, $Items) {
  $s = $Site.sections.$SectionName
  $indexPath = Join-Path (Join-Path $Root $SectionName) $s.home
  if (-not (Test-Path -LiteralPath $indexPath)) { return }
  $text = Read-Text $indexPath

  $rows = ''
  foreach ($cat in $s.categories) {
    foreach ($item in $cat.items) {
      $detail = Join-Path (Join-Path $Root $SectionName) ($item.slug + '.html')
      if (-not (Test-Path -LiteralPath $detail)) { continue }
      $detailText = Read-Text $detail
      $title = Get-Match-Inner $detailText '<h2>(.*?)</h2>'
      $subtitle = Get-Match-Inner $detailText '<p class="subtitle">(.*?)</p>'
      if ($SectionName -eq 'macrohub') { $title = $item.slug }
      $trOpen = '<tr>'
      if ($SectionName -eq 'knowledgebase') { $trOpen = '<tr data-slug="' + $item.slug + '">' }
      $rows += $trOpen + '<td>' + (Escape-Html $cat.name) + '</td><td><a href="' + $item.slug + '.html">' + $title + '</a></td><td>' + $subtitle + '</td></tr>' + "`r`n"
    }
    $rows += "`r`n"
  }

  $tableClass = 'macro-table'
  if ($SectionName -eq 'knowledgebase') { $tableClass = 'kb-table' }
  $text = Update-Table $text $tableClass $rows
  $text = Update-SummaryCount $text @($Items).Count
  if ($SectionName -eq 'knowledgebase') {
    $text = Update-SearchBlock $text
    $text = Ensure-SearchScripts $text
  }
  Save-File $indexPath $text
}

# ---------------------------------------------------------------- KB search
function Update-SearchBlock([string]$Text) {
  $s = $Site.sections.knowledgebase.search
  $start = '<!--#SEARCH#-->'
  $end = '<!--/#SEARCH#-->'

  $block  = $start + "`r`n"
  $block += '<div class="kb-search">' + "`r`n"
  $block += '<input type="search" id="kb-search-input" autocomplete="off" placeholder="' + (Escape-Html $s.placeholder) + '" aria-label="' + (Escape-Html $s.label) + '" />' + "`r`n"
  $block += '<span id="kb-search-status" class="kb-search-status" aria-live="polite"></span>' + "`r`n"
  $block += '</div>' + "`r`n"
  $block += $end

  if ($Text.Contains($start) -and $Text.Contains($end)) {
    $pattern = '(?s)' + [regex]::Escape($start) + '.*?' + [regex]::Escape($end)
    $m = [regex]::Match($Text, $pattern)
    return $Text.Substring(0, $m.Index) + $block + $Text.Substring($m.Index + $m.Length)
  }

  $m = [regex]::Match($Text, '(?s)<p class="summary">.*?</p>')
  if (-not $m.Success) {
    [void]$Issues.Add('NO-SUMMARY: cannot place the search box on the knowledgebase index')
    return $Text
  }
  $at = $m.Index + $m.Length
  return $Text.Substring(0, $at) + "`r`n" + $block + $Text.Substring($at)
}

function Ensure-SearchScripts([string]$Text) {
  $data = '<script src="../assets/kb-search-index.js"></script>'
  $code = '<script src="../assets/kb-search.js"></script>'
  if ($Text.Contains($data) -and $Text.Contains($code)) { return $Text }
  return $Text.Replace('</body>', ($data + "`r`n" + $code + "`r`n" + '</body>'))
}

function Get-PlainText([string]$Html) {
  $t = [regex]::Replace($Html, '<[^>]+>', ' ')
  $t = [System.Net.WebUtility]::HtmlDecode($t)
  $t = [regex]::Replace($t, '\s+', ' ')
  return $t.Trim()
}

function Invoke-SearchIndex {
  $entries = [ordered]@{}
  foreach ($cat in $Site.sections.knowledgebase.categories) {
    foreach ($item in $cat.items) {
      $p = Join-Path (Join-Path $Root 'knowledgebase') ($item.slug + '.html')
      if (-not (Test-Path -LiteralPath $p)) { continue }
      $t = Read-Text $p
      $title = Get-PlainText (Get-Match-Inner $t '<h2>(.*?)</h2>')
      $subtitle = Get-PlainText (Get-Match-Inner $t '<p class="subtitle">(.*?)</p>')
      $article = Get-PlainText (Get-Match-Inner $t '(?s)<div class="detail">(.*)')
      if ($article.Length -gt 600) { $article = $article.Substring(0, 600) }
      $entries[$item.slug] = [ordered]@{
        t = $title
        d = $subtitle
        c = $cat.name
        k = $article
      }
    }
  }
  $json = $entries | ConvertTo-Json -Compress -Depth 5
  Save-File (Join-Path $Root 'assets\kb-search-index.js') ('window.KB_INDEX=' + $json + ';')
}

# ------------------------------------------------------------- markdown->html
function Join-Lines([string]$A, [string]$B) {
  if ($A -eq '') { return $B }
  if ($A -match '[\u4e00-\u9fff]$' -and $B -match '^[\u4e00-\u9fff]') { return $A + $B }
  return $A + ' ' + $B
}

function Join-Text($Lines) {
  $s = ''
  foreach ($l in $Lines) { $s = Join-Lines $s $l.Trim() }
  return $s
}

function Format-Inline([string]$Text) {
  $t = Escape-Html $Text
  $t = [regex]::Replace($t, '`([^`]+)`', '<code>$1</code>')
  $t = [regex]::Replace($t, '\*\*([^*]+)\*\*', '<strong>$1</strong>')
  $t = [regex]::Replace($t, '\[([^\]]+)\]\(([^)]+)\)', '<a href="$2">$1</a>')
  return $t
}

function Split-Cells([string]$Row) {
  $t = $Row.Trim().Trim('|')
  return @($t -split '\|' | ForEach-Object { $_.Trim() })
}

function Pop-ListLevel($Out, $State) {
  if ($State.LiOpen) { [void]$Out.Add('</li>'); $State.LiOpen = $false }
  $top = $State.Stack[$State.Stack.Count - 1]
  [void]$Out.Add('</' + $top.Tag + '>')
  if ($State.Stack.Count -eq 1) {
    $State.Stack = @()
  } else {
    $State.Stack = @($State.Stack[0..($State.Stack.Count - 2)])
  }
}

function Close-Lists($Out, $State) {
  while ($State.Stack.Count -gt 0) { Pop-ListLevel $Out $State }
}

function Convert-MarkdownToHtml([string]$Md) {
  $lines = $Md -split "`r?`n"
  $n = $lines.Count
  $out = New-Object System.Collections.ArrayList
  $state = @{ Stack = @(); LiOpen = $false }
  $i = 0
  $skipTitle = $true

  while ($i -lt $n) {
    $line = $lines[$i]

    if ($line -match '^\s*$') {
      Close-Lists $out $state
      [void]$out.Add('')
      $i++
      continue
    }

    if ($skipTitle) {
      if ($line -match '^#\s+(.*)$') { $skipTitle = $false; $i++; continue }
      $skipTitle = $false
    }

    if ($line -match '^\s*```') {
      Close-Lists $out $state
      $i++
      $buf = @()
      while ($i -lt $n -and $lines[$i] -notmatch '^\s*```') { $buf += $lines[$i]; $i++ }
      $i++
      [void]$out.Add('<pre class="code">' + (Escape-Html ($buf -join "`r`n")) + '</pre>')
      continue
    }

    if ($line -match '^\s*\|' -and ($i + 1) -lt $n -and $lines[$i + 1] -match '^\s*\|[\.\_external\-|]+\|\s*$') {
      Close-Lists $out $state
      $th = ''
      foreach ($c in (Split-Cells $lines[$i])) { $th += '<th>' + (Format-Inline $c) + '</th>' }
      $i += 2
      $body = ''
      while ($i -lt $n -and $lines[$i] -match '^\s*\|') {
        $row = '<tr>'
        foreach ($c in (Split-Cells $lines[$i])) { $row += '<td>' + (Format-Inline $c) + '</td>' }
        $body += $row + '</tr>' + "`r`n"
        $i++
      }
      [void]$out.Add('<table class="macro-table"><thead><tr>' + $th + '</tr></thead><tbody>' + $body + '</tbody></table>')
      continue
    }

    if ($line -match '^(#{1,6})\s+(.*)$') {
      Close-Lists $out $state
      $level = [Math]::Min(6, $Matches[1].Length + 1)
      [void]$out.Add('<h' + $level + '>' + (Format-Inline $Matches[2]) + '</h' + $level + '>')
      $i++
      continue
    }

    if ($line -match '^\s*---\s*$') {
      Close-Lists $out $state
      [void]$out.Add('<hr/>')
      $i++
      continue
    }

    if ($line -match '^\s*>\s?(.*)$') {
      Close-Lists $out $state
      $buf = @($Matches[1])
      $i++
      while ($i -lt $n -and $lines[$i] -match '^\s*>\s?(.*)$') { $buf += $Matches[1]; $i++ }
      [void]$out.Add('<div class="callout"><p>' + (Format-Inline (Join-Text $buf)) + '</p></div>')
      continue
    }

    if ($line -match '^(\s*)(-|\*|\d+\.)\s+(.*)$') {
      $indent = $Matches[1].Length
      $tag = 'ul'
      if ($Matches[2] -match '^\d') { $tag = 'ol' }
      $depth = [int]($indent / 2) + 1

      while ($state.Stack.Count -gt $depth) { Pop-ListLevel $out $state }
      if ($state.Stack.Count -eq $depth - 1) {
        [void]$out.Add('<' + $tag + '>')
        $state.Stack = @($state.Stack + @([pscustomobject]@{ Tag = $tag }))
      } elseif ($state.Stack.Count -gt 0) {
        $top = $state.Stack[$state.Stack.Count - 1]
        if ($top.Tag -ne $tag) {
          Pop-ListLevel $out $state
          [void]$out.Add('<' + $tag + '>')
          $state.Stack = @($state.Stack + @([pscustomobject]@{ Tag = $tag }))
        }
      }
      if ($state.LiOpen) { [void]$out.Add('</li>') }
      [void]$out.Add('<li>' + (Format-Inline $Matches[3]))
      $state.LiOpen = $true
      $i++
      continue
    }

    Close-Lists $out $state
    $buf = @($line)
    $i++
    while ($i -lt $n -and
           $lines[$i] -notmatch '^\s*$' -and
           $lines[$i] -notmatch '^\s*(```|#{1,6}\s|\||>\s|(-|\*|\d+\.)\s)' -and
           $lines[$i] -notmatch '^\s*---\s*$') {
      $buf += $lines[$i]
      $i++
    }
    [void]$out.Add('<p>' + (Format-Inline (Join-Text $buf)) + '</p>')
  }

  Close-Lists $out $state
  return (($out -join "`r`n") -replace "(`r`n){3,}", "`r`n`r`n").Trim()
}

function Invoke-Conventions([string]$SectionName) {
  $s = $Site.sections.$SectionName
  $title = 'Conventions'
  foreach ($l in $s.headerLinks) {
    if ($l.href -eq 'conventions.html') { $title = $l.text }
  }
  $mdPath = Join-Path $Root $s.conventionsSource
  if (-not (Test-Path -LiteralPath $mdPath)) {
    [void]$Issues.Add('MISSING-CONVENTIONS-SOURCE: ' + $s.conventionsSource)
    return
  }

  $body = Convert-MarkdownToHtml (Read-Text $mdPath)
  $theme = '../' + $s.css
  $copy = '../assets/macrohub_copy.js'
  if ($SectionName -eq 'knowledgebase') { $copy = '../assets/knowledgebase_copy.js' }

  $page  = '<!DOCTYPE html>' + "`r`n<html>`r`n<head>`r`n"
  $page += '<meta charset="UTF-8">' + "`r`n"
  $page += '<title>' + (Escape-Html $title) + ' - ' + (Escape-Html $s.label) + '</title>' + "`r`n"
  $page += '<link rel="stylesheet" type="text/css" href="../assets/base.css" />' + "`r`n"
  $page += '<link rel="stylesheet" type="text/css" href="' + $theme + '" />' + "`r`n"
  $page += '</head>' + "`r`n<body>" + "`r`n"
  $page += Render-Header $SectionName 0 + "`r`n"
  $page += Render-Nav $SectionName $null + "`r`n"
  $page += '<div id="section">' + "`r`n"
  $page += '<p class="crumb"><a href="index.html">' + (Escape-Html $s.label) + '</a> / ' + (Escape-Html $title) + '</p>' + "`r`n"
  $page += '<h2>' + (Escape-Html $title) + '</h2>' + "`r`n<hr/>" + "`r`n"
  $page += '<div class="detail doc">' + "`r`n" + $body + "`r`n</div>" + "`r`n"
  $page += '</div>' + "`r`n"
  $page += '<script src="' + $copy + '"></script>' + "`r`n"
  $page += '</body>' + "`r`n</html>`r`n"

  Save-File (Join-Path (Join-Path $Root $SectionName) 'conventions.html') $page
}

# -------------------------------------------------------------------- gallery
function Invoke-Gallery {
  $galleryDir = Join-Path $Root 'gallery'
  if (-not (Test-Path -LiteralPath $galleryDir -PathType Container)) { return }
  $targets = @()
  Get-ChildItem -LiteralPath $galleryDir -Recurse -Filter *.html -File | ForEach-Object {
    $rel = $_.FullName.Substring($galleryDir.Length).TrimStart('\', '/')
    $depth = ($rel -split '[\\/]').Count - 1
    $targets += @{ Path = $_.FullName; Depth = $depth }
  }
  $targets += @{ Path = (Join-Path $Root 'assets\tmpl_gallery_index.html'); Depth = 0 }
  $targets += @{ Path = (Join-Path $Root 'assets\tmpl_gallery_detail.html'); Depth = 1 }

  foreach ($t in $targets) {
    if (-not (Test-Path -LiteralPath $t.Path)) { continue }
    $text = Read-Text $t.Path
    $header = Render-Header 'gallery' $t.Depth
    $text = Apply-Block $text $HeaderStart $HeaderEnd $header $HeaderAdopt
    if ($null -eq $text) {
      [void]$Issues.Add('NO-HEADER: ' + $t.Path.Substring($Root.Length + 1))
      continue
    }
    $text = Ensure-BaseCss $text $t.Depth
    Save-File $t.Path $text
  }
}

# ------------------------------------------------------- dependency packages
# Source code stays out of the site and codehub is never modified. ZIP files
# are generated into assets\macropackages so pages can use a plain <a href>
# download that works from file:// without any server or script.
function Get-PackageFingerprint([string[]]$Paths) {
  $parts = @()
  foreach ($p in ($Paths | Sort-Object { Split-Path -Leaf $_ })) {
    $sha = [System.Security.Cryptography.SHA1]::Create()
    $hash = $sha.ComputeHash([System.IO.File]::ReadAllBytes($p))
    $parts += ((Split-Path -Leaf $p) + ':' + ([BitConverter]::ToString($hash) -replace '-', ''))
    $sha.Dispose()
  }
  $sha = [System.Security.Cryptography.SHA1]::Create()
  $hash = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes(($parts -join "`n")))
  $result = [BitConverter]::ToString($hash) -replace '-', ''
  $sha.Dispose()
  return $result
}

function New-Package([string]$ZipPath, [string[]]$Paths) {
  $parent = Split-Path -Parent $ZipPath
  if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }
  if (Test-Path -LiteralPath $ZipPath) { Remove-Item -LiteralPath $ZipPath -Force }
  $archive = [System.IO.Compression.ZipFile]::Open($ZipPath, [System.IO.Compression.ZipArchiveMode]::Create)
  try {
    foreach ($p in ($Paths | Sort-Object { Split-Path -Leaf $_ })) {
      [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
        $archive, $p, (Split-Path -Leaf $p), [System.IO.Compression.CompressionLevel]::Optimal)
    }
  } finally {
    $archive.Dispose()
  }
}

function Invoke-Packages {
  $ProjectRoot = Split-Path -Parent $Root
  $PackRoot = Join-Path $Root 'assets\macropackages'
  $ManifestPath = Join-Path $PackRoot 'manifest.json'

  $macroSlugs = @()
  foreach ($cat in $Site.sections.macrohub.categories) {
    foreach ($item in $cat.items) { $macroSlugs += $item.slug }
  }

  $oldManifest = $null
  if (Test-Path -LiteralPath $ManifestPath) {
    $oldManifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
  }

  $packages = [ordered]@{}
  $allPaths = @{}
  foreach ($slug in $macroSlugs) {
    $paths = @()
    foreach ($n in (Get-Closure $slug)) {
      if ($Macros.ContainsKey($n)) { $paths += $Macros[$n].Path }
    }
    if ($paths.Count -gt 1) { $packages[$slug] = $paths }
    foreach ($p in $paths) { $allPaths[(Split-Path -Leaf $p)] = $p }
  }
  $packages['__all__'] = @($allPaths.Values)

  $manifest = [ordered]@{}
  foreach ($key in $packages.Keys) {
    $paths = @($packages[$key])
    $names = @($paths | ForEach-Object { Split-Path -Leaf $_ } | Sort-Object)
    $fingerprint = Get-PackageFingerprint $paths
    $manifest[$key] = [ordered]@{ files = $names; fingerprint = $fingerprint }

    $zipName = $key
    if ($key -eq '__all__') { $zipName = 'macrohub' }
    $zipPath = Join-Path $PackRoot ($zipName + '.zip')

    $fresh = $false
    if (Test-Path -LiteralPath $zipPath) {
      if ($null -ne $oldManifest -and $null -ne $oldManifest.$key -and $oldManifest.$key.fingerprint -eq $fingerprint) {
        $fresh = $true
      }
    }
    if (-not $fresh) {
      if ($Check) {
        [void]$Issues.Add('STALE-PACKAGE: macropackages/' + $zipName + '.zip')
      } else {
        New-Package $zipPath $paths
        $script:Changed++
      }
    }
  }
  Save-File $ManifestPath (($manifest | ConvertTo-Json -Depth 5) + "`r`n")

  # drop packages that no longer belong to the site (removed macros)
  if (Test-Path -LiteralPath $PackRoot) {
    $expected = @()
    foreach ($key in $packages.Keys) {
      $zipName = $key
      if ($key -eq '__all__') { $zipName = 'macrohub' }
      $expected += ($zipName + '.zip')
    }
    Get-ChildItem -LiteralPath $PackRoot -Filter *.zip -File | ForEach-Object {
      if ($expected -notcontains $_.Name) {
        if ($Check) {
          [void]$Issues.Add('UNEXPECTED-PACKAGE: assets/macropackages/' + $_.Name)
        } else {
          Remove-Item -LiteralPath $_.FullName -Force
          $script:Changed++
        }
      }
    }
  }

  # pages: plain href to the sibling package folder, no client-side script
  $zipLinkRe = '<p class="download"><a href="#" data-zip="[^"]*"[^>]*>[^<]*</a></p>'
  $zipHrefRe = '<p class="download"><a href="[^"]*codehub/macro/zips/[^"]*"[^>]*>[^<]*</a></p>'
  $zipPackRe = '<p class="download"><a href="[^"]*macropackages/[^"]*"[^>]*>[^<]*</a></p>'
  $sasLinkRe = '<p class="download"><a href="[^"]*\.sas" download>[^<]*</a></p>'
  $zipScript = '<script src="../assets/macrohub-zip.js"></script>'

  foreach ($slug in $macroSlugs) {
    $pagePath = Join-Path (Join-Path $Root 'macrohub') ($slug + '.html')
    if (-not (Test-Path -LiteralPath $pagePath)) { continue }
    $text = Read-Text $pagePath
    $text = [regex]::Replace($text, $zipLinkRe + '\r?\n?', '')
    $text = [regex]::Replace($text, $zipHrefRe + '\r?\n?', '')
    $text = [regex]::Replace($text, $zipPackRe + '\r?\n?', '')
    $text = [regex]::Replace($text, [regex]::Escape($zipScript) + '\r?\n?', '')

    if ($packages.Contains($slug)) {
      $link = '<p class="download"><a href="../assets/macropackages/' + $slug + '.zip" download>' + $slug + ' and its dependencies.zip</a></p>'
      $rx = [regex]$sasLinkRe
      $text = $rx.Replace($text, ('$0' + "`r`n" + $link), 1)
    }
    Save-File $pagePath $text
  }

  $indexPath = Join-Path (Join-Path $Root 'macrohub') 'index.html'
  if (Test-Path -LiteralPath $indexPath) {
    $text = Read-Text $indexPath
    $text = [regex]::Replace($text, [regex]::Escape($zipScript) + '\r?\n?', '')
    $rx = [regex]'<p class="download zip-download">.*?</p>'
    $link = '<p class="download zip-download"><a href="../assets/macropackages/macrohub.zip" download>macrohub.zip</a></p>'
    if ($rx.IsMatch($text)) { $text = $rx.Replace($text, $link, 1) }
    Save-File $indexPath $text
  }

  # the site must carry no source code and no legacy ZIP assets
  foreach ($f in @(
      (Join-Path $Root 'assets\macrohub-zip.js'),
      (Join-Path $Root 'assets\zip-manifest.json'),
      (Join-Path $Root 'assets\macrohub-zip-data.js'))) {
    if (Test-Path -LiteralPath $f) {
      if ($Check) { [void]$Issues.Add('OBSOLETE: ' + $f.Substring($Root.Length + 1)) }
      else { Remove-Item -LiteralPath $f -Force; $script:Changed++ }
    }
  }
  $zipAssetDir = Join-Path $Root 'assets\zip'
  if (Test-Path -LiteralPath $zipAssetDir) {
    if ($Check) { [void]$Issues.Add('OBSOLETE: assets/zip (embedded source) should be removed') }
    else { Remove-Item -LiteralPath $zipAssetDir -Recurse -Force; $script:Changed++ }
  }
  $oldPackDir = Join-Path $ProjectRoot 'macropackages'
  if (Test-Path -LiteralPath $oldPackDir) {
    if ($Check) { [void]$Issues.Add('OBSOLETE: project/macropackages (moved to sashelp/assets) should be removed') }
    else { Remove-Item -LiteralPath $oldPackDir -Recurse -Force; $script:Changed++ }
  }
  $codehubZips = Join-Path $ProjectRoot 'codehub\macro\zips'
  if (Test-Path -LiteralPath $codehubZips) {
    if ($Check) { [void]$Issues.Add('CODEHUB-DIRTY: codehub/macro/zips must not exist') }
    else { Remove-Item -LiteralPath $codehubZips -Recurse -Force; $script:Changed++ }
  }
}

# ------------------------------------------------------------------------ run
$MacroItems = Invoke-Section 'macrohub'
$KbItems    = Invoke-Section 'knowledgebase'
Invoke-Index 'macrohub' $MacroItems
Invoke-Index 'knowledgebase' $KbItems
Invoke-SearchIndex
Invoke-Conventions 'macrohub'
Invoke-Conventions 'knowledgebase'
Invoke-Gallery
Invoke-Packages
Test-UndeclaredDeps @($MacroItems | ForEach-Object { $_.Slug })

if ($Warnings.Count -gt 0) {
  Write-Host ('Warnings: ' + $Warnings.Count) -ForegroundColor Yellow
  foreach ($w in $Warnings) { Write-Host ('  ' + $w) }
}

if ($Check) {
  if ($Issues.Count -gt 0) {
    Write-Host ('CHECK FAILED: ' + $Issues.Count + ' issue(s)') -ForegroundColor Red
    foreach ($i in $Issues) { Write-Host ('  ' + $i) }
    exit 1
  }
  Write-Host ('CHECK OK: ' + (@($MacroItems).Count) + ' macros, ' + (@($KbItems).Count) + ' knowledge entries') -ForegroundColor Green
  exit 0
}

Write-Host ('BUILD OK: ' + $script:Changed + ' file(s) updated; ' + (@($MacroItems).Count) + ' macros, ' + (@($KbItems).Count) + ' knowledge entries') -ForegroundColor Green
if ($Issues.Count -gt 0) {
  Write-Host ('Issues: ' + $Issues.Count) -ForegroundColor Yellow
  foreach ($i in $Issues) { Write-Host ('  ' + $i) }
}
