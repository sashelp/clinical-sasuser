<#
.SYNOPSIS
    将指定文件从 UTF-8（无 BOM 或带 BOM）转换为 GB2312（CP936）编码。
    支持一次处理多个文件，支持拖放（由 .bat 调用）。
#>

param(
    [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
    [string[]]$Files
)

if (-not $Files -or $Files.Count -eq 0) {
    Write-Host "用法：将文件拖放到 convert_to_gb2312.bat 上，或直接调用本脚本并传入文件路径。"
    Write-Host "示例：powershell -NoProfile -ExecutionPolicy Bypass -File convert_to_gb2312.ps1 \"file1.txt\" \"file2.txt\""
    exit 1
}

# 准备编码对象
$utf8 = New-Object System.Text.UTF8Encoding($false,$true)
try {
    $gb2312 = [System.Text.Encoding]::GetEncoding("GB2312")
} catch {
    $gb2312 = [System.Text.Encoding]::GetEncoding(936)
}

foreach ($inputPath in $Files) {
    # 支持通配符和单文件路径
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

        # 二进制检测
        if ($bytes -contains 0) {
            Write-Host "可能为二进制文件，跳过: $path"
            continue
        }

        # 如果带 BOM, 移除 BOM 后按 UTF8 解码
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            $text = $utf8.GetString($bytes, 3, $bytes.Length - 3)
        } else {
            # 尝试按 UTF-8 解码
            try {
                $text = $utf8.GetString($bytes)
            } catch {
                Write-Host "不是有效 UTF-8 文本，跳过: $path"
                continue
            }
        }

        # 写回为 GB2312（覆盖）
        try {
            [System.IO.File]::WriteAllText($path, $text, $gb2312)
            Write-Host "已转换为 GB2312: $path"
        } catch {
            Write-Host "写入失败: $path - $_"
        }
    }
}
