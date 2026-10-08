#!/usr/bin/env bash
# Dựng lại hai trang tĩnh cho GitHub Pages từ workspace GGrow.
# Chạy: ./publish.sh        (từ thư mục repo này)
#
# KHÔNG sửa tay index.html / design-system.html — chúng là bản render tự động.
# Nguồn sự thật là ~/Documents/PMS/ggrow-workspace (registry.json + render/**/*.js).
#
# Dùng chung bước render với bản publish lên prototype.ghn.vn/ggrow: gọi `publish.sh --dry-run`
# của workspace (shell pb 1.11.0 + hai chỉnh sửa link), rồi đổi tên cho GitHub Pages:
# prototype.html -> index.html, và link quay về prototype trong design-system trỏ index.html.
set -euo pipefail

WS="${GGROW_WS:-$HOME/Documents/PMS/ggrow-workspace}"
OUT="$(cd "$(dirname "$0")" && pwd)"

[ -x "$WS/publish.sh" ] || { echo "không thấy workspace tại $WS (đặt GGROW_WS)" >&2; exit 1; }
"$WS/publish.sh" --dry-run
B="$WS/.preview/publish"

cp "$B/prototype.html"     "$OUT/index.html"
cp "$B/design-system.html" "$OUT/design-system.html"
cp "$B/registry.json"      "$OUT/registry.json"

python3 - "$OUT/design-system.html" <<'PY'
import io, sys
p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()
n = s.count('href="prototype.html"')
if n != 1:
    sys.exit("  design-system: href=\"prototype.html\" xuất hiện %d lần, cần đúng 1" % n)
io.open(p, "w", encoding="utf-8").write(s.replace('href="prototype.html"', 'href="index.html"'))
print("  link: design-system -> index.html")
PY

echo "xong · $OUT/index.html · $OUT/design-system.html · workspace $(git -C "$WS" rev-parse --short HEAD)"
