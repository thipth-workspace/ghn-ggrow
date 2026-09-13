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

# Shell prototype KHÔNG dựng switcher (chỉ shell design-system có), nên trên Pages trang
# index là ngõ cụt: vào được prototype thì không có đường sang design system. Chèn một liên
# kết vào thanh meta-nav. Phải chèn vào CHUỖI mà `renderMetaNav()` trả về chứ không vào DOM —
# hàm đó gán lại `innerHTML` của #meta-nav mỗi lần render, chèn thẳng vào DOM sẽ bị xoá ngay.
python3 - "$OUT/index.html" <<'PYLINK'
import io, sys
p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()

k = s.find("<span>Sandbox</span>")
if k == -1:
    sys.exit("  KHÔNG thấy nút Sandbox — shell đã đổi, bỏ bước chèn liên kết")
tail = "</button>`;"
end = s.find(tail, k)
if end == -1:
    sys.exit("  KHÔNG thấy điểm kết nút Sandbox — bỏ bước chèn")
anchor = s[k:end + len(tail)]
link = '<a class="pb-ds-link" href="design-system.html">Design system</a>'
s = s.replace(anchor, anchor[:-2] + link + "`;", 1)

css = ('<style>.pb-ds-link{display:inline-flex;align-items:center;height:30px;'
       'padding:0 12px;margin-left:8px;border-radius:var(--radius, 8px);'
       'background:rgba(255,255,255,0.06);border:1px solid rgba(255,255,255,0.16);'
       'color:var(--neutral-10, #e5e7eb);text-decoration:none;'
       'font-family:var(--font-heading);font-size:var(--font-size-s);'
       'font-weight:var(--font-weight-bold)}'
       '.pb-ds-link:hover{background:rgba(255,255,255,0.12)}</style>')
if s.count("</head>") != 1:
    sys.exit("  </head> không duy nhất — bỏ bước chèn css")
s = s.replace("</head>", css + "</head>", 1)

io.open(p, "w", encoding="utf-8").write(s)
print("  liên kết  index.html -> design-system.html            x1")
PYLINK

echo "xong · $OUT/index.html · $OUT/design-system.html"
