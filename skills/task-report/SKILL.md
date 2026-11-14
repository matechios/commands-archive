---
name: task-report
description: "Soạn báo cáo kỹ thuật mobile/backend dạng một file HTML (khuyến nghị ≤ 3 trang A4 nếu in) cho dev gửi leader hoặc PO. Gồm hiện trạng, phương án và kế hoạch triển khai, bảng so sánh khi cần, nội dung cần xác nhận. Dùng cho khảo sát code, bug/incident, tích hợp SDK/API, chọn giải pháp, tiến độ hoặc tổng quan tính năng; chỉ soạn và xuất file HTML."
---

# Báo cáo dev gửi leader / PO

Người nhận đọc xong phải biết: **đang có gì, ảnh hưởng gì, đề xuất gì, cần ai chốt gì**. Mặc định tiếng Việt, xuất **một file HTML**, không xuất PDF hay định dạng khác. Độ dài **khuyến nghị ≤ 3 trang A4 nếu người nhận in**: bài đơn giản khoảng 1 trang, khảo sát hoặc chọn giải pháp 2–3 trang. Đây là mục tiêu tối ưu, không phải giới hạn cứng: nội dung cần cho quyết định thì giữ, kể cả khi vượt 3 trang. Không đệm chữ cho đủ trang. Yêu cầu rõ về định dạng/độ dài của người dùng được ưu tiên.

## Tài nguyên

Đường dẫn tính từ thư mục chứa `SKILL.md`. Đọc cả hai file trước khi soạn; thiếu file thì báo người dùng, không giả vờ đã đọc.

- `assets/report-template.html`: khung và CSS dùng cho mọi báo cáo.
- `assets/example-report.html`: báo cáo mẫu đã điền (so sánh hai API: tính năng, chất lượng đo thử, chi phí) để tham khảo độ dài, giọng văn, cách dùng tag/badge. Nội dung là giả định; không chép tình huống, tên hay số liệu.

## Chọn thông tin

- Xác định: báo cáo việc gì, gửi ai, để thông báo hay xin quyết định. Chưa rõ người nhận thì viết chung cho leader và PO.
- Chỉ giữ ý phục vụ kết luận, đánh giá ảnh hưởng, chọn phương án hoặc giao việc; gộp ý trùng nhưng giữ đủ căn cứ và đánh đổi để người nhận tự đánh giá.
- Giữ nguyên yêu cầu bắt buộc của sản phẩm. Phương án thiếu chức năng phải nêu khoảng thiếu và cách kiểm chứng, không tự giảm scope.
- Thiếu dữ liệu vẫn soạn phần đã đủ căn cứ. Chỉ hỏi 1–2 câu khi thông tin thiếu làm đổi kết luận; có thể đưa bản nháp trong lúc chờ.

## Căn cứ và nguồn

Nguyên tắc chung cho toàn bộ báo cáo: **chỉ ghi điều có căn cứ**. Không bịa số đo, nguyên nhân gốc, trạng thái hoàn tất, owner, deadline, người nhận, báo giá, ngày công, hạ tầng, SLO, tải, trạng thái production, link hay số dòng code.

- Phân biệt: đã đọc source/tài liệu, đã chạy thử, đã đo, nhận định, đề xuất. Có code hoặc có API chưa chứng minh app đáp ứng đủ nhu cầu; thiếu bằng chứng ≠ không hỗ trợ; tài liệu marketing ≠ kết quả thử của dự án.
- Thông tin chưa biết: bỏ nếu không ảnh hưởng quyết định; nếu có thì ghi ngắn cạnh ý liên quan (“chưa đo”, “cần xác nhận”). Một lưu ý phạm vi kiểm chứng là đủ; không lặp disclaimer.
- Chi phí: giữ đơn vị, giả định sản lượng, chu kỳ thanh toán, khoản chưa gồm. Không so giá khi phạm vi chưa tương đương.
- Gắn nguồn ngắn cạnh phát hiện quan trọng (ticket, PR, test, tài liệu). Footer **Nguồn và phạm vi kiểm chứng** liệt kê link thật (docs SDK/API, bảng giá, store guideline, ticket/PR), mỗi link kèm một câu dùng làm căn cứ gì. Không ghi đường dẫn hay tên file local. Nguồn nội bộ thì tìm trang chính thức tương ứng; không có thì ghi tên dự án/tài liệu, loại nguồn và mốc, ví dụ `Source code CleanMaster iOS, nhánh main, 12/11/2026` hoặc `Log tạo đơn tháng 10/2026`. Tài liệu cũ thì ghi mốc, không trình bày giá/quy định cũ như đã xác minh hiện tại.

## Cấu trúc

Dùng template làm khung (header, Tóm tắt, mục đánh số, footer nguồn), bỏ mục không có giá trị và đánh lại số. Mở bằng **Tóm tắt** dạng 1–3 ý đầu dòng ngắn, bao quát (chức năng/luồng và nền tảng/build liên quan, vấn đề, hướng xử lý, mức kiểm chứng); đủ ý thì dừng, không thêm cho đủ ba. Không có mục “Mục tiêu & phạm vi” riêng, không chép lại các mục dưới. Tiêu đề mục không dùng chữ “kỹ thuật”.

Các mục đều cùng cấp `h2` với số mục (01, 02…); tiêu đề phụ như 2.1, 2.2 là `h3` trong mục cha, không phải mục riêng.

### Sự cố / bug, tích hợp SDK/API, chọn giải pháp (khung mặc định của template)

1. **Hiện trạng & vấn đề:** bảng ba cột **Chức năng / luồng** (màn hình/luồng/endpoint/module) – **Hiện trạng** (hành vi hoặc lỗi kèm căn cứ: code/log/crash/test/số đo) – **Ảnh hưởng** (tác động tới người dùng, dữ liệu, tính năng). Tách nguyên nhân đã xác nhận khỏi giả thuyết.
2. **Phương án & kế hoạch triển khai:** gộp so sánh, tác động, cách làm trong một mục (2.1 so sánh, 2.2 implement–test–release, tiêu chí nghiệm thu). Không tách thành ba mục so sánh / ảnh hưởng / kế hoạch. Không có hai hướng cần cân nhắc thì bỏ 2.1, bỏ số phụ của 2.2.
3. **Cần xác nhận:** chỉ 1–2 việc thật sự cần chốt (phương án, scope hoặc lịch release), mỗi việc một `li` trong `.decisions`; người phản hồi và hạn đặt trong `.owner`, chỉ khi đã biết. Bỏ mục nếu chỉ cập nhật.

Theo loại việc:

- **Sự cố / reject / blocker:** mục 1 nêu việc bị chặn, ảnh hưởng, bằng chứng/nguyên nhân đã xác nhận; mục 2 là hướng xử lý. Thêm phương án dự phòng chỉ khi hướng chính có thể không đạt.
- **Chọn dịch vụ / SDK:** trọng tâm là 2.1; giữ yêu cầu bắt buộc, khoảng thiếu, chi phí, ảnh hưởng chuyển đổi; kết bằng lựa chọn hoặc phép thử cần làm.

### Khảo sát / cải tiến

Dùng khi đọc code hoặc thử nghiệm để tìm hướng cải tiến, chưa có hai phương án cụ thể để so và chưa tới bước release. Giữ header, Tóm tắt, footer của template; vẫn ba mục `h2`:

1. **01 Hiện trạng & vấn đề:** bảng ba cột như khung mặc định; mỗi hàng là một phát hiện, xếp theo mức ảnh hưởng. Gộp các phát hiện nhỏ cùng luồng vào một hàng. Ghi rõ từng ý là đã đọc code, đã tái hiện hay đã đo.
2. **02 Hướng cải tiến:** các tiểu mục `h3` đánh số liên tục 2.1, 2.2…:
   - **Một tiểu mục cho mỗi mục tiêu khảo sát** (ví dụ 2.1 Tăng tốc, 2.2 Phân loại nội dung), không theo 2.1 so sánh / 2.2 release. Mỗi hướng gồm: làm gì, lợi ích kỳ vọng, đánh đổi hoặc điều kiện; lợi ích chưa đo thì không ghi số.
   - **Bullet hay bảng:** dưới 4 hướng, hoặc các hướng cần mô tả theo ý khác nhau → bullet, mỗi hướng một `li` mở bằng tên hướng in đậm. Từ 4 hướng trở lên cùng mô tả được theo một bộ tiêu chí → bảng **Hướng / chức năng** – **Cách làm** – **Cần kiểm chứng**.
   - **Tiểu mục cuối luôn là “Kiểm chứng & thứ tự triển khai”** (số tiếp theo, ví dụ 2.3 nếu có hai mục tiêu): bảng **Bước** – **Thay đổi & dependency** – **Test / tiêu chí nghiệm thu**. Bước đầu thường là đo baseline và chuẩn bị dữ liệu kiểm thử; các bước sau theo thứ tự ưu tiên. Dưới bảng là `.recommendation` nêu nên làm gì trước và vì sao; nói rõ thứ tự chưa chốt nếu chưa có estimate.
3. **03 Cần xác nhận:** cách hiểu yêu cầu còn mơ hồ, phạm vi, hoặc việc cho phép làm bước kiểm chứng.

Không dựng bảng so sánh phương án hay bước release khi khảo sát chưa tới đó. Danh sách file source không đưa vào báo cáo; tên class/module nằm trong ô bảng.

### Tiến độ ngày/tuần/sprint

Thay mục 01–03 của template bằng:

1. **Kết quả đạt được:** bảng **Hạng mục** – **Trạng thái** (tag: `.ok` Hoàn tất, `.warn` Đang làm, `.no` Bị chặn) – **Kết quả & căn cứ** (PR, build, môi trường đã lên). Không dùng số commit thay kết quả; không gọi “đã triển khai” khi mới có code.
2. **Vướng mắc & ảnh hưởng:** mỗi việc một dòng: bị chặn bởi gì, ảnh hưởng tới mốc nào, cần ai hỗ trợ. Bỏ mục nếu không có.
3. **Kế hoạch kỳ tới:** danh sách ưu tiên ngắn; owner/hạn chỉ ghi khi đã biết.

Thêm **Cần xác nhận** chỉ khi có việc cần chốt.

### Tổng quan tính năng / công nghệ

1. **Tính năng làm gì:** 2–4 ý về mục đích, người dùng, nền tảng.
2. **Luồng chính:** bảng **Luồng** – **Cách hoạt động** – **Module / service / SDK liên quan**, 3–5 hàng.
3. **Giới hạn & lưu ý:** chỉ khi có căn cứ. Không ép có sự cố, so sánh hay phê duyệt.

## Diễn đạt

- Dùng từ team dev quen thuộc (luồng xử lý, module/service, SDK/API, contract, cache, dependency, regression test, staging/production, rollback…) khi đúng ngữ cảnh.
- Viết theo chuỗi **thành phần → hành vi/lỗi → tác động → cách xử lý/test**. Mới đọc code thì dùng “luồng hiện tại có thể…” kèm cách tái hiện.
- **Mobile:** chọn khía cạnh liên quan: build/version, iOS/Android, máy thật/simulator, SDK, lifecycle/background, permission, local storage, offline sync, crash/ANR, startup, RAM/pin, review store. Không giả định có cả hai nền tảng.
- **Server:** endpoint/service, tương thích API, auth, schema/migration, query/cache, queue/job, latency/error rate, timeout/retry, deploy/rollback.
- **App + server:** nêu API/data contract, tương thích app version cũ, thứ tự release.
- Tránh văn quản trị chung chung (“tóm tắt điều hành”, “hướng đầu tư”, “điểm được/mất”). Dùng “tóm tắt”, “hướng xử lý”, “ưu điểm/hạn chế”, “tiêu chí nghiệm thu”.
- Gửi **PO**: giải thích tác động tới người dùng, scope, release. Gửi **leader**: thêm module, nguyên nhân, dependency, hướng implement và test đủ để chia task.

## So sánh phương án

- Chỉ so khi có ít nhất hai hướng thực sự cần cân nhắc hoặc người dùng yêu cầu; không dựng phương án giả. Đối chiếu hiện tại với hướng cải tiến cũng là so sánh.
- Bảng ở mục 2.1: 2–3 phương án, 4–6 tiêu chí liên quan (đáp ứng tính năng, thay đổi app/server/API/data, hiệu năng, công implement/test, chi phí, tương thích, rủi ro release). Ma trận quá rộng thì tách hai bảng liền nhau (ví dụ tính năng/chất lượng và chi phí), không thu nhỏ chữ.
- Gắn tag đầu ô: **Đáp ứng** (`.tag.ok`), **Một phần** (`.tag.warn`), **Không đáp ứng** (`.tag.no`), **Chưa xác minh** (`.tag.unk`).
- Đánh dấu cột phương án đề xuất bằng `class="pick"` trên `th` và mọi `td` của cột (chỉ khi đã có hướng đề xuất). Ưu điểm, hạn chế, dependency, phạm vi sửa nằm ngay trong bảng; không lặp ở mục khác.
- Dưới bảng: `.recommendation` nêu chọn hướng nào, vì sao, chạy thử/đo/test cần làm trước khi implement hoặc release. Không chấm điểm có trọng số khi chưa có căn cứ.

## Xuất HTML

- **Tên và vị trí file:** `YYYY-MM-DD-<slug>.html` (ngày báo cáo; slug chữ thường không dấu, nối bằng `-`, tối đa khoảng 6 từ, ví dụ `2026-11-14-upload-anh-background.html`). Lưu ở thư mục làm việc hiện tại, kể cả khi tài liệu nguồn nằm ở thư mục khác; chỉ lưu nơi khác khi người dùng chỉ định. Đã có file trùng tên thì thêm hậu tố `-2`, `-3`…; không ghi đè file sẵn có trừ khi người dùng yêu cầu sửa chính file đó.
- Không ghi được file thì trả toàn bộ HTML trong một khối mã `html`, không nói đã tạo file.
- Một file độc lập, UTF-8, `lang="vi"`, CSS nhúng, không cần mạng/font/thư viện ngoài. Giữ nguyên CSS của template; chỉ chỉnh biến trong `:root` (màu thương hiệu, font, cỡ chữ, khoảng cách), theo màu thương hiệu người dùng cung cấp nếu có.
- **Header:** eyebrow ghi **tên app hoặc tên tính năng** (báo cáo về cả app hoặc nhiều tính năng thì ghi tên app; về một tính năng thì ghi tên tính năng), không ghi tên module/class hay nền tảng. `h1` ghi vấn đề hoặc đề xuất, không lặp lại eyebrow. Subtitle: một dòng, dạng cụm từ ngắn nối bằng “·”, chỉ gồm **nền tảng** (iOS, Android, server), **version/build/min OS** và **môi trường** (máy thật, simulator, staging, production), ví dụ `iOS 4.12 · min iOS 14 · máy thật`. Không đưa framework/SDK/class (PhotoKit, Vision, `UploadService`…) hay cách khảo sát vào subtitle; những thứ đó nằm trong nội dung và footer nguồn. Không có trường Gửi.
- **Ngày** và **Báo cáo bởi** luôn có trong header:
  - Ngày: ngày hiện tại của môi trường (ngày soạn báo cáo), định dạng `dd/mm/yyyy`; chỉ dùng ngày khác khi người dùng nêu rõ. Ngày ghi trong tài liệu nguồn (ví dụ “ngày khảo sát” của bản cũ) không thay ngày báo cáo.
  - Báo cáo bởi: chỉ ghi tên người báo cáo, không ghi team hay chức danh. Tên lấy theo người dùng nêu. Chưa có thì, nếu chạy được lệnh, đọc `git config user.name` để gợi ý và hỏi người dùng xác nhận một câu; không có gợi ý thì hỏi trực tiếp. Không bịa tên.
  - Bản nháp khi chờ xác nhận: có gợi ý từ git thì ghi nguyên giá trị đó, không thêm chú thích như “(chờ xác nhận)” vào file; không có gợi ý thì giữ placeholder `[Tên người báo cáo]`. Trong câu trả lời, nói rõ tên đang chờ xác nhận.
- **Badge** cạnh Tóm tắt ghi mức kiểm chứng: `.badge` (trung tính) khi mới đọc code/tài liệu, `.badge.ok` khi đã chạy thử/đo, `.badge.warn` khi phần quan trọng chưa xác minh.
- Template mang ví dụ cả mobile lẫn server trong placeholder; chỉ giữ khía cạnh đúng với báo cáo, không để sót hàng hay tiêu chí của nền tảng không liên quan.
- Thay cả `<title>` lẫn nội dung. Xóa mọi placeholder và **mọi comment HTML trong `<body>`**; giữ nguyên comment trong `<style>` (thuộc CSS). Xóa badge, mục, nguồn không có dữ liệu.
- Escape ký tự đặc biệt; không đưa script/markup từ ghi chú nguồn vào file; link chỉ dùng URL thật (HTTPS).
- Bảng: `.table-wrap > table` với `thead`, `th scope="col"`, `th scope="row"` cho cột đầu, `tbody`. Không dùng chiều cao cố định hay `overflow: hidden` để cắt nội dung. Trạng thái luôn kèm chữ, không chỉ dựa vào màu.
- **Độ dài:** không tự xuất PDF hay đếm trang. Ước lượng bằng **số từ của phần chữ trong `<body>`**: bỏ thẻ HTML và comment, tách theo khoảng trắng, mỗi tiếng Việt tính một từ. Mốc đã đo: `example-report.html` khoảng 740 từ và 4 bảng ≈ 2 trang A4; khoảng 1.300 từ và 3 bảng ≈ 3 trang. Bảng nhiều hàng chiếm chỗ hơn bullet cùng số từ. Vượt mức này thì trước hết bỏ ý lặp, gộp hàng và rút ô bảng; phần còn lại vẫn cần cho người nhận quyết định thì giữ, chấp nhận dài hơn 3 trang. Không thu nhỏ chữ để ép trang. CSS in (`@media print`) trong template đã lo khổ A4, lặp header bảng, không ngắt giữa hàng; giữ nguyên.

## Trước khi trả kết quả

- Bỏ mở đầu xã giao, lịch sử thao tác, kiến thức nền phổ thông, danh sách file đầy đủ, kết luận lặp. Mỗi bullet một ý (1–2 câu). Chỉ dùng bảng ở những chỗ khung yêu cầu hoặc khi đối chiếu nhiều mục theo cùng tiêu chí; ý đơn lẻ thì viết bullet.
- Thay “đang nghiên cứu tối ưu” bằng điều đã phát hiện và bước sẽ kiểm chứng. Báo cáo chỉ thông tin thì không tự tạo việc cần phê duyệt.
- Kiểm tra: không còn `[` placeholder `]` (trừ tên người báo cáo đang chờ xác nhận), không còn comment trong `<body>`, không còn `example.com`, không tài nguyên ngoài.
- Trả lời người dùng ngắn: đường dẫn file đã tạo và 1–2 điểm cần họ xác nhận (nếu có); không kèm giải thích quá trình hay checklist nội bộ. Soạn báo cáo không đồng nghĩa được phép gửi tin nhắn, email hay nộp lên hệ thống.
