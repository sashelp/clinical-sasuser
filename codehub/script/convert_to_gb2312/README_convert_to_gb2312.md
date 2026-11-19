# 将 UTF-8 转为 GB2312 工具

文件：
- `convert_to_gb2312.ps1` - PowerShell 主脚本
- `convert_to_gb2312.bat` - 拖放包装器

用法：
- 将文件拖放到 `convert_to_gb2312.bat` 上，支持一次拖放多个文件。
- 或运行：

```
powershell -NoProfile -ExecutionPolicy Bypass -File convert_to_gb2312.ps1 "D:\temp\20260624\ds_attr.sas"
```

注意：
- 脚本仅尝试将 UTF-8（含 BOM 或无 BOM）文本转换为 GB2312，遇到非 UTF-8 文本会跳过。
- 若文件本来就是二进制或包含 NUL 字节，脚本会跳过该文件。
