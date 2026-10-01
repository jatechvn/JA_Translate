import 'dart:io';
import 'package:flutter/material.dart';

/// Supported application languages.
enum AppLanguage {
  vi('VI', 'Tiếng Việt', '🇻🇳'),
  en('ENG', 'English', '🇬🇧'),
  cn('CN', '中文', '🇨🇳');

  final String code;
  final String label;
  final String flag;

  const AppLanguage(this.code, this.label, this.flag);

  static AppLanguage fromCode(String code) {
    final upper = code.toUpperCase();
    if (upper == 'EN' || upper == 'ENG') return AppLanguage.en;
    if (upper == 'CN' || upper == 'ZH') return AppLanguage.cn;
    return AppLanguage.vi;
  }
}

/// Language and localization provider for instant 1-click language switching.
class LanguageProvider extends ChangeNotifier {
  late AppLanguage _currentLanguage;

  LanguageProvider({String? initialLang}) {
    if (initialLang != null) {
      _currentLanguage = AppLanguage.fromCode(initialLang);
    } else {
      _currentLanguage = _detectSystemLanguage();
    }
  }

  AppLanguage get currentLanguage => _currentLanguage;
  String get code => _currentLanguage.code;

  static AppLanguage _detectSystemLanguage() {
    try {
      final locale = Platform.localeName.toLowerCase();
      if (locale.startsWith('zh') || locale.contains('cn')) {
        return AppLanguage.cn;
      } else if (locale.startsWith('en')) {
        return AppLanguage.en;
      } else if (locale.startsWith('vi')) {
        return AppLanguage.vi;
      }
    } catch (_) {}
    return AppLanguage.vi; // Default to Vietnamese
  }

  /// Cycles to the next language: VI -> ENG -> CN -> VI
  void cycleLanguage() {
    switch (_currentLanguage) {
      case AppLanguage.vi:
        _currentLanguage = AppLanguage.en;
        break;
      case AppLanguage.en:
        _currentLanguage = AppLanguage.cn;
        break;
      case AppLanguage.cn:
        _currentLanguage = AppLanguage.vi;
        break;
    }
    notifyListeners();
  }

  void setLanguage(AppLanguage language) {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      notifyListeners();
    }
  }

  List<String> get tabLabels {
    switch (_currentLanguage) {
      case AppLanguage.vi:
        return ['Văn bản', 'Tài liệu', 'Lịch sử', 'AI Studio'];
      case AppLanguage.en:
        return ['Text', 'Documents', 'History', 'AI Studio'];
      case AppLanguage.cn:
        return ['文本翻译', '文档翻译', '翻译历史', 'AI 工作台'];
    }
  }

  /// Lookup localization string with fallback
  String t(String key, [List<dynamic>? args]) {
    final dict = _dictionary[key];
    String text;
    if (dict == null) {
      text = key;
    } else {
      text = dict[_currentLanguage.code] ?? dict['ENG'] ?? dict['VI'] ?? key;
    }

    if (args != null && args.isNotEmpty) {
      for (final arg in args) {
        text = text.replaceFirst(RegExp(r'%[sd]'), arg.toString());
      }
    }
    return text;
  }

  String tr(String key, [List<dynamic>? args]) => t(key, args);

  static final Map<String, Map<String, String>> _dictionary = {
    'ai_native_engine': {
      'VI': 'Engine dịch trong app',
      'ENG': 'In-app translation engine',
      'CN': '应用内翻译引擎'
    },
    'ai_engine_opus': {
      'VI': 'OPUS-MT (nhẹ)',
      'ENG': 'OPUS-MT (compact)',
      'CN': 'OPUS-MT（小型）'
    },
    'ai_engine_gguf': {
      'VI': 'Qwen GGUF',
      'ENG': 'Qwen GGUF',
      'CN': 'Qwen GGUF'
    },
    'ai_gguf_description': {
      'VI':
          'Dịch nguyên đoạn bằng GGUF trong app. Chất lượng ngữ cảnh phụ thuộc model; dùng nhiều RAM hơn OPUS-MT.',
      'ENG':
          'Translate the whole passage with GGUF inside the app. Context quality depends on the model; uses more RAM than OPUS-MT.',
      'CN': '在应用内使用 GGUF 翻译整段文本。上下文质量取决于模型；比 OPUS-MT 使用更多内存。'
    },
    'ai_gguf_limit': {
      'VI': 'Ngữ cảnh 4096 token; giữ đoạn dưới 3072 token đầu vào.',
      'ENG': '4096-token context; keep input passages under 3072 tokens.',
      'CN': '上下文长度为 4096 token；输入段落须少于 3072 token。'
    },

    'engine_missing_native': {
      'VI': 'Thiếu thư viện dịch native.',
      'ENG': 'Native translation libraries are missing.',
      'CN': '缺少本地翻译库。'
    },
    'engine_missing_translation_pack': {
      'VI': 'Thiếu gói dịch cho cặp ngôn ngữ đã chọn.',
      'ENG': 'Translation pack missing for the selected languages.',
      'CN': '缺少所选语言的翻译模型。'
    },
    'ai_native_description': {
      'VI':
          'Dịch trực tiếp trong app, không cần server. Chỉ nạp một gói dịch vào RAM mỗi lần.',
      'ENG':
          'Translate inside the app without a server. Only one translation pack is loaded at a time.',
      'CN': '直接在应用中翻译，无需服务器。每次仅加载一个翻译模型。'
    },
    'ai_native_loaded': {'VI': 'Đã nạp', 'ENG': 'Loaded', 'CN': '已加载'},
    'ai_native_auto_load': {
      'VI': 'Tự nạp gói phù hợp khi bắt đầu dịch.',
      'ENG': 'The matching pack loads automatically when translation starts.',
      'CN': '开始翻译时自动加载对应模型。'
    },
    'ai_native_load': {'VI': 'Nạp model', 'ENG': 'Load model', 'CN': '加载模型'},
    'ai_native_unload': {
      'VI': 'Giải phóng RAM',
      'ENG': 'Free memory',
      'CN': '释放内存'
    },
    'ai_native_folder': {
      'VI': 'Thư mục gói dịch',
      'ENG': 'Translation packs folder',
      'CN': '翻译模型文件夹'
    },
    'translation_error_prefix': {
      'VI': 'Lỗi dịch',
      'ENG': 'Translation failed',
      'CN': '翻译失败'
    },
    'ai_native_error': {
      'VI': 'Lỗi engine dịch',
      'ENG': 'Translation engine error',
      'CN': '翻译引擎错误'
    },
    'ai_native_pivot': {
      'VI':
          'VI ↔ ZH dịch qua tiếng Anh. Tự nhận diện dựa trên ký tự; tiếng Việt không dấu nên chọn nguồn thủ công.',
      'ENG':
          'VI ↔ ZH translates through English. Detection uses characters; select Vietnamese manually for text without accents.',
      'CN': '越南语 ↔ 中文通过英语翻译。自动检测依赖字符；无声调越南语请手动选择。'
    },

    // Top Bar & General UI
    'app_title': {
      'VI': 'JA Translate',
      'ENG': 'JA Translate',
      'CN': 'JA 翻译',
    },
    'app_subtitle': {
      'VI': 'Liquid Glass Edition',
      'ENG': 'Liquid Glass Edition',
      'CN': '液态玻璃典藏版',
    },
    'theme_dark': {
      'VI': 'TỐI',
      'ENG': 'DARK',
      'CN': '暗色',
    },
    'theme_light': {
      'VI': 'SÁNG',
      'ENG': 'LIGHT',
      'CN': '明亮',
    },
    'theme_auto': {
      'VI': 'TỰ ĐỘNG',
      'ENG': 'AUTO',
      'CN': '自动',
    },
    'settings_btn': {
      'VI': 'Cài Đặt',
      'ENG': 'Settings',
      'CN': '设置',
    },
    'lang_tooltip': {
      'VI': 'Đổi ngôn ngữ giao diện (1-Click)',
      'ENG': 'Change UI Language (1-Click)',
      'CN': '切换界面语言 (1-Click)',
    },
    'perf_tooltip': {
      'VI': 'Cấu hình phần cứng & hiệu ứng kính',
      'ENG': 'Hardware Profile & Glass Tuning',
      'CN': '硬件档位与玻璃效果调优',
    },
    'theme_tooltip': {
      'VI': 'Chuyển giao diện Sáng / Tối',
      'ENG': 'Toggle Light / Dark Theme',
      'CN': '切换亮色 / 暗色主题',
    },

    // Engine Status
    'engine_local': {
      'VI': 'LOCAL AI',
      'ENG': 'LOCAL AI',
      'CN': '本地 AI',
    },
    'engine_cloud': {
      'VI': 'CLOUD AI',
      'ENG': 'CLOUD AI',
      'CN': '云端 AI',
    },
    'status_ready': {
      'VI': 'SẴN SÀNG',
      'ENG': 'READY',
      'CN': '就绪',
    },
    'status_translating': {
      'VI': 'ĐANG DỊCH...',
      'ENG': 'TRANSLATING...',
      'CN': '正在翻译...',
    },

    // Text Translation View
    'source_lang': {
      'VI': 'NGUỒN',
      'ENG': 'SOURCE',
      'CN': '源语言',
    },
    'target_lang': {
      'VI': 'ĐÍCH',
      'ENG': 'TARGET',
      'CN': '目标语言',
    },
    'lang_auto': {
      'VI': 'Tự động',
      'ENG': 'Auto',
      'CN': '自动检测',
    },
    'lang_vi': {
      'VI': 'Tiếng Việt',
      'ENG': 'Vietnamese',
      'CN': '越南语',
    },
    'lang_en': {
      'VI': 'English',
      'ENG': 'English',
      'CN': '英语',
    },
    'lang_zh': {
      'VI': '中文',
      'ENG': 'Chinese',
      'CN': '中文',
    },
    'input_hint': {
      'VI': 'Nhập hoặc dán nội dung cần dịch tại đây... (Ctrl+Enter để dịch)',
      'ENG':
          'Paste text or type here to translate... (Ctrl+Enter to translate)',
      'CN': '在此输入或粘贴需要翻译的内容... (Ctrl+Enter 翻译)',
    },
    'output_hint': {
      'VI': 'Kết quả dịch thuật sẽ xuất hiện tại đây...',
      'ENG': 'Translation result will stream here...',
      'CN': '翻译结果将实时流式呈现在此...',
    },
    'btn_start_translation': {
      'VI': 'BẮT ĐẦU DỊCH (CTRL+ENTER)',
      'ENG': 'START TRANSLATION (CTRL+ENTER)',
      'CN': '开始翻译 (CTRL+ENTER)',
    },
    'btn_translating': {
      'VI': 'ĐANG XỬ LÝ DỊCH THUẬT...',
      'ENG': 'TRANSLATING IN PROGRESS...',
      'CN': '正在深度翻译中...',
    },
    'btn_clear': {
      'VI': 'XÓA',
      'ENG': 'CLEAR',
      'CN': '清空',
    },
    'btn_paste': {
      'VI': 'Dán',
      'ENG': 'Paste',
      'CN': '粘贴',
    },
    'btn_copy': {
      'VI': 'Sao chép',
      'ENG': 'Copy',
      'CN': '复制',
    },
    'btn_tts': {
      'VI': 'Đọc phát âm (TTS)',
      'ENG': 'Speak Audio (TTS)',
      'CN': '朗读发音 (TTS)',
    },
    'btn_stt': {
      'VI': 'Ghi âm giọng nói (STT)',
      'ENG': 'Voice Input (STT)',
      'CN': '语音输入 (STT)',
    },
    'btn_ocr': {
      'VI': 'Trích xuất chữ từ ảnh (OCR)',
      'ENG': 'Extract Text from Image (OCR)',
      'CN': '提取图片文字 (OCR)',
    },
    'btn_pinyin': {
      'VI': 'Hiện / Ẩn Pinyin',
      'ENG': 'Toggle Pinyin',
      'CN': '显示 / 隐藏拼音',
    },
    'toast_copied': {
      'VI': 'Đã sao chép vào bộ nhớ tạm!',
      'ENG': 'Copied to clipboard!',
      'CN': '已复制到剪贴板！',
    },
    'char_count': {
      'VI': '%s ký tự • %s từ',
      'ENG': '%s chars • %s words',
      'CN': '%s 字符 • %s 词',
    },
    'realtime_translate': {
      'VI': 'Dịch thời gian thực',
      'ENG': 'Realtime Translate',
      'CN': '实时即时翻译',
    },

    // Document Translation View
    'doc_title': {
      'VI': 'Dịch Thuật Tài Liệu Chuyên Sâu',
      'ENG': 'Pro Document Translation',
      'CN': '专业文档全文翻译',
    },
    'doc_desc': {
      'VI':
          'Hỗ trợ PDF, Microsoft Word (.docx), TXT với thuật toán tối ưu phông tiếng Việt và chèn Pinyin song ngữ.',
      'ENG':
          'Supports PDF, Word (.docx), TXT with Vietnamese font optimization and bilingual Pinyin annotations.',
      'CN': '支持 PDF、Word (.docx)、TXT，具备越南语字体优化与拼音双语对照排版。',
    },
    'doc_drop_hint': {
      'VI': 'Kéo thả tệp tài liệu vào đây hoặc nhấp để chọn',
      'ENG': 'Drag and drop document files here or click to browse',
      'CN': '将文档拖拽至此或点击选择文件',
    },
    'doc_browse': {
      'VI': 'Chọn Tệp Tin',
      'ENG': 'Browse File',
      'CN': '浏览文件',
    },
    'doc_viet_font_opt': {
      'VI': 'Tối ưu phông chữ tiếng Việt (Chống lỗi dấu PDF)',
      'ENG': 'Vietnamese Font Optimization (Fix PDF Diacritics)',
      'CN': '越南语字体优化 (修复 PDF 声调乱码)',
    },
    'doc_pinyin_annot': {
      'VI': 'Chèn chú thích Pinyin song ngữ (Bilingual Annotation)',
      'ENG': 'Include Bilingual Pinyin Annotations',
      'CN': '包含双语拼音音标注释',
    },
    'doc_btn_translate': {
      'VI': 'BẮT ĐẦU DỊCH TÀI LIỆU',
      'ENG': 'START DOCUMENT TRANSLATION',
      'CN': '开始翻译文档',
    },
    'doc_export_result': {
      'VI': 'Mở Thư Mục Kết Quả',
      'ENG': 'Open Result Folder',
      'CN': '打开结果目录',
    },

    // History View
    'history_title': {
      'VI': 'Lịch Sử & Bản Dịch Đã Lưu',
      'ENG': 'History & Saved Translations',
      'CN': '历史记录与已存译文',
    },
    'history_search_hint': {
      'VI': 'Tìm kiếm trong lịch sử dịch...',
      'ENG': 'Search translation history...',
      'CN': '搜索翻译历史...',
    },
    'history_empty': {
      'VI': 'Chưa có bản dịch nào trong lịch sử',
      'ENG': 'No translation history yet',
      'CN': '暂无翻译历史记录',
    },
    'history_restore': {
      'VI': 'Đưa vào khung dịch',
      'ENG': 'Restore to Editor',
      'CN': '载入翻译框',
    },
    'history_clear_all': {
      'VI': 'Xóa toàn bộ lịch sử',
      'ENG': 'Clear All History',
      'CN': '清空所有历史',
    },

    'ai_studio_0': {
      'VI': "Local AI (Qwen)",
      'ENG': "Local AI (Qwen)",
      'CN': "本地 AI (Qwen)"
    },
    'ai_studio_1': {
      'VI': "Cloud AI (API Gateway)",
      'ENG': "Cloud AI (API Gateway)",
      'CN': "云端 AI (API Gateway)"
    },
    'ai_studio_2': {
      'VI': "Proxy & Network",
      'ENG': "Proxy & Network",
      'CN': "代理与网络"
    },
    'ai_studio_3': {
      'VI': "Đã dừng llama-server!",
      'ENG': "llama-server stopped!",
      'CN': "llama-server 已停止！"
    },
    'ai_studio_4': {
      'VI': "Vui lòng chọn model GGUF trước khi khởi động!",
      'ENG': "Select a GGUF model before starting!",
      'CN': "启动前请选择 GGUF 模型！"
    },
    'ai_studio_5': {
      'VI': "llama-server đã khởi động thành công (Port 8080)!",
      'ENG': "llama-server started successfully (Port 8080)!",
      'CN': "llama-server 启动成功（端口 8080）！"
    },
    'ai_studio_6': {
      'VI': "Không thể khởi động llama-server!",
      'ENG': "Could not start llama-server!",
      'CN': "无法启动 llama-server！"
    },
    'ai_studio_7': {
      'VI': "Đã lưu cấu hình Cloud AI!",
      'ENG': "Cloud AI configuration saved!",
      'CN': "云端 AI 配置已保存！"
    },
    'ai_studio_8': {
      'VI': "Kết nối Cloud AI thành công!",
      'ENG': "Cloud AI connection successful!",
      'CN': "云端 AI 连接成功！"
    },
    'ai_studio_9': {
      'VI': "Lỗi: Kiểm tra lại API Key!",
      'ENG': "Error: Check your API key!",
      'CN': "错误：请检查 API Key！"
    },
    'ai_studio_10': {
      'VI': "Lỗi kiểm tra kết nối: {error}",
      'ENG': "Connection test failed: {error}",
      'CN': "连接测试失败：{error}"
    },
    'ai_studio_11': {
      'VI': "Đã lưu cấu hình Proxy!",
      'ENG': "Proxy configuration saved!",
      'CN': "代理配置已保存！"
    },
    'ai_studio_12': {
      'VI': "Trạng Thái Server Local",
      'ENG': "Local Server Status",
      'CN': "本地服务器状态"
    },
    'ai_studio_13': {
      'VI': "PORT 8080 • ĐANG CHẠY",
      'ENG': "PORT 8080 • RUNNING",
      'CN': "端口 8080 • 运行中"
    },
    'ai_studio_14': {'VI': "ĐÃ DỪNG", 'ENG': "STOPPED", 'CN': "已停止"},
    'ai_studio_15': {
      'VI': "llama-server đang lắng nghe tại http://127.0.0.1:8080",
      'ENG': "llama-server listening at http://127.0.0.1:8080",
      'CN': "llama-server 正在监听 http://127.0.0.1:8080"
    },
    'ai_studio_16': {
      'VI': "Server đang tắt. Bấm Khởi động để nạp mô hình vào RAM.",
      'ENG': "Server is stopped. Start it to load the model into RAM.",
      'CN': "服务器已停止。点击启动以将模型加载到内存。"
    },
    'ai_studio_17': {
      'VI': "Mở Thư Mục models/",
      'ENG': "Open models/ Folder",
      'CN': "打开 models/ 目录"
    },
    'ai_studio_18': {'VI': "Dừng Server", 'ENG': "Stop Server", 'CN': "停止服务器"},
    'ai_studio_19': {
      'VI': "Khởi Động Server",
      'ENG': "Start Server",
      'CN': "启动服务器"
    },
    'ai_studio_20': {
      'VI': "Mô hình GGUF đang chọn:",
      'ENG': "Selected GGUF model:",
      'CN': "已选择的 GGUF 模型："
    },
    'ai_studio_21': {
      'VI':
          "Chưa tìm thấy tệp .gguf trong thư mục models/. Bạn có thể copy tệp mô hình vào thư mục hoặc tải theo danh sách bên dưới.",
      'ENG':
          "No .gguf files found in models/. Copy a model into the folder or download one below.",
      'CN': "models/ 中未找到 .gguf 文件。请复制模型到该目录或从下面下载。"
    },
    'ai_studio_22': {
      'VI': "Mô Hình Khuyên Dùng Cho Máy Trạm",
      'ENG': "Recommended Models",
      'CN': "推荐模型"
    },
    'ai_studio_23': {'VI': "ĐÃ CÀI ĐẶT", 'ENG': "INSTALLED", 'CN': "已安装"},
    'ai_studio_24': {'VI': "Tải GGUF", 'ENG': "Download GGUF", 'CN': "下载 GGUF"},
    'ai_studio_25': {
      'VI': "Cấu Hình Cloud AI Gateway",
      'ENG': "Cloud AI Gateway Configuration",
      'CN': "云端 AI 网关配置"
    },
    'ai_studio_26': {
      'VI':
          "Hỗ trợ NVIDIA NIM, OpenAI, Groq, OpenRouter với khả năng dịch thuật tốc độ cao và nhận diện hình ảnh.",
      'ENG':
          "Supports NVIDIA NIM, OpenAI, Groq and OpenRouter for fast translation and image recognition.",
      'CN': "支持 NVIDIA NIM、OpenAI、Groq 和 OpenRouter，提供快速翻译和图像识别。"
    },
    'ai_studio_27': {
      'VI': "Nhập API key...",
      'ENG': "Enter API key...",
      'CN': "输入 API Key..."
    },
    'ai_studio_28': {
      'VI': "Mô hình Cloud:",
      'ENG': "Cloud model:",
      'CN': "云端模型："
    },
    'ai_studio_29': {
      'VI': "Kiểm Tra Kết Nối",
      'ENG': "Test Connection",
      'CN': "测试连接"
    },
    'ai_studio_30': {
      'VI': "Lưu Cấu Hình",
      'ENG': "Save Configuration",
      'CN': "保存配置"
    },
    'ai_studio_31': {
      'VI': "Cấu Hình HTTP Proxy Doanh Nghiệp",
      'ENG': "Enterprise HTTP Proxy Configuration",
      'CN': "企业 HTTP 代理配置"
    },
    'ai_studio_32': {
      'VI':
          "Cho phép ứng dụng kết nối ra ngoài internet trong mạng xưởng bị chặn cổng.",
      'ENG':
          "Connect to the internet through a proxy on restricted factory networks.",
      'CN': "通过代理在受限的工厂网络中连接互联网。"
    },
    'ai_studio_33': {
      'VI': "Proxy Host / IP:",
      'ENG': "Proxy Host / IP:",
      'CN': "代理主机 / IP："
    },
    'ai_studio_34': {
      'VI': "10.81.x.x hoặc proxy.company.com",
      'ENG': "10.81.x.x or proxy.company.com",
      'CN': "10.81.x.x 或 proxy.company.com"
    },
    'ai_studio_35': {'VI': "Port:", 'ENG': "Port:", 'CN': "端口："},
    'ai_studio_36': {
      'VI': "Username (tùy chọn):",
      'ENG': "Username (optional):",
      'CN': "用户名（可选）："
    },
    'ai_studio_37': {
      'VI': "Password (tùy chọn):",
      'ENG': "Password (optional):",
      'CN': "密码（可选）："
    },
    'ai_studio_38': {
      'VI': "Lưu Cấu Hình Proxy",
      'ENG': "Save Proxy Configuration",
      'CN': "保存代理配置"
    },
    'ai_preset_name_0': {
      'VI': "Qwen2.5-1.5B (Khuyên dùng)",
      'ENG': "Qwen2.5-1.5B (Recommended)",
      'CN': "Qwen2.5-1.5B（推荐）"
    },
    'ai_preset_desc_0': {
      'VI':
          "Tối ưu tốc độ cao nhất và chuẩn xác nhất cho máy 8GB RAM. Chiếm ~1.1GB RAM.",
      'ENG': "Optimized for 8GB RAM PCs. Uses ~1.1GB RAM.",
      'CN': "适用于 8GB 内存电脑。占用约 1.1GB 内存。"
    },
    'ai_preset_name_1': {
      'VI': "Qwen2.5-0.5B (Siêu nhẹ)",
      'ENG': "Qwen2.5-0.5B (Lightweight)",
      'CN': "Qwen2.5-0.5B（轻量）"
    },
    'ai_preset_desc_1': {
      'VI': "Cực nhẹ, tốc độ dịch tức thì. Chiếm ~500MB RAM.",
      'ENG': "Lightweight, fast translation. Uses ~500MB RAM.",
      'CN': "轻量、快速翻译。占用约 500MB 内存。"
    },
    'ai_preset_name_2': {
      'VI': "Qwen2.5-3B (Chất lượng cao)",
      'ENG': "Qwen2.5-3B (High quality)",
      'CN': "Qwen2.5-3B（高质量）"
    },
    'ai_preset_desc_2': {
      'VI':
          "Bản dịch chi tiết, câu từ học thuật mượt mà hơn. Chiếm ~2.3GB RAM.",
      'ENG': "Detailed translations. Uses ~2.3GB RAM.",
      'CN': "详细翻译。占用约 2.3GB 内存。"
    },
    'ai_preset_name_3': {
      'VI': "Qwen2-VL-2B (Dịch Ảnh & Chữ Local)",
      'ENG': "Qwen2-VL-2B (Local image & text)",
      'CN': "Qwen2-VL-2B（本地图文）"
    },
    'ai_preset_desc_3': {
      'VI':
          "Hỗ trợ nhận diện dịch trực tiếp cả hình ảnh và văn bản offline. Chiếm ~2.1GB RAM.",
      'ENG': "Offline image and text translation. Uses ~2.1GB RAM.",
      'CN': "离线图像和文字翻译。占用约 2.1GB 内存。"
    },
    'ai_download_success': {
      'VI': "Đã tải mô hình vào models/!",
      'ENG': "Model downloaded to models/!",
      'CN': "模型已下载到 models/！"
    },
    'ai_download_error': {
      'VI': "Không thể tải mô hình",
      'ENG': "Model download failed",
      'CN': "模型下载失败"
    },
    'ai_downloading': {
      'VI': "Đang tải...",
      'ENG': "Downloading...",
      'CN': "正在下载..."
    },

    'engine_missing_local_model': {
      'VI': "CHƯA CÓ MODEL",
      'ENG': "MODEL REQUIRED",
      'CN': "需要模型"
    },
    'engine_missing_local_server': {
      'VI': "THIẾU LLAMA-SERVER",
      'ENG': "LLAMA-SERVER REQUIRED",
      'CN': "需要 LLAMA-SERVER"
    },
    'engine_missing_cloud_config': {
      'VI': "CHƯA CẤU HÌNH CLOUD",
      'ENG': "CLOUD CONFIG REQUIRED",
      'CN': "需要云端配置"
    },
    'engine_configured': {
      'VI': "ĐÃ CẤU HÌNH",
      'ENG': "CONFIGURED",
      'CN': "已配置"
    },
    'ai_unknown_size': {
      'VI': "Chưa rõ kích thước",
      'ENG': "Unknown size",
      'CN': "大小未知"
    },
    'missing_local_title': {
      'VI': "Chưa Có Model Local GGUF",
      'ENG': "Local GGUF Model Required",
      'CN': "需要本地 GGUF 模型"
    },
    'missing_local_body': {
      'VI': "Chưa có mô hình GGUF đang chọn trong models/ để dịch offline.",
      'ENG':
          "The selected GGUF model is missing from models/ for offline translation.",
      'CN': "models/ 中缺少所选的 GGUF 模型，无法离线翻译。"
    },
    'missing_local_hint': {
      'VI':
          "Vào AI Studio để tải và chọn mô hình GGUF, hoặc chuyển sang Cloud AI.",
      'ENG':
          "Open AI Studio to download and select a GGUF model, or switch to Cloud AI.",
      'CN': "打开 AI Studio 下载并选择 GGUF 模型，或切换到云端 AI。"
    },
    'missing_cloud_title': {
      'VI': "Chưa Cấu Hình Cloud AI",
      'ENG': "Cloud AI Configuration Required",
      'CN': "需要云端 AI 配置"
    },
    'missing_cloud_body': {
      'VI': "Cloud AI cần API Key, mô hình và địa chỉ API hợp lệ.",
      'ENG': "Cloud AI requires an API key, model and valid API URL.",
      'CN': "云端 AI 需要 API Key、模型和有效的 API 地址。"
    },
    'missing_cloud_hint': {
      'VI':
          "Vui lòng vào tab AI Studio để nhập API Key và chọn mô hình mong muốn.",
      'ENG': "Open the AI Studio tab to enter an API key and select a model.",
      'CN': "请打开 AI Studio 标签页，输入 API Key 并选择模型。"
    },
    'missing_local_server_title': {
      'VI': "Thiếu llama-server",
      'ENG': "llama-server Required",
      'CN': "需要 llama-server"
    },
    'missing_local_server_body': {
      'VI':
          "Không tìm thấy bin/llama-server.exe. Hãy bổ sung llama-server trước khi dùng Local AI.",
      'ENG':
          "bin/llama-server.exe was not found. Install llama-server before using Local AI.",
      'CN': "未找到 bin/llama-server.exe。使用本地 AI 前请安装 llama-server。"
    },
    'use_cloud_temporarily': {
      'VI': "Dùng Cloud AI Tạm Thời",
      'ENG': "Use Cloud AI Temporarily",
      'CN': "临时使用云端 AI"
    },
    // AI Studio View
    'ai_studio_title': {
      'VI': 'Quản Trị AI Studio & Mạng',
      'ENG': 'AI Studio & Network Engine',
      'CN': 'AI 工作台与网络引擎',
    },
    'ai_local_section': {
      'VI': 'Động cơ Local AI (Qwen)',
      'ENG': 'Local AI Engine (llama-server)',
      'CN': '本地 AI 引擎 (llama-server)',
    },
    'ai_cloud_section': {
      'VI': 'Động cơ Cloud AI (API Gateway)',
      'ENG': 'Cloud AI Engine (API Gateway)',
      'CN': '云端 AI 引擎 (API Gateway)',
    },
    'ai_proxy_section': {
      'VI': 'Cấu hình Mạng & Proxy',
      'ENG': 'Network & Proxy Gateway',
      'CN': '网络与代理网关',
    },

    // Settings Modal
    'settings_dialog_title': {
      'VI': 'Cài Đặt Hệ Thống JA Translate',
      'ENG': 'JA Translate System Settings',
      'CN': 'JA 翻译系统设置',
    },
    'tab_settings_general': {
      'VI': 'Cài đặt chung',
      'ENG': 'General',
      'CN': '通用设置',
    },
    'tab_settings_ui': {
      'VI': 'Giao diện & Kính mờ',
      'ENG': 'Appearance & Glass',
      'CN': '界面与玻璃',
    },
    'tab_settings_trans': {
      'VI': 'Dịch thuật & Phông chữ',
      'ENG': 'Translation & Fonts',
      'CN': '翻译与字体',
    },
    'tab_settings_ota': {
      'VI': 'Cập nhật OTA',
      'ENG': 'LAN OTA Updates',
      'CN': '局域网 OTA 更新',
    },
    'tab_settings_shortcuts': {
      'VI': 'Phím tắt',
      'ENG': 'Shortcuts',
      'CN': '快捷键',
    },
    'tab_settings_about': {
      'VI': 'Giới thiệu',
      'ENG': 'About',
      'CN': '关于',
    },
    'tab_settings_shortcuts_about': {
      'VI': 'Phím tắt & Thông tin',
      'ENG': 'Shortcuts & About',
      'CN': '快捷键与关于',
    },
    'settings_card_header': {
      'VI': 'Thẻ kính Bento (Cards)',
      'ENG': 'Bento Glass Cards',
      'CN': 'Bento 玻璃卡片',
    },
    'settings_default': {
      'VI': 'Mặc định',
      'ENG': 'Default',
      'CN': '恢复默认',
    },
    'settings_card_blur': {
      'VI': 'Độ mờ kính (Blur)',
      'ENG': 'Card Blur Sigma',
      'CN': '卡片模糊度',
    },
    'settings_card_opacity': {
      'VI': 'Độ trong suốt nền (Opacity)',
      'ENG': 'Card Opacity',
      'CN': '卡片不透明度',
    },
    'settings_dialog_header': {
      'VI': 'Hộp thoại & Cửa sổ nổi (Dialogs)',
      'ENG': 'Dialogs & Modals',
      'CN': '弹窗与对话框',
    },
    'settings_dialog_blur': {
      'VI': 'Độ mờ hộp thoại (Blur)',
      'ENG': 'Dialog Blur Sigma',
      'CN': '对话框模糊度',
    },
    'settings_dialog_opacity': {
      'VI': 'Độ trong suốt hộp thoại (Opacity)',
      'ENG': 'Dialog Opacity',
      'CN': '对话框不透明度',
    },
    'settings_dropdown_header': {
      'VI': 'Menu thả xuống (Dropdowns)',
      'ENG': 'Dropdown Menus',
      'CN': '下拉菜单',
    },
    'settings_dropdown_blur': {
      'VI': 'Độ mờ menu (Blur)',
      'ENG': 'Dropdown Blur Sigma',
      'CN': '下拉菜单模糊度',
    },
    'settings_dropdown_opacity': {
      'VI': 'Độ trong suốt menu (Opacity)',
      'ENG': 'Dropdown Opacity',
      'CN': '下拉菜单不透明度',
    },
    'settings_btn_save': {
      'VI': 'Lưu thay đổi',
      'ENG': 'Save Changes',
      'CN': '保存更改',
    },
    'settings_btn_close': {
      'VI': 'Đóng',
      'ENG': 'Close',
      'CN': '关闭',
    },

    // OTA Keys
    'ota_btn': {
      'VI': 'CẬP NHẬT',
      'ENG': 'UPDATE',
      'CN': '更新',
    },
    'ota_title': {
      'VI': 'Cập Nhật Mạng Nội Bộ (LAN OTA)',
      'ENG': 'LAN OTA Update',
      'CN': '局域网 OTA 更新',
    },
    'ota_server_path': {
      'VI': 'Đường dẫn máy chủ (SMB / UNC):',
      'ENG': 'Update Server Path (SMB / UNC):',
      'CN': '更新服务器路径 (SMB / UNC):',
    },
    'ota_server_path_hint': {
      'VI': r'\\10.81.141.226\temp\FBT\JA_PROJECT\JA_Update\JA_Translate',
      'ENG': r'\\10.81.141.226\temp\FBT\JA_PROJECT\JA_Update\JA_Translate',
      'CN': r'\\10.81.141.226\temp\FBT\JA_PROJECT\JA_Update\JA_Translate',
    },
    'ota_username': {
      'VI': 'Tài khoản SMB (nếu có):',
      'ENG': 'SMB Username (optional):',
      'CN': 'SMB 用户名 (可选):',
    },
    'ota_password': {
      'VI': 'Mật khẩu SMB (nếu có):',
      'ENG': 'SMB Password (optional):',
      'CN': 'SMB 密码 (可选):',
    },
    'ota_interval': {
      'VI': 'Chu kỳ tự động kiểm tra:',
      'ENG': 'Auto-check Interval:',
      'CN': '自动检查周期:',
    },
    'ota_interval_daily': {
      'VI': 'Hàng ngày',
      'ENG': 'Daily',
      'CN': '每天',
    },
    'ota_interval_weekly': {
      'VI': 'Hàng tuần',
      'ENG': 'Weekly',
      'CN': '每周',
    },
    'ota_interval_monthly': {
      'VI': 'Hàng tháng',
      'ENG': 'Monthly',
      'CN': '每月',
    },
    'ota_interval_off': {
      'VI': 'Tắt',
      'ENG': 'Off',
      'CN': '关闭',
    },
    'ota_test_connection': {
      'VI': 'Kiểm tra kết nối',
      'ENG': 'Test Connection',
      'CN': '测试连接',
    },
    'ota_open_config_folder': {
      'VI': 'Mở thư mục cấu hình',
      'ENG': 'Open Config Folder',
      'CN': '打开配置目录',
    },
    'ota_testing_connection': {
      'VI': 'Đang kiểm tra kết nối...',
      'ENG': 'Testing connection...',
      'CN': '正在测试连接...',
    },
    'ota_connection_success': {
      'VI': 'Kết nối máy chủ thành công!',
      'ENG': 'Server connection successful!',
      'CN': '服务器连接成功！',
    },
    'ota_connection_failed': {
      'VI': 'Không thể kết nối máy chủ',
      'ENG': 'Failed to connect to server',
      'CN': '无法连接到服务器',
    },
    'ota_check_now': {
      'VI': 'Kiểm tra bản cập nhật ngay',
      'ENG': 'Check for Updates Now',
      'CN': '立即检查更新',
    },
    'ota_checking': {
      'VI': 'Đang kiểm tra máy chủ...',
      'ENG': 'Checking update server...',
      'CN': '正在检查更新服务器...',
    },
    'ota_up_to_date': {
      'VI': 'Bạn đang sử dụng phiên bản mới nhất!',
      'ENG': 'You are using the latest version!',
      'CN': '当前已是最新版本！',
    },
    'ota_update_available': {
      'VI': 'Đã phát hiện phiên bản mới',
      'ENG': 'New version is available',
      'CN': '发现新版本',
    },
    'ota_save': {
      'VI': 'Lưu Cấu Hình',
      'ENG': 'Save Config',
      'CN': '保存配置',
    },
    'ota_saved_success': {
      'VI': 'Đã lưu cấu hình OTA thành công!',
      'ENG': 'OTA configuration saved!',
      'CN': 'OTA 配置保存成功！',
    },
  };
}
