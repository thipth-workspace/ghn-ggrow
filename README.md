# GGrow — Prototype quản lý hiệu suất

Clickable prototype cho GGrow Phase 2 (GHN). Hai trang tĩnh, tự chứa.

| trang         | link                 |
| ------------- | -------------------- |
| Prototype     | `index.html`         |
| Design system | `design-system.html` |

Hai trang có liên kết qua lại ở góc phải thanh trên cùng.

## Lưu ý

- **Dữ liệu là giả lập.**
- Hai file HTML là **bản dựng tự động, không sửa tay.** Nguồn là
  `registry.json` + `render/**/*.js` trong repo nội bộ
  (`gitlab.ghn.vn/research-and-design/product-design/pms`).

## Dựng lại

```bash
./publish.sh
```

Script đọc repo nội bộ (mặc định `~/Documents/PMS/pms-master/prototype`, đổi bằng biến
môi trường `GGROW_SRC`), render hai trang bằng generator của Product Builder, chép kèm
`registry.json`, rồi vá hai chỗ mà bản render mặc định không hợp với GitHub Pages:

1. Switcher của trang design system trỏ vào route dev server (`/` và `/design-system`) —
   đổi sang đường dẫn tương đối theo tên file thật.
2. Shell prototype không dựng switcher, nên `index.html` là ngõ cụt — chèn thêm liên kết
   sang design system vào thanh meta-nav.

Cả hai bước đều báo lỗi và dừng nếu không tìm thấy điểm neo, để một lần nâng cấp shell
không âm thầm làm mất liên kết.
