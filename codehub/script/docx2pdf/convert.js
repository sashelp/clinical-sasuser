/**
 * convert.js — 一键 docx → pdf 转换工具
 * 
 * 流程：
 *   1. Word COM (PowerShell) 导出 PDF + 书签
 *   2. qpdf JSON 往返：写入 PageMode + PageLayout + Linearized
 * 
 * 用法：
 *   node convert.js <input.docx>
 *   node convert.js <input.docx> <output.pdf>
 *   node convert.js <folder_path>
 */

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const SCRIPT_DIR = __dirname;
const LOG_LINES = [];

// ============================================================
// 工具函数
// ============================================================

function log(msg) {
    const line = `[${new Date().toLocaleTimeString()}] ${msg}`;
    console.log(line);
    LOG_LINES.push(line);
}

function error(msg) {
    const line = `[ERROR] ${msg}`;
    console.error(line);
    LOG_LINES.push(line);
}

function getQpdfPath() {
    // Look for qpdf.exe in script directory or PATH
    const local = path.join(SCRIPT_DIR, 'qpdf', 'bin', 'qpdf.exe');
    if (fs.existsSync(local)) {
        log(`qpdf 已找到: ${local}`);
        return local;
    }
    // Try PATH
    try {
        const result = execSync('where qpdf 2>nul', { encoding: 'utf8' }).trim();
        if (result) {
            const p = result.split('\n')[0].trim();
            log(`qpdf 已找到 (PATH): ${p}`);
            return p;
        }
    } catch (e) { /* not in PATH */ }
    error('qpdf 未找到！请确保 qpdf.exe 位于: ' + local);
    error('  Linearized 和 PageMode 设置将跳过');
    return null;
}

// ============================================================
// 阶段 1：Word COM 转换 docx → pdf
// ============================================================

function convertWithWord(inputPath, outputPath) {
    return new Promise((resolve, reject) => {
        const psScript = path.join(SCRIPT_DIR, 'convert_word.ps1');
        log(`Word COM 转换: ${path.basename(inputPath)}`);

        const ps = spawn('powershell', [
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', psScript,
            '-InputPath', inputPath,
            '-OutputPath', outputPath
        ], { stdio: ['ignore', 'pipe', 'pipe'] });

        let stdout = '';
        let stderr = '';

        ps.stdout.on('data', d => { stdout += d.toString(); });
        ps.stderr.on('data', d => { stderr += d.toString(); });

        ps.on('close', (code) => {
            if (code === 0) {
                log(`  -> PDF 已生成: ${outputPath}`);
                resolve(outputPath);
            } else {
                reject(new Error(`Word COM 转换失败 (code ${code}):\n${stderr || stdout}`));
            }
        });

        ps.on('error', (err) => {
            reject(new Error(`无法启动 PowerShell: ${err.message}`));
        });
    });
}

// ============================================================
// 阶段 2 + 3：qpdf 一站式处理 — PageMode/PageLayout + Linearized
// 通过 qpdf JSON 往返修改 catalog，再 linearize
// ============================================================

function postProcessAndLinearize(pdfPath) {
    const qpdf = getQpdfPath();
    if (!qpdf) {
        log('qpdf 未找到，跳过后处理与 Linearized 优化');
        return false;
    }

    log(`qpdf 后处理: PageMode + PageLayout + Linearized`);

    const tmpJson = pdfPath + '.qpdf.json';
    const tmpPdf = pdfPath + '.qpdf.tmp';
    const tmpPdf2 = pdfPath + '.qpdf.tmp2';

    try {
        // Step 1: Export full JSON from PDF
        const jsonStr = execSync(`"${qpdf}" --json "${pdfPath}"`, {
            encoding: 'utf8',
            timeout: 30000,
            maxBuffer: 100 * 1024 * 1024,
            windowsHide: true
        });

        const full = JSON.parse(jsonStr);

        // Step 2: Add PageMode/PageLayout to the catalog object
        // The catalog is obj:1 0 R in qpdf JSON v2 format
        const catalogKey = 'obj:1 0 R';
        const qpdfData = full.qpdf && full.qpdf[1];
        if (!qpdfData || !qpdfData[catalogKey]) {
            error('无法在 qpdf JSON 中找到 Catalog 对象，仅做 linearize');
            // Fallback: just linearize without catalog modification
            execSync(`"${qpdf}" --linearize --replace-input "${pdfPath}"`, {
                encoding: 'utf8', timeout: 30000, windowsHide: true
            });
            log('  -> Linearized 完成（未修改 catalog）');
            return true;
        }

        const catalog = qpdfData[catalogKey].value;
        if (!catalog['/PageMode']) {
            catalog['/PageMode'] = '/UseOutlines';
        }

        // Step 2b: Set initial view — Fit Width
        // /FitH null = fit page width, null top = default vertical position
        catalog['/OpenAction'] = ['/FitH', null];

        // Step 2c: Expand all bookmarks
        function expandAllOutlines(items, qpdfData) {
            if (!items || !Array.isArray(items)) return;
            for (const item of items) {
                if (item.object) {
                    const objKey = 'obj:' + item.object.replace(/\s+/g, ' ');
                    const realObj = qpdfData[objKey];
                    if (realObj && realObj.value && typeof realObj.value['/Count'] === 'number') {
                        if (realObj.value['/Count'] < 0) {
                            realObj.value['/Count'] = -realObj.value['/Count'];
                        }
                    }
                }
                if (item.kids) expandAllOutlines(item.kids, qpdfData);
            }
        }
        if (full.outlines) expandAllOutlines(full.outlines, qpdfData);

        // Step 3: Write modified JSON
        fs.writeFileSync(tmpJson, JSON.stringify(full));

        // Step 4: Apply catalog/bokmark changes (step 1)
        const tmpPdf2 = pdfPath + '.qpdf.tmp2';
        execSync(`"${qpdf}" --update-from-json="${tmpJson}" "${pdfPath}" "${tmpPdf}"`, {
            encoding: 'utf8', timeout: 30000, windowsHide: true
        });

        // Step 5: Linearize (step 2, separate to isolate failures)
        execSync(`"${qpdf}" --linearize "${tmpPdf}" "${tmpPdf2}"`, {
            encoding: 'utf8', timeout: 30000, windowsHide: true
        });

        // Step 6: Replace original with final file
        fs.unlinkSync(pdfPath);
        fs.unlinkSync(tmpPdf);
        fs.renameSync(tmpPdf2, pdfPath);

        log(`  -> PageMode=UseOutlines, FitWidth, AllBookmarksExpanded, Linearized 完成`);
        return true;
    } catch (e) {
        error(`qpdf 后处理失败: ${e.stderr || e.message}`);
        return false;
        try { fs.unlinkSync(tmpJson); } catch (_) {}
        try { fs.unlinkSync(tmpPdf); } catch (_) {}
        try { fs.unlinkSync(tmpPdf2); } catch (_) {}
    } finally {
        try { fs.unlinkSync(tmpJson); } catch (_) {}
        try { fs.unlinkSync(tmpPdf); } catch (_) {}
        try { fs.unlinkSync(tmpPdf2); } catch (_) {}
    }
}

// ============================================================
// 主流程：单文件转换
// ============================================================

async function convertOne(inputPath, outputPath) {
    const absInput = path.resolve(inputPath);
    const absOutput = path.resolve(outputPath || inputPath.replace(/\.docx$/i, '.pdf'));

    if (!fs.existsSync(absInput)) {
        error(`文件不存在: ${absInput}`);
        return false;
    }

    const ext = path.extname(absInput).toLowerCase();
    if (ext !== '.docx') {
        error(`不支持的文件格式: ${ext}（仅支持 .docx）`);
        return false;
    }

    try {
        // 阶段 1: Word COM 导出
        await convertWithWord(absInput, absOutput);

        // 阶段 2+3: qpdf 后处理
        const qpdfOk = postProcessAndLinearize(absOutput);

        // 写日志文件（与 PDF 同目录）
        const logFile = absOutput.replace(/\.pdf$/i, '.log');
        fs.writeFileSync(logFile, LOG_LINES.join('\n'), 'utf8');

        log(`✅ 完成: ${absOutput}`);
        return true;
    } catch (e) {
        error(`转换失败: ${e.message}`);
        // 也写日志文件
        const logFile = absOutput.replace(/\.pdf$/i, '.log');
        try { fs.writeFileSync(logFile, LOG_LINES.join('\n'), 'utf8'); } catch (_) {}
        return false;
    }
}

// ============================================================
// 批量转换
// ============================================================

async function convertBatch(folderPath) {
    const dir = path.resolve(folderPath);
    if (!fs.statSync(dir).isDirectory()) {
        error(`不是文件夹: ${dir}`);
        return;
    }

    const files = fs.readdirSync(dir)
        .filter(f => f.toLowerCase().endsWith('.docx'))
        .filter(f => !f.startsWith('~$'));  // 跳过 Word 临时文件

    if (files.length === 0) {
        log(`文件夹中没有 .docx 文件: ${dir}`);
        return;
    }

    log(`批量转换 ${files.length} 个文件...`);
    let ok = 0, fail = 0;
    for (const f of files) {
        const input = path.join(dir, f);
        const output = input.replace(/\.docx$/i, '.pdf');
        const success = await convertOne(input, output);
        if (success) ok++; else fail++;
    }
    log(`批量完成: ${ok} 成功, ${fail} 失败`);
}

// ============================================================
// 入口
// ============================================================

async function main() {
    const args = process.argv.slice(2);

    if (args.length === 0 || args[0] === '--help' || args[0] === '-h') {
        console.log(`
docx2pdf — 一键 .docx → .pdf 转换，自动生成书签、设置初始视图、线性化

用法:
  node convert.js <input.docx>             转换单个文件
  node convert.js <input.docx> <output.pdf> 指定输出路径
  node convert.js <folder_path>            批量转换文件夹内所有 .docx

PDF 输出特性:
  - 文档结构标题 -> PDF 书签（基于 outline level 的段落样式）
  - 承前缩放：不强制每页缩放，继承前页比例
  - 初始视图：打开时自动显示书签面板
  - 快速 Web 查看：Linearized PDF，支持边下载边渲染

依赖:
  - Microsoft Word（COM 自动化）
  - qpdf（可选，用于 Linearized 优化）
        `);
        return;
    }

    const target = args[0];
    const stat = fs.statSync(target, { throwIfNoEntry: false });

    if (!stat) {
        error(`路径不存在: ${target}`);
        process.exit(1);
    }

    if (stat.isDirectory()) {
        await convertBatch(target);
    } else {
        const output = args.length >= 2 ? args[1] : null;
        const ok = await convertOne(target, output);
        process.exit(ok ? 0 : 1);
    }
}

main().catch(e => {
    error(`未预期的错误: ${e.message}`);
    console.error(e.stack);
    process.exit(1);
});
