# 知识库（knowledgebase）制作指南

本文档记录 `sashelp/knowledgebase` 知识库首页与详情页的结构、写作规范、知识来源与新增知识的操作步骤，供后续维护与扩展使用。

- 站点根目录：`.\SASHELP`
- 知识库目录：`.\sashelp\knowledgebase`

---

## 1. 目录与文件结构

```
sashelp/
├─ index.html                     # 站点首页（SAS/HELP）
├─ site.json                      # 全站唯一事实源：分类、条目、页头链接
├─ build/
│  └─ build.ps1                   # 构建与校验脚本
├─ assets/
│  ├─ base.css                    # 公共骨架（页头、导航、内容区、代码块、表格）
│  ├─ knowledgebase.css           # 知识库差异样式（含搜索框）
│  ├─ knowledgebase_copy.js       # 自动为代码块添加“复制”按钮
│  ├─ kb-search.js                # 知识库首页搜索（过滤目录表格）
│  └─ kb-search-index.js          # 搜索索引（构建生成，不含源码）
├─ knowledgebase/
│  ├─ index.html                  # 知识库首页（目录页 + 搜索框）
│  ├─ conventions.html            # 开发约定（由 design/knowledgebase-guide.md 生成）
│  ├─ orres_stat_empty.html       # 详情页，文件名固定为 <英文短名>.html
│  ├─ sdtm_var_in_adam.html
│  ├─ population_flags.html
│  ├─ reproducibility.html
│  └─ external_macro.html
└─ design/
   └─ knowledgebase-guide.md      # 本文档
```

页头与导航由 `build/build.ps1` 写入 `<!--#HEADER#-->` / `<!--#NAV#-->` 标记块，正文不要手动改这两块。构建与校验：

```powershell
powershell -File build\build.ps1
powershell -File build\build.ps1 -Check
```

详情页文件名用**英文短横线/下划线命名**，与内容语义对应，便于辨识与链接。例如：

| 详情页 | 文件名 |
| --- | --- |
| SDTM 中 --ORRES / --STAT 双空 | `orres_stat_empty.html` |
| ADaM 中 SDTM 变量保留 | `sdtm_var_in_adam.html` |
| population flags 放在哪 | `population_flags.html` |
| 程序文件可复现 | `reproducibility.html` |
| 避免外部宏调用 | `external_macro.html` |

---

## 2. 分类体系

知识库首页与所有详情页的左侧导航必须保持一致；导航、首页表格与摘要数字都由 `build/build.ps1` 从 `site.json` 生成。当前共 31 条知识，分为 7 类：

| 类别 | 当前条目数 |
| --- | --- |
| SDTM | 10 |
| ADaM | 5 |
| 临床提交 | 2 |
| SAS 编程 | 7 |
| 统计分析 | 3 |
| 性能与调优 | 3 |
| 客户端 | 1 |

**分类不是固定的，允许新增。** 在 `site.json` 的 `sections.knowledgebase.categories` 里按顺序新增一个类别（含 `name` 与该类别下的条目），再运行一次构建脚本即可，页面结构不用动。

导航顺序约定：SDTM → ADaM → 临床提交 → SAS 编程 → 统计分析 → 性能与调优 → 客户端（后续新增类别自行决定插入位置，保持逻辑相邻即可）。

---

## 3. 页面整体结构

所有页面遵循同一骨架（与宏库 macrohub、图形库 gallery 一致）：

1. **页头 `#header`**：左侧 SAS/HELP 标识，右侧“知识目录（链接到 index.html）”“文档（空链接）”“开发约定（链接到 conventions.html）”。
2. **左侧导航 `#nav`**：固定宽度 220px，按类别分组列出条目；类别标题用 `<li class="nav-cat">`，条目用 `<li><a href="...">`。
3. **右侧内容 `#section`**：
   - 详情页含面包屑：`<p class="crumb"><a href="index.html">知识库</a> / <类别></p>`
   - 标题：`<h2>问题</h2>`
   - 短回答：`<p class="subtitle">一句话结论</p>`
   - 水平分割线 `<hr/>`
   - 详情主体 `<div class="detail">`

详情页**不设“目录”章节**，正文直接从“结论”开始。

---

## 4. 目录页 `index.html` 的制作

首页由三部分组成：

1. **页头与左侧导航**：与详情页完全一致，导航项不带 `current`。
2. **标题与摘要**：

```html
<h2>知识库</h2>
<hr/>
<p class="summary">共 N 条知识，点开问题看完整解答、流程图和参考出处。</p>
```

3. **知识清单表格**，三列 = 类别 / 问题 / 短回答：

```html
<table class="kb-table">
<col width="14%" />
<col width="36%" />
<col width="50%" />
<thead>
<tr><th>类别</th><th>问题</th><th>短回答</th></tr>
</thead>
<tbody>
<tr><td>SDTM</td><td><a href="orres_stat_empty.html">SDTM 中能允许 --ORRES 和 --STAT 同时为空的记录吗？</a></td><td>一句话短回答。</td></tr>
...
</tbody>
</table>
```

约定：

- 按类别分组排列，同类别的条目连在一起。
- “问题”列放完整问句（就是详情页 `<h2>` 的标题），链接到详情页。
- “短回答”列放一句话结论（就是详情页 `<p class="subtitle">` 的内容）。
- 表格行数 = 详情页数量 = 导航中的条目数量。
- 空类别（如当前的 SAS 编程）只出现在导航里，不出现在表格中。

站点根 `sashelp/index.html` 的“知识库”入口链接到 `knowledgebase/index.html`。

---

## 5. 详情页的结构

详情页正文章节按需设置，**没有固定顺序，也没有目录**。核心是回答清楚问题。常见章节组合：

```
结论 → 规则/依据 → 判断流程（流程图）→ 情形对照（表格）→ 易踩的坑 → 参考出处
```

以“population flags”这类复杂主题为例，章节更多：

```
结论 → 先分清两个概念 → 版本演变 → 数据流向（流程图）→ 正确写法
→ 遗留场景 → 常见错误 → 人工判定流程 → 三条路线 → 标准 vs 实践 → 参考出处
```

原则：**按“把问题讲明白”的需要来组织，不套模板。** 有必要的才加流程图、表格、示例；一个简单问题也可以只有“结论 + 说明 + 参考出处”三段。

---

## 6. 详情页各章节写作规范

### 6.1 标题区

- `<p class="crumb">`：面包屑，末段写所属类别。
- `<h2>`：写完整问题（即目录页“问题”列的同名文本）。
- `<p class="subtitle">`：写一句话结论（即目录页“短回答”列的同名文本）。
- `<hr/>` 之后进入 `<div class="detail">`。

### 6.2 结论

用结论高亮框，一句或几句把答案说死：

```html
<h3 id="conclusion">结论</h3>
<div class="conclusion">
<p>……</p>
</div>
```

### 6.3 正文章节

- 一级小节用 `<h3>`（左侧蓝竖线样式），二级用 `<h4>`。
- 每个 `<h3>` 建议带 `id`（如 `id="conclusion"`），便于将来引用，但**不要**在页面顶部放目录锚点列表。
- 说明性文字用 `<p>`；并列要点用 `<ul class="notes">` 或 `<ol class="notes">`。
- 引用原文（指导原则、FDA 指南原句）用提示框：

```html
<div class="callout">
<p>“……”</p>
</div>
```

### 6.4 表格

统一用 `<table class="kb-table">`，列宽用 `<col width="..."/>` 指定，表头 `<thead><tr><th>…</th></tr></thead>`。

### 6.5 流程图

用内联 SVG，包在流程图容器里：

```html
<div class="flow">
<p class="flow-title">图的标题</p>
<svg viewBox="0 0 680 400" xmlns="http://www.w3.org/2000/svg">
  ...（rect / text / line，配 marker 箭头）...
</svg>
</div>
```

SVG 规范见第 9 节。

### 6.6 代码块

SAS 代码用 `<pre class="code">…</pre>`，右上角“复制”按钮由 `assets/knowledgebase_copy.js` 自动添加，**不要在 HTML 里手写按钮**。

### 6.7 参考出处

每条知识末尾放“参考出处”，用列表列出资料原文出处：

```html
<h3 id="refs">参考出处</h3>
<ul class="refs">
<li>《药物临床试验数据递交指导原则（试行）》，国家药品监督管理局药品审评中心（CDE），2020 年 7 月。<span class="src">第四部分“试验数据的可追溯性”。</span></li>
<li>CDISC, <a href="https://www.cdisc.org/standards/foundational/sdtmig/sdtmig-v3-3" target="_blank" rel="noopener"><i>SDTMIG v3.3</i></a>。<span class="src">DM assumptions：人群标志补充限定符不应使用。</span></li>
</ul>
```

`<span class="src">` 里写该资料中具体相关的章节/条款，方便读者定位原文。

**资料名一律加超链接**：能拿到公开地址的，把标题（含 `<i>`）整体包进 `<a>`，外链统一带 `target="_blank" rel="noopener"`，让人一眼能点开原文核对。链接样式由 `.refs a` 控制，不要写行内样式。确实没有公开链接的（内部文档、未公开的会议材料），保持纯文本，不要用搜索页或首页凑数。

---

## 7. 写作风格（重要）

读者定位：**刚入行的临床编程同事**。写作身份：**有经验的临床编程经理带新人**。目标是清晰、易懂地把知识讲明白。

- **口语化**，像当面跟同事解释，不要论文腔。少用“其归属是”“由此推出”“该规则确立了……”这类书面套话，改成“它的位置是”“所以记住”“说白了就是……”。
- **少用互联网黑话**。避免“落地、抓手、赋能、闭环、对齐、粒度、颗粒度、反哺”等词，换成直白说法：“落地”→ 放到/处理/写成；“粒度”→ 层级/级别。
- **不过度加括号注释**。新同事经验少但有独立判断能力，不要把每个词都“写一个词，再打个括号写注释”。行业通用缩写（SDTM、ADaM、SAFFL、ORRES、null flavor）直接写，不解释；也不要中英对照（“可追溯性（Traceability）”“宏（macro）”这类）。
- 专业英文术语直接写英文（permissible、required、Assigned、Derived），不加中文翻译。
- 尊重读者：不写废话铺垫，不重复啰嗦，直接给结论和理由。

---

## 8. 知识来源

一条知识可能来自三类来源，整理进知识库时都要落到“参考出处”里，写清原始来源：

1. **网页**：如 CDISC 官网、FDA/CDE 官网、论坛、博客等。整理时提炼出结论与关键依据，在“参考出处”标注网页来源（机构、文档名、章节/条目）。
2. **PDF 文档**：如指导原则、白皮书、行业标准。读取后提炼，标注文档名、发布机构、年份、相关章节。
3. **与 AI 大模型的对话**：把历史问答整理成知识条目时，结论要经过人工核实（尤其涉及标准/法规的细节），确认无误后再入库；“参考出处”应写回**原始权威来源**（标准原文、指导原则等），而不是“某 AI 说的”。

无论哪种来源，入库前都建议核实关键结论，避免把错误结论固化进团队知识库。

---

## 9. 流程图（SVG）规范

流程图是内联 SVG，跟随站点深色主题，用色约定：

| 元素 | 颜色 |
| --- | --- |
| 起点/关键节点 | 填充 `#0070C0`，描边 `#005a9e`，白字 |
| 合规/推荐结果 | 填充 `#70AD47`，描边 `#5c8e39`，白字 |
| 不合规/警告结果 | 填充 `#c0504d`，描边 `#9c3f3d`，白字 |
| 普通步骤/判断 | 填充 `#1c1c1c`，描边 `#555555`，浅灰字 `#e6e6e6` |
| 中性结果 | 填充 `#333333`，描边 `#555555`，浅字 |
| 备注框 | 填充 `#1a1a1a`，描边 `#00B0F0`，字色 `#00B0F0` |
| 箭头 | 描边 `#8a8a8a`，配 `<marker>` 箭头 |
| 次级说明文字 | `#8a8a8a`，font-size 11 |

约束：

- 根元素 `<svg viewBox="0 0 680 高度" ...>`，宽度由 CSS 撑满容器。
- 文字用 `<text x=".." y=".." text-anchor="middle">` 居中，避免中文溢出。
- 箭头需在 `<defs>` 里定义 `<marker>`，再用 `marker-end="url(#id)"` 引用；同一页面多个 SVG 时 marker 的 `id` 不要重复。
- 盒内多行文字用多个 `<text>` 叠加（第二行字号小一号、颜色浅一号）。
- 判断分支用“是/否”小字标注在箭头上方。

---

## 10. 样式与脚本

### 10.1 `assets/base.css` 与 `assets/knowledgebase.css`

`assets/base.css` 提供全站共用骨架（`#header`、`#nav`、`#section`、`.kb-table` / `.macro-table`、`pre.code`、`.copy-btn`、`ul.notes` 等），`assets/knowledgebase.css` 只保留知识库特有的差异（`.conclusion`、`.callout`、`.flow`、`.refs`、`ol.notes` 等）。页面按“先 base、后主题”的顺序引入：

```html
<link rel="stylesheet" type="text/css" href="../assets/base.css" />
<link rel="stylesheet" type="text/css" href="../assets/knowledgebase.css" />
```

主要类与用途：

| 选择器 | 用途 |
| --- | --- |
| `#header` | 固定页头 |
| `#nav` / `#nav li.nav-cat` | 左侧固定导航（220px）与类别标题 |
| `#section` | 右侧内容区 |
| `.kb-table` | 各类表格（目录页清单、对照表、情形表） |
| `.conclusion` | 结论高亮框（绿色左边框） |
| `.callout` | 提示/原文引用框（蓝色左边框） |
| `.flow` / `.flow svg` | 流程图容器（深色底、细边框） |
| `pre.code` / `.copy-btn` | 代码块与复制按钮 |
| `ul.notes` / `ol.notes` | 要点列表 |
| `.refs` / `.refs .src` | 参考出处列表与章节说明 |
| `.refs a` | 参考出处中的资料链接（青色 + 点线下划线） |
| `.crumb` / `.subtitle` | 面包屑 / 短回答 |

写作时不要添加行内样式；公共样式加到 `assets/base.css`，知识库特有的加到 `assets/knowledgebase.css`。

### 10.2 `assets/knowledgebase_copy.js`

脚本在页面加载后执行：查找所有 `pre.code`，包裹 `.code-block` 容器，自动添加“复制”按钮，点击后优先 `document.execCommand('copy')`，失败回退 `navigator.clipboard`；成功后按钮短暂显示“已复制”（绿色描边），1.5 秒后回弹为“复制”。详情页底部统一引入一次即可。

### 10.3 知识库搜索

**搜索只出现在知识库**，宏程序库与图形库不提供搜索。

- 首页目录表格上方有一个搜索框（`#kb-search-input`），文案取自 `site.json` 的 `sections.knowledgebase.search`。
- 过滤逻辑在 `assets/kb-search.js`：按输入内容实时匹配每一行的“类别 / 问题 / 短回答”，以及索引里的 `t`（问题）、`d`（短回答）、`c`（类别）、`k`（正文摘要）；`Escape` 清空并恢复全部行，右下角显示“命中 N / 总数 条”。
- `assets/kb-search-index.js` 由 `build/build.ps1` 自动生成（`window.KB_INDEX`），每条知识的 `k` 取正文 `<div class="detail">` 的前 600 字纯文本；**不要手改**，新增知识后重新构建即可。
- 目录表格的每一行由构建脚本写入 `data-slug="<文件名>"`，搜索脚本按它关联索引。

### 10.4 `knowledgebase/conventions.html`

- 由 `build/build.ps1` 从 `design/knowledgebase-conventions.md` 渲染生成（源文件路径记录在 `site.json` 的 `conventionsSource`），**不要手改这个 HTML**；改约定后跑一次构建即可同步，`-Check` 会检测页面是否落后于 MD。
- `design/knowledgebase-conventions.md` 是面向知识条目作者的内容（选题、核实、结构、文风、术语、示例、参考出处等），不涉及站点版式；本文档（制作指南）只讲站点制作，不发布到站点。
- 页头“开发约定”链接由 `site.json` 的 `headerLinks` 指向 `conventions.html`。
- 转换规则与宏库一致：跳过首行 `# 标题`，`##`/`###` 映射为 `h3`/`h4`，支持表格、嵌套列表、代码块（`pre.code`，带复制按钮）、引用块、分隔线与行内格式。

---

## 11. 编码与转义

- 所有 HTML 保存为 **UTF-8**，`<head>` 中声明 `<meta charset="UTF-8">`。
- 代码块中的 `&`、`<`、`>` 必须转义：`&` → `&amp;`，`<` → `&lt;`，`>` → `&gt;`。
- 中文正文直接书写，不要用 HTML 实体表示中文。
- 变量名、宏名、SAS 关键字保持英文原样；正文标点用中文标点（“”等）。

---

## 12. 新增一条知识的步骤

### 第 1 步：确定分类与文件

- 从现有 7 类里选一个类别；都不合适就新增类别。
- 定一个英文短横线/下划线文件名，如 `xxx_yyy.html`。

### 第 2 步：核实内容

- 阅读知识来源（网页 / PDF / 历史 AI 对话），提炼结论与依据。
- 涉及标准/法规的细节，对照权威原文核实。

### 第 3 步：写详情页

- 复制一个现有详情页（如 `orres_stat_empty.html`）作为骨架，另存为 `<文件名>.html`。
- 修改：`<title>`、面包屑类别、`<h2>` 问题、`<p class="subtitle">` 短回答。
- 按第 5、6 节写正文：结论 + 说明，必要时加流程图、表格、示例。
- 末尾写“参考出处”。
- 按第 7 节检查文风：口语化、无黑话、无过度括号注释。

### 第 4 步：登记到 site.json 并重新构建

页头、导航、首页表格与摘要数字都由构建脚本生成，不要手改。

1. 在 `site.json` 的 `sections.knowledgebase.categories` 中找到对应类别，按顺序插入一条：

```json
{ "slug": "<文件名不含 .html>", "label": "<导航里显示的短标签>" }
```

2. 运行构建脚本：

```powershell
powershell -File build\build.ps1
```

构建会重建所有页面的页头与导航（当前项自动加 `class="current"`），用详情页的 `<h2>` 与 `<p class="subtitle">` 重建首页表格、更新摘要里的条目数，并刷新 `assets/kb-search-index.js`，新条目立刻能被搜索到。

3. 校验：`powershell -File build\build.ps1 -Check` 会检查 `site.json` 与页面是否一一对应、各页面标记块是否完整。

### 第 5 步：浏览器验证

页面不依赖运行时 `fetch`，可以直接双击 `knowledgebase/index.html` 打开，也可以启动任意静态服务后访问 `http://localhost:8000/knowledgebase/index.html`，检查：

- 页面正常加载，控制台无报错；
- 左侧导航类别齐全、当前项高亮正确；
- 首页表格与导航条目一致、类别正确；
- 首页搜索框能按问题/结论/关键词过滤条目，清空后恢复全部；
- 流程图正常渲染、无文字溢出；
- 每个 `pre.code` 右上角有“复制”按钮，点击后短暂显示“已复制”再回弹；
- 参考出处链接（若有）可用。

---

## 13. 新增知识检查清单

- [ ] 已确定分类（现有 7 类或新增类别）
- [ ] 文件名用英文短横线/下划线命名
- [ ] 已核实关键结论（对照权威原文）
- [ ] 已创建 `<文件名>.html`，已在 `site.json` 登记并通过 `build\build.ps1 -Check`
- [ ] 面包屑、`<h2>` 问题、`<p class="subtitle">` 短回答正确
- [ ] 详情页无“目录”章节，正文从“结论”开始
- [ ] 结论写在一句话/几句话内，结论框高亮
- [ ] 有必要的流程图/表格/示例已补充，SVG 用色符合第 9 节
- [ ] 文风口语化、无互联网黑话、无过度括号注释
- [ ] 末尾有“参考出处”，标注原始来源与相关章节，资料名已加超链接（外链带 `target="_blank" rel="noopener"`）
- [ ] `index.html` 已增加导航项、表格行并更新数量（由构建脚本完成）
- [ ] `assets/kb-search-index.js` 已刷新，新条目可被搜索到
- [ ] 双击打开与本地服务下浏览器验证均通过，无死链、无控制台报错

---

## 附录 A：详情页模板骨架

将 `<文件名>`、`<类别>`、`<问题>`、`<短回答>` 替换为实际内容，正文按需增删章节。

```html
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta>
<title><条目名> - 知识库</title>
<link rel="stylesheet" type="text/css" href="../assets/base.css" />
<link rel="stylesheet" type="text/css" href="../assets/knowledgebase.css" />
</head>

<body>
<!--#HEADER#-->
<div id="header">
<div class="left">
<a href="../index.html"><span style="color: #0070C0;">SAS</span>/<span style="color: #70AD47;">HELP</span></a>
</div>
<div class="right">
<a href="index.html">知识目录</a>
<a href="">文档</a>
<a href="conventions.html">开发约定</a>
</div>
</div>
<!--/#HEADER#-->

<!--#NAV#-->
<div id="nav">
<ul>
<li class="nav-cat">SDTM</li>
<li><a href="orres_stat_empty.html">--ORRES / --STAT 双空</a></li>

<li class="nav-cat">ADaM</li>
<li><a href="sdtm_var_in_adam.html">SDTM 变量保留</a></li>
<li><a href="population_flags.html">population flags</a></li>

<li class="nav-cat">临床提交</li>
<li><a href="reproducibility.html">程序文件可复现</a></li>
<li><a href="external_macro.html">避免外部宏调用</a></li>

<li class="nav-cat">SAS 编程</li>
<li><a href="<文件名>.html" class="current"><条目名></a></li>
</ul>
</div>
<!--/#NAV#-->

<div id="section">
<p class="crumb"><a href="index.html">知识库</a> / <类别></p>
<h2><问题></h2>
<p class="subtitle"><短回答></p>
<hr/>

<div class="detail">

<h3 id="conclusion">结论</h3>
<div class="conclusion">
<p>……</p>
</div>

<h3 id="...">……</h3>
<p>……</p>

<h3 id="refs">参考出处</h3>
<ul class="refs">
<li>……。<span class="src">……。</span></li>
</ul>

</div>
</div>

<script src="../assets/knowledgebase_copy.js"></script>
</body>
</html>
```

> 注意：模板里的“SAS 编程”类别为预留空类别；若新增的正是 SAS 编程类知识，把条目挂在它下面并去掉下面示例里多余的占位即可。新增条目时，记得同步更新**所有**已有详情页的导航。
