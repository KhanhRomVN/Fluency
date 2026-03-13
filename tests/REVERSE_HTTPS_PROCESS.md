# Chia sẻ: Quy trình Tra cứu Từ điển Collins không dùng Browser (Reverse HTTPS)

Tài liệu này ghi lại quá trình chúng ta thực hiện để tra cứu từ điển bằng dòng lệnh (CLI) mà không bị Cloudflare chặn, bao gồm cả việc lấy danh sách gợi ý và định nghĩa chi tiết.

## 1. Vấn đề: Cloudflare chặn các truy vấn tự động
Server Collins sử dụng Cloudflare để ngăn chặn bot. Nếu không có các thông số định danh hợp lệ, bạn sẽ nhận lỗi **403 Forbidden** hoặc bị yêu cầu xác thực qua trang **"Just a moment..."**.

## 2. Giải pháp: Reverse HTTPS Engineering
Chúng ta "đóng giả" trình duyệt bằng cách sử dụng lại các thông số từ một phiên làm việc thực tế.

### Bước 1: Bắt gói tin (Capture)
1. Mở trình duyệt, truy cập [collinsdictionary.com](https://www.collinsdictionary.com).
2. Nhấn **F12** -> tab **Network**.
3. **Để lấy Recommend List (Autocomplete):** Gõ chữ vào thanh tìm kiếm và tìm request có dạng:  
   `GET https://www.collinsdictionary.com/autocomplete/?dictCode=english&q=...`
4. **Để lấy Detail Term (Định nghĩa):** Nhấn Enter để xem định nghĩa và tìm request có dạng:  
   `GET https://www.collinsdictionary.com/dictionary/english/...`

### Bước 2: Các giá trị Bypass quan trọng (Tokens & Sessions)
Để vượt qua Cloudflare, chúng ta cần trích xuất chính xác:
- **`cf_clearance`:** Đây là "lệnh bài" quan trọng nhất, chứng minh trình duyệt đã vượt qua thử thách của Cloudflare.
- **`XSRF-TOKEN`:** Token bảo mật để xác thực các yêu cầu nội bộ.
- **`JSESSIONID`:** Định danh phiên làm việc trên server.
- **User-Agent:** Chuỗi định danh trình duyệt (phải khớp với loại trình duyệt bạn đang dùng để bắt gói tin).

### Bước 3: Tái tạo (Replicate) bằng cURL
Lưu các cookies vào file `session_cookies.txt` và thực hiện lệnh:

```bash
# Lấy Recommend List
curl -s -b session_cookies.txt -A "User-Agent-Cua-Ban" \
  "https://www.collinsdictionary.com/autocomplete/?dictCode=english&q=play"

# Lấy Định nghĩa chi tiết
curl -s -L -b session_cookies.txt -A "User-Agent-Cua-Ban" \
  --compressed "https://www.collinsdictionary.com/dictionary/english/play-a-banjo"
```

## 3. Hệ thống Automation (Test Script)
Chúng ta đã tích hợp cả hai cơ chế này vào script `tests/test_dictionary_lookup.sh`:

- **Chế độ `auto` (Recommend List):** Gọi API autocomplete, sau đó dùng `python3 -m json.tool` để phân tích danh sách gợi ý.
- **Chế độ `def` (Detail Term):** Gọi trang HTML định nghĩa, xử lý URL (thay khoảng trắng bằng dấu gạch ngang) và dùng `grep` để trích xuất thẻ Meta Description/Title.

## 4. Lưu ý quan trọng
- **Cookie hết hạn:** `cf_clearance` chỉ có hiệu lực trong một khoảng thời gian (thường là vài giờ đến vài ngày). Nếu script bị lỗi 403, bạn cần lấy lại cookie mới từ trình duyệt.
- **Kỹ thuật trích xuất:** Với Detail Term, dữ liệu nằm trong HTML; với Recommend List, dữ liệu nằm trong JSON.

---
*Ghi chú: Việc sử dụng `--compressed` là bắt buộc vì server thường trả về dữ liệu nén để tối ưu tốc độ.*
