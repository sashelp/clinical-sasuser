=== docx2pdf Portable ===
 一键 .docx → .pdf 转换工具，支持书签、初始视图、快速 Web 查看

【系统要求】
  - Windows 10/11
  - Microsoft Word 必须已安装（用于文档渲染）
  - 无需安装 Node.js（已捆绑）

【使用方法】
  1. 解压此压缩包到任意目录
  2. 将 .docx 文件拖拽到 convert.vbs 图标上
  3. 等待弹窗提示"Done!"，点击"是"即可打开 PDF

  或者：
  双击 convert.vbs 选择文件
  或者命令行：convert.bat 文件.docx

【输出位置】
  生成的 .pdf 与原 .docx 在同一文件夹，同名。

【PDF 特性】
  - 文档标题自动转换为 PDF 书签（全部展开）
  - 打开时默认"适合宽度"视图
  - 书签面板自动显示
  - 支持快速 Web 查看（Linearized PDF）

【文件说明】
  convert.vbs      - 拖拽启动器（推荐使用）
  convert.bat      - 命令行启动器
  convert.js       - 主程序
  convert_word.ps1 - Word COM 引擎
  node.exe         - Node.js 运行环境
  qpdf/bin/        - PDF 后处理工具

【注意事项】
  - 请勿移动或删除压缩包内的任何文件
  - 如需在桌面使用，右键 convert.vbs → 发送到 → 桌面快捷方式
  - 转换过程中请勿操作 Word

【版本】
  Node.js v24.18.0 / qpdf 11.10.1
