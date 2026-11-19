# 转换为 UTF-8 带 BOM 工具

文件列表：
- `convert_to_utf8_bom.ps1` - PowerShell 主脚本，实现编码检测与转换。
- `convert_to_utf8_bom.bat` - 批处理包装器，支持将文件拖放到 .bat 上执行。

使用方法：
- 将要转换的文件或多个文件同时拖放到 `convert_to_utf8_bom.bat` 上。
- 或在 PowerShell 中手动运行：

```
powershell -NoProfile -ExecutionPolicy Bypass -File convert_to_utf8_bom.ps1 "file1.txt" "file2.txt"
```

说明：
- 脚本会跳过包含 NUL 字节的文件（可能为二进制）。
- 已带 UTF-8 BOM 的文件将被跳过。
- 默认尝试将非 UTF-8 文本按 GB2312 解码回文本，若失败将使用系统默认编码解码。
