#!/usr/bin/env bash
# Dựng lại hai trang tĩnh cho GitHub Pages từ workspace GGrow — shell pb 2.3.0.
# Chạy: ./publish.sh        (từ thư mục repo này)
#
# KHÔNG sửa tay index.html / design-system.html — chúng là bản render tự động.
# Nguồn sự thật là ~/Documents/PMS/ggrow-workspace (registry.json + render/**/*.js).
#
# Khác bản publish lên prototype.ghn.vn/ggrow (shell 1.11.0, vì gitleaks của pms-prototype báo nhầm
# bảng itemHash của 2.3.0): GitHub không chạy gitleaks đó, nên ở đây dùng thẳng shell 2.3.0.
set -euo pipefail

WS="${GGROW_WS:-$HOME/Documents/PMS/ggrow-workspace}"
PB="${GGROW_PB:-$HOME/.claude/plugins/cache/product-builder/pb/2.3.0}"
[ -d "$PB" ] || PB="$HOME/.claude/plugins/marketplaces/product-builder/pb"
OUT="$(cd "$(dirname "$0")" && pwd)"

[ -f "$WS/registry.json" ] || { echo "không thấy workspace tại $WS (đặt GGROW_WS)" >&2; exit 1; }
cd "$WS"
python3 "$PB/tools/lint_registry.py" registry.json | tail -1 || true
python3 "$PB/tools/render.py"      registry.json "$PB/template/prototype.html"     "$OUT/index.html"
python3 "$PB/tools/render.py" --ds registry.json "$PB/template/design-system.html" \
                                                 "$PB/template/runtime.js"          "$OUT/design-system.html"
cp registry.json "$OUT/registry.json"

# Shell 2.3.0 viết link theo route của dev server (`/design-system`, `/?screen=<id>`). Pages phục vụ
# file tĩnh, có khi dưới một đường dẫn con (`<user>.github.io/<repo>/`), nên đổi sang tương đối.
python3 - "$OUT" <<'PY'
import io, sys
out = sys.argv[1]
edits = {
    "index.html": [("'/design-system", "'design-system.html"),          # window.open(...) x2
                   ('href="/design-system"', 'href="design-system.html"')],
    "design-system.html": [('href="/design-system"', 'href="design-system.html"'),
                           ("href=\"/?screen=", "href=\"index.html?screen=")],
}
for name, pairs in edits.items():
    p = out + "/" + name
    s = io.open(p, encoding="utf-8").read()
    for a, b in pairs:
        n = s.count(a)
        if n == 0:
            sys.exit("  %s: không thấy %r — shell đã đổi?" % (name, a))
        s = s.replace(a, b)
        print("  %-18s %-26s -> %-28s x%d" % (name, a, b, n))
    io.open(p, "w", encoding="utf-8").write(s)
PY

echo "xong · $OUT/index.html · $OUT/design-system.html · shell $(head -2 "$OUT/index.html" | tail -1 | grep -o 'v[0-9.]*') · workspace $(git -C "$WS" rev-parse --short HEAD)"
