"""Converts gettext .po files (Godot, and most engines' i18n exports) into one Roblox
LocalizationTable CSV.

    python tools/convert_po.py <folder-with-po-files> [output.csv]

Default output: src/localization/GameStrings.csv (put the folder in default.project.json, for
example under ReplicatedStorage, and Rojo turns the .csv into a LocalizationTable).
Columns: Key,Source,Context,Example,<one Roblox locale id per language>. Key is left empty;
Roblox matches translations by Source + Context, so look strings up the same way in code.
Row order: the .pot file's msgids if there is one, then msgids found only in .po files.
Godot BBCode ([b], [i], [u], [s], [color=#rrggbb]) becomes Roblox RichText; alignment tags
are dropped; anything else is left as it is and counted in the report. Fuzzy entries are skipped.
The source folder is only read. The output is generated: rerun this instead of editing it.
"""

from __future__ import annotations

import csv
import re
import sys
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DEFAULT_OUT = REPO / "src" / "localization" / "GameStrings.csv"

# .po locale code -> Roblox locale id (from Roblox's supported-languages list). Region forms
# such as de_DE fall back to their language (de); add entries for codes your files use.
LOCALES = {
    "ar": "ar-001", "bg": "bg-bg", "cs": "cs-cz", "da": "da-dk", "de": "de-de",
    "el": "el-gr", "es_419": "es-mx", "es_ES": "es-es", "fi": "fi-fi",
    "fr": "fr-fr", "hu": "hu-hu", "id": "id-id", "it": "it-it", "ja": "ja-jp",
    "ko": "ko-kr", "ms": "ms-my", "nb": "nb-no", "nl": "nl-nl", "pl": "pl-pl",
    "pt": "pt-pt", "pt_BR": "pt-br", "ro": "ro-ro", "ru": "ru-ru", "sv": "sv-se",
    "th": "th-th", "tr": "tr-tr", "uk": "uk-ua", "vi": "vi-vn",
    "zh_CN": "zh-cn", "zh_TW": "zh-tw",
}  # Anything else found is reported and skipped.


def roblox_locale(code: str) -> str | None:
    return LOCALES.get(code) or LOCALES.get(code.replace("-", "_")) or LOCALES.get(code.split("_")[0].split("-")[0])

SIMPLE_TAGS = {"b": "b", "i": "i", "u": "u", "s": "s"}
STRIP_TAGS = {"center", "right", "left", "fill"}
TAG_RE = re.compile(r"\[(/?)([A-Za-z_]+)(?:=([^\]\s]*))?(\s[^\]]*)?\]")
COLOR_RE = re.compile(r"#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?")

UNESC = {"n": "\n", "t": "\t", "r": "\r", '"': '"', "\\": "\\"}


def unquote(s: str) -> str:
    s = s.strip()
    assert s.startswith('"') and s.endswith('"'), s
    return re.sub(r"\\(.)", lambda m: UNESC.get(m.group(1), m.group(0)), s[1:-1])


def parse_po(path: Path):
    """Yield (ctx, msgid, msgstr, fuzzy) for live entries, header excluded."""
    entries = []
    cur = None
    field = None
    fuzzy = False

    def flush():
        nonlocal cur
        if cur is not None and "msgid" in cur and cur["msgid"] != "":
            entries.append((cur.get("msgctxt", ""), cur["msgid"], cur.get("msgstr", ""), cur["fuzzy"]))
        cur = None

    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line:
            flush()
            field = None
            fuzzy = False
            continue
        if line.startswith("#~"):  # obsolete
            field = None
            continue
        if line.startswith("#"):
            if line.startswith("#,") and "fuzzy" in line:
                fuzzy = True
            if cur is not None and field == "msgstr":  # comment starts the next entry
                flush()
                fuzzy = line.startswith("#,") and "fuzzy" in line
            continue
        m = re.match(r"(msgctxt|msgid|msgstr)\s+(.*)", line)
        if m:
            field = m.group(1)
            if field in ("msgctxt", "msgid") and (cur is None or field in cur and field == "msgid" or "msgstr" in cur):
                flush()
            if cur is None:
                cur = {"fuzzy": fuzzy}
            cur[field] = unquote(m.group(2))
        elif line.startswith('"') and cur is not None and field:
            cur[field] += unquote(line)
    flush()
    return entries


def esc(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def convert_text(text: str, tag_counts: Counter | None = None) -> str:
    """BBCode -> RichText, escaping plain text. Same transform for every cell."""
    out = []
    pos = 0
    for m in TAG_RE.finditer(text):
        out.append(esc(text[pos:m.start()]))
        pos = m.end()
        closing, name, arg = m.group(1), m.group(2).lower(), m.group(3)
        if m.group(4):  # extra attributes (e.g. [wave amp=1]): not convertible
            name = name + "+attrs"
        if name in SIMPLE_TAGS and arg is None:
            out.append(f"<{'/' if closing else ''}{SIMPLE_TAGS[name]}>")
            kind = name
        elif name == "color" and (closing or (arg and COLOR_RE.fullmatch(arg))):
            if closing:
                out.append("</font>")
            else:
                out.append(f'<font color="{arg[:7]}">')
            kind = name
        elif name in STRIP_TAGS:
            kind = name
        else:
            out.append(m.group(0))  # unsupported: leave untouched
            kind = "!" + name
        if tag_counts is not None and not closing:
            tag_counts[kind] += 1
    out.append(esc(text[pos:]))
    return "".join(out)


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        return 2
    src = Path(sys.argv[1])
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_OUT
    rows: dict[tuple[str, str], dict[str, str]] = {}
    pot_tags: Counter = Counter()
    for pot in sorted(src.glob("*.pot")):
        for ctx, mid, _, _ in parse_po(pot):
            rows.setdefault((convert_text(mid, pot_tags), ctx), {})
    n_pot = len(rows)

    skipped_fuzzy: Counter = Counter()
    collisions = 0
    extra = 0
    found = []
    unknown = []
    for p in sorted(src.glob("*.po")):
        code = p.stem
        rid = roblox_locale(code)
        if rid is None or code.split("_")[0].split("-")[0] == "en":
            unknown.append(code)
            continue
        found.append((code, rid))
        for ctx, mid, mstr, fuzzy in parse_po(p):
            key = (convert_text(mid), ctx)
            if fuzzy:
                skipped_fuzzy[code] += 1
                if key not in rows:
                    rows[key] = {}
                continue
            if key not in rows:
                rows[key] = {}
                extra += 1
            val = convert_text(mstr) if mstr else ""
            if val and rows[key].get(rid) not in (None, "", val):
                collisions += 1
                continue
            if val:
                rows[key][rid] = val

    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, lineterminator="\n", quoting=csv.QUOTE_MINIMAL)
        w.writerow(["Key", "Source", "Context", "Example"] + [r for _, r in found])
        for (source, ctx), vals in rows.items():
            w.writerow(["", source, ctx, ""] + [vals.get(r, "") for _, r in found])

    print(f"wrote {out}")
    print(f"entries: {len(rows)} (pot {n_pot}, extra from .po {extra}); merge conflicts {collisions}")
    print(f"fuzzy skipped: {dict(skipped_fuzzy)}; skipped (English or unmapped) po files: {unknown}")
    print("fill rates:")
    for code, rid in found:
        n = sum(1 for v in rows.values() if v.get(rid))
        print(f"  {code:6} -> {rid:6} {n}/{len(rows)} ({100 * n / len(rows):.1f}%)")
    print("BBCode tags in msgids (!name = left untouched):", dict(pot_tags))
    return 0


if __name__ == "__main__":
    sys.exit(main())
