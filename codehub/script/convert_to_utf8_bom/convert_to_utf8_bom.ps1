<#
.SYNOPSIS
    将指定文件从 UTF-8 或 GB2312 编码转换为带 BOM 的 UTF-8 编码。
    支持一次处理多个文件，支持拖放（由 .bat/.vbs 调用）。

.DESCRIPTION
    本脚本尝试检测文件是否为 UTF-8（无 BOM）或 GB2312（简体中文常见编码），
    并将其覆盖写回为带 BOM 的 UTF-8 编码。遇到明显的二进制文件（包含 NUL 字节）或
    已带 BOM 的文件将跳过。
#>

param(
    [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
    [string[]]$Files
)

if (-not $Files -or $Files.Count -eq 0) {
    Write-Host "用法：将文件拖放到 convert_to_utf8_bom.bat 或 convert_to_utf8_bom.vbs 上，或直接调用本脚本并传入文件路径。"
    Write-Host "示例：powershell -NoProfile -ExecutionPolicy Bypass -File convert_to_utf8_bom.ps1 \"file1.txt\" \"file2.txt\""
    exit 1
}

# 获取 GB2312 编码（若不可用则回退到 CP936 或系统默认）
try {
    $gbEnc = [System.Text.Encoding]::GetEncoding("GB2312")
} catch {
    try { $gbEnc = [System.Text.Encoding]::GetEncoding(936) } catch { $gbEnc = [System.Text.Encoding]::Default }
}

# UTF-8 编码对象：严格检查（无 BOM、遇错抛出）和写回时带 BOM 的对象
$utf8Strict = New-Object System.Text.UTF8Encoding($false,$true)
$utf8Bom = New-Object System.Text.UTF8Encoding($true,$false)

foreach ($inputPath in $Files) {
    # 支持通配符和单文件路径（兼容旧版 PowerShell，不使用 -File 参数）
    $items = @()
    try {
        $gci = Get-ChildItem -Path $inputPath -ErrorAction SilentlyContinue
        if ($gci) {
            foreach ($gi in $gci) {
                if (-not $gi.PSIsContainer) { $items += $gi }
            }
        }
    } catch {
        $items = @()
    }

    if (-not $items -or $items.Count -eq 0) {
        if (Test-Path $inputPath -PathType Leaf) {
            $items = @((Get-Item -LiteralPath $inputPath))
        } else {
            Write-Host "未找到: $inputPath"
            continue
        }
    }

    foreach ($item in $items) {
        $path = $item.FullName
        try {
            $bytes = [System.IO.File]::ReadAllBytes($path)
        } catch {
            Write-Host "读取失败: $path  - $_"
            continue
        }

        # 简单二进制检测：若包含 NUL 字节，则跳过
        if ($bytes -contains 0) {
            Write-Host "可能为二进制文件，跳过: $path"
            continue
        }

        # 若已有 UTF-8 BOM，则认为已是目标编码，跳过
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            Write-Host "已是 UTF-8 带 BOM: $path"
            continue
        }

        $text = $null
        $isUtf8 = $false
        try {
            # 若为有效 UTF-8（无 BOM），则转换成功，否则抛出
            $text = $utf8Strict.GetString($bytes)
            $isUtf8 = $true
        } catch {
            $isUtf8 = $false
        }

        if (-not $isUtf8) {
            try {
                $text = $gbEnc.GetString($bytes)
            } catch {
                try {
                    $text = [System.Text.Encoding]::Default.GetString($bytes)
                } catch {
                    Write-Host "无法识别编码，跳过: $path"
                    continue
                }
            }
        }

        # 覆盖写回为带 BOM 的 UTF-8
        try {
            [System.IO.File]::WriteAllText($path, $text, $utf8Bom)
            Write-Host "已转换为 UTF-8 带 BOM: $path"
        } catch {
            Write-Host "写入失败: $path - $_"
        }
    }
}
