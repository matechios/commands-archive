---
name: task-report
description: "Soạn báo cáo kỹ thuật mobile/backend dạng HTML, tối đa 3 trang A4, cho dev gửi leader hoặc PO. Gồm hiện trạng, phương án kỹ thuật và kế hoạch triển khai, bảng so sánh khi cần, nội dung cần xác nhận. Dùng cho khảo sát code, bug/incident, tích hợp SDK/API, chọn giải pháp hoặc tiến độ; chỉ soạn và xuất báo cáo."
---

# Báo cáo dev gửi leader / PO

Người nhận đọc xong phải biết: **đang có gì, ảnh hưởng gì, đề xuất gì, cần ai chốt gì**. Mặc định tiếng Việt, xuất một file HTML, **tối đa 3 trang A4 khi in**. Bài đơn giản 1 trang; khảo sát hoặc chọn giải pháp 2–3 trang. Không đệm chữ cho đủ trang. Yêu cầu rõ về định dạng/độ dài của người dùng được ưu tiên.

## Môi trường

- Gói gồm `SKILL.md` và `assets/report-template.html` (đường dẫn tính từ thư mục chứa `SKILL.md`). Đọc template trước khi xuất; thiếu file thì yêu cầu cung cấp, không giả vờ đã đọc.
- Không phụ thuộc tool, hệ điều hành hay dịch vụ ngoài. Không tạo được file thì trả toàn bộ HTML trong một khối mã `html`, không nói đã tạo file.
- Chưa render/in thử được thì nói ngắn ngoài báo cáo rằng số trang chưa xác minh.

## Chọn thông tin

- Xác định: báo cáo việc gì, gửi ai, để thông báo hay xin quyết định. Chưa rõ người nhận thì viết chung cho leader và PO.
- Chỉ giữ ý phục vụ kết luận, đánh giá ảnh hưởng, chọn phương án hoặc giao việc; gộp ý trùng nhưng giữ đủ căn cứ và đánh đổi để người nhận tự đánh giá.
- Giữ nguyên yêu cầu bắt buộc của sản phẩm. Phương án thiếu chức năng phải nêu khoảng thiếu và cách kiểm chứng, không tự giảm scope.
- Thiếu dữ liệu vẫn soạn phần đã đủ căn cứ. Chỉ hỏi 1–2 câu khi thông tin thiếu làm đổi kết luận; có thể đưa bản nháp trong lúc chờ.

## Mức chắc chắn và nguồn

- Phân biệt: đọc source/tài liệu, đã chạy thử, đã đo, nhận định, đề xuất. Có code hoặc có API chưa chứng minh app đáp ứng đủ nhu cầu.
- Chỉ ghi số đo, trạng thái hoàn tất, nguyên nhân gốc, owner, deadline khi có căn cứ. Thông tin chưa biết: bỏ nếu không ảnh hưởng quyết định; nếu có thì ghi ngắn cạnh ý liên quan (“chưa đo”, “cần xác nhận”).
- Một lưu ý phạm vi kiểm chứng là đủ; không lặp disclaimer. Chỉ giữ riêng giới hạn làm đổi quyết định.
- Chi phí: giữ đơn vị, giả định sản lượng, chu kỳ thanh toán, khoản chưa gồm. Không so giá khi phạm vi chưa tương đương; không bịa báo giá, ngày công, tỷ lệ tiết kiệm.
- Gắn nguồn ngắn cạnh phát hiện quan trọng (ticket, PR, test, tài liệu). Mục **Nguồn và phạm vi kiểm chứng** liệt kê link tài liệu liên quan (docs SDK/API, bảng giá, store guideline, ticket/PR); mỗi link kèm một câu cho biết dùng làm căn cứ gì. Tránh tên file hoặc đường dẫn local; nguồn chỉ có ở dạng file nội bộ thì tìm trang chính thức tương ứng, không có thì ghi tên tài liệu và mốc. Chỉ dùng link thật, không bịa số dòng. Tài liệu cũ thì ghi mốc nguồn, không trình bày giá/quy định cũ như đã xác minh hiện tại.

## Cấu trúc

Dùng template làm khung, bỏ mục không có giá trị và đánh lại số. Mở bằng **Tóm tắt** dạng 1–3 ý đầu dòng ngắn, bao quát (chức năng/luồng và nền tảng/build liên quan, vấn đề, hướng xử lý, mức kiểm chứng); không có mục “Mục tiêu & phạm vi” riêng, không chép lại các mục dưới. Tiêu đề mục không dùng chữ “kỹ thuật”.

1. **Hiện trạng & vấn đề:** bảng ba cột **Chức năng / luồng** – **Hành vi trong app** – **Bằng chứng & ảnh hưởng người dùng** (code/log/crash/test/số đo); tách nguyên nhân đã xác nhận khỏi giả thuyết.
2. **Phương án & kế hoạch triển khai:** gộp so sánh, tác động, cách làm trong một mục (2.1 so sánh, 2.2 implement–test–release, tiêu chí nghiệm thu). Không tách thành ba mục so sánh / ảnh hưởng / kế hoạch.
3. **Cần xác nhận:** chỉ 1–2 việc thật sự cần chốt (phương án, scope hoặc lịch release), mỗi việc một dòng; kèm người phản hồi và hạn nếu đã biết. Bỏ mục nếu chỉ cập nhật.

Tiêu đề mục 02 dùng cùng kiểu với mục 01 (số mục + tên); 2.1, 2.2 là tiêu đề phụ trong mục 02, không phải mục riêng. Trang 1 = tóm tắt và mục 1; mục 2 có thể kéo sang trang 2–3, tiếp theo là mục 3. Xóa trang mẫu còn trống.

## Diễn đạt

- Dùng từ team dev quen thuộc (luồng xử lý, module/service, SDK/API, contract, cache, dependency, regression test, staging/production, rollback…) khi đúng ngữ cảnh.
- Viết theo chuỗi **thành phần → hành vi/lỗi → tác động → cách xử lý/test**. Mới đọc code thì dùng “luồng hiện tại có thể…” kèm cách tái hiện.
- **Mobile:** chọn khía cạnh liên quan: build/version, iOS/Android, máy thật/simulator, SDK, lifecycle/background, permission, local storage, offline sync, crash/ANR, startup, RAM/pin, review store. Không giả định có cả hai nền tảng.
- **Server:** endpoint/service, tương thích API, auth, schema/migration, query/cache, queue/job, latency/error rate, timeout/retry, deploy/rollback. Không bịa hạ tầng, SLO, tải hay trạng thái production.
- **App + server:** nêu API/data contract, tương thích app version cũ, thứ tự release.
- Tránh văn quản trị chung chung (“tóm tắt điều hành”, “hướng đầu tư”, “điểm được/mất”). Dùng “tóm tắt”, “hướng xử lý”, “ưu điểm/hạn chế”, “tiêu chí nghiệm thu”.
- Gửi **PO**: giải thích tác động tới người dùng, scope, release. Gửi **leader**: thêm module, nguyên nhân, dependency, hướng implement và test đủ để chia task.

## So sánh phương án

- Chỉ so khi có ít nhất hai hướng thực sự cần cân nhắc hoặc người dùng yêu cầu; không dựng phương án giả. Đối chiếu hiện tại với hướng cải tiến cũng là so sánh.
- Bảng ở mục 2.1: 2–3 phương án, 4–6 tiêu chí liên quan (đáp ứng tính năng, thay đổi app/server/API/data, hiệu năng, công implement/test, chi phí, tương thích, rủi ro release). Ma trận quá rộng thì tách hai bảng, không thu nhỏ chữ.
- Gắn tag **Đáp ứng** (`.tag.ok`), **Không đáp ứng** (`.tag.no`), **Chưa xác minh** (`.tag.unk`). Thiếu bằng chứng ≠ không hỗ trợ; tài liệu marketing ≠ kết quả thử của dự án.
- Đánh dấu cột phương án đề xuất bằng `class="pick"` (chỉ khi đã có hướng đề xuất). Ưu điểm, hạn chế, dependency, phạm vi sửa nằm ngay trong bảng; không lặp ở mục khác.
- Dưới bảng: `.recommendation` nêu chọn hướng nào, vì sao, chạy thử/đo/test cần làm trước khi implement hoặc release. Không chấm điểm có trọng số khi chưa có căn cứ.

## Theo tình huống

- **Sự cố / reject / blocker:** việc bị chặn → ảnh hưởng → bằng chứng/nguyên nhân đã xác nhận → hướng xử lý. Thêm phương án dự phòng chỉ khi hướng chính có thể không đạt.
- **Khảo sát / cải tiến:** mục tiêu → phát hiện ưu tiên → hướng đề xuất → cần kiểm chứng gì trước khi làm.
- **Chọn dịch vụ:** dùng mục so sánh; giữ yêu cầu bắt buộc, khoảng thiếu, chi phí, ảnh hưởng chuyển đổi; kết bằng lựa chọn hoặc phép thử cần làm.
- **Tổng quan tính năng/công nghệ:** sản phẩm làm gì, 3–5 luồng chính; không ép có sự cố hay phê duyệt.
- **Tiến độ ngày/tuần/sprint:** kết quả đạt → việc còn vướng và ảnh hưởng → ưu tiên kỳ tới. Không dùng số commit thay kết quả; không gọi “đã triển khai” khi mới có code.

## Xuất HTML

- Một file `.html` độc lập, UTF-8, `lang="vi"`, CSS nhúng, không cần mạng/font/thư viện ngoài. Đặt tên theo chủ đề/kỳ báo cáo.
- Chỉnh style qua biến đầu `:root` (màu thương hiệu, font, cỡ chữ, khoảng cách); theo màu thương hiệu người dùng cung cấp nếu có.
- Header: dòng nhỏ phía trên (eyebrow) ghi tên tính năng/module app; tiêu đề `h1` ghi vấn đề hoặc đề xuất, không lặp lại tên module. **Ngày** và **Báo cáo bởi** là bắt buộc, luôn có trong header; chưa biết người báo cáo thì hỏi người dùng một câu trước khi xuất (có thể đưa bản nháp trong lúc chờ), không bịa tên; không có trường Gửi. Heading mở đầu là **Tóm tắt**; badge cạnh heading ghi mức kiểm chứng.
- Thay cả `<title>` lẫn nội dung. Xóa placeholder, badge, mục, nguồn không có dữ liệu (riêng Ngày và Báo cáo bởi luôn giữ). Không bịa ngày, người viết, người nhận, trạng thái.
- Escape ký tự đặc biệt; không đưa script/markup từ ghi chú nguồn vào file; link chỉ dùng URL thật (HTTPS).
- Bảng: `.table-wrap > table` với `thead`, `th scope="col"`, `tbody`; mỗi nhóm cần sang trang in mới là một `.report-page`. Không dùng chiều cao cố định hay `overflow: hidden` để cắt nội dung.
- Giữ responsive và `@media print` (A4, lề 16 mm, chữ nội dung ≥ 10 pt, lặp header bảng, không ngắt giữa hàng). Không thu nhỏ chữ để đạt 3 trang. Trạng thái luôn kèm chữ, không chỉ dựa vào màu.
- Trước khi giao: không còn placeholder, không tài nguyên ngoài. Nếu có công cụ, xem thử màn hình hẹp và xuất PDF A4 tỷ lệ 100% (tắt header/footer trình duyệt) để đếm trang; quá 3 trang thì bỏ ý lặp, rút ô bảng hoặc chỉnh ngắt trang. CSS không tự bảo đảm số trang.

## Trước khi trả kết quả

- Bỏ mở đầu xã giao, lịch sử thao tác, kiến thức nền phổ thông, danh sách file đầy đủ, kết luận lặp. Mỗi bullet một ý (1–2 câu); bảng chỉ để so sánh.
- Thay “đang nghiên cứu tối ưu” bằng điều đã phát hiện và bước sẽ kiểm chứng. Báo cáo chỉ thông tin thì không tự tạo việc cần phê duyệt.
- Trả file HTML hoàn chỉnh, không kèm giải thích quá trình hay checklist nội bộ. Soạn báo cáo không đồng nghĩa được phép gửi tin nhắn, email hay nộp lên hệ thống.
