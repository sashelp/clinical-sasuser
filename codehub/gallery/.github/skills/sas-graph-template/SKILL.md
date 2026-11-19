---
name: sas-graph-template
description: "Use this skill to create new SAS gallery graphics in the style of existing scatter, series, and box templates. It captures the common design pattern, template structure, and output conventions used across the project."
---

# SAS Graph Template

Use this skill when creating a new .sas chart template in the Gallery project. It captures the recurring pattern used by the existing scatter, series, and box programs and is intended to help generate new chart scripts consistently.

Ignore `gen_gallery_html.sas`; it is a gallery generator, not a chart template. The reusable pattern is in the per-chart programs under the type folders, such as `scatter/`, `series/`, and `box/`.

## Core pattern across the gallery

The SAS programs in this project all follow the same three-phase structure:

1. Prepare/transform data
2. Define a `statgraph` template with `proc template`
3. Render the graph using `proc sgrender` and export to RTF/PNG

This design pattern is the foundation for all new chart programs.

## Standard skeleton

```sas
/* Header metadata */
/*
*Name       : <图表名称>
*Brief      : <简要说明>
*Param      : X=<var>,必需参数,X 轴变量
*Param      : Y=<var>,必需参数,Y 轴变量
*Param      : CLASS=<var>,可选参数,分组变量, 未指定时, 全部数据被视为属于同一组别
*Param      : XMIN=<num>,可选参数,X 轴最小刻度值
*Param      : XMAX=<num>,可选参数,X 轴最大刻度值
*Param      : XINC=<num>,可选参数,X 轴分度值
*Param      : YMIN=<num>,可选参数,Y 轴最小刻度值
*Param      : YMAX=<num>,可选参数,Y 轴最大刻度值
*Param      : YINC=<num>,可选参数,Y 轴分度值
*Note       : <说明>
*Dependency : NULL
*Version    : SAS 9.4M7
*History    : <日期>, <作者>, <说明>
*/

/* 1. 获取绘图数据 */
proc format;
  value val_2mask
  low-high='XX'
  ;
  value cls_2mask
  1='组别 1'
  2='组别 2'
  ;
run;

data tab1;
  set sashelp.class;  * or any base dataset
  sexn=whichc(sex,'M','F');
run;

/* 2. 定义绘图模板 */
proc template;
  define statgraph <template_name>;
  begingraph;
  dynamic x y class xmin xmax xinc ymin ymax yinc;
  layout overlay/walldisplay=none
    xaxisopts=(label=eval(collab(x)) offsetmin=0.03 offsetmax=0.03
      linearopts=(thresholdmin=1 thresholdmax=1
      viewmin=xmin viewmax=xmax tickvaluesequence=(start=xmin end=xmax increment=xinc)))
    yaxisopts=(label=eval(collab(y)) offsetmin=0.03 offsetmax=0.08
      linearopts=(thresholdmin=1 thresholdmax=1
      viewmin=ymin viewmax=ymax minorticks=1 minortickcount=4
      tickvaluesequence=(start=ymin end=ymax increment=yinc)));

    /* one chart statement, for example:
       scatterplot x=x y=y/group=class index=class grouporder=ascending name="sca";
       seriesplot x=x y=y/group=class index=class grouporder=ascending name="ser";
       boxplot x=x y=y/orient=vertical group=class index=class boxwidth=0.4 grouporder=ascending;
    */

    /* legends if needed */
    /* discretelegend "sca"/location=inside autoalign=(topright) down=1 border=0; */
  endlayout;
  endgraph;
  end;
run;

/* 3. 绘制图形 */
%let out_path=Z:\SASUSER\CodeHub\Gallery\output;
ods _all_ close;
ods graphics on/reset=all outputfmt=png width=12cm height=9cm noborder;
ods rtf file="&out_path\<folder>\<template_name>.rtf" image_dpi=300 style=htmlblue startpage=no;
proc sgrender data=tab1 template=<template_name>;
  dynamic x="..." y="..." class="..." xmin=... xmax=... xinc=... ymin=... ymax=... yinc=...;
  format ...;
  label ...;
run;

proc report data=sashelp.class style(report)={pretext="Title: <template_name>" just=left font_size=10.5pt};
  column name;
  define name/noprint;
run;
ods rtf close;
ods graphics off;
```

## Creative conventions used by the gallery

### 1) Data preparation is explicit and light
- Use a `proc format` block to create `val_2mask` and `cls_2mask` style mappings.
- Convert grouping variables to numeric codes using `whichc()` when discrete group colors or legends are needed.
- Keep a clean intermediate dataset such as `tab1`, `tab2`, or `tab3` and avoid mixing transformation logic into the rendering phase.

### 2) Templates are reusable and parameterized
- Every `statgraph` typically declares `dynamic x y class ...` plus axis range variables like `xmin xmax xinc ymin ymax yinc`.
- Axis control happens through `xaxisopts` and `yaxisopts` using `eval(collab(x))`, `viewmin`, `viewmax`, and `tickvaluesequence`.
- When chart bounds are known, set them in `proc sgrender` with explicit `dynamic` arguments; otherwise let SAS infer them.

### 3) Plot logic is separated from appearance logic
- Plot statements appear inside `layout overlay`.
- `format` and `label` are applied in the render step rather than hardcoded into the template whenever the title/labels need to vary by dataset or use case.
- Legends are added with `discretelegend`, `mergedlegend`, or custom legend patterns depending on whether the plot is grouped or multi-series.

### 4) Output is consistent and gallery-friendly
- Keep the output path pattern: `&out_path\<chart_type>\<template_name>.rtf`.
- Use `ods graphics on/reset=all outputfmt=png width=12cm height=9cm noborder`.
- Add a small `proc report` with `pretext="Title: <template_name>"` so each chart has a visible title in the output document.

## Chart family patterns

### Scatter charts
- Typical structure: `scatterplot x=x y=y/group=class index=class ...;`
- Usually paired with `discretelegend`.
- Best for revealing relationships between two quantitative variables.

### Series / line charts
- Typical structure: `seriesplot x=x y=y/group=class ...;`
- Often add a `scatterplot` layer and a `mergedlegend` to show trace + points together.
- Good for temporal trends and grouped changes over the x-axis.

### Box charts
- Typical structure: `boxplot x=x y=y/orient=vertical group=class ...;`
- Use `display=(caps mean median outliers)` when appropriate.
- Good for comparing distributions across groups.

## Tips for new programs

- Choose a file name and template name that match, such as `scatter3.sas` + `define statgraph scatter3;`.
- Use `sashelp` examples first when exploring the chart idea; later replace with the project dataset.
- Preserve the same 3-part layout so the gallery remains easy to scan and maintain.
- Favor explicit grouping via `whichc` and `class` rather than ad hoc custom encoding.
- Keep axis labels meaningful and consistent with the underlying variables.

## Anti-patterns to avoid

- Do not copy a generator file such as `gen_gallery_html.sas` and treat it as a chart template source.
- Do not collapse data preparation, template definition, and rendering into a single block.
- Do not hardcode axis values in the template when the project convention is to pass them through `dynamic`.
- Do not create one-off legend or axis logic that breaks the consistent gallery style.
- Do not validate Chinese SAS source with the default MBCS session when a UTF-8 session is available.

## Example transformation mindset

When creating a new graph:

1. Identify the x/y variables and optional group variable.
2. Create a prepared dataset (`tab1`) with numeric group codes if needed.
3. Define a graph template using `layout overlay` and plot-specific statements.
4. Call `proc sgrender` with the template and explicit dynamic values.
5. Export to the RTF output path and add the title block.

This is the reuse pattern the gallery uses repeatedly.

## Running and debugging in a UTF-8 SAS session

When executing a Gallery program on Windows, always prefer the installed SAS executable
with an explicit UTF-8 session:

```powershell
$sas = 'C:\Program Files\SASHome\SASFoundation\9.4\sas.exe'
$source = 'Z:\SASUSER\CodeHub\Gallery\prog\scatter\scatter6.sas'
$log = 'Z:\SASUSER\CodeHub\Gallery\output\scatter\scatter6_utf8.log'

& $sas -nodms -encoding utf-8 -sysin $source -log $log
Write-Host "ExitCode=$LASTEXITCODE"
```

Confirm the session encoding before trusting the result:

```sas
%put ENCODING=%sysfunc(getoption(encoding));
proc options option=encoding;
run;
```

The log must contain `ENCODING=UTF-8`. The source file itself should also be saved as
UTF-8 (preferably UTF-8 without an incompatible legacy code page), especially when it
contains Chinese comments, labels, titles, or format values.

### Error-driven debugging loop

1. Run the program with `-encoding utf-8`, a dedicated `.log`, and an explicit exit-code check.
2. Read the log, not only the process exit code. A zero exit code does not guarantee that
   the SAS log is free of `ERROR:` or `WARNING:` messages.
3. Fix the first actionable `ERROR:` in source order, then rerun the complete program.
   Do not hide errors with broad options or by ignoring the log.
4. If the graph renders but a warning remains, decide whether it is caused by the change.
   For example, `PROC REPORT data=sashelp.class` can warn about transcoding legacy
   SASHELP character data in a UTF-8 session; this is separate from GTL rendering.
5. Verify all expected outputs after rerunning, such as the RTF file, PNG image, and
   any intermediate data sets reported in the log.

Useful PowerShell checks:

```powershell
if (-not (Test-Path $source)) { throw "SAS source not found: $source" }
if (-not (Test-Path $log)) { throw "SAS log not created: $log" }

$errors = Select-String -Path $log -Pattern 'ERROR:'
$warnings = Select-String -Path $log -Pattern 'WARNING:'
if ($errors) { $errors | ForEach-Object { Write-Error $_.Line } }
if ($warnings) { $warnings | ForEach-Object { Write-Warning $_.Line } }
```

### Common diagnosis categories

- **Source or encoding errors**: confirm the file is UTF-8 and the command includes
  `-encoding utf-8`; garbled Chinese text in the log is often a display/code-page issue,
  so inspect the actual `ERROR:` and `WARNING:` content before changing SAS code.
- **Missing SAS components**: errors around `GINSIDE`, maps, or graph procedures require
  the corresponding licensed SAS/GRAPH component; verify the installed SAS products.
- **GTL compile errors**: inspect `PROC TEMPLATE` syntax, dynamic variable names, plot
  statement options, and whether every referenced variable exists in the render dataset.
- **Rendering/data errors**: inspect the `NOTE:` row counts for the input and combined
  plotting data sets, then verify `PROC SGRENDER` reads the intended dataset and template.
- **Output errors**: check that the output directory exists and that the RTF/PNG file is
  not locked by an open viewer.

After correcting an error, rerun with the same UTF-8 command and keep the log beside the
generated output when the result is useful for future diagnosis.
