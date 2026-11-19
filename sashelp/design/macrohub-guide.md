# 宏程序库（macrohub）制作指南

本文档记录 `sashelp/macrohub` 宏程序库首页与详情页的结构、制作过程、写作规范与新增宏程序的操作步骤，供后续维护与扩展使用。

- 站点根目录：`.\SASHELP`
- 宏程序库目录：`.\sashelp\macrohub`
- 宏源文件目录：`.\codehub\macro\dev`

---

## 1. 目录与文件结构

```
sashelp/
├─ index.html                     # 站点首页（SAS/HELP）
├─ site.json                      # 全站唯一事实源：分类、条目、页头链接
├─ build/
│  └─ build.ps1                   # 构建与校验脚本
├─ assets/
│  ├─ base.css                    # 公共骨架：页头、导航、内容区、代码块、表格
│  ├─ macrohub.css                # 宏程序库差异样式
│  ├─ macrohub_copy.js            # 自动为代码块添加“复制”按钮
│  └─ macropackages/              # 依赖 ZIP 包（构建生成，只含 .zip 与清单）
├─ macrohub/
│  ├─ index.html                  # 宏程序库首页
│  ├─ conventions.html            # 开发约定（由 design/macrohub-guide.md 生成）
│  ├─ var_attr.html               # 详情页，文件名固定为 <宏名>.html
│  ├─ var_coexist.html
│  ├─ var_exist.html
│  ├─ ...
│  └─ for.html
└─ design/
   └─ macrohub-guide.md           # 本文档
```

`macrohub` 文件夹下只存放 `.html` 文件；样式、脚本统一放在 `assets` 文件夹中，页面通过 `../assets/...` 引用。

页头、左侧导航、首页表格与统计数字都由 `build/build.ps1` 从 `site.json` 生成，分别写在下面的标记块内，**不要手动修改标记块中的内容**：

```html
<!--#HEADER#--> ... <!--/#HEADER#-->
<!--#NAV#-->    ... <!--/#NAV#-->
<!--#TABLE#-->  ... <!--/#TABLE#-->
```

构建与校验：

```powershell
powershell -File build\build.ps1           # 生成/更新页面
powershell -File build\build.ps1 -Check    # 只校验，不改文件；有漂移时退出码为 1
```

依赖关系由构建脚本从 `codehub/macro/dev/**/*.sas` 头部的 `*Dependency`、`SubMacros` 解析（并用宏体里的 `%宏名(` 调用补齐声明缺失的情况），再取传递闭包，打包成 ZIP 放到 `sashelp\assets\macropackages\`。页面只是普通下载链接，`file://` 双击打开也能直接下载，不需要启动服务；站点内不含任何宏源码，`codehub` 也不做任何改动。

宏源文件与站点不在同一目录，详情页的“源代码”下载链接使用相对路径：

```
../../codehub/macro/dev/<子目录>/<宏名>.sas
```

例如 `var_attr.html` 中的链接：

```html
<a href="../../codehub/macro/dev/var/var_attr.sas" download>var_attr.sas</a>
```

由于 `macrohub` 位于 `SASHELP` 下，`../..` 指向 `project`，再进入 `codehub`。

---

## 2. 当前宏清单与分类

宏程序库首页与所有详情页的左侧导航必须保持一致。当前收录 33 个宏，分为 8 类（分类与条目在 `site.json` 中维护，导航与首页表格由 `build/build.ps1` 生成）：

| 类别 | 宏 |
| --- | --- |
| 变量操作 | var_attr、var_coexist、var_exist、var_nlevel |
| 数据集操作 | ds_attr、ds_num2char、ds_varlist、ds_zipvarlen |
| 逻辑库操作 | lib_memlist、lib_zipvarlen |
| 目录操作 | dir_attr、dir_exist、dir_memlist |
| 文件操作 | file_attr |
| CDISC 标准 | sdtm_epoch、sdtm_fulldomain、sdtm_lobxfl |
| 统计分析 | stat_countocc、stat_rateci、stat_summaryc、stat_summaryn |
| 开源宏 | for、nodup、parmv、prefix、range、seplist、sorted、splitmac、suffix、suffix_counter、windex、words |

以下宏暂未制作详情页，因此也未出现在导航与首页表格中：

- `cdisc_blfl`

后续补齐这些宏时，按第 5、6 节的步骤同时更新导航与首页表格。

---

## 3. 页面整体结构

所有页面遵循同一骨架：

1. **页头 `#header`**：左侧 SAS/HELP 标识，右侧依次为“宏目录（链接到 index.html）”“文档（空链接）”“开发约定（链接到 conventions.html）”。
2. **左侧导航 `#nav`**：固定宽度 220px，按类别分组列出宏名。
3. **右侧内容 `#section`**：
   - 面包屑：`<p class="crumb"><a href="index.html">宏程序库</a> / <类别></p>`
   - 宏名：`<h2>`
   - 一句话说明：`<p class="subtitle">`
   - 依赖：`<p class="dependency">依赖: ...</p>`
   - 水平分割线 `<hr/>`
   - 详情主体 `<div class="detail">`

详情主体中章节顺序固定：

```
目录 → 名称 → 简介 → 语法 → 参数说明 → 用法示例 → 注意事项 → 已知风险 → 源代码 → 修订记录
```

其中“依赖”不是正文章节，只显示在副标题下方、分割线之上，并且必须排在 `<hr/>` 之前。

> 完整详情页必须包含「已知风险」章节；开源宏简化页仍保持 5 章节格式，不新增该章节（风险声明保留在「注意事项」中）。

---

## 4. 详情页各章节写作规范

### 4.1 标题区

- `<h2>` 只写宏名，例如 `var_attr`。
- `<p class="subtitle">` 写一句中文功能描述，例如“获取变量属性值”。
- `<p class="dependency">`：
  - 无依赖：`依赖: 无`
  - 有依赖：`依赖: <a href="var_exist.html">var_exist</a>`，多个依赖用“、”或逗号分隔，每个宏名都链接到对应详情页。
- 依赖宏必须已经存在详情页，否则会产生死链。

### 4.2 目录

完整详情页固定 9 项，锚点必须与正文章节的 `id` 一致（开源宏简化页不设目录）：

```html
<ul class="toc">
<li><a href="#name">名称</a></li>
<li><a href="#brief">简介</a></li>
<li><a href="#syntax">语法</a></li>
<li><a href="#parameters">参数说明</a></li>
<li><a href="#examples">用法示例</a></li>
<li><a href="#notes">注意事项</a></li>
<li><a href="#risks">已知风险</a></li>
<li><a href="#source">源代码</a></li>
<li><a href="#history">修订记录</a></li>
</ul>
```

不要加入“依赖”项。

### 4.3 名称

```html
<h3 id="name">名称</h3>
<p><code>宏名</code></p>
```

### 4.4 简介

- 用 2～4 句话说明宏做什么、输入什么、结果放在哪里。
- **必须写明返回值**：
  - 函数式宏：写清返回值类型与含义（如返回 1/0、返回文本、返回 -i）。
  - 过程式宏：写明“宏不返回值，结果写入 `OUT=` 数据集/直接修改输入数据集”。
- 不写“常用情形”“应用场景”等泛泛内容。

示例（函数式宏）：

> 返回指定数据集中指定变量的某一属性值。宏以函数方式返回文本结果：`ATTR=NUM` 返回变量位置……返回值可直接用于 `%put`、`%let`、`%if` 等宏语句。

示例（过程式宏）：

> 将 `DATA=` 中指定的数值变量转换为字符变量，并写入 `OUT=` 数据集……宏不返回值，结果保存在输出数据集中。

### 4.5 语法

- **只保留必需参数**，可选参数放到“参数说明”表里。
- 参数值使用语法占位符，不出现真实数据集、变量或业务实例：
  - `data=<dataset>`
  - `var=<variables>`
  - `attr=<attribute>`
  - `level=<level>`
- 函数式宏在语法下方补一句调用限制：

```html
<p>该宏为函数式宏，返回值会直接替换到调用位置，因此必须放在
<code>%put</code>、<code>%let</code>、<code>%if</code> 等宏语句中使用，
不能作为独立语句提交。</p>
```

- 过程式宏写“结果写入 `OUT=` 数据集，不返回值”。
- HTML 中尖括号必须转义：`&lt;dataset&gt;`。

### 4.6 参数说明

固定四列表格，列宽 18% / 12% / 12% / 58%：

| 名称 | 类型 | 默认值 | 描述 |
| --- | --- | --- | --- |
| DATA= | 必需参数 | 无 | ... |
| TYPE= | 可选参数 | ALL | ... |

约定：

- 类型写“必需参数”“可选参数”；位置参数可写“必需参数（位置参数）”。
- 没有默认值写“无”；默认值中若含宏变量，HTML 里写成 `&amp;DATA.`。
- 一个参数有多个取值时，用 `<br/>` 分行列出，例如：

```html
<td>ALL：不校验变量类型。<br/>
C：要求为字符型。<br/>
N：要求为数值型。</td>
```

- 只描述宏实际支持的值；以宏源码中的校验列表为准。

### 4.7 用法示例

- **至少 3 个示例**，推荐 4～5 个，覆盖主要参数组合。
- 每个示例由四部分组成：示例标题、可运行代码、运行结果、结果说明。

```html
<h4>示例 1：示例标题</h4>
<pre class="code">可运行的 SAS 代码</pre>
<p class="result-label">运行结果：</p>
<pre class="result">日志中的实际输出</pre>
<p>结合参数与宏运行机制，说明结果是如何得到的。</p>
```

- **代码必须复制后可直接运行**：
  - 需要数据集时，在示例内部用 `DATA` 步创建，不要依赖读者本地可能不存在的 `adam.*` 数据集；
  - 需要逻辑库时，优先使用 `%sysfunc(pathname(work))` 动态路径，例如：

```sas
options dlcreatedir;
libname dirdemo "%sysfunc(pathname(work))\dirdemo";
data dirdemo.ds1; x=1; run;
```

  - 示例末尾保留能展示结果的语句（`%put`、`PROC PRINT`、`PROC SQL` 查询等）。
- **必须给出运行结果**，按结果类型选择展示方式：
  - 函数返回值、`%put` 输出、日志文本：使用 `<pre class="result">`；
  - 输出数据集：使用 `<table class="macro-table result-table">`，展示关键列或前几行，并在标题中注明“前 N 行”“节选列”；
  - 如需截图，可插入图片，但应优先使用文本或表格，便于复制与检索。
- 结果说明要解释“为什么是这个结果”，而不是重复代码含义。
- 代码中的 `&`、`<`、`>` 在 HTML 中必须转义（`&amp;`、`&lt;`、`&gt;`），否则会被浏览器当作实体或标签。
- 代码块右上角的“复制”按钮由 `../assets/macrohub_copy.js` 自动添加，**不要在 HTML 中手写按钮**；`pre.result` 不生成复制按钮。

### 4.8 注意事项

- 使用 `<ul class="notes">`，4～8 条为宜。
- **非开源宏**：注意事项只能写宏源文件头部注释明确记载的内容，包括 `*Param(Req)`、`*Param(Opt)`、`*Detail`、`*Note`、`*Dependency`、`*History`；不得加入通过运行推断出的行为（如“会输出 ERROR 并终止”“视图会报不存在”等），除非头部注释已明确说明。写入页面时不要保留“（源码 Note）”“（源码 Param）”等来源标注，直接陈述内容即可。
- **开源宏**（当前仅 `for`）：可以补充实测行为，但仍需以源码文档为主，并保留原作者署名。
- 不重复简介中的功能描述。
- 头部注释未记载注意事项时，不写“源码未记载”之类的说明，直接省略该条。

### 4.9 已知风险

- 位置固定在“注意事项”之后、“源代码”之前，`id="risks"`。
- 用于记录当前版本已确认但未修复的风险、对输入参数的强假设，以及临时变量/临时数据集的冲突覆盖风险。按实际情况使用以下子标题，不适用时省略：
  1. **已知但未修复的风险**
  2. **对输入参数的强假设**
  3. **临时变量与临时数据集冲突风险**
- 写作要求：
  - **不暴露宏内部执行细节**：不写具体过程名、语句或函数名，用结果性描述表达。例如写“会被覆盖并在宏运行结束时删除”，不要写“会被 PROC SORT 覆盖，并在结束时被 PROC DELETE 删除”。
  - **不考虑并发场景**：不写并发、嵌套调用相关的内容。
  - **同一对象合并为一条**：对同一数据集、变量或参数的多项要求写进一个风险点，不要拆分。例如对 SE 数据集的要求（相邻记录连续、包含全部受试者、包含 SESTDTC/SEENDTC/EPOCH、仅末段 SEENDTC 可缺失）合并为一条。
  - 每条风险写清触发条件与影响；需要时可在同一条内给出规避建议。
  - **声明 SAS 软件缺陷**：若风险来自已知的 SAS 软件缺陷，应在风险点中明确写出“这是 SAS 软件的已知缺陷”，不要只描述现象。
  - 仅写已确认的内容；暂无已确认风险时写“暂无已确认的已知风险。”，不要留空章节。
- 示例结构：

```html
<h3 id="risks">已知风险</h3>
<p>以下列出当前版本已知但未修复的问题、使用约束与冲突风险。</p>
<h4>1. 已知但未修复的风险</h4>
<ul class="notes">...</ul>
<h4>2. 对输入参数的强假设</h4>
<ul class="notes">...</ul>
<h4>3. 临时变量与临时数据集冲突风险</h4>
<ul class="notes">...</ul>
```

- 开源宏简化页不新增该章节；其风险声明保留在「注意事项」的固定条目中。

### 4.10 源代码

```html
<h3 id="source">源代码</h3>
<p class="download"><a href="../../codehub/macro/dev/<子目录>/<宏名>.sas" download>宏名.sas</a></p>
```

- 仅当宏存在依赖宏（源文件头部 `*Dependency` / `SubMacros` 声明，或宏体内 `%宏名(` 调用可推导出）时，“源代码”章节才提供第二个下载链接：`<宏名> and its dependencies.zip`，放在原宏文件下载链接的下一行。压缩包由构建脚本预先打到 `assets\macropackages\`，页面只是一个普通下载链接，包内文件平铺存放。
- 无依赖宏的页面不显示 ZIP 链接。

```html
<p class="download"><a href="../assets/macropackages/<宏名>.zip" download><宏名> and its dependencies.zip</a></p>
```

- 依赖关系以宏源文件头部的 `*Dependency` 为准；若依赖宏本身还有依赖，需要一并打包（构建脚本自动取传递闭包）。
- 「源代码」章节的内容使用单倍行距、段落间距 0.75em，标题行「源代码」本身不调整。实现为 `#section .detail #source ~ .download { line-height: 1; margin: 0.75em 0; }`，定义在 `assets/macrohub.css`。
- 所有页面底部只引入复制脚本，不需要任何 ZIP 脚本：

```html
<script src="../assets/macrohub_copy.js"></script>
```

### 4.11 修订记录

- 放在“源代码”之后，使用与参数说明相同的表格样式。
- 内容取自宏源码头部的 `*History`，按日期**从新到旧**排列：

```html
<h3 id="history">修订记录</h3>
<table class="macro-table">
<col width="16%" />
<col width="12%" />
<col width="72%" />
<thead>
<tr><th>日期</th><th>修订人</th><th>修订内容</th></tr>
</thead>
<tbody>
<tr><td>2026-11-02</td><td>Luo Hao</td><td>新增 <code>TYPE=</code> 参数，用于校验变量类型。</td></tr>
<tr><td>2025-12-25</td><td>Luo Hao</td><td>原始版本。</td></tr>
</tbody>
</table>
```

- 开源宏没有 `*History` 时，可写一行 `— / 原作者 / 原始版本（开源宏，作者 …）`。

### 4.12 开源宏详情页的简化格式

除 `for` 外，其余开源宏（nodup、parmv、prefix、range、seplist、sorted、splitmac、suffix、suffix_counter、windex、words）采用简化详情页：

- 只保留 5 个章节：`名称`、`简介`、`用法示例`、`注意事项`、`源代码`。
- 不设目录、依赖行、语法、参数说明、已知风险、修订记录。
- `用法示例` 只提供 1～2 个示例，但每个示例下方必须给出实际运行结果与说明，格式见 4.7 节。
- `注意事项` 固定只有一条：

```html
<ul class="notes">
<li>本程序为未经验证的开源宏程序，使用时风险自负。</li>
</ul>
```

新增此类开源宏时，复制任一简化页（如 `nodup.html`）修改宏名、简介、示例与源代码链接，并在首页与各页导航的“开源宏”分类中追加条目。

---

## 5. 新增一个宏详情页的步骤

### 第 1 步：从源码提取元数据

读取 `codehub/macro/dev/<子目录>/<宏名>.sas` 头部注释，整理：

- `*Brief`：英文功能摘要，翻译为中文标题与简介的基础。
- `*Param(Req)` / `*Param(Opt)`：参数名、是否必需、默认值、取值列表。
- `*Detail` / `*Note`：返回值、限制、已知问题。
- `*Dependency`：依赖宏，用于“依赖”行。
- `*History`：修订记录。

同时阅读宏主体，确认：

- 是函数式宏还是过程式宏；
- 参数校验顺序与错误行为；
- 是否会修改输入数据；
- 内部使用的数据集名、变量名；
- 实际返回值的类型与含义。

**源码头部注释与宏实际行为不一致时，以实际测试结果为准，并可在注意事项中说明。**

### 第 2 步：用 SAS 验证

至少验证：

1. 每个返回值的实际内容（函数式宏）；
2. 每个参数的典型取值；
3. 输出数据集的列名、列标签、排序；
4. 破坏性宏对数据的实际修改结果；
5. 错误路径的报错信息（可选，需单独运行）。

SAS 调用方式见第 8 节。

### 第 3 步：复制模板生成页面

复制一个结构完整的详情页（推荐 `var_attr.html` 或 `var_coexist.html`），另存为 `<宏名>.html`，然后修改：

1. `<title>`：`<宏名> - 宏程序库`
2. 左侧导航：新页面对应项加 `class="current"`，其余页面去掉。
3. 面包屑中的类别。
4. `<h2>`、`subtitle`、`dependency`。
5. 名称、简介、语法、参数表、示例、注意事项、已知风险。
6. 源代码链接。
7. 修订记录。

目录本身不需要改（完整详情页始终 9 项；开源简化页不设目录）。

### 第 4 步：登记到 site.json 并重新构建

所有详情页和首页的导航、首页表格、摘要数字都由构建脚本统一生成，不要手改。

1. 在 `site.json` 的 `sections.macrohub.categories` 中找到对应类别，按字母顺序插入一条：

```json
{ "slug": "<宏名>" }
```

2. 运行构建脚本：

```powershell
powershell -File build\build.ps1
```

构建会：重建所有页面的页头与导航（当前项自动加 `class="current"`）、重建首页表格、更新摘要里的宏数量、按依赖闭包在 `sashelp\assets\macropackages\` 生成/刷新压缩包，并决定该页是否出现“and its dependencies.zip”链接（闭包大于 1 个文件时才出现）。

3. 校验：`powershell -File build\build.ps1 -Check` 会检查 `site.json` 与页面是否一一对应、各页面标记块是否完整、压缩包指纹是否与 `.sas` 源文件同步。

### 第 5 步：浏览器验证

页面不依赖运行时服务，直接双击 `macrohub/index.html` 即可；依赖 ZIP 和单个 `.sas` 都是磁盘上的真实文件，点击即可下载。若需要从 `http://` 预览，用任意静态服务即可，站点内没有需要特殊路由的内容。

检查：

- 页面能正常加载，控制台无报错；
- 页头右侧显示“宏目录 / 文档 / 开发约定”；
- 目录 8 个链接均可跳转；
- 每个 `pre.code` 右上角有“复制”按钮，点击后显示“已复制”；
- 每个示例下方的 `pre.result` 与结果表格正常显示，代码未被转义成 HTML 文本；
- 依赖链接、源代码下载链接可用；
- 左侧导航当前项高亮正确；
- 首页表格与导航包含新宏，数量一致。

---

## 6. 首页 `macrohub/index.html` 的制作

首页由三部分组成：

1. **页头与左侧导航**：与详情页完全一致，导航项不带 `current`。
2. **标题与摘要**：

```html
<h2>宏程序库</h2>
<p class="download zip-download"><a href="../assets/macropackages/macrohub.zip" download>macrohub.zip</a></p>
<hr/>
<p class="summary">共 33 个宏程序，点击名称查看详细说明与用法示例。</p>
```

- `macrohub.zip` 链接放在标题下方，指向 `assets\macropackages\macrohub.zip`，包含目录页列出的全部 `.sas` 文件；站点内不保存源码，压缩包统一放在 `assets/macropackages`。
- 首页底部只引入 `../assets/macrohub_copy.js`。
- 新增、删除宏或修改任意宏源文件后，运行一次 `build\build.ps1` 重新打包。

3. **宏清单表格**：

```html
<table class="macro-table">
<col width="14%" />
<col width="20%" />
<col width="66%" />
<thead>
<tr><th>类别</th><th>名称</th><th>简介</th></tr>
</thead>
<tbody>
<tr><td>变量操作</td><td><a href="var_attr.html">var_attr</a></td><td>获取变量属性值</td></tr>
...
</tbody>
</table>
```

- 按类别分组，组间空一行，便于阅读。
- 名称列链接到详情页；简介列保持一句话。
- 表格行数 = 详情页数量 = 导航中的宏数量。

站点根 `sashelp/index.html` 的“宏程序库”入口链接到 `macrohub/index.html`。

---

## 7. 样式与脚本

### 7.1 `assets/base.css` 与 `assets/macrohub.css`

`assets/base.css` 保存全站共用骨架（`body`、`#header`、`#nav`、`#section`、`ul.toc`、`pre.code`、`.copy-btn`、`.macro-table` / `.kb-table` 等），`assets/macrohub.css` 只保留宏程序库独有的差异（内容区内边距、`pre.result`、`.dependency` 等）。页面按“先 base、后主题”的顺序引入：

```html
<link rel="stylesheet" type="text/css" href="../assets/base.css" />
<link rel="stylesheet" type="text/css" href="../assets/macrohub.css" />
```

主要类与用途：

| 选择器 | 用途 |
| --- | --- |
| `#header` | 固定页头 |
| `#nav` | 左侧固定导航（220px） |
| `#nav li.nav-cat` | 类别标题（灰色、小字） |
| `#section` | 右侧内容区 |
| `.macro-table` | 参数表、修订记录表、首页清单 |
| `ul.toc` | 横向目录（斜杠分隔） |
| `pre.code` | 代码块（深色背景、绿色左边框） |
| `.code-block` | 代码块外层容器（相对定位） |
| `.copy-btn` | 复制按钮（绝对定位在右上角） |
| `pre.result` | 运行结果文本（灰色左边框、等宽字体） |
| `.result-label` | 运行结果提示文字 |
| `table.result-table` | 运行结果数据集（沿用 `.macro-table` 样式） |
| `.subtitle` | 副标题（灰色） |
| `.dependency` | 依赖行（灰色、1.25 倍行距、无外边距） |
| `ul.notes` | 注意事项列表 |
| `#section code` | 内联代码：背景 `#333333`、前景 `#ffffff`，全站适用（定义在 `base.css`） |
| `#section .detail #source ~ .download` | 「源代码」章节内容单倍行距、段落间距 0.75em，标题不调整（定义在 `macrohub.css`） |

写作时不要添加行内样式；公共样式加到 `assets/base.css`，分区特有的加到 `assets/macrohub.css`。

> 内联 `<code>` 的背景色应比页面背景略亮，前景为纯白；当前页面背景为 `#222222`，内联代码背景取 `#333333`。该规则写在 `assets/base.css` 的 `#section code` 中，对整个可视化站点生效。

### 7.2 `assets/macrohub_copy.js`

脚本在页面加载后执行：

- 查找所有 `pre.code`；
- 为其包裹 `.code-block` 容器；
- 自动添加“复制”按钮；
- 点击时优先使用 `document.execCommand('copy')`，失败时回退到 `navigator.clipboard`；
- 成功后按钮短暂显示“已复制”（绿色描边），1.5 秒后回弹为“复制”；失败时短暂显示“复制失败”（红色描边）后回弹。

因此，详情页中只需写 `<pre class="code">...</pre>`，不要手写按钮，也不要在页面内重复引入脚本（页面底部统一引入一次）。

### 7.3 `assets/macropackages/`

**站点内不放明文源码，`codehub` 也不做任何改动。** 依赖压缩包由 `build/build.ps1` 生成到 `sashelp/assets/macropackages/`。

#### 目的

- **点一下就下载。** 宏的依赖往往不止一个文件，逐个下载太麻烦；这里预先把“宏 + 依赖闭包”打成一个 ZIP，页面只放普通 `<a href>`，双击 `file://` 打开也能直接下载，不需要启动服务，也不需要任何客户端打包脚本。
- **站点内不出现明文源码。** 页面、`assets` 下的 CSS/JS 都没有 `.sas` 内容，只有这个目录里的二进制 ZIP；想看源码仍然走 `codehub/macro/dev/<子目录>/` 的下载链接。
- **不污染源码库。** 构建只读取 `codehub`，不往里面写任何文件；ZIP 属于站点自身的产物，和站点一起备份、一起发布。

#### 生成方法

`build/build.ps1` 里的 `Invoke-Packages` 负责生成，规则如下：

1. 从 `codehub/macro/dev/<子目录>/<宏名>.sas` 头部解析 `*Dependency` / `SubMacros`，再用宏体内的 `%宏名(` 调用补齐漏声明的依赖，取传递闭包。
2. 闭包超过 1 个文件的宏，打一个 `<宏名>.zip`；所有宏的源文件再打一个 `macrohub.zip` 供首页下载。
3. 包内文件**平铺存放**（不带子目录），编码保持原样（UTF-8）。
4. 每次构建都计算“文件名 + SHA1”的指纹，写进 `manifest.json`；指纹没变的包不重写，指纹变了的包重新生成。
5. 页面链接由同一次构建同步更新：有依赖的页面出现 `../assets/macropackages/<宏名>.zip`，无依赖的页面不出现。

```
sashelp/
├─ assets/
│  ├─ base.css
│  ├─ macrohub.css
│  ├─ macrohub_copy.js
│  └─ macropackages/
│     ├─ var_attr.zip
│     ├─ ...
│     ├─ macrohub.zip        # 全量包，供首页下载
│     └─ manifest.json       # 每个包的文件名 + SHA1 指纹（不含源码）
├─ macrohub/
└─ knowledgebase/
```

#### 维护约定

- **不要手改** 这个目录：删了也没关系，重跑 `build\build.ps1` 会重新生成。
- 改了任何 `.sas` 后必须跑一次构建；`build.ps1 -Check` 会报 `STALE-PACKAGE` 提醒。
- 新增/删除宏时，构建会自动增删对应 ZIP，并清掉不再需要的包（以 `manifest.json` 为准）。
- `manifest.json` 只登记文件名和指纹，不含源码内容，可以安全地随站点发布。

### 7.4 `macrohub/conventions.html`

- 由 `build/build.ps1` 从 `design/macrohub-conventions.md` 渲染生成（源文件路径记录在 `site.json` 的 `conventionsSource`），**不要手改这个 HTML**；改约定后跑一次构建即可同步，`-Check` 会检测页面是否落后于 MD。
- `design/macrohub-conventions.md` 是面向宏开发者的内容（命名、头注释、校验、清理、修订、测试等），依据 `codehub/macro/dev/.github/skills/sas-macro-development/SKILL.md` 整理并补充；本文档（制作指南）只讲站点制作，不发布到站点。
- 页头“开发约定”链接由 `site.json` 的 `headerLinks` 指向 `conventions.html`。
- 转换规则：跳过首行 `# 标题`（页面标题取页头链接的文字），`##`/`###` 映射为 `h3`/`h4`；支持表格、有序/无序（含嵌套）列表、代码块（渲染为 `pre.code`，自动带复制按钮）、引用块、`---` 分隔线，以及行内 `code`、`**粗体**`、`[链接](url)`。
- 页面复用详情页的页头、导航与样式，正文放在 `<div class="detail doc">` 内。

---

## 8. SAS 验证规范

### 8.1 启动命令

UTF-8（默认）：

```powershell
"sas.exe" -CONFIG "$env:SAS_CFG"
```

EUC-CN：

```powershell
"sas.exe" -CONFIG ".\_external\Program Files\SASHome\SASFoundation\9.4\nls\zh\sasv9.cfg"
```

批处理调用建议使用同步等待并生成日志：

```powershell
$p = Start-Process -FilePath "sas.exe" `
  -ArgumentList '-CONFIG','"$env:SAS_CFG"',`
                 '-SYSIN','"<测试程序>.sas"','-LOG','"<日志>.log"',`
                 '-PRINT','"<输出>.lst"','-NOSYNTAXCHECK' `
  -Wait -PassThru -NoNewWindow
```

直接使用 `&` 调用可能拿不到日志，优先使用 `Start-Process -Wait`。

### 8.2 测试要点

- 在临时目录建立测试逻辑库与测试数据集，测试结束后删除。
- 用 `%put` 加标记输出每个返回值，例如：

```sas
%put NOTE: NLEVEL c1 default -> [%var_nlevel(data=t.miss,var=c1)];
```

- 过程式宏用 `PROC CONTENTS` / `PROC PRINT` 检查结果数据集的结构与内容。
- 会执行 `%abort cancel` 的错误路径必须**单独运行**，因为该语句会终止整个 SAS 会话。

### 8.3 本次已验证的关键结论

- `ds_num2char` 转换后的字符变量长度为 200，转换变量排在其余原始变量之前。
- `ds_zipvarlen` 对 0 观测数据集将字符变量长度设为 1；`DELFMT=N` 保留原格式。
- `lib_zipvarlen` 默认 `SUPP_POLICY=FDA`：`SUPP` 开头的数据集不参与全库最大长度计算，但仍会被单独压缩。
- `dir_memlist` 的 `MEMINFO=Y` 会额外输出根目录记录（`DEPTH=0`）。
- `for` 的数据集遍历支持 `WHERE=`，但 `OBS=` 等数据集选项不生效。
- `var_exist`、`var_attr`、`var_coexist`、`var_nlevel`、`ds_attr`、`ds_varlist`、`lib_memlist`、`dir_exist`、`dir_attr`、`file_attr` 的返回值均已实测。
- `sdtm_fulldomain` 输出包含父域变量、`IDVAR`、`IDVARVAL` 及转置后的 `QNAM` 列。
- `sdtm_epoch` 对含缺失部分的 `DTC` 不做日期填补，按非缺失部分参与映射；若有多个 EPOCH 匹配，取最后一个。
- `stat_countocc` 输出 `ns0`~`nsN`、`ne0`~`neN`、`np0`~`npN`、`nsp0`~`nspN` 及 `_TESTV_`/`_TESTP_`/`_TESTM_`。
- `stat_rateci` 输出 `_METHOD_`、`_PROP_`、`_ALPHA_`、`_CL_L_`、`_CL_U_`、`_SOURCE_`。
- `stat_summaryc` 输出 `TRT1`、`TRT2`…及合计列 `TRT0`，`CHISQ` 出现警告时自动改用 Fisher。
- `stat_summaryn` 输出每个 BY 组、分析变量、统计量一行，分组列为 `TRT1`、`TRT2`…及合计列 `TRT0`；`TEST=PAR` 为 t 检验，`TEST=NPAR` 为 Wilcoxon。

---

## 9. 编码与转义

- 所有 HTML 文件保存为 **UTF-8**，并在 `<head>` 中声明 `<meta charset="UTF-8">`。
- 代码块中的 `&`、`<`、`>` 必须转义：
  - `&` → `&amp;`
  - `<` → `&lt;`
  - `>` → `&gt;`
- 参数默认值中的宏变量也要转义，例如 `&amp;DATA.`。
- 中文正文直接书写，不要使用 HTML 实体表示中文。
- 宏名、参数名、SAS 关键字保持英文原样；专业术语可保留英文缩写（如 SUPP、CMH、RECFM）。

---

## 10. 新增宏检查清单

- [ ] 已阅读宏源码并整理 `*Brief`、参数、依赖、`*History`
- [ ] 已用 SAS 实测返回值或输出数据集
- [ ] 已创建 `<宏名>.html`，文件名为小写宏名
- [ ] 页头、导航与现有页面一致，当前项有 `class="current"`
- [ ] 面包屑、标题、副标题正确
- [ ] 依赖行在 `<hr/>` 上方，无依赖写“依赖: 无”，依赖名已加链接
- [ ] 目录 9 项且锚点可跳转（含「已知风险」；开源简化页不设目录）
- [ ] 简介写明了返回值或输出位置
- [ ] 语法只含必需参数，使用 `<dataset>` 等占位符，且已转义
- [ ] 参数表包含全部参数，默认值准确
- [ ] 完整详情页的用法示例至少 3 个，代码复制后可直接运行，`&` 已转义
- [ ] 完整详情页的每个示例下方都有实际运行结果（`pre.result` 或结果表格）及结果说明
- [ ] 注意事项仅引用源码头部注释内容（开源宏除外），且不出现“（源码 ...）”来源标注
- [ ] 完整详情页包含「已知风险」章节，位于注意事项与源代码之间
- [ ] 已知风险不暴露宏执行细节、不写并发场景、同一对象的要求已合并为一条
- [ ] 来自已知 SAS 软件缺陷的风险已明确声明“这是 SAS 软件的已知缺陷”
- [ ] 开源宏简化页仅保留 5 个章节，示例 1～2 个且均含运行结果，注意事项为固定声明，且不含已知风险章节
- [ ] 页头右侧为“宏目录 / 文档 / 开发约定”三个链接，且“开发约定”能打开 `conventions.html`
- [ ] 源代码下载链接指向正确的 `.sas`
- [ ] 仅存在依赖宏的详情页提供 `<宏名> and its dependencies.zip` 链接，指向 `../assets/macropackages/<宏名>.zip`
- [ ] 所有页面底部只引入 `../assets/macrohub_copy.js`
- [ ] 站内没有明文 `.sas` 源码，`codehub` 未被改动；`build\build.ps1 -Check` 通过
- [ ] 内联代码样式（背景略亮于页面、纯白前景）与「源代码」章节单倍行距已生效
- [ ] 修订记录按日期从新到旧
- [ ] `macrohub/index.html` 已增加导航项、表格行并更新数量
- [ ] 双击打开与本地服务下浏览器验证均通过，无死链、无控制台报错
- [ ] 清理临时 SAS 测试文件与测试数据集

---

## 附录 A：详情页模板骨架

将下面的 `<宏名>`、`<类别>`、`<副标题>`、`<依赖>` 等替换为实际内容。代码块中用 `...` 表示需要补充的部分。

```html
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta>
<title><宏名> - 宏程序库</title>
<link rel="stylesheet" type="text/css" href="../assets/base.css" />
<link rel="stylesheet" type="text/css" href="../assets/macrohub.css" />
</head>

<body>
<!--#HEADER#-->
<div id="header">
<div class="left">
<a href="../index.html"><span style="color: #0070C0;">SAS</span>/<span style="color: #70AD47;">HELP</span></a>
</div>
<div class="right">
<a href="index.html">宏目录</a>
<a href="">文档</a>
<a href="conventions.html">开发约定</a>
</div>
</div>
<!--/#HEADER#-->

<!--#NAV#-->
<div id="nav">
<ul>
<li class="nav-cat">变量操作</li>
<li><a href="var_attr.html">var_attr</a></li>
...
<li><a href="<宏名>.html" class="current"><宏名></a></li>
...
</ul>
</div>
<!--/#NAV#-->

<div id="section">
<p class="crumb"><a href="index.html">宏程序库</a> / <类别></p>
<h2><宏名></h2>
<p class="subtitle"><副标题></p>
<p class="dependency"><依赖></p>
<hr/>

<div class="detail">

<h3 id="toc">目录</h3>
<ul class="toc">
<li><a href="#name">名称</a></li>
<li><a href="#brief">简介</a></li>
<li><a href="#syntax">语法</a></li>
<li><a href="#parameters">参数说明</a></li>
<li><a href="#examples">用法示例</a></li>
<li><a href="#notes">注意事项</a></li>
<li><a href="#risks">已知风险</a></li>
<li><a href="#source">源代码</a></li>
<li><a href="#history">修订记录</a></li>
</ul>

<h3 id="name">名称</h3>
<p><code><宏名></code></p>

<h3 id="brief">简介</h3>
<p>...</p>

<h3 id="syntax">语法</h3>
<pre class="code">%<宏名>(data=&lt;dataset&gt;, ...)</pre>
<p>...</p>

<h3 id="parameters">参数说明</h3>
<table class="macro-table">
<col width="18%" />
<col width="12%" />
<col width="12%" />
<col width="58%" />
<thead>
<tr><th>名称</th><th>类型</th><th>默认值</th><th>描述</th></tr>
</thead>
<tbody>
<tr>
<td>DATA=</td>
<td>必需参数</td>
<td>无</td>
<td>...</td>
</tr>
</tbody>
</table>

<h3 id="examples">用法示例</h3>
<h4>示例 1：...</h4>
<pre class="code">...</pre>
<p class="result-label">运行结果：</p>
<pre class="result">...</pre>
<p>...</p>

<h3 id="notes">注意事项</h3>
<ul class="notes">
<li>...</li>
</ul>

<h3 id="risks">已知风险</h3>
<p>以下列出当前版本已知但未修复的问题、使用约束与冲突风险。</p>
<h4>1. 已知但未修复的风险</h4>
<ul class="notes">...</ul>
<h4>2. 对输入参数的强假设</h4>
<ul class="notes">...</ul>
<h4>3. 临时变量与临时数据集冲突风险</h4>
<ul class="notes">...</ul>

<h3 id="source">源代码</h3>
<p class="download"><a href="../../codehub/macro/dev/<子目录>/<宏名>.sas" download><宏名>.sas</a></p>

<h3 id="history">修订记录</h3>
<table class="macro-table">
<col width="16%" />
<col width="12%" />
<col width="72%" />
<thead>
<tr><th>日期</th><th>修订人</th><th>修订内容</th></tr>
</thead>
<tbody>
<tr><td>...</td><td>...</td><td>...</td></tr>
</tbody>
</table>

</div>
</div>

<script src="../assets/macrohub_copy.js"></script>
</body>
</html>
```

---

## 附录 B：本次批量制作记录

- 原始导航共 33 个宏；按需求排除 2 个（cdisc_blfl、sdtm_epoch）后，首批制作 32 个详情页，其中 11 个开源宏使用简化格式。
- 2026-11-09 已补齐 `sdtm_epoch` 详情页；当前详情页 33 个、导航 33 项、首页表格 33 行。
- 已新增 `修订记录` 章节，位置在“源代码”之后，使用表格展示，并在目录中增加对应锚点。
- 所有页面已通过本地 HTTP 服务在浏览器中验证：
  - 首页表格 32 行、导航 32 项；
  - 详情页 8 个目录锚点均存在；
  - 每个代码块均自动生成“复制”按钮；
  - 占位符尖括号按文本渲染；
  - 页面无控制台报错。
- 已用 SAS 9.4M7 UTF-8 会话对 32 个宏的代表性行为逐一验证，关键结论见 8.3 节。
- 所有详情页的用法示例均按“复制后可直接运行”的标准编写：示例内部自行创建数据或逻辑库，并在代码下方给出实测的日志输出或结果数据集表格，再说明结果与参数的关系。
- 页头右侧统一为“宏目录 / 文档 / 开发约定”；非开源宏的“注意事项”仅引用源文件头部注释内容。
- 首页提供 `macrohub.zip`；存在依赖宏的详情页在“源代码”章节提供 `<宏名> and its dependencies.zip`。两者都由 `build\build.ps1` 打包到 `sashelp\assets\macropackages\`，页面只放普通下载链接；站点内不含任何宏源码，`codehub` 未改动，双击 `file://` 即可下载，无需启动服务。
- `macrohub` 文件夹下只存放 `.html` 文件；`base.css`、`macrohub.css`、`macrohub_copy.js` 位于 `sashelp/assets`，页面以 `../assets/...` 引用。
