import argparse
import sys
from pathlib import Path

try:
    from lxml import etree
except ImportError:
    print("错误：缺少依赖 'lxml'。请先安装：")
    print("    pip install lxml")
    sys.exit(1)


def ask_user(prompt, default=""):
    if default:
        value = input(f"{prompt} [{default}]：").strip()
        return value or default
    value = input(f"{prompt}：").strip()
    return value


def resolve_path(path_value, base_dir):
    path = Path(path_value)
    if path.is_absolute():
        return path
    return (base_dir / path).resolve()


def main():
    parser = argparse.ArgumentParser(description="将 XML + XSL 转换为 HTML")
    parser.add_argument("xml_file", nargs="?", default="", help="输入的 XML 文件路径")
    parser.add_argument("xsl_file", nargs="?", default="", help="输入的 XSL 文件路径")
    parser.add_argument("output_file", nargs="?", default="", help="输出的 HTML 文件路径")
    args = parser.parse_args()

    script_dir = Path(__file__).resolve().parent
    current_dir = Path.cwd()

    print("XML/XSL 转 HTML 工具")
    print("如果不输入内容，直接按回车即可使用默认值。")

    xml_input = args.xml_file or ask_user("请输入 XML 文件", "define.xml")
    xsl_input = args.xsl_file or ask_user("请输入 XSL 文件", "define2-1-0.xsl")
    output_input = args.output_file or ask_user("请输入输出 HTML 文件", "define.html")

    xml_path = resolve_path(xml_input, current_dir)
    if not xml_path.exists():
        xml_path = resolve_path(xml_input, script_dir)

    xsl_path = resolve_path(xsl_input, current_dir)
    if not xsl_path.exists():
        xsl_path = resolve_path(xsl_input, script_dir)

    output_path = resolve_path(output_input, current_dir)

    if not xml_path.exists():
        print(f"错误：找不到 XML 文件：{xml_path}")
        return 1

    if not xsl_path.exists():
        print(f"错误：找不到 XSL 文件：{xsl_path}")
        return 1

    try:
        xml_tree = etree.parse(str(xml_path))
        xslt_tree = etree.parse(str(xsl_path))
        transform = etree.XSLT(xslt_tree)
        result_tree = transform(xml_tree)
    except Exception as exc:
        print(f"转换失败：{exc}")
        return 1

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "wb") as f:
        f.write(etree.tostring(result_tree, pretty_print=True, method="html"))

    print(f"转换成功！输出文件：{output_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())