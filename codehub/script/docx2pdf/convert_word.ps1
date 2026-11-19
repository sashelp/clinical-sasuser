# convert_word.ps1 — Word COM docx-to-PDF converter with bookmarks
param(
    [Parameter(Mandatory=$true)]
    [string]$InputPath,
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Resolve to absolute paths
$InputPath = [System.IO.Path]::GetFullPath($InputPath)
$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)

if (-not (Test-Path $InputPath)) {
    Write-Error "Input file not found: $InputPath"
    exit 1
}

# Ensure output directory exists
$outDir = Split-Path $OutputPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0  # wdAlertsNone — suppress all popups
    $word.ScreenUpdating = $false

    $doc = $word.Documents.Open($InputPath, $false, $true, $false)

    # ExportAsFixedFormat parameters:
    #   OutputFileName
    #   ExportFormat: 17 = wdExportFormatPDF
    #   OpenAfterExport: $false
    #   OptimizeFor: 1 = wdExportOptimizeForOnScreen
    #   Range: 0 = wdExportAllDocument
    #   IncludeDocProps: $true
    #   KeepIRM: $true
    #   CreateBookmarks: 1 = wdExportCreateHeadingBookmarks
    #   DocStructureTags: $true
    #   BitmapMissingFonts: $true
    #   UseISO19005_1: $false
    $doc.ExportAsFixedFormat(
        $OutputPath,
        17,        # wdExportFormatPDF
        $false,    # OpenAfterExport
        1,         # wdExportOptimizeForOnScreen
        0,         # wdExportAllDocument
        0, 0,      # StartPage, EndPage (0=all)
        0,         # wdExportDocumentContent
        $true,     # IncludeDocProps
        $true,     # KeepIRM
        1          # wdExportCreateHeadingBookmarks
    ) | Out-Null

    # Additional params via the newer overload (Word 2013+)
    # The above uses the 11-param overload. Some Word versions support more params.
    # If bookmarks aren't generated, we may need to use the full overload.
    
    $doc.Close($false)
    $word.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null

    Write-Output "OK: $OutputPath"
} catch {
    # Cleanup on error
    if ($doc) {
        $doc.Close($false)
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
    }
    if ($word) {
        $word.Quit()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
    }
    Write-Error "Conversion failed: $($_.Exception.Message)"
    exit 1
} finally {
    # Force garbage collection to release COM references
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}
