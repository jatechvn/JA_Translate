// lib/modules/ui/localization.dart
// Centralized lightweight localization dictionary for EN/VN/CN

class UiLocalizations {
  static const Map<String, Map<String, String>> _values = {
    'engine_missing_native': {
      'VN': 'Thiếu thư viện dịch native.',
      'ENG': 'Native translation libraries are missing.',
      'CN': '缺少本地翻译库。'
    },
    'engine_missing_translation_pack': {
      'VN': 'Thiếu gói dịch cho cặp ngôn ngữ đã chọn.',
      'ENG': 'Translation pack missing for the selected languages.',
      'CN': '缺少所选语言的翻译模型。'
    },
    'ai_native_description': {
      'VN':
          'Dịch trực tiếp trong app, không cần server. Chỉ nạp một gói dịch vào RAM mỗi lần.',
      'ENG':
          'Translate inside the app without a server. Only one translation pack is loaded at a time.',
      'CN': '直接在应用中翻译，无需服务器。每次仅加载一个翻译模型。'
    },
    'ai_native_loaded': {'VN': 'Đã nạp', 'ENG': 'Loaded', 'CN': '已加载'},
    'ai_native_auto_load': {
      'VN': 'Tự nạp gói phù hợp khi bắt đầu dịch.',
      'ENG': 'The matching pack loads automatically when translation starts.',
      'CN': '开始翻译时自动加载对应模型。'
    },
    'ai_native_load': {'VN': 'Nạp model', 'ENG': 'Load model', 'CN': '加载模型'},
    'ai_native_unload': {
      'VN': 'Giải phóng RAM',
      'ENG': 'Free memory',
      'CN': '释放内存'
    },
    'ai_native_folder': {
      'VN': 'Thư mục gói dịch',
      'ENG': 'Translation packs folder',
      'CN': '翻译模型文件夹'
    },
    'ai_native_error': {
      'VN': 'Lỗi engine dịch',
      'ENG': 'Translation engine error',
      'CN': '翻译引擎错误'
    },
    'ai_native_pivot': {
      'VN':
          'VI ↔ ZH dịch qua tiếng Anh. Tự nhận diện dựa trên ký tự; tiếng Việt không dấu nên chọn nguồn thủ công.',
      'ENG':
          'VI ↔ ZH translates through English. Detection uses characters; select Vietnamese manually for text without accents.',
      'CN': '越南语 ↔ 中文通过英语翻译。自动检测依赖字符；无声调越南语请手动选择。'
    },
    'source': {
      'VN': 'NGUỒN',
      'ENG': 'SOURCE',
      'CN': '源语言',
    },
    'target': {
      'VN': 'ĐÍCH',
      'ENG': 'TARGET',
      'CN': '目标语言',
    },
    'clear': {
      'VN': 'XÓA',
      'ENG': 'CLEAR',
      'CN': '清空',
    },
    'start_translation': {
      'VN': 'BẮT ĐẦU DỊCH',
      'ENG': 'START TRANSLATION',
      'CN': '开始翻译',
    },
    'thinking': {
      'VN': 'ĐANG DỊCH...',
      'ENG': 'THINKING...',
      'CN': '正在翻译...',
    },
    'processing_pinyin': {
      'VN': 'ĐANG TẠO PINYIN...',
      'ENG': 'PROCESSING PINYIN...',
      'CN': '正在生成拼音...',
    },
    'complete': {
      'VN': 'HOÀN THÀNH',
      'ENG': 'COMPLETE',
      'CN': '完成',
    },
    'error': {
      'VN': 'LỖI',
      'ENG': 'ERROR',
      'CN': '错误',
    },
    'ready': {
      'VN': 'SẴN SÀNG',
      'ENG': 'READY',
      'CN': '就绪',
    },
    'input_title': {
      'VN': 'BẢN GỐC',
      'ENG': 'INPUT',
      'CN': '原文字数',
    },
    'result_title': {
      'VN': 'KẾT QUẢ',
      'ENG': 'RESULT',
      'CN': '译文结果',
    },
    'input_hint': {
      'VN': 'Dán văn bản hoặc nhập tại đây... (Ctrl+Enter để dịch)',
      'ENG': 'Paste text or type here... (Ctrl+Enter to translate)',
      'CN': '粘贴文本或在此输入... (Ctrl+Enter 翻译)',
    },
    'result_hint': {
      'VN': 'Kết quả dịch sẽ xuất hiện tại đây...',
      'ENG': 'Translation result will stream here...',
      'CN': '翻译结果将在此处显示...',
    },
    'proxy_btn': {
      'VN': 'PROXY',
      'ENG': 'PROXY',
      'CN': '代理',
    },
    'theme_dark': {
      'VN': 'TỐI',
      'ENG': 'DARK',
      'CN': '深色',
    },
    'theme_light': {
      'VN': 'SÁNG',
      'ENG': 'LIGHT',
      'CN': '浅色',
    },
    'theme_auto': {
      'VN': 'TỰ ĐỘNG',
      'ENG': 'AUTO',
      'CN': '自动',
    },
    'tooltip_attach': {
      'VN': 'Đính kèm ảnh',
      'ENG': 'Attach Image',
      'CN': '附加图片',
    },
    'tooltip_snip': {
      'VN': 'Chụp màn hình dịch nhanh (Alt + S)',
      'ENG': 'Screen Snip & Translate (Alt + S)',
      'CN': '截图快速翻译 (Alt + S)',
    },
    'tooltip_copy_input': {
      'VN': 'Sao chép bản gốc',
      'ENG': 'Copy Input',
      'CN': '复制原文',
    },
    'tooltip_copy_result': {
      'VN': 'Sao chép kết quả',
      'ENG': 'Copy Result',
      'CN': '复制译文',
    },
    'tooltip_swap': {
      'VN': 'Đổi chiều ngôn ngữ',
      'ENG': 'Swap Languages',
      'CN': '交换语言',
    },
    'tooltip_speak': {
      'VN': 'Nghe phát âm',
      'ENG': 'Listen to speech',
      'CN': '朗读发音',
    },
    'tooltip_mic': {
      'VN': 'Nhập bằng giọng nói (Mic)',
      'ENG': 'Voice Input (Mic)',
      'CN': '语音输入 (麦克风)',
    },
    'mic_recording': {
      'VN': 'Đang lắng nghe... Bấm để dịch',
      'ENG': 'Listening... Click to translate',
      'CN': '正在聆听... 点击翻译',
    },
    'pinyin_label': {
      'VN': 'Phiên âm Pinyin:',
      'ENG': 'Pinyin Phonetics:',
      'CN': '拼音旁注:',
    },
    'copied_toast': {
      'VN': 'Đã sao chép vào khay nhớ tạm!',
      'ENG': 'Copied to clipboard!',
      'CN': '已复制到剪贴板！',
    },
    'proxy_title': {
      'VN': 'Cấu hình Proxy',
      'ENG': 'Proxy Configuration',
      'CN': '代理配置',
    },
    'proxy_enable': {
      'VN': 'Kích hoạt Proxy HTTP',
      'ENG': 'Enable HTTP Proxy',
      'CN': '启用 HTTP 代理',
    },
    'proxy_host': {
      'VN': 'Địa chỉ Proxy',
      'ENG': 'Proxy Host',
      'CN': '代理主机',
    },
    'proxy_port': {
      'VN': 'Cổng Proxy',
      'ENG': 'Proxy Port',
      'CN': '代理端口',
    },
    'proxy_user': {
      'VN': 'Tên đăng nhập (Tùy chọn)',
      'ENG': 'Username (Optional)',
      'CN': '用户名 (可选)',
    },
    'proxy_pass': {
      'VN': 'Mật khẩu (Tùy chọn)',
      'ENG': 'Password (Optional)',
      'CN': '密码 (可选)',
    },
    'proxy_cancel': {
      'VN': 'HỦY',
      'ENG': 'CANCEL',
      'CN': '取消',
    },
    'proxy_save': {
      'VN': 'LƯU CẤU HÌNH',
      'ENG': 'SAVE SETTINGS',
      'CN': '保存设置',
    },
    'proxy_enabled_status': {
      'VN': 'KÍCH HOẠT',
      'ENG': 'ENABLED',
      'CN': '已启用',
    },
    'proxy_disabled_status': {
      'VN': 'VÔ HIỆU HÓA',
      'ENG': 'DISABLED',
      'CN': '已禁用',
    },
    'lang_auto': {
      'VN': 'Tự động',
      'ENG': 'Auto',
      'CN': '自动',
    },
    'tab_text': {
      'VN': 'Văn Bản',
      'ENG': 'Text',
      'CN': '文本',
    },
    'tab_doc': {
      'VN': 'Tài Liệu',
      'ENG': 'Document',
      'CN': '文档',
    },
    'select_file': {
      'VN': 'Chọn File',
      'ENG': 'Select File',
      'CN': '选择文件',
    },
    'drag_drop_hint': {
      'VN': 'Nhấp để chọn tài liệu hoặc kéo thả vào đây',
      'ENG': 'Click to select a document or drag & drop it here',
      'CN': '点击选择文档或拖拽到此处',
    },
    'supported_formats_hint': {
      'VN': 'Định dạng được hỗ trợ: .txt, .md, .docx, .xlsx, .pptx, .pdf',
      'ENG': 'Supported formats: .txt, .md, .docx, .xlsx, .pptx, .pdf',
      'CN': '支持的格式: .txt, .md, .docx, .xlsx, .pptx, .pdf',
    },
    'remove_file': {
      'VN': 'Gỡ bỏ file',
      'ENG': 'Remove File',
      'CN': '移除文件',
    },
    'translating_chunk': {
      'VN': 'Đang dịch đoạn {chunk} trên {total}...',
      'ENG': 'Translating chunk {chunk} of {total}...',
      'CN': '正在翻译第 {chunk} / {total} 段...',
    },
    'reading_file': {
      'VN': 'Đang đọc file tài liệu...',
      'ENG': 'Reading document file...',
      'CN': '正在读取文档文件...',
    },
    'error_reading_file': {
      'VN': 'Lỗi khi đọc file tài liệu.',
      'ENG': 'Error reading document file.',
      'CN': '读取文档文件时出错。',
    },
    'error_empty_file': {
      'VN': 'Lỗi: Nội dung file trống.',
      'ENG': 'Error: File content is empty.',
      'CN': '错误：文件内容为空。',
    },
    'save_translated': {
      'VN': 'Lưu Bản Dịch',
      'ENG': 'Save Translated File',
      'CN': '保存译文',
    },
    'save_success': {
      'VN': 'Đã lưu file dịch thành công!',
      'ENG': 'Saved translated file successfully!',
      'CN': '已成功保存译文文件！',
    },
    'save_error': {
      'VN': 'Có lỗi xảy ra khi lưu file.',
      'ENG': 'An error occurred while saving the file.',
      'CN': '保存文件时发生错误',
    },
    'file_info': {
      'VN': 'Thông tin tài liệu',
      'ENG': 'Document Info',
      'CN': '文档信息',
    },
    'file_path': {
      'VN': 'Đường dẫn:',
      'ENG': 'Path:',
      'CN': '路径:',
    },
    'file_size': {
      'VN': 'Kích thước:',
      'ENG': 'Size:',
      'CN': '大小:',
    },
    'char_count': {
      'VN': 'Số ký tự:',
      'ENG': 'Characters:',
      'CN': '字符数:',
    },
    'word_count': {
      'VN': 'Số từ (ước tính):',
      'ENG': 'Words (approx):',
      'CN': '字数 (约):',
    },
    'ready_translate': {
      'VN': 'Sẵn sàng dịch tài liệu',
      'ENG': 'Ready to translate document',
      'CN': '准备翻译文档',
    },
    'attached_images_status': {
      'VN': 'ĐÃ ĐÍNH KÈM {count} ẢNH',
      'ENG': 'ATTACHED {count} IMAGES',
      'CN': '已附加 {count} 张图片',
    },
    'proxy_updated_status': {
      'VN': 'ĐÃ CẬP NHẬT PROXY: {state}',
      'ENG': 'PROXY UPDATED: {state}',
      'CN': '已更新代理: {state}',
    },
    'tab_history': {
      'VN': 'Lịch sử',
      'ENG': 'History',
      'CN': '历史',
    },
    'history_title': {
      'VN': 'Lịch sử dịch gần đây',
      'ENG': 'Recent Translation History',
      'CN': '最近翻译历史',
    },
    'saved_title': {
      'VN': 'Bản dịch đã lưu',
      'ENG': 'Saved Translations',
      'CN': '已保存翻译',
    },
    'no_records': {
      'VN': 'Không tìm thấy bản ghi nào.',
      'ENG': 'No records found.',
      'CN': '未找到记录。',
    },
    'clear_history': {
      'VN': 'Xóa lịch sử',
      'ENG': 'Clear History',
      'CN': '清除历史',
    },
    'tooltip_save': {
      'VN': 'Lưu bản dịch này',
      'ENG': 'Save this translation',
      'CN': '保存此翻译',
    },
    'tooltip_unsave': {
      'VN': 'Hủy lưu bản dịch này',
      'ENG': 'Unsave this translation',
      'CN': '取消保存此翻译',
    },
    'toast_saved': {
      'VN': 'Đã lưu bản dịch!',
      'ENG': 'Translation saved!',
      'CN': '已保存翻译！',
    },
    'toast_unsaved': {
      'VN': 'Đã hủy lưu bản dịch!',
      'ENG': 'Translation unsaved!',
      'CN': '已取消保存翻译！',
    },
    'subtab_all': {
      'VN': 'TẤT CẢ LỊCH SỬ',
      'ENG': 'ALL HISTORY',
      'CN': '全部历史',
    },
    'subtab_saved': {
      'VN': 'BẢN DỊCH ĐÃ LƯU',
      'ENG': 'SAVED',
      'CN': '已收藏',
    },
    'provider_cloud': {
      'VN': 'CLOUD',
      'ENG': 'CLOUD',
      'CN': '云端',
    },
    'provider_local': {
      'VN': 'LOCAL',
      'ENG': 'LOCAL',
      'CN': '本地',
    },
    'local_ai_title': {
      'VN': 'Cấu hình Local AI (Embedded llama.cpp)',
      'ENG': 'Local AI Configuration (llama.cpp)',
      'CN': '本地 AI 配置 (llama.cpp)',
    },
    'local_ai_endpoint': {
      'VN': 'Địa chỉ API (Endpoint)',
      'ENG': 'API Endpoint',
      'CN': '接口地址',
    },
    'local_ai_model': {
      'VN': 'Tên Model Local',
      'ENG': 'Local Model Name',
      'CN': '本地模型名称',
    },
    'local_ai_test': {
      'VN': 'Kiểm tra kết nối',
      'ENG': 'Test Connection',
      'CN': '测试连接',
    },
    'local_ai_connected': {
      'VN': 'Llama Server đang hoạt động tốt!',
      'ENG': 'Llama Server is running properly!',
      'CN': 'Llama 服务运行正常！',
    },
    'local_ai_failed': {
      'VN': 'Llama Server chưa khởi chạy.',
      'ENG': 'Llama Server is not running.',
      'CN': 'Llama 服务未运行。',
    },
    'cloud_ai_title': {
      'VN': 'Cấu hình Cloud AI (API Key & Model)',
      'ENG': 'Cloud AI Configuration (API Key & Model)',
      'CN': '云端 AI 配置 (API Key 与模型)',
    },
    'cloud_api_key': {
      'VN': 'API Key',
      'ENG': 'API Key',
      'CN': 'API 密钥',
    },
    'cloud_api_base': {
      'VN': 'Địa chỉ API (Base URL)',
      'ENG': 'API Base URL',
      'CN': 'API 接口地址',
    },
    'cloud_text_model': {
      'VN': 'Model Dịch thuật (Text)',
      'ENG': 'Text Translation Model',
      'CN': '文本翻译模型',
    },
    'cloud_vision_model': {
      'VN': 'Model Xử lý ảnh (Vision OCR)',
      'ENG': 'Vision OCR Model',
      'CN': '图片识别模型',
    },
    'cloud_test': {
      'VN': 'Kiểm tra kết nối Cloud',
      'ENG': 'Test Cloud Connection',
      'CN': '测试云端连接',
    },
    'cloud_test_ok': {
      'VN': 'Kết nối Cloud API thành công!',
      'ENG': 'Connected to Cloud API successfully!',
      'CN': '成功连接到云端 API！',
    },
    'cloud_test_fail': {
      'VN': 'Lỗi kết nối Cloud API',
      'ENG': 'Cloud API connection failed',
      'CN': '云端 API 连接失败',
    },
    'local_installed_models': {
      'VN': 'Model đã cài đặt trong máy:',
      'ENG': 'Installed Models on device:',
      'CN': '本机已安装模型：',
    },
    'local_no_models': {
      'VN': 'Chưa phát hiện model nào. Hãy tải model bên dưới!',
      'ENG': 'No models found. Download one below!',
      'CN': '未发现模型，请在下方下载！',
    },
    'local_download_btn': {
      'VN': 'Tải về máy',
      'ENG': 'Download',
      'CN': '下载到本机',
    },
    'local_download_rec': {
      'VN': 'Tải Qwen2.5-1.5B (Khuyên dùng Mini PC 8GB RAM)',
      'ENG': 'Download Qwen2.5-1.5B (Recommended for 8GB RAM)',
      'CN': '下载 Qwen2.5-1.5B (推荐 8GB 内存配置)',
    },
    'local_downloading': {
      'VN': 'Đang tải model...',
      'ENG': 'Downloading model...',
      'CN': '正在下载模型...',
    },
    'local_download_success': {
      'VN': 'Tải model thành công!',
      'ENG': 'Model downloaded successfully!',
      'CN': '模型下载成功！',
    },
    'local_download_fail': {
      'VN': 'Tải model thất bại',
      'ENG': 'Model download failed',
      'CN': '模型下载失败',
    },
    'menu_config_cloud': {
      'VN': 'Cấu hình Cloud AI (NVIDIA / OpenAI)',
      'ENG': 'Cloud AI Settings (NVIDIA / OpenAI)',
      'CN': '云端 AI 设置 (NVIDIA / OpenAI)',
    },
    'menu_config_local': {
      'VN': 'Cấu hình Local AI & Tự tải Model',
      'ENG': 'Local AI Settings & Model Downloader',
      'CN': '本地 AI 设置与模型下载',
    },
    'local_engine_title': {
      'VN': 'Bộ máy AI Local',
      'ENG': 'Local AI Engine',
      'CN': '本地 AI 引擎',
    },
    'local_engine_embedded': {
      'VN': 'Embedded llama.cpp (Thư mục App - Tối ưu nhất)',
      'ENG': 'Embedded llama.cpp (App Folder - Optimized)',
      'CN': '内置 llama.cpp (程序目录 - 最优)',
    },
    'local_models_folder': {
      'VN': 'Thư mục Models (Lưu ngay trong App):',
      'ENG': 'Models Directory (Inside App):',
      'CN': '模型目录 (程序内部):',
    },
    'local_open_folder': {
      'VN': 'Mở thư mục Models',
      'ENG': 'Open Models Folder',
      'CN': '打开模型目录',
    },
    'local_server_status': {
      'VN': 'Trạng thái Server:',
      'ENG': 'Server Status:',
      'CN': '服务状态：',
    },
    'local_server_running': {
      'VN': 'Đang chạy (Cổng 8080)',
      'ENG': 'Running (Port 8080)',
      'CN': '运行中 (端口 8080)',
    },
    'local_server_stopped': {
      'VN': 'Đã dừng',
      'ENG': 'Stopped',
      'CN': '已停止',
    },
    'local_threads_label': {
      'VN': 'Số luồng CPU (Threads):',
      'ENG': 'CPU Threads:',
      'CN': 'CPU 线程数：',
    },
    'local_start_server': {
      'VN': 'Khởi động',
      'ENG': 'Start',
      'CN': '启动',
    },
    'local_stop_server': {
      'VN': 'Dừng',
      'ENG': 'Stop',
      'CN': '停止',
    },
    'ota_btn': {
      'VN': 'CẬP NHẬT',
      'ENG': 'UPDATE',
      'CN': '更新',
    },
    'ota_title': {
      'VN': 'CẬP NHẬT OTA NỘI BỘ',
      'ENG': 'LAN OTA UPDATE',
      'CN': '局域网 OTA 更新',
    },
    'ota_dialog_title': {
      'VN': 'Cập Nhật Phiên Bản Mới',
      'ENG': 'Software Update',
      'CN': '软件更新',
    },
    'ota_server_path': {
      'VN': 'Đường dẫn máy chủ (SMB / UNC):',
      'ENG': 'Update Server Path (SMB / UNC):',
      'CN': '更新服务器路径 (SMB / UNC)：',
    },
    'ota_server_path_hint': {
      'VN': r'\\10.81.141.226\temp\FBT\JA_PROJECT\JA_Update\JA_Translate',
      'ENG': r'\\10.81.141.226\temp\FBT\JA_PROJECT\JA_Update\JA_Translate',
      'CN': r'\\10.81.141.226\temp\FBT\JA_PROJECT\JA_Update\JA_Translate',
    },
    'ota_username': {
      'VN': 'Tên đăng nhập SMB (nếu có):',
      'ENG': 'SMB Username (optional):',
      'CN': 'SMB 用户名 (可选)：',
    },
    'ota_password': {
      'VN': 'Mật khẩu SMB (nếu có):',
      'ENG': 'SMB Password (optional):',
      'CN': 'SMB 密码 (可选)：',
    },
    'ota_interval': {
      'VN': 'Chu kỳ tự động kiểm tra:',
      'ENG': 'Auto-check Interval:',
      'CN': '自动检查周期：',
    },
    'ota_interval_daily': {
      'VN': 'Hàng ngày',
      'ENG': 'Daily',
      'CN': '每天',
    },
    'ota_interval_weekly': {
      'VN': 'Hàng tuần',
      'ENG': 'Weekly',
      'CN': '每周',
    },
    'ota_interval_monthly': {
      'VN': 'Hàng tháng',
      'ENG': 'Monthly',
      'CN': '每月',
    },
    'ota_interval_off': {
      'VN': 'Tắt',
      'ENG': 'Off',
      'CN': '关闭',
    },
    'ota_check_now': {
      'VN': 'Kiểm tra bản cập nhật ngay',
      'ENG': 'Check for Updates Now',
      'CN': '立即检查更新',
    },
    'ota_checking': {
      'VN': 'Đang kiểm tra máy chủ...',
      'ENG': 'Checking update server...',
      'CN': '正在检查更新服务器...',
    },
    'ota_up_to_date': {
      'VN': 'Bạn đang sử dụng phiên bản mới nhất!',
      'ENG': 'You are using the latest version!',
      'CN': '您已使用最新版本！',
    },
    'ota_update_available': {
      'VN': 'Đã phát hiện phiên bản mới',
      'ENG': 'New version is available',
      'CN': '发现新版本',
    },
    'ota_current_version': {
      'VN': 'Phiên bản hiện tại:',
      'ENG': 'Current Version:',
      'CN': '当前版本：',
    },
    'ota_latest_version': {
      'VN': 'Phiên bản mới nhất:',
      'ENG': 'Latest Version:',
      'CN': '最新版本：',
    },
    'ota_release_notes': {
      'VN': 'Nhật ký thay đổi:',
      'ENG': 'Release Notes:',
      'CN': '更新日志：',
    },
    'ota_update_later': {
      'VN': 'Để sau',
      'ENG': 'Later',
      'CN': '稍后',
    },
    'ota_update_now': {
      'VN': 'Cập nhật ngay',
      'ENG': 'Update Now',
      'CN': '立即更新',
    },
    'ota_downloading': {
      'VN': 'Đang tải bản cập nhật...',
      'ENG': 'Downloading update...',
      'CN': '正在下载更新...',
    },
    'ota_save': {
      'VN': 'Lưu Cấu Hình',
      'ENG': 'Save Config',
      'CN': '保存配置',
    },
    'ota_saved_success': {
      'VN': 'Đã lưu cấu hình OTA thành công!',
      'ENG': 'OTA configuration saved!',
      'CN': 'OTA 配置已保存！',
    },
    'ota_error_prefix': {
      'VN': 'Lỗi kiểm tra cập nhật:',
      'ENG': 'Update check failed:',
      'CN': '检查更新失败：',
    },
    'ota_default_release_notes': {
      'VN':
          'Bản phát hành bao gồm các cải tiến hiệu năng, tính năng mới và các bản vá lỗi.',
      'ENG':
          'This release includes performance improvements, new features, and bug fixes.',
      'CN': '此版本包含性能改进、新功能和错误修复。',
    },
    'ota_test_connection': {
      'VN': 'Kiểm tra kết nối',
      'ENG': 'Test Connection',
      'CN': '测试连接',
    },
    'ota_open_config_folder': {
      'VN': 'Mở thư mục cấu hình',
      'ENG': 'Open Config Folder',
      'CN': '打开配置目录',
    },
    'ota_testing_connection': {
      'VN': 'Đang kiểm tra kết nối...',
      'ENG': 'Testing connection...',
      'CN': '正在测试连接...',
    },
    'ota_connection_success': {
      'VN': 'Kết nối máy chủ thành công!',
      'ENG': 'Server connection successful!',
      'CN': '服务器连接成功！',
    },
    'ota_connection_failed': {
      'VN': 'Không thể kết nối máy chủ',
      'ENG': 'Failed to connect to server',
      'CN': '无法连接到服务器',
    },
  };

  /// Translate key to target language. Defaults to English if not found.
  static String get(String key, String lang) {
    final Map<String, String>? keyValues = _values[key];
    if (keyValues == null) return key;
    return keyValues[lang] ?? keyValues['ENG'] ?? key;
  }
}
