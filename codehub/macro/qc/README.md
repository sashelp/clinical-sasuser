# SAS 宏程序验收测试（QC）说明

本目录是 `dev/` 下宏程序的**验收测试工程**（QC），用于开发流程中的质量把关。
所有测试使用本地 SAS 9.4 批处理方式运行，可重复执行，结果可追溯。

## 目录结构

```
qc/
├── README.md                 本说明文件
├── run_all.ps1               一键运行脚本（全局，运行全部测试并汇总）
├── _results/                 汇总结果输出（qc_summary_*.txt / .html）
├── _framework/
│   ├── qc_env.sas           公共路径配置（修改本文件可迁移宏库位置）
│   ├── qc_framework.sas     测试框架宏（断言、用例、汇总协议）
│   └── qc_testdata.sas      公共测试数据构造宏
├── <主题>/                  与 dev/<主题>/ 对应的主题目录
│   └── <宏名>/              每个被测宏一个独立子目录
│       ├── <宏名>_test.sas          正测试（功能正确性）
│       ├── <宏名>_err_XX.sas        负测试（错误处理，每个错误场景一个文件）
│       ├── <宏名>_bug_*.sas         已知缺陷复现测试（回归跟踪）
│       └── logs/                    每次运行的 SAS 日志（自动生成）
```

## 测试内容

验收用例根据各宏的功能和参数契约设计，通常包含以下类别：

- **功能性测试**：检查正常输入下的返回值、输出数据集结构、变量属性、观测数及关键结果。
- **异常参数测试**：检查必需参数缺失、数据集或变量不存在、参数值非法等情况，确认宏输出预期诊断并按约定终止。
- **空输入数据集测试**：检查输入数据集或分母数据集为 0 条观测时的行为，确认输出、警告或中止符合宏的设计。
- **边界条件测试**：覆盖分类数不足、缺失值、无匹配、0 观测等边界输入，以及宏对这些输入的规定行为。
- **回归测试**：针对曾发现并处理的问题保留可重复用例，避免后续变更引入回退。

例如，`stat_countocc` 的验收会检查 subject/event 计数、百分比分母、缺失编码和累计行、多编码、自定义标签和格式、不同检验选项，以及空数据、单一分类水平和默认 `TEST=NONE` 等场景。各宏的具体用例以对应目录中的 SAS 测试程序为准。

## 测试类型

| 类型     | 命名规则            | 判定依据                                                                       | 用途                                |
| -------- | ------------------- | ------------------------------------------------------------------------------ | ----------------------------------- |
| 正测试   | `<宏>_test.sas`   | SAS 日志输出 `#####QC_RESULT ... STATUS=PASS`                                | 验证宏在正常输入下的功能与输出      |
| 负测试   | `<宏>_err_XX.sas` | 日志包含 `*EXPECTED_ERROR` 声明的错误文本且未出现 `QC_UNEXPECTED_CONTINUE` | 验证宏对非法/缺失参数正确报错并终止 |
| 缺陷复现 | `<宏>_bug_*.sas`  | 日志出现 `QC_RESULT STATUS=PASS` 说明缺陷已修复（FIXED）；否则为 DEFECT      | 记录已知缺陷，追踪修复进度          |

测试程序由 `run_all.ps1` 运行并汇总；报告结构见[使用方法 → 2. 报告输出结构](#2-报告输出结构)。

## 使用方法

### 1. 运行全部测试

```powershell
powershell -ExecutionPolicy Bypass -File qc\run_all.ps1
```

输出：

- 控制台实时显示每个测试的 PASS / FAIL / DEFECT / ERROR
- `qc\_results\qc_summary_<时间戳>.txt`（文本汇总）
- `qc\_results\qc_summary_<时间戳>.html`（网页版报告）

### 1.1 只运行指定宏的测试

```powershell
# 单个宏
powershell -ExecutionPolicy Bypass -File qc\run_all.ps1 -Macro sdtm_fulldomain

# 多个宏（逗号分隔）
powershell -ExecutionPolicy Bypass -File qc\run_all.ps1 -Macro ds_attr,sdtm_fulldomain

# 通配符（大小写不敏感）
powershell -ExecutionPolicy Bypass -File qc\run_all.ps1 -Macro 'var_*'

# 查看哪些宏有验收测试
powershell -ExecutionPolicy Bypass -File qc\run_all.ps1 -List
```

过滤规则：匹配 `qc\<主题>\<宏名>\` 的目录名，或测试文件名以 `<宏名>_` 开头；
支持 `*`、`?` 通配符。过滤运行同样生成汇总报告，文件名追加 `_<过滤条件>`（非法字符替换为 `-`）。
若过滤条件未匹配任何测试，脚本打印警告并以退出码 1 结束。

### 2. 报告输出结构

无论是 `.txt` 还是 `.html`，报告都包含两张表：

**① 宏汇总表（Macro Summary）—— 每个宏一行**

| 列        | 含义                                                                                             |
| --------- | ------------------------------------------------------------------------------------------------ |
| THEME     | 主题目录（`var` / `ds` / `file` / `lib` …）                                             |
| MACRO     | 被测宏名                                                                                         |
| POSITIVE  | 正测试结果：`PASS` / `FAIL` / `ERROR`，无正测试显示 `-`                                  |
| NEGATIVE  | 负测试结果：`n/m PASS`，有失败时追显示 `(k FAIL)`                                            |
| BUG_TRACK | 缺陷复现结果：`k DEFECT`（已修复则再显示 `, j FIXED`），无则 `-`                           |
| VERDICT   | **汇总结论**：有 FAIL/ERROR → `FAIL`；否则有 DEFECT → `DEFECT`；全部通过 → `PASS` |

> 汇总逻辑：任何一个测试程序 FAIL 或 ERROR，该宏整体判 `FAIL`；无 FAIL 但有 DEFECT，判 `DEFECT`；否则 `PASS`。

**② 逐测试明细表（Per-Test Detail）—— 每个测试程序一行**

在原 `STATUS / KIND / FILE / NCASE / NFAIL / DETAIL` 基础上新增两列：

- **`DESCRIPTION`（测试简介）**：紧跟 `FILE` 列，取自测试程序头部注释块的同一行
  `<文件名>.sas - <简介>`（通常是文件第 2 行），例如
  `* stat_countocc_err_01.sas - Negative test: DATA= empty` → `Negative test: DATA= empty`。
  新增测试文件请保持该格式，否则该列显示 `-`。描述最长 200 字符，超出部分截断，
  模板见 [3.1 测试程序文件模板](#31-测试程序文件模板强制)。
- **`REVISION`（修订建议）**：
  - `PASS` / `FIXED` 的测试 → `-`（无需修订）
  - `FAIL` / `DEFECT` / `ERROR` 的测试 → 给出针对 `dev/<主题>/<宏>.sas` 的具体修改建议

修订建议由两处维护：

- `run_all.ps1` 中的 `$RevMap`（哈希表）：为**已知缺陷**逐条配置精确的修复指引（例如「`lib_zipvarlen.sas`: 2.1 节 call execute 转发 delfmt/delinfmt 给 %ds_zipvarlen」）
- `Get-Rev` 函数：对未在 `$RevMap` 中登记的非 PASS 测试给出通用兜底建议（如负测试 FAIL →「修复宏：使非法/缺失参数按预期报错并 %abort cancel」）

> 新增测试时如发现新的已知缺陷，建议同步在 `$RevMap` 中登记一条修复指引，让报告能直接指导修复。

### 3. 新增宏的测试

对于 `dev/<主题>/<新宏>.sas`，按以下步骤（参考本仓库已有示例，并**必须**套用 3.1 的模板）：

1. 在 `qc/<主题>/` 下创建 `<新宏>/` 目录
2. 编写正测试 `<新宏>_test.sas`：
   - 头部注释块（见模板节）
   - `%include` 框架与宏
   - `%qc_begin/.../%qc_case/.../%qc_end` 组织用例
3. 为每个错误场景编写独立负测试 `<新宏>_err_XX.sas`
4. 若有已知缺陷，编写 `<新宏>_bug_*.sas`
5. 运行 `run_all.ps1` 验证

### 3.1 测试程序文件模板（强制）

> **硬性要求：每个测试程序的第 2 行必须是 `* <文件名>.sas - <一句话描述>`。**
> `run_all.ps1` 的 `Get-Desc` 用正则
> `^\s*[*/#]+\s*<basename>\.sas\s+-\s+(.+?)\s*(\*/)?\s*$`
> 扫描文件前 3 行，命中后把 `-` 之后的文本填入报告的 `DESCRIPTION` 列。
> 格式不符时该列显示 `-`，并且不会报错——所以务必保留这一行。

描述写作约定：

- 一句话说明"这个测试在测什么"，中文或英文皆可，**最长 200 字符**（超出部分被 `run_all.ps1` 截断）
- `.txt` 报告的 `DESCRIPTION` 列按当次运行中最长的描述自动加宽（上限 200），`NCASE` 等后续列始终对齐
- 负测试以场景为主，如 `Negative test: DATA= empty`；正测试可用一句话概括覆盖点
- 描述里避免出现行尾 `*/`；不要跨行书写（只取该行文本）

#### 模板 A：负测试 `<宏名>_err_XX.sas`（一个错误场景一个文件）

```sas
/*==============================================================================
 * <宏名>_err_01.sas - Negative test: <场景一句话描述>
 *==============================================================================
 * Macro under test : %<宏名>
 * Expected         : abort cancel with "<期望出现在日志中的报错文本>"
 *============================================================================*/
/*--- bootstrap: derive repo root from SYSIN, no absolute paths (qc_env.sas) ---*/
%let _qcboot_=%sysfunc(getoption(sysin));
%let _qcboot_=%substr(&_qcboot_.,1,%eval(%length(&_qcboot_.)-%length(%scan(&_qcboot_.,-1,%str(\)))-1));
%let _qcboot_=%substr(&_qcboot_.,1,%eval(%length(&_qcboot_.)-%length(%scan(&_qcboot_.,-1,%str(\)))-1));
%let _qcboot_=%substr(&_qcboot_.,1,%eval(%length(&_qcboot_.)-%length(%scan(&_qcboot_.,-1,%str(\)))-1));
%include "&_qcboot_.\_framework\qc_env.sas";
%let _qcboot_=;
/*----------------------------------------------------------------------------*/
%include "&_QCFW_.";
%include "&_QCDEV_<主题宏变量>_.\<依赖宏>.sas";   /* 按被测宏头 Dependency 补齐 */
%include "&_QCDEV_<主题宏变量>_.\<宏名>.sas";

%qc_begin(prog=<宏名>_err_01, macro=<宏名>);
%qc_case(desc=1 <场景描述>);
*EXPECTED_ERROR: <期望报文，须与宏实际输出完全一致，不含分号>;
%qc_abort_marker;
%<宏名>(<触发该错误的参数组合>);
%qc_unexpected_continue;
```

要点：`*EXPECTED_ERROR: ...;` 是 `run_all.ps1` 判定负测试 PASS 的唯一依据（正则
`\*EXPECTED_ERROR:\s*([^\r\n;]+);`）；`%qc_abort_marker;` 放在被调宏之前，
`%qc_unexpected_continue;` 放在之后——若宏没有 `%abort`，这两行会在日志里留下
`QC_UNEXPECTED_CONTINUE`，测试判 FAIL。

#### 模板 B：正测试 `<宏名>_test.sas`（一个宏一个文件，多用例）

```sas
/*==============================================================================
 * <宏名>_test.sas - Positive (functional) acceptance tests
 *==============================================================================
 * Macro under test : %<宏名>
 * File under test   : dev/<主题>/<宏名>.sas
 * Dependencies      : %<依赖宏>（与宏头 Dependency 一致）
 * Coverage          : <覆盖点：正常输入、边界值、选项组合、输出结构等>
 *============================================================================*/
/*--- bootstrap: derive repo root from SYSIN, no absolute paths (qc_env.sas) ---*/
%let _qcboot_=%sysfunc(getoption(sysin));
%let _qcboot_=%substr(%length(&_qcboot_.)-...);   /* 与模板 A 完全相同的 3 行回退 */
%include "&_qcboot_.\_framework\qc_env.sas";
%let _qcboot_=;
/*----------------------------------------------------------------------------*/
%include "&_QCFW_.";
%include "&_QCDEV_<主题宏变量>_.\...";

%qc_begin(prog=<宏名>_test, macro=<宏名>);

%qc_case(desc=1 <用例 1 描述>);
<构造测试数据 / 调用宏>
%qc_check_eq(actual=&r., expect=<期望>, desc=<断言描述>);

%qc_case(desc=2 <用例 2 描述>);
%qc_expect_ds(ds=<输出数据集>, desc=<断言描述>);
%qc_expect_nobs(ds=<输出数据集>, expect=<期望观测数>, desc=<断言描述>);
%qc_expect_len(ds=, var=, expect=, desc=);
%qc_expect_colval(ds=, var=, where=, expect=, desc=);

%qc_end;
```

要点：断言宏全部来自 `qc_framework.sas`（`%qc_check`、`%qc_check_eq`、
`%qc_expect_ds`、`%qc_expect_var`、`%qc_expect_nobs`、`%qc_expect_len`、
`%qc_expect_fmt`、`%qc_expect_file`、`%qc_expect_dir`、`%qc_expect_cnt`、
`%qc_expect_colval`）；必须以 `%qc_end;` 结束，它才会输出被 `run_all.ps1` 解析的
`QC_RESULT` 行。用例描述写法见"编写正测试的注意事项"第 1–4 条。

#### 模板 C：缺陷复现 `<宏名>_bug_<简短名>.sas`

```sas
/*==============================================================================
 * <宏名>_bug_<简短英文名>.sas - Bug regression: <缺陷一句话描述>
 *==============================================================================
 * Macro under test : %<宏名>
 * Expected         : <修复后应达到的正确行为>
 * Status           : OPEN | FIXED <yyyy-mm-dd> - <简述>
 * Original defect  : <缺陷现象与原始报错文本>
 * Fix              : <修复要点>
 * Test passes when  the defect is fixed (run_all then reports FIXED).
 *============================================================================*/
/*--- bootstrap: 与模板 A 相同 ---*/
%include "&_QCFW_.";
%include "&_QCDEV_<主题宏变量>_.\<依赖宏>.sas";
%include "&_QCDEV_<主题宏变量>_.\<宏名>.sas";
%qc_begin(prog=<宏名>_bug_<简短英文名>, macro=<宏名>);

<复现缺陷的最小输入>
%qc_case(desc=1 <应满足的行为>);
%qc_check_eq(actual=&r., expect=<期望>, desc=<断言描述>);

%qc_end;
```

要点：缺陷仍存在 → 断言失败、无 `QC_RESULT STATUS=PASS` → 报告 `DEFECT`；
缺陷修好后 → `FIXED`。修复后不要删除该文件，保留为回归用例。

### 4. 单宏快速调试

```powershell
& "sas.exe" -CONFIG "$env:SAS_CFG" -SYSIN qc\<主题>\<宏>\<宏>_test.sas -LOG ...\logs\<宏>_test.log -PRINT NONE -NOICON
```

## 测试框架协议（qc_framework.sas）

框架宏向 SAS 日志输出机器可读标记，由 run_all.ps1 解析：

| 标记                               | 含义                       |
| ---------------------------------- | -------------------------- |
| `#####QC_BEGIN prog= macro=`     | 用例开始                   |
| `#####QC_CASE n= desc=`          | 用例编号与描述             |
| `#####QC_PASS / QC_FAIL`         | 单条断言结果               |
| `#####QC_RESULT ... STATUS=PASS` | FAIL                       |
| `#####QC_ABORT_MARKER`           | 负测试：期望终止的位置标记 |
| `#####QC_UNEXPECTED_CONTINUE`    | 负测试：宏未终止（缺陷）   |

## 编写正测试的注意事项

1. **函数返回负数时的传递**：`%var_coexist(...,resulttype=POSITION)` 返回 `-1/-2` 等负值，直接放进 `%qc_check_eq(actual=...)` 会导致宏解析错乱。应先用 `%let r=%宏();` 捕获，再传 `&r.`。
2. **正则表达式元字符**：`PATTERN=` 参数传给 `prxparse` 需带**定界符**（如 `pattern=/^num/`），且 `^`、`$` 等字符在多层宏嵌套中需用 `%nrstr` + `%superq` 保护（见 ds_varlist 测试）。
3. **`desc=` 描述中避免使用 `)`、`%` 与 `,`**，否则会截断宏参数（逗号会被当作参数分隔符，导致 "所有位置参数均应位于关键字参数之前" 错误）。
4. **开放代码中不能使用 `%if`**，正测试中需把 `%if %宏() %then` 包装在宿主宏内。
5. **负测试的一个场景必须单独一个 SAS 作业**：被测试宏用 `%abort cancel` 终止整个会话。
6. **被测宏引用了库内 helper 时，测试文件必须按宏头 `Dependency` 一并 `%include`**。
   例如 `%sdtm_fulldomain` 依赖 `%var_exist`、`%var_attr`、`%var_coexist`；缺少时会报
   `没有解析宏 "VAR_COEXIST" 的调用` 并导致被测宏终止，测试表现为"输出数据集不存在"而非真实结果。

## 修改配置

- SAS 可执行文件 / 配置路径：修改 `run_all.ps1` 顶部 `$SasExe` / `$SasCfg`
- 宏库根路径：**无需配置**。`$QcRoot` 取 `run_all.ps1` 所在目录（`$PSScriptRoot`），
  `qc_env.sas` 再从 SYSIN 上溯 4 层推导 `_QCROOT_`，并校验
  `_framework\qc_env.sas` 是否存在，推导失败立即 `%abort cancel`。

**只有 SAS 程序与配置文件两处需要写绝对路径。** 所有测试文件（`*_test.sas` /
`*_err_XX.sas` / `*_bug_*.sas`）在开头使用同一段引导块，从 SAS 自身的 SYSIN 路径
推导出仓库位置，再用 `&_QCFW_.`、`&_QCDEV_*_.`、`&_QCSB_*_.`、`&_QCRES_.` 等宏变量
引用其它文件：

```sas
/*--- bootstrap: derive repo root from SYSIN, no absolute paths (qc_env.sas) ---*/
%let _qcboot_=%sysfunc(getoption(sysin));
%let _qcboot_=%substr(&_qcboot_.,1,%eval(%length(&_qcboot_.)-%length(%scan(&_qcboot_.,-1,%str(\)))-1));
%let _qcboot_=%substr(&_qcboot_.,1,%eval(%length(&_qcboot_.)-%length(%scan(&_qcboot_.,-1,%str(\)))-1));
%let _qcboot_=%substr(&_qcboot_.,1,%eval(%length(&_qcboot_.)-%length(%scan(&_qcboot_.,-1,%str(\)))-1));
%include "&_qcboot_.\_framework\qc_env.sas";
%let _qcboot_=;
```

每个测试文件都位于 `qc\<主题>\<宏>\`（距 `qc` 根 3 层），所以引导块固定回退 3 级得到
`qc` 目录，再 include `_framework\qc_env.sas`；`qc_env.sas` 内部按同样的规则再回退 1 级
得到 `Macro` 根。因此**整个 `qc` / `dev` 目录搬移、或用 OneDrive 在多台机器间同步时，
无需修改任何脚本**，前提是测试文件保持在 `qc\<主题>\<宏>\` 的三层位置。

新增测试文件时，直接复制任一现有测试文件开头的引导块即可，不要写死绝对路径。
