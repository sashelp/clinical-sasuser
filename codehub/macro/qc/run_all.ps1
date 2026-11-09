#==============================================================================
# run_all.ps1 - SAS macro acceptance test runner
#==============================================================================
# Scans qc\<theme>\<macro>\ for positive (*_test.sas), negative (*_err_*.sas)
# and bug-regression (*_bug_*.sas) test programs, runs each one in its own
# SAS session and parses the SAS log for the QC protocol markers emitted by
# qc_framework.sas.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File qc\run_all.ps1
#       run every macro's tests
#   powershell -ExecutionPolicy Bypass -File qc\run_all.ps1 -Macro sdtm_fulldomain
#       run only the tests under qc\<theme>\sdtm_fulldomain\
#   powershell -ExecutionPolicy Bypass -File qc\run_all.ps1 -Macro ds_attr,sdtm_fulldomain
#       run several macros; wildcards are supported, e.g. -Macro 'var_*'
#   powershell -ExecutionPolicy Bypass -File qc\run_all.ps1 -List
#       list macros that have acceptance tests, then exit
#
# Outputs:
#   qc\_results\qc_summary_YYYYmmdd_HHMMSS[_<macro filter>].txt
#   qc\_results\qc_summary_YYYYmmdd_HHMMSS[_<macro filter>].html
#   qc\<theme>\<macro>\logs\<testfile>.log
#
# Report layout (both .txt and .html)
#   1. Macro Summary   -- one row per macro: positive / negative / bug-track
#                         results and an overall verdict (PASS/FAIL/DEFECT)
#   2. Per-Test Detail -- one row per test program, with a DESCRIPTION column
#                         taken from the header block of the test program
#                         ("<file>.sas - <description>", normally line 2), and a
#                         REVISION column that suggests what to change in
#                         dev/<theme>/<macro>.sas when a test is FAIL / DEFECT /
#                         ERROR (see $RevMap below)
#==============================================================================

param(
  [string[]]$Macro = @(),
  [switch]$List
)

$ErrorActionPreference = 'Continue'

# ---------- configuration ----------
# QcRoot is the folder that contains this script, so the harness can be moved
# or synced across machines without editing a path.
$QcRoot  = $PSScriptRoot
$SasExe  = if ($env:SAS_EXE) { $env:SAS_EXE } else {
  (Get-Command -Name sas.exe -CommandType Application -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty Source)
}
$SasCfg  = $env:SAS_CFG
#----------------------------------------------------------------

$ResDir   = Join-Path $QcRoot '_results'
New-Item -ItemType Directory -Force -Path $ResDir | Out-Null

# temporary sandbox container used by %qc_sandbox_reset; removed after each
# test program so no run can inherit files from another program/session
$SandboxTmp = Join-Path $QcRoot '_sandbox_tmp'
if (Test-Path -LiteralPath $SandboxTmp) {
  Remove-Item -LiteralPath $SandboxTmp -Recurse -Force -ErrorAction SilentlyContinue
}

# ---------- collect test programs ----------
$AllTests = @(
  Get-ChildItem -LiteralPath $QcRoot -Recurse -File | Where-Object {
    $_.Extension -eq '.sas' -and
    $_.FullName -notmatch '[\\/]_framework[\\/]' -and
    $_.Name -match '(_test\.sas$|_err_\d+\.sas$|_bug_.*\.sas$)'
  }
) | Sort-Object FullName

# macro names are the parent folder names of the test programs
$AvailableMacros = @($AllTests | ForEach-Object { $_.Directory.Name } | Sort-Object -Unique)

if ($List) {
  Write-Host 'Macros with acceptance tests:' -ForegroundColor Cyan
  foreach ($am in $AvailableMacros) {
    $cnt = @($AllTests | Where-Object { $_.Directory.Name -eq $am }).Count
    Write-Host ("  {0,-20} {1} test program(s)" -f $am, $cnt)
  }
  exit 0
}

if (-not $SasExe) {
  throw 'Set SAS_EXE or add sas.exe to PATH before running QC tests.'
}
if (-not $SasCfg -or -not (Test-Path -LiteralPath $SasCfg -PathType Leaf)) {
  throw 'Set SAS_CFG to a valid local SAS configuration file before running QC tests.'
}

# ---------- optional MACRO filter ----------
# accept both "-Macro a,b" (one comma separated string) and "-Macro a -Macro b"
$Macro = @(
  $Macro |
    Where-Object { $_ } |
    ForEach-Object { $_ -split ',' } |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne '' }
)

$Tests = if ($Macro.Count -eq 0) {
  $AllTests
} else {
  @($AllTests | Where-Object {
    $folder = $_.Directory.Name
    $stem   = $_.BaseName
    $hit = $false
    foreach ($pat in $Macro) {
      if ($folder -like $pat -or $stem -like ($pat + '*')) { $hit = $true; break }
    }
    $hit
  })
}

if ($Macro.Count -gt 0) {
  foreach ($pat in $Macro) {
    $cnt = @($AllTests | Where-Object {
      $_.Directory.Name -like $pat -or $_.BaseName -like ($pat + '*')
    }).Count
    if ($cnt -eq 0) {
      Write-Host ("WARNING: MACRO filter '{0}' matched no test programs." -f $pat) -ForegroundColor Yellow
    }
  }
}

if ($Tests.Count -eq 0) {
  if ($Macro.Count -gt 0) {
    Write-Host ("No test files found for MACRO filter: {0}" -f ($Macro -join ', ')) -ForegroundColor Red
    Write-Host ("Available macros: {0}" -f ($AvailableMacros -join ', '))
  } else {
    Write-Host 'No test files found.'
  }
  exit 1
}

$filterLabel = if ($Macro.Count -gt 0) { " (MACRO filter: $($Macro -join ', '))" } else { '' }
Write-Host ("Found {0} test programs{1}." -f $Tests.Count, $filterLabel) -ForegroundColor Cyan

$Results = @()

foreach ($T in $Tests) {
  $Rel    = $T.FullName.Substring($QcRoot.Length).TrimStart('\')
  $Stem   = [System.IO.Path]::GetFileNameWithoutExtension($T.Name)
  $TmpDir = Split-Path -Parent $T.FullName
  $LogDir = Join-Path $TmpDir 'logs'
  New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
  $LogF   = Join-Path $LogDir ($Stem + '.log')

  Write-Host ("  Running {0}" -f $Rel) -NoNewline

  # use System.Diagnostics.Process with a 120s timeout guard
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName               = $SasExe
  $psi.Arguments              = "-CONFIG `"$SasCfg`" -SYSIN `"$($T.FullName)`" -LOG `"$LogF`" -PRINT NONE -NOICON -NOSYNCHIO"
  $psi.UseShellExecute        = $false
  $psi.CreateNoWindow         = $true
  $proc = [System.Diagnostics.Process]::Start($psi)
  if (-not $proc.WaitForExit(120000)) {
    Write-Host ' TIMEOUT (killed)' -ForegroundColor Red
    try { $proc.Kill() } catch {}
  } else {
    $proc.WaitForExit()
  }
  Start-Sleep -Milliseconds 300

  $logText = if (Test-Path -LiteralPath $LogF) { Get-Content -LiteralPath $LogF -Raw } else { '' }

  $resultLine = ($logText -split "`r?`n") | Where-Object { $_ -match '^#####QC_RESULT' } | Select-Object -First 1

  $isNeg = ($T.Name -match '_err_\d+\.sas$')
  $isBug = ($T.Name -match '_bug_.*\.sas$')

  if (-not $isNeg -and -not $isBug) {
    # ----- positive test: expect QC_RESULT ----
    if ($resultLine) {
      $m = [regex]::Match($resultLine, 'STATUS=(\w+) ncase=(\d+) npass=(\d+) nfail=(\d+)')
      if ($m.Success) {
        $Results += [pscustomobject]@{
          File = $Rel; Kind='positive'; Status=$m.Groups[1].Value
          NCase=[int]$m.Groups[2].Value; NPass=[int]$m.Groups[3].Value; NFail=[int]$m.Groups[4].Value
          Detail = if ($m.Groups[1].Value -eq 'PASS') { '' } else { 'failed assertions' }
          Exit=$proc.ExitCode
        }
        Write-Host (" {0} (ncase={1} npass={2} nfail={3})" -f $m.Groups[1].Value, $m.Groups[2].Value, $m.Groups[3].Value, $m.Groups[4].Value) -ForegroundColor $(if ($m.Groups[1].Value -eq 'PASS') {'Green'} else {'Red'})
      } else {
        $Results += [pscustomobject]@{ File=$Rel; Kind='positive'; Status='ERROR'; NCase=0; NPass=0; NFail=0; Detail='could not parse QC_RESULT'; Exit=$proc.ExitCode }
        Write-Host ' ERROR (unparsable result)' -ForegroundColor Red
      }
    } else {
      $Results += [pscustomobject]@{ File=$Rel; Kind='positive'; Status='ERROR'; NCase=0; NPass=0; NFail=0; Detail='no QC_RESULT marker - job aborted early or crashed'; Exit=$proc.ExitCode }
      Write-Host ' ERROR (no QC_RESULT)' -ForegroundColor Red
    }
  }
  elseif ($isBug) {
    # ----- bug regression: defect still present vs fixed -----
    if ($resultLine -and $resultLine -match 'STATUS=PASS') {
      $Results += [pscustomobject]@{ File=$Rel; Kind='bug-regression'; Status='FIXED'; NCase=0; NPass=0; NFail=0; Detail='defect no longer reproduces (test now PASSES)'; Exit=$proc.ExitCode }
      Write-Host ' FIXED (defect gone)' -ForegroundColor Green
    } else {
      $Results += [pscustomobject]@{ File=$Rel; Kind='bug-regression'; Status='DEFECT'; NCase=0; NPass=0; NFail=0; Detail='known defect reproduced (macro fails to meet spec); fix then rerun to see FIXED'; Exit=$proc.ExitCode }
      Write-Host ' DEFECT (still present)' -ForegroundColor Yellow
    }
  }
  else {
    # ----- negative test: the macro must abort -----
    $src = Get-Content -LiteralPath $T.FullName -Raw
    $em  = [regex]::Match($src, '\*EXPECTED_ERROR:\s*([^\r\n;]+);')
    $expected = if ($em.Success) { $em.Groups[1].Value.Trim() } else { '' }

    $hasExpected = $expected -ne '' -and $logText -match [regex]::Escape($expected)
    $hasContinue = $logText -match 'QC_UNEXPECTED_CONTINUE|^#####QC_RESULT'
    $hasMarker   = $logText -match 'QC_ABORT_MARKER'

    $ok = $hasExpected -and (-not $hasContinue)
    $status = if ($ok) { 'PASS' } else { 'FAIL' }

    $detailParts = @()
    if ($expected -eq '')   { $detailParts += 'no EXPECTED_ERROR keyword in source' }
    if (-not $hasExpected)  { $detailParts += "expected error text not found in log: '$expected'" }
    if ($hasContinue)       { $detailParts += 'macro did NOT abort (unexpected continue / result produced)' }
    if (-not $hasMarker)    { $detailParts += 'QC_ABORT_MARKER not found' }

    $Results += [pscustomobject]@{
      File=$Rel; Kind='negative'; Status=$status; NCase=1
      NPass = $(if ($ok) {1} else {0}); NFail = $(if ($ok) {0} else {1})
      Detail = ($detailParts -join '; '); Exit=$proc.ExitCode
    }
    Write-Host (" {0} (abort-as-expected)" -f $status) -ForegroundColor $(if ($ok) {'Green'} else {'Red'})
  }

  # remove this program's temporary sandbox now that the SAS session has ended
  if (Test-Path -LiteralPath $SandboxTmp) {
    Remove-Item -LiteralPath $SandboxTmp -Recurse -Force -ErrorAction SilentlyContinue
  }
}
# ---------- per-macro roll-up ----------
# Each $Results entry has File like "theme\macro\macro_test.sas".  Group them
# by macro so the report can show a one-row-per-macro summary.
$MacroInfo = foreach ($r in $Results) {
  $parts = $r.File -split '\\'
  [pscustomobject]@{
    Theme  = if ($parts.Count -ge 1) { $parts[0] } else { '' }
    Macro  = if ($parts.Count -ge 2) { $parts[1] } else { [System.IO.Path]::GetFileNameWithoutExtension($r.File) }
    Kind   = $r.Kind
    Status = $r.Status
    File   = $r.File
  }
}
$MacroNames = $MacroInfo | Select-Object Theme, Macro -Unique | Sort-Object Theme, Macro

$macroRows = foreach ($mn in $MacroNames) {
  $mTests  = $MacroInfo | Where-Object { $_.Theme -eq $mn.Theme -and $_.Macro -eq $mn.Macro }
  $pos     = ($mTests | Where-Object Kind -eq 'positive' | Select-Object -First 1)
  $negs    = @($mTests | Where-Object Kind -eq 'negative')
  $bugs    = @($mTests | Where-Object Kind -eq 'bug-regression')

  $posStr  = if ($pos) { $pos.Status } else { '-' }
  $negStr  = if ($negs.Count -gt 0) {
    $np = @($negs | Where-Object Status -eq 'PASS').Count
    $nf = @($negs | Where-Object Status -eq 'FAIL').Count
    if ($nf -gt 0) { ("{0}/{1} PASS ({2} FAIL)" -f $np, $negs.Count, $nf) }
    else           { ("{0}/{1} PASS"       -f $np, $negs.Count) }
  } else { '-' }
  $bugStr  = if ($bugs.Count -gt 0) {
    $bd = @($bugs | Where-Object Status -eq 'DEFECT').Count
    $bf = @($bugs | Where-Object Status -eq 'FIXED').Count
    ("{0} DEFECT{1}" -f $bd, $(if ($bf -gt 0) { (", {0} FIXED" -f $bf) } else { '' }))
  } else { '-' }

  $hasFail = @($mTests | Where-Object { $_.Status -eq 'FAIL' -or $_.Status -eq 'ERROR' }).Count
  $hasDef  = @($mTests | Where-Object Status -eq 'DEFECT').Count
  $verdict = if ($hasFail -gt 0) { 'FAIL' }
             elseif ($hasDef -gt 0) { 'DEFECT' }
             else { 'PASS' }

  [pscustomobject]@{
    Theme=$mn.Theme; Macro=$mn.Macro; Positive=$posStr; Negative=$negStr;
    Bug=$bugStr; Verdict=$verdict
  }
}

# ---------- per-test fix recommendations ----------
$RevMap = @{
  'lib\lib_memlist\lib_memlist_err_03.sas'   = 'dev/lib/lib_memlist.sas: %macro 声明补 /minoperator，使 TYPE= 的 IN 校验生效'
  'lib\lib_memlist\lib_memlist_bug_typepattern.sas' = 'dev/lib/lib_memlist.sas: TYPE= 与 PATTERN= 校验拆为两个独立 %if 块，避免 %else 链跳过 PATTERN'
  'lib\lib_zipvarlen\lib_zipvarlen_err_03.sas' = 'dev/lib/lib_zipvarlen.sas: %macro 补 /minoperator（DELFMT= 校验）'
  'lib\lib_zipvarlen\lib_zipvarlen_err_04.sas' = 'dev/lib/lib_zipvarlen.sas: %macro 补 /minoperator（DELINFMT= 校验）'
  'lib\lib_zipvarlen\lib_zipvarlen_err_05.sas' = 'dev/lib/lib_zipvarlen.sas: %macro 补 /minoperator（SUPP_POLICY= 校验）'
  'lib\lib_zipvarlen\lib_zipvarlen_bug_delfmt.sas' = 'dev/lib/lib_zipvarlen.sas: 2.1 节 call execute 转发 delfmt/delinfmt 给 %ds_zipvarlen'
  'ds\ds_zipvarlen\ds_zipvarlen_bug_nochar.sas' = 'dev/ds/ds_zipvarlen.sas: %cvarlist 为空时避免 %sysfunc(countw(&cvarlist.)) 无参调用（先 %bquote 判空）'
  'cdisc\sdtm_fulldomain\sdtm_fulldomain_bug_nolabel.sas' = 'dev/cdisc/sdtm_fulldomain.sas: 合并前按元数据判断 _LABEL_ 是否存在再决定 drop（QVAL 无标签时 PROC TRANSPOSE 不生成 _LABEL_）'
  'cdisc\sdtm_fulldomain\sdtm_fulldomain_bug_chidvar.sas' = 'dev/cdisc/sdtm_fulldomain.sas: 先判断父域 IDVAR 变量类型；字符型 IDVAR 不应 input(idvarval,best.) 转成数值键'
  'stat\stat_rateci\stat_rateci_err_13.sas' = '已修正 2026-10-30：0 观测检查前移到参数校验链首位（第 61 行），BY= 非空时同样生效'
  'stat\stat_rateci\stat_rateci_bug_noby.sas' = '已修正 2026-10-30：2.1.2 增加 BY= 为空的独立 SQL 分支（select b.* c.* / group by b.&class. c.&var.）'
  'stat\stat_rateci\stat_rateci_bug_dmethod_all.sas' = '已修正 2026-10-30：第 121 行改为 "%if &dmethod.=ALL"'
  'stat\stat_rateci\stat_rateci_bug_riskdifflevel.sas' = 'dev/stat/stat_rateci.sas: 2.3.2 的 column=&levelnumber. 依赖各 class 内 VAR= 的出现顺序；PROC FREQ 前按 _pair_ &BY. 与水平标记排序，保证 LEVEL= 恒为第一列'
  'stat\stat_rateci\stat_rateci_bug_smethod_all.sas' = '已修正 2026-10-30：SMETHOD=ALL 展开为 AC BLAKER EXACT JEFFREYS LR LOGIT MIDP WALD WILSON（宏头注释仍写 6 种，建议同步更新）'
  'stat\stat_summaryc\stat_summaryc_bug_allmissvar.sas' = 'dev/stat/stat_summaryc.sas：VAR= 全缺失时 PROC FREQ 不生成 crosstabfreqs，需在 2.3 前判空并直接构造总计行'
  'stat\stat_summaryn\stat_summaryn_bug_gmlabel.sas' = 'dev/stat/stat_summaryn.sas: LABEL 语句为 __stat_gm_lclm 与 __stat_gm_uclm 补标签（如 GM 95% CI Lower / Upper）'
  'cdisc\sdtm_epoch\sdtm_epoch_bug_gatevar.sas' = '已修正 2026-11-09：第 61 行匹配门控改为 if &dtc.^=''''，不再依赖 VSDTC；缺陷回归保留'
  'cdisc\sdtm_lobxfl\sdtm_lobxfl_bug_compile.sas' = 'dev/cdisc/sdtm_lobxfl.sas: 第 130-131 行改为先 %let 最后一个 BY 变量（BY= 为空时取最后一个 SUBJECT 变量）再直接拼接 IF 语句，避免 %STR 内嵌 %SCAN 丢失空格分隔符；此前的多余 %END 已于 2026-11-07 21:40 移除'
  'cdisc\sdtm_lobxfl\sdtm_lobxfl_test.sas' = 'dev/cdisc/sdtm_lobxfl.sas: 修复第 130-131 行 IF 语句生成缺陷后再复核值级断言；%SCAN ERROR 会使 SAS 进入语法检查模式并使全部用例失败'
  'dir\dir_attr\dir_attr_err_03.sas' = 'dev/dir/dir_attr.sas: ATTR= 校验正则的 ^$ 分支使空值通过 prxmatch，需先判空再校验 ATTR= 并 %abort cancel'
  'dir\dir_memlist\dir_memlist_bug_quoted.sas' = 'dev/dir/dir_memlist.sas: 构建根记录前对 DIR= 应用 %qsysfunc(dequote(&dir.))，否则路径保留引号且成员 fopen 失败被全部误判为 Directory'
}

function Get-Rev($r) {
  if ($RevMap.ContainsKey($r.File)) { return $RevMap[$r.File] }
  if ($r.Status -eq 'PASS')  { return '-' }
  if ($r.Status -eq 'FIXED') { return '-' }
  if ($r.Status -eq 'FAIL') {
    if ($r.Kind -eq 'negative') { return '修复宏：使非法/缺失参数按预期报错并 %abort cancel' }
    return '检查日志，修复宏输出或修正测试断言'
  }
  if ($r.Status -eq 'DEFECT') { return '修复缺陷后重跑，预期转为 FIXED' }
  return '检查日志定位原因'
}

$Rev = foreach ($r in $Results) { Get-Rev $r }

# ---------- per-test description ----------
# Every test program starts with a header block whose second line reads
#   * <file>.sas - <short description>
# (e.g. "* stat_countocc_err_01.sas - Negative test: DATA= empty").
# Descriptions are capped at $DescMax characters so the .txt table keeps its
# column alignment; the .txt DESCRIPTION column is sized to the longest
# description found (capped at $DescMax, at least the header width).
$DescMax = 200

function Get-Desc([string]$path) {
  $base = [System.IO.Path]::GetFileNameWithoutExtension($path)
  $head = @(Get-Content -LiteralPath $path -TotalCount 3 -ErrorAction SilentlyContinue)
  foreach ($ln in $head) {
    if (-not $ln) { continue }
    $m = [regex]::Match($ln, '^\s*[*/#]+\s*' + [regex]::Escape($base) + '\.sas\s+-\s+(.+?)\s*(\*/)?\s*$')
    if ($m.Success) {
      $d = $m.Groups[1].Value.Trim()
      if ($d.Length -gt $DescMax) { $d = $d.Substring(0, $DescMax) }
      return $d
    }
  }
  return '-'
}

$Desc = foreach ($r in $Results) { Get-Desc (Join-Path $QcRoot $r.File) }

$DescW = 11
if ($Desc.Count -gt 0) {
  $maxLen = ($Desc | Measure-Object -Property Length -Maximum).Maximum
  if ($maxLen -gt $DescW) { $DescW = [Math]::Min([int]$maxLen, $DescMax) }
}

# ---------- summary ----------
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$tag = ''
if ($Macro.Count -gt 0) {
  $tag = '_' + (($Macro | ForEach-Object { $_ -replace '[^A-Za-z0-9_.-]', '-' }) -join '-')
}
$txtOut = Join-Path $ResDir ("qc_summary_{0}{1}.txt" -f $stamp, $tag)
$htmlOut = Join-Path $ResDir ("qc_summary_{0}{1}.html" -f $stamp, $tag)

$nPass = @($Results | Where-Object Status -eq 'PASS').Count
$nFail = @($Results | Where-Object Status -eq 'FAIL').Count
$nErr  = @($Results | Where-Object Status -eq 'ERROR').Count
$nDef  = @($Results | Where-Object Status -eq 'DEFECT').Count
$nFix  = @($Results | Where-Object Status -eq 'FIXED').Count
$nTot  = $Results.Count

$lines = @()
$lines += "SAS Macro Acceptance Test Summary"
$lines += "Generated : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
if ($Macro.Count -gt 0) {
  $lines += ("MACRO filter: {0}" -f ($Macro -join ', '))
}
$lines += ("Total tests: {0}   PASS: {1}   FAIL: {2}   ERROR: {3}   DEFECT: {4}   FIXED: {5}" -f $nTot, $nPass, $nFail, $nErr, $nDef, $nFix)
$lines += ""

# ----- macro-level summary table (one row per macro) -----
$lines += "Macro Summary"
$lines += ("{0,-12} {1,-16} {2,-10} {3,-22} {4,-16} {5}" -f 'THEME','MACRO','POSITIVE','NEGATIVE','BUG_TRACK','VERDICT')
$lines += ("{0,-12} {1,-16} {2,-10} {3,-22} {4,-16} {5}" -f '-----','-----','--------','--------','--------','-------')
foreach ($m in $macroRows) {
  $lines += ("{0,-12} {1,-16} {2,-10} {3,-22} {4,-16} {5}" -f $m.Theme, $m.Macro, $m.Positive, $m.Negative, $m.Bug, $m.Verdict)
}
$lines += ""

# ----- per-test detail table (with fix recommendation) -----
$rowFmt = "{0,-8} {1,-15} {2,-52} {3,-$DescW} {4,-8} {5,-8} {6,-46} {7}"
$lines += ($rowFmt -f 'STATUS','KIND','FILE','DESCRIPTION','NCASE','NFAIL','DETAIL','REVISION')
$lines += ($rowFmt -f '------','------------','----','-----------','-----','-----','-------','--------')
for ($i = 0; $i -lt $Results.Count; $i++) {
  $r = $Results[$i]
  $lines += ($rowFmt -f $r.Status, $r.Kind, $r.File, $Desc[$i], $r.NCase, $r.NFail, $r.Detail, $Rev[$i])
}
$lines | Set-Content -LiteralPath $txtOut -Encoding UTF8
Write-Host ""
Write-Host ("SUMMARY: {0}/{1} tests passed. See {2}" -f $nPass, $nTot, $txtOut) -ForegroundColor Cyan

# ---------- HTML report ----------
$esc = { param($s) if ($null -eq $s) {''} else { [System.Net.WebUtility]::HtmlEncode($s.ToString()) } }

$html = @"
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>SAS Macro QC Report</title></head>
<body>
<h2>SAS Macro Acceptance Test Report</h2>
<p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
$(if ($Macro.Count -gt 0) { "<p>Macro filter: <strong>$(& $esc ($Macro -join ', '))</strong></p>" })
<p><strong>$nPass / $nTot</strong> tests passed (FAIL: $nFail, ERROR: $nErr, DEFECT: $nDef, FIXED: $nFix)</p>
<h3>Macro Summary</h3>
<table border="1" cellpadding="4" cellspacing="0" style="border-collapse:collapse;font-family:Consolas,monospace;font-size:13px">
<tr style="background:#eceff1"><th>Theme</th><th>Macro</th><th>Positive</th><th>Negative</th><th>Bug Track</th><th>Verdict</th></tr>
$(
  foreach ($m in $macroRows) {
    $bgv = switch ($m.Verdict) { 'PASS' {'#e8f5e9'} 'FAIL' {'#ffebee'} 'DEFECT' {'#fff3e0'} default {'#f5f5f5'} }
    $tr = '<tr style="background:{0}"><td>{1}</td><td>{2}</td><td>{3}</td><td>{4}</td><td>{5}</td><td><strong>{6}</strong></td></tr>' -f `
      $bgv, (& $esc $m.Theme), (& $esc $m.Macro), (& $esc $m.Positive), (& $esc $m.Negative), (& $esc $m.Bug), (& $esc $m.Verdict)
    $tr
  }
)
</table>
<h3>Per-Test Detail</h3>
<table border="1" cellpadding="4" cellspacing="0" style="border-collapse:collapse;font-family:Consolas,monospace;font-size:13px">
<tr style="background:#eceff1"><th>Status</th><th>Kind</th><th align="left">File</th><th align="left">Description</th><th>NCase</th><th>NFail</th><th align="left">Detail</th><th align="left">Revision</th></tr>
$(
  for ($i = 0; $i -lt $Results.Count; $i++) {
    $r = $Results[$i]
    $bg = switch ($r.Status) { 'PASS' {'#e8f5e9'} 'FAIL' {'#ffebee'} 'DEFECT' {'#fff3e0'} 'FIXED' {'#e3f2fd'} default {'#f5f5f5'} }
    $revBg = if ($r.Status -in @('FAIL','ERROR')) { '#fff8e1' } elseif ($r.Status -eq 'DEFECT') { '#fff3e0' } else { 'transparent' }
    $tr = '<tr style="background:{0}"><td>{1}</td><td>{2}</td><td>{3}</td><td>{4}</td><td>{5}</td><td>{6}</td><td>{7}</td><td style="background:{8}">{9}</td></tr>' -f `
      $bg, (& $esc $r.Status), (& $esc $r.Kind), (& $esc $r.File), (& $esc $Desc[$i]), $r.NCase, $r.NFail, (& $esc $r.Detail), $revBg, (& $esc $Rev[$i])
    $tr
  }
)
</table>
</body>
</html>
"@
$html | Set-Content -LiteralPath $htmlOut -Encoding UTF8

if ($nFail -gt 0 -or $nErr -gt 0) { exit 1 } else { exit 0 }