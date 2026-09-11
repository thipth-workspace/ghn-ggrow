#!/usr/bin/env bash
# Dựng lại hai trang tĩnh cho GitHub Pages từ registry nội bộ.
# Chạy: ./publish.sh        (từ thư mục repo này)
#
# KHÔNG sửa tay index.html / design-system.html — chúng là bản render tự động.
# Nguồn sự thật là registry.json + render/**/*.js trong repo nội bộ.
set -euo pipefail

SRC="${GGROW_SRC:-$HOME/Documents/PMS/pms-master/prototype}"
PB="${GGROW_PB:-$HOME/.claude/plugins/cache/product-builder/pb/1.11.0}"
OUT="$(cd "$(dirname "$0")" && pwd)"

[ -f "$SRC/registry.json" ] || { echo "không thấy registry tại $SRC" >&2; exit 1; }

cd "$SRC"
# lint chi de tham khao: thoat 1 khi co canh bao, khong duoc chan publish
python3 "$PB/tools/lint_registry.py" registry.json | tail -1 || true
python3 "$PB/tools/render.py"      registry.json "$PB/template/prototype.html"     "$OUT/index.html"
python3 "$PB/tools/render.py" --ds registry.json "$PB/template/design-system.html" \
                                                 "$PB/template/runtime.js"          "$OUT/design-system.html"
cp registry.json "$OUT/registry.json"

# Shell dựng switcher bằng route của dev server (`/` và `/design-system`). Pages phục vụ
# file tĩnh nên hai đường dẫn đó 404 — đổi sang đường dẫn tương đối theo tên file thật.
python3 - "$OUT/design-system.html" <<'PY'
import io, sys
p = sys.argv[1]
s = io.open(p, encoding='utf-8').read()
pairs = [('href="/design-system"', 'href="design-system.html"'),
         ('href="/"',              'href="index.html"')]
for old, new in pairs:
    n = s.count(old)
    if n:
        s = s.replace(old, new)
    print('  switcher %-26s -> %-24s x%d' % (old, new, n))
io.open(p, 'w', encoding='utf-8').write(s)
PY

echo "xong · $OUT/index.html · $OUT/design-system.html"
