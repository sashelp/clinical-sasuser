# clinical-sasuser

临床试验 SAS 编程资源库：可复用宏、验收测试、GTL 图形模板与可视化知识站点。

## 内容

- `codehub/macro/dev`：21 个自研 SAS 宏 + 12 个开源导入宏
- `codehub/macro/qc`：21 个宏的验收测试，覆盖正测试、负测试与缺陷回归
- `codehub/gallery`：41 个 GTL 图形模板及同名 RTF 输出
- `codehub/script`：编码转换、文档转换等小工具
- `sashelp`：纯静态站点（宏程序库 / 知识库 / 图形库 / 关于）

## 快速开始

浏览站点：直接用浏览器打开 `sashelp/index.html`，或部署到 GitHub Pages。

运行验收测试（在 `codehub/macro` 下）：

```powershell
powershell -ExecutionPolicy Bypass -File qc\run_all.ps1 -List
powershell -ExecutionPolicy Bypass -File qc\run_all.ps1 -Macro stat_summaryc
```

重建站点（在 `sashelp` 下）：

```powershell
powershell -File build\build.ps1
powershell -File build\build.ps1 -Check
```

## 约定

- 验收时只运行目标宏的测试，不执行全量套件。
- 测试文件第 2 行固定为 `* <文件名>.sas - <一句话描述>`。
- 负测试一个错误场景一个文件。
- `sashelp/build/build.ps1` 只读 `codehub`，不回写源码。

## 环境

- SAS 9.4M7（UTF-8 或 EUC-CN 配置均可）
- Windows PowerShell 5.1

## 文档

- 项目进展与待办：[PROGRESS.md](PROGRESS.md)
- 验收测试框架：[codehub/macro/qc/README.md](codehub/macro/qc/README.md)

## License

[MIT](LICENSE) © 2026 Luo Hao
