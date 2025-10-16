import re
from pathlib import Path

# このスクリプトのあるフォルダを基準にする
BASE_DIR = Path(__file__).resolve().parent
src_dir = BASE_DIR / "src"
build_file = BASE_DIR / "build" / "main.html"
build_file.parent.mkdir(exist_ok=True, parents=True)


def snake_to_pascal(s):
    return "".join(word.capitalize() for word in s.split("_"))


def process_text(text):
    text = text.replace("infinity", "Infinity")
    text = re.sub(r"(^|(?<=\s))//.*$", "", text, flags=re.MULTILINE)  # remove comments
    text = re.sub(r"\b(if|for|while) ([^{\n]+) {", r"\1 (\2) {", text)
    text = re.sub(r"fn ([^(]+)(.*?)\) {", r"const \1 = \2) => {", text)
    # text = re.sub(r"fn ([\w.]+)\((.*?)\) {", r"\1 = (\2) => {", text)
    text = text.replace(" == ", " === ")
    text = text.replace(" ~= ", " !== ")
    text = text.replace("nil", "undefined")
    text = re.sub(
        r"\bnew ([a-zA-Z0-9_]+)", lambda m: f"new {snake_to_pascal(m.group(1))}", text
    )
    text = re.sub(
        r"([a-z0-9])_([a-z0-9])", lambda m: m.group(1) + m.group(2).upper(), text
    )
    text = text.replace("math.", "Math.")
    text = re.sub(r"([a-zA-Z0-9_]+)\s+:=\s+", r"const \1 = ", text)
    # text = re.sub(r"\bfn (\w+)\((.*?)\) {", r"const \1 = (\2) => {", text)
    # text = re.sub(r"([a-zA-Z0-9]+)\s+:=\s+\(?(.*)\)? => {",
    #       r"const \1 = (\2) => {", text)
    # text = re.sub(r"^\s*(.*)\s+:=\s+", r"const \1 = ", text)
    # text = re.sub(r"([^\s]+)\s+:=\s+", r"const \1 = ", text)
    text = re.sub(r"\[(.*)\]\s+:=\s+", r"const [\1] = ", text)
    text = re.sub(r"^\s*\n", "", text, flags=re.MULTILINE)  # remove empty lines
    text = re.sub(r"fn\(([^{]*)\)", r"(\1) =>", text)  # anonymous functions
    text = re.sub(
        r"const (([a-zA-Z0-9_]+)(\.[a-zA-Z0-9_]+)+.* =>)", r"\1", text
    )  # remove the consts that we added lol
    text = re.sub(
        r"const ([a-zA-Z0-9_]+\[.* =>)", r"\1", text
    )  # remove the consts that we added lol
    return text


# Concatenate all JS files (except main.zs first), then main.zs last
all_text = ""

for file in sorted(src_dir.glob("*.zs")):
    if file.name == "main.zs":
        continue
    all_text += file.read_text(encoding="utf-8") + "\n"

main_file = src_dir / "main.zs"
if main_file.exists():
    all_text += main_file.read_text(encoding="utf-8")

# Process everything at once
processed_text = process_text(all_text)

with build_file.open("w", encoding="utf-8") as out:
    out.write('<!doctype html><body><script>"use strict"\n')
    out.write(processed_text)
    out.write("</script>")
