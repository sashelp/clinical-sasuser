# 项目进展

> 状态快照（更新于 2026-11-19）+ 变更记录。每次有实质进展时追加到「变更记录」，
> 并同步修订上面的状态数字。

## 状态快照（2026-11-19）

### 仓库结构

- 仓库根目录为 `OneDrive\project\clinical-sasuser`（此前文档按 `OneDrive\project` 描述）；
  目录名统一为小写：`codehub\Macro` → `codehub\macro`，`SASHELP` → `sashelp`。
- 新增 `codehub\gallery`（图形模板库）、`codehub\script`（通用脚本）与 `LICENSE`（MIT）。
- 原根目录下的 `business\`、`Project_CodeHubSpec.7z` 已不在本仓库内。

### 宏库 `codehub\macro\dev`

- 自研宏 **21** 个 + `opensource` 导入宏 **12** 个，另有 `compile_all.sas` 与编译目录
  `sasmacr.sas7bcat`。`ds_splitvar` 已于 2026-11-19 删除。
- 主题目录 `var` `ds` `dir` `lib` `file` `stat` `cdisc` 有内容；
  `be` `log` `report` 为空占位。
- 新增 `.github\skills\sas-macro-development\SKILL.md`（本库宏开发约定）。

### 验收测试 `codehub\macro\qc`

- 覆盖 **21** 个宏、**229** 个测试程序（正测试 21 / 负测试 190 / 缺陷回归 18）。
- 框架 `_framework\` 4 个文件（`qc_env.sas`、`qc_framework.sas`、`qc_sandbox.sas`、
  `qc_testdata.sas`）；汇总器 `run_all.ps1`；报告在 `_results\`
  （当前 31 个文件：14 组报告 + 3 个持久数据集）。

| 主题 | dev 宏数 | qc 已测宏数 | 测试程序数 |
| --- | --- | --- | --- |
| var | 4 | 4 | 30 |
| ds | 4 | 4 | 26 |
| dir | 3 | 3 | 19 |
| lib | 2 | 2 | 13 |
| file | 1 | 1 | 4 |
| stat | 4 | 4 | 90 |
| cdisc | 3 | 3 | 47 |
| opensource | 12 | 0 | 0（外部代码，默认不验收） |

### 图形模板库 `codehub\gallery`

- **41** 个模板程序，每个都生成同名 RTF（`.sas` + `.rtf` 成对，共 41 对）：
  bar 4、box 7、scatter 8、series 16、survival 6。
- `forest` `histogram` `other` `panel` `reg` `tumor` 为空占位目录。
- 新增 `.github\skills\sas-graph-template\SKILL.md`（图形模板三段式约定）。

### 通用脚本 `codehub\script`

- 3 个带说明的工具目录：`convert_to_gb2312`、`convert_to_utf8_bom`、`docx2pdf`
  （含随附的 node / qpdf）。
- 9 个单文件脚本：`check_excel_formulas.vbs`、`copy_filenames.vbs`、`doc2txt.vbs`、
  `filename2lowcase.bat`、`find_sas_multibyte.vbs`、`kill_old_sas.ps1`、`lowername.vbs`、
  `rtf2docx.vbs`、`xml2html.py`。

### 站点 `sashelp`

- `site.json` 为唯一配置源，驱动 macrohub / knowledgebase / gallery 三个板块；
  `macroSource` 已更新为 `../codehub/macro/dev`。
- macrohub：**33** 个宏页面 + `conventions.html`；knowledgebase：**31** 条知识条目 +
  `conventions.html`；gallery：`index.html` + **41** 个详情页（bar 4、box 7、scatter 8、
  series 16、survival 6）。
- 新增根级 `about.html`：站点用途、GitHub Issues 意见入口、作者简介；
  根页「关于」已改为链接，三个板块页头均加入「关于」。
- `assets\macropackages\`：17 个 ZIP + `manifest.json`。
- `design\gen_gallery_html.sas` 从 Gallery 源程序生成站点页面；`build\build.ps1`
  刷新页头、导航、索引与依赖包，支持 `-Check` 漂移校验。

### 最近一次验收结果

- 全量：`qc_summary_20261109_140634`（2026-11-09 14:06:34），21 个宏、当时 222 个测试，
  0 FAIL / 0 ERROR、1 DEFECT、15 FIXED；除 `stat_summaryc` 外全部 PASS。
- 最近一次定向：`qc_summary_20261119_140638_stat_summaryc-stat_summaryn`
  （2026-11-19 14:06:38），47 个测试，43 PASS、0 FAIL、0 ERROR、1 DEFECT、3 FIXED：
  - `stat_summaryn` 整体 **PASS**（`bug_gmlabel` 已修复）
  - `stat_summaryc` 判 **DEFECT**：既有 `stat_summaryc_bug_allmissvar` 未修复；
    本次 `TOTCLASSID=` 默认值与 `n(nmiss)` 标签变更相关的用例全部通过

## 待办

1. **修复 `stat_summaryc` 全缺失列缺陷**：`VAR=` 全缺失时 `PROC FREQ` 不生成 crosstabfreqs，
   需在 2.3 前判空并直接构造总计行（报告 REVISION 列已给出指引）。
2. **全量重跑 `run_all.ps1`**：当前有 229 个测试程序，全量结论仍停留在 222 个测试时。
3. **`gen_gallery_html.sas` 路径仍为绝对路径**：顶部 `prog_path` / `html_path` / `tmpl_*`
   绑定本机目录，跨机或搬移后需手改；可参照 `qc_env.sas` 改为从 SYSIN 推导。
4. `gallery` 6 个空类型目录（forest / histogram / other / panel / reg / tumor）
   确认是补齐还是删除。
5. `opensource` 12 个导入宏是否需要抽检，待定（当前定位为外部维护代码）。
6. `be` / `log` / `report` 三个主题目录为空，确认是预留还是可删除。
7. **GitHub 后续配置**：仓库已上传并启用 Issues；GitHub Pages 尚未启用。
   `codehub\script\docx2pdf\node.exe`（88.2 MB）已随初始提交上传，如需瘦身需重写历史或迁移 LFS。

## 变更记录

### 2026-11-19（下午）

- 删除 `ds_splitvar`：移除 `dev\ds\ds_splitvar.sas`、`sashelp\macrohub\ds_splitvar.html`、
  `assets\macropackages\ds_splitvar.zip` 及 `site.json` 配置项；`qc\ds` 原本没有该宏的测试目录。
  删除后站点宏数为 33，依赖包为 17 个 ZIP + manifest。
- `stat_summaryc` / `stat_summaryn` 验收：按新契约（`TOTCLASSID=` 默认 99、
  `N_NMISS` 标签 `n(nmiss)`）更新测试预期（默认合计列 `trt0` → `trt99`、
  `n(miss)` → `n(nmiss)`）；重跑 47 个测试，43 PASS、0 FAIL、0 ERROR、1 DEFECT、3 FIXED。
  - `stat_summaryn` PASS；`stat_summaryc` 仅既有 `bug_allmissvar` 判 DEFECT。
- 同步两个详情页：`TOTCLASSID=` 默认值改为 99，示例列改为 `trt99`，
  `N_NMISS` 标签改为 `n(nmiss)`；修订记录按宏头原样同步为
  `Change behavior: TOTCLASSLAB= ...`（2026-11-19）。
- 执行 `build.ps1` 重建站点：42 个文件更新，`-Check` 通过（33 macros、31 knowledge entries）；
  原 8 项漂移全部清除。
- 修复 `build.ps1` 宏头扫描：取消前 60 行限制，改为从首行扫描到首个 `%macro` 行或文件尾；
  6 条 `UNDECLARED-DEP` 误报消除，`-Check` 无警告（33 macros、31 knowledge entries）。
- 新增站点「关于」页 `sashelp\about.html`：沿用 `base.css` 与固定页头，含站点用途、
  GitHub Issues 意见入口（仓库地址未配置时自动回退为邮件）与作者简介；
  根页「关于」改为链接，三个板块页头加入「关于」；浏览器验证通过。
- 仓库已上传 GitHub：`https://github.com/sashelp/clinical-sasuser`（Public，Issues 已启用），
  初始提交 `af77e0d`；关于页反馈入口已指向实际仓库（`b8328e2`）。

### 2026-11-19

- 仓库结构变更后同步更新 `README.md` 与 `PROGRESS.md`：
  - 根目录改为 `OneDrive\project\clinical-sasuser`；`codehub\Macro` → `codehub\macro`、
    `SASHELP` → `sashelp`，`site.json` 的相对路径已同步为 `../codehub/macro/dev`。
  - 新增区域：`codehub\gallery`（41 个 GTL 模板 + 同名 RTF）、`codehub\script`
    （3 个工具目录 + 9 个脚本）、`LICENSE`（MIT）。
- 盘点当前测试规模：21 个宏 / 229 个测试程序（正 21、负 190、缺陷回归 18）；
  `_results` 当时保留 12 组报告与 3 个持久数据集。
- 执行 `sashelp\build\build.ps1 -Check`，记录 8 项漂移与 6 条 `UNDECLARED-DEP`
  警告（根因：扫描仅限宏头前 60 行，已于当日下午修复）。

### 2026-11-09（下午）

- 修复 QC 框架的机器绑定路径：
  - `qc\_framework\qc_env.sas`：`_QCROOT_` 改为从 SYSIN 上溯 4 层推导，并新增
    `_framework\qc_env.sas` 存在性校验，推导失败立即 `%abort cancel`；
  - `qc\run_all.ps1`：`$QcRoot` 改为 `$PSScriptRoot`。
  两处均不再硬编码 `C:\Users\hao\...`，项目可整体搬移或跨机同步。
- 本机验证：`-List` 正常列出 21 个宏；`-Macro file_attr` 4/4 PASS。
- 同步更正 `qc\README.md`「修改配置」一节：说明根路径由 `$PSScriptRoot` + SYSIN
  自动推导、无需配置，并明确测试文件须保持 `qc\<主题>\<宏>\` 三层深度。

### 2026-11-09

- 建立项目根文档：新增 `README.md`（项目定位、三个子区域边界、依赖关系、命令、
  硬性约定、跨会话接续流程）与 `PROGRESS.md`（本文件）。
- 确认三个子区域已在同一根目录下，`SASHELP\site.json` 的 `macroSource` 相对路径
  `../codehub/Macro/dev` 依赖此布局，不可单独搬移。
- 盘点宏库与测试覆盖：22 个自研宏 / 21 个已验收宏 / 222 个测试程序。
- 发现 QC 框架绝对路径与本机用户目录不一致（已于当日下午修复）。
