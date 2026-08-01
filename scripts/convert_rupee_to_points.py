#!/usr/bin/env python3
"""Convert all ₹ (rupee) currency displays to in-platform points across Dart files.

AdSense compliance: rewards apps may not offer direct monetary items (cash).
This rewrites display strings so amounts read as "pts" instead of ₹.

Patterns handled (in order):
  1. ₹${expr}       -> ${expr} pts      (e.g. '₹${amount.toStringAsFixed(2)}' -> '${amount.toStringAsFixed(2)} pts')
  2. ₹$ident        -> $ident pts        (e.g. '₹$target' -> '$target pts')
  3. ₹<number>      -> <number> pts      (e.g. '₹50' -> '50 pts', '₹0.80' -> '0.80 pts')
  4. remaining ₹    -> pts                (e.g. '₹', '(₹)', '₹ ' -> 'pts', '(pts)', 'pts ')
"""
import re
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

# Patterns: each is (regex, replacement)
# 1. ₹${...} interpolation
RE_INTERP_BRACE = re.compile(r'\u20B9(\$\{[^}]*\})')
# 2. ₹$ident
RE_INTERP_IDENT = re.compile(r'\u20B9(\$[A-Za-z_][A-Za-z0-9_]*)')
# 3. ₹<number>
RE_NUMBER = re.compile(r'\u20B9(\d+(?:\.\d+)?)')
# 4. bare ₹
RE_BARE = re.compile(r'\u20B9')


def convert_text(text: str) -> str:
    text = RE_INTERP_BRACE.sub(r'\1 pts', text)
    text = RE_INTERP_IDENT.sub(r'\1 pts', text)
    text = RE_NUMBER.sub(r'\1 pts', text)
    text = RE_BARE.sub('pts', text)
    return text


def main() -> int:
    targets = ['lib', 'test']
    changed = []
    for target in targets:
        base = ROOT / target
        if not base.exists():
            continue
        for path in sorted(base.rglob('*.dart')):
            original = path.read_text(encoding='utf-8')
            converted = convert_text(original)
            if converted != original:
                path.write_text(converted, encoding='utf-8')
                changed.append(str(path.relative_to(ROOT)))
    print(f'Converted {len(changed)} file(s):')
    for f in changed:
        print(f'  {f}')
    if not changed:
        print('No ₹ symbols found to convert.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
