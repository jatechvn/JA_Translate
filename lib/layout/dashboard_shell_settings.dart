part of 'dashboard_shell.dart';

class TopBarExpandingButton extends StatefulWidget {
  final Widget icon;
  final String? collapsedLabel;
  final String expandedLabel;
  final Color? textColor;
  final VoidCallback onTap;
  final String tooltip;
  final AppColors colors;
  final bool isCompact;

  const TopBarExpandingButton({
    super.key,
    required this.icon,
    this.collapsedLabel,
    required this.expandedLabel,
    this.textColor,
    required this.onTap,
    required this.tooltip,
    required this.colors,
    this.isCompact = false,
  });

  @override
  State<TopBarExpandingButton> createState() => _TopBarExpandingButtonState();
}

class _TopBarExpandingButtonState extends State<TopBarExpandingButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final showLabel =
        _isHovered || (!widget.isCompact && widget.collapsedLabel != null);
    final currentLabel =
        _isHovered ? widget.expandedLabel : (widget.collapsedLabel ?? '');

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(100),
              splashFactory: NoSplash.splashFactory,
              hoverColor: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: showLabel ? 11 : 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? colors.cardHoverBg.withValues(alpha: 0.35)
                      : colors.subCardBg,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: _isHovered
                        ? (widget.textColor ?? colors.accentCyan).withValues(
                            alpha: 0.65,
                          )
                        : colors.subCardBorder,
                    width: _isHovered ? 1.2 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered
                          ? (widget.textColor ?? colors.primaryGlow).withValues(
                              alpha: 0.25,
                            )
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: _isHovered ? 10 : 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.icon,
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      clipBehavior: Clip.none,
                      child: showLabel && currentLabel.isNotEmpty
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 6),
                                Text(
                                  currentLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  style: TextStyle(
                                    color:
                                        widget.textColor ?? colors.textPrimary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Backward compatibility alias
typedef TopBarPillButton = TopBarExpandingButton;

class _SettingsTabSelector extends StatelessWidget {
  const _SettingsTabSelector({
    required this.activeTab,
    required this.colors,
    required this.language,
    required this.onTabSelected,
  });

  final int activeTab;
  final AppColors colors;
  final LanguageProvider language;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.subCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.subCardBorder),
      ),
      child: Row(
        children: [
          _buildItem(0, Icons.tune_rounded, language.t('tab_settings_general')),
          _buildItem(1, Icons.system_update_alt_rounded,
              language.t('tab_settings_ota')),
          _buildItem(2, Icons.info_outline_rounded,
              language.t('tab_settings_shortcuts_about')),
        ],
      ),
    );
  }

  Widget _buildItem(int index, IconData icon, String label) {
    final isSelected = activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      colors.accentColor,
                      colors.accentCyan.withValues(alpha: 0.88),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.primaryGlow.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colors.textSecondary,
                    fontSize: 12.5,
                    letterSpacing: 0.2,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 0: General Settings (Consolidating Glass Tuning & Translation Options)
// ---------------------------------------------------------------------------
class _SettingsGeneralTab extends StatefulWidget {
  final AppColors colors;
  final ThemeProvider theme;
  final LanguageProvider language;
  final double localCardBlur;
  final double localCardOpacity;
  final double localDialogBlur;
  final double localDialogOpacity;
  final double localDropdownBlur;
  final double localDropdownOpacity;
  final ValueChanged<double> onCardBlurChanged;
  final ValueChanged<double> onCardOpacityChanged;
  final ValueChanged<double> onDialogBlurChanged;
  final ValueChanged<double> onDialogOpacityChanged;
  final ValueChanged<double> onDropdownBlurChanged;
  final ValueChanged<double> onDropdownOpacityChanged;
  final VoidCallback onResetDefaults;

  const _SettingsGeneralTab({
    required this.colors,
    required this.theme,
    required this.language,
    required this.localCardBlur,
    required this.localCardOpacity,
    required this.localDialogBlur,
    required this.localDialogOpacity,
    required this.localDropdownBlur,
    required this.localDropdownOpacity,
    required this.onCardBlurChanged,
    required this.onCardOpacityChanged,
    required this.onDialogBlurChanged,
    required this.onDialogOpacityChanged,
    required this.onDropdownBlurChanged,
    required this.onDropdownOpacityChanged,
    required this.onResetDefaults,
  });

  @override
  State<_SettingsGeneralTab> createState() => _SettingsGeneralTabState();
}

class _SettingsGeneralTabState extends State<_SettingsGeneralTab> {
  late bool _realtimeTranslate;
  late bool _showPinyin;
  late bool _vietnameseFontOpt;
  late String _defaultTargetLang;

  @override
  void initState() {
    super.initState();
    _realtimeTranslate =
        AppConfig.get('SETTINGS', 'realtime_translate', defaultValue: 'true') ==
            'true';
    _showPinyin =
        AppConfig.get('SETTINGS', 'show_pinyin', defaultValue: 'true') ==
            'true';
    _vietnameseFontOpt = AppConfig.get(
          'SETTINGS',
          'vietnamese_font_optimization',
          defaultValue: 'true',
        ) ==
        'true';
    _defaultTargetLang = AppConfig.get(
      'SETTINGS',
      'default_target_lang',
      defaultValue: 'vi',
    );
  }

  void _saveSettings() {
    AppConfig.set(
      'SETTINGS',
      'realtime_translate',
      _realtimeTranslate.toString(),
    );
    AppConfig.set('SETTINGS', 'show_pinyin', _showPinyin.toString());
    AppConfig.set(
      'SETTINGS',
      'vietnamese_font_optimization',
      _vietnameseFontOpt.toString(),
    );
    AppConfig.set('SETTINGS', 'default_target_lang', _defaultTargetLang);
    AppConfig.save();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final lang = widget.language;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Glass Cards Tuning
          BentoCard(
            colors: colors,
            blurSigma: widget.localCardBlur,
            bgOpacity: widget.localCardOpacity,
            padding: const EdgeInsets.all(18),
            borderRadius: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.blur_on_rounded,
                          size: 19,
                          color: colors.accentPurple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          lang.t('settings_card_header'),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: widget.onResetDefaults,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          lang.t('settings_default'),
                          style: TextStyle(
                            color: colors.accentCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildSlider(
                  label: lang.t('settings_card_blur'),
                  value: widget.localCardBlur,
                  min: 0,
                  max: 40,
                  unit: 'px',
                  onChanged: widget.onCardBlurChanged,
                ),
                const SizedBox(height: 10),
                _buildSlider(
                  label: lang.t('settings_card_opacity'),
                  value: widget.localCardOpacity,
                  min: 0.05,
                  max: 0.95,
                  unit: '%',
                  multiplier: 100,
                  onChanged: widget.onCardOpacityChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Section 2: Dialogs Glass Tuning
          BentoCard(
            colors: colors,
            blurSigma: widget.localCardBlur,
            bgOpacity: widget.localCardOpacity,
            padding: const EdgeInsets.all(18),
            borderRadius: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.layers_rounded,
                      size: 19,
                      color: colors.accentCyan,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      lang.t('settings_dialog_header'),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildSlider(
                  label: lang.t('settings_dialog_blur'),
                  value: widget.localDialogBlur,
                  min: 0,
                  max: 40,
                  unit: 'px',
                  onChanged: widget.onDialogBlurChanged,
                ),
                const SizedBox(height: 10),
                _buildSlider(
                  label: lang.t('settings_dialog_opacity'),
                  value: widget.localDialogOpacity,
                  min: 0.30,
                  max: 0.98,
                  unit: '%',
                  multiplier: 100,
                  onChanged: widget.onDialogOpacityChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Section 3: Dropdown Glass Tuning
          BentoCard(
            colors: colors,
            blurSigma: widget.localCardBlur,
            bgOpacity: widget.localCardOpacity,
            padding: const EdgeInsets.all(18),
            borderRadius: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.menu_open_rounded,
                      size: 19,
                      color: colors.accentAmber,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      lang.t('settings_dropdown_header'),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildSlider(
                  label: lang.t('settings_dropdown_blur'),
                  value: widget.localDropdownBlur,
                  min: 0,
                  max: 40,
                  unit: 'px',
                  onChanged: widget.onDropdownBlurChanged,
                ),
                const SizedBox(height: 10),
                _buildSlider(
                  label: lang.t('settings_dropdown_opacity'),
                  value: widget.localDropdownOpacity,
                  min: 0.30,
                  max: 0.98,
                  unit: '%',
                  multiplier: 100,
                  onChanged: widget.onDropdownOpacityChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Section 4: Translation Options & Fonts
          BentoCard(
            colors: colors,
            padding: const EdgeInsets.all(18),
            borderRadius: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.translate_rounded,
                      color: colors.accentCyan,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      lang.t('tab_settings_trans'),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSwitchTile(
                  title: lang.t('realtime_translate'),
                  subtitle: lang.t('settings_auto_translate'),
                  value: _realtimeTranslate,
                  onChanged: (v) {
                    setState(() => _realtimeTranslate = v);
                    _saveSettings();
                  },
                ),
                const SizedBox(height: 14),
                _buildSwitchTile(
                  title: lang.t('btn_pinyin'),
                  subtitle: lang.t('settings_pinyin_display'),
                  value: _showPinyin,
                  onChanged: (v) {
                    setState(() => _showPinyin = v);
                    _saveSettings();
                  },
                ),
                const SizedBox(height: 14),
                _buildSwitchTile(
                  title: lang.t('doc_viet_font_opt'),
                  subtitle: lang.t('settings_pdf_fonts'),
                  value: _vietnameseFontOpt,
                  onChanged: (v) {
                    setState(() => _vietnameseFontOpt = v);
                    _saveSettings();
                  },
                ),
                const SizedBox(height: 18),
                Divider(color: colors.subCardBorder, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.t('settings_target_lang'),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLangChip('vi', 'Tiếng Việt 🇻🇳'),
                        const SizedBox(width: 6),
                        _buildLangChip('en', 'English 🇬🇧'),
                        const SizedBox(width: 6),
                        _buildLangChip('zh', '中文 🇨🇳'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    double multiplier = 1,
    required ValueChanged<double> onChanged,
  }) {
    final colors = widget.colors;
    final displayVal = (value * multiplier).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$displayVal$unit',
              style: TextStyle(
                color: colors.accentCyan,
                fontSize: 12.5,
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: colors.accentCyan,
            inactiveTrackColor: colors.subCardBorder,
            thumbColor: Colors.white,
            overlayColor: colors.accentCyan.withValues(alpha: 0.15),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildLangChip(String code, String label) {
    final colors = widget.colors;
    final isSelected = _defaultTargetLang == code;
    return InkWell(
      onTap: () {
        setState(() => _defaultTargetLang = code);
        _saveSettings();
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentColor : colors.subCardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colors.accentColor : colors.subCardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = widget.colors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: colors.accentCyan,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2: LAN OTA Update Settings with Quick Selection Chips
// ---------------------------------------------------------------------------
class _SettingsOtaTab extends StatefulWidget {
  final AppColors colors;
  final LanguageProvider language;

  const _SettingsOtaTab({
    required this.colors,
    required this.language,
  });

  @override
  State<_SettingsOtaTab> createState() => _SettingsOtaTabState();
}

class _SettingsOtaTabState extends State<_SettingsOtaTab> {
  final _service = OtaUpdateService();
  late final TextEditingController _serverPathController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  String _selectedInterval = 'daily';
  bool _obscurePassword = true;

  bool _isChecking = false;
  String? _checkStatusMessage;
  bool _checkStatusIsSuccess = true;

  bool _isTestingConnection = false;
  String? _testConnectionResult;
  bool? _testConnectionSuccess;

  @override
  void initState() {
    super.initState();
    _serverPathController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _service.loadConfig();
    setState(() {
      _serverPathController.text = config.serverPath;
      _usernameController.text = config.username;
      _passwordController.text = config.password;
      _selectedInterval = config.checkInterval;
    });
  }

  @override
  void dispose() {
    _serverPathController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    final newConfig = OtaUpdateConfig(
      serverPath: _serverPathController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      checkInterval: _selectedInterval,
    );
    await _service.saveConfig(newConfig);
    if (!mounted) return;
    showAppToast(
      context,
      colors: widget.colors,
      message: widget.language.t('ota_saved_success'),
      icon: Icons.check_circle_rounded,
      accentColor: widget.colors.accentEmerald,
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _testConnectionResult = null;
    });

    final success = await _service.testServerConnection(
      serverPath: _serverPathController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() {
      _isTestingConnection = false;
      _testConnectionSuccess = success;
      _testConnectionResult = success
          ? widget.language.t('ota_connection_success')
          : widget.language.t('ota_connection_failed');
    });
  }

  Future<void> _checkNow() async {
    setState(() {
      _isChecking = true;
      _checkStatusMessage = null;
    });

    await _saveConfig();
    final result = await _service.checkForUpdates();

    if (!mounted) return;
    setState(() {
      _isChecking = false;
      if (result.hasUpdate && result.packageInfo != null) {
        _checkStatusIsSuccess = true;
        _checkStatusMessage =
            '${widget.language.t('ota_update_available')}: ${result.packageInfo!.version.displayVersion}';
      } else if (!result.isConnectionSuccess) {
        _checkStatusIsSuccess = false;
        _checkStatusMessage =
            result.errorMessage ?? widget.language.t('ota_connection_failed');
      } else {
        _checkStatusIsSuccess = true;
        _checkStatusMessage = widget.language.t('ota_up_to_date');
      }
    });

    if (result.hasUpdate && result.packageInfo != null) {
      await showGlassUpdateDialog(
        context: context,
        packageInfo: result.packageInfo!,
        uiLang: widget.language.currentLanguage.code,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final lang = widget.language;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          BentoCard(
            colors: colors,
            padding: const EdgeInsets.all(16),
            borderRadius: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.system_update_alt_rounded,
                            color: colors.accentEmerald, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          lang.t('ota_title'),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    PillBadge(
                      label: 'v$appVersion',
                      color: colors.accentCyan,
                      bg: colors.accentCyan.withValues(alpha: 0.15),
                      border: colors.accentCyan.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  lang.t('ota_server_path'),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _serverPathController,
                  style: TextStyle(color: colors.textPrimary, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: lang.t('ota_server_path_hint'),
                    hintStyle: TextStyle(color: colors.textMuted, fontSize: 11),
                    filled: true,
                    fillColor: colors.subCardBg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(color: colors.subCardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(color: colors.subCardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide:
                          BorderSide(color: colors.accentEmerald, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  lang.t('ota_interval'),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildIntervalChip('daily', lang.t('ota_interval_daily')),
                    const SizedBox(width: 6),
                    _buildIntervalChip('weekly', lang.t('ota_interval_weekly')),
                    const SizedBox(width: 6),
                    _buildIntervalChip(
                        'monthly', lang.t('ota_interval_monthly')),
                    const SizedBox(width: 6),
                    _buildIntervalChip('off', lang.t('ota_interval_off')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.t('ota_username'),
                            style: TextStyle(
                                color: colors.textMuted, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _usernameController,
                            style: TextStyle(
                                color: colors.textPrimary, fontSize: 11.5),
                            decoration: InputDecoration(
                              hintText: 'user',
                              filled: true,
                              fillColor: colors.subCardBg,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: colors.subCardBorder),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.t('ota_password'),
                            style: TextStyle(
                                color: colors.textMuted, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(
                                color: colors.textPrimary, fontSize: 11.5),
                            decoration: InputDecoration(
                              hintText: '••••',
                              filled: true,
                              fillColor: colors.subCardBg,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 14,
                                  color: colors.textMuted,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: colors.subCardBorder),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isTestingConnection ? null : _testConnection,
                      icon: _isTestingConnection
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering_rounded, size: 14),
                      label: Text(
                        _isTestingConnection
                            ? lang.t('ota_testing_connection')
                            : lang.t('ota_test_connection'),
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GlowingActionButton(
                      height: 34,
                      colors: colors,
                      icon: _isChecking
                          ? Icons.hourglass_top_rounded
                          : Icons.sync_rounded,
                      label: _isChecking
                          ? lang.t('ota_checking')
                          : lang.t('ota_check_now'),
                      onPressed: _isChecking ? () {} : _checkNow,
                    ),
                  ],
                ),
                if (_testConnectionResult != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _testConnectionResult!,
                    style: TextStyle(
                      color: _testConnectionSuccess == true
                          ? colors.accentEmerald
                          : colors.accentAmber,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (_checkStatusMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _checkStatusMessage!,
                    style: TextStyle(
                      color: _checkStatusIsSuccess
                          ? colors.accentCyan
                          : colors.accentAmber,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalChip(String key, String label) {
    final colors = widget.colors;
    final isSelected = _selectedInterval == key;
    return InkWell(
      onTap: () {
        setState(() => _selectedInterval = key);
        _saveConfig();
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentEmerald : colors.subCardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colors.accentEmerald : colors.subCardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2: Consolidated Shortcuts & About System Diagnostics Tab
// ---------------------------------------------------------------------------
class _SettingsShortcutsAndAboutTab extends StatelessWidget {
  final AppColors colors;
  final ThemeProvider theme;
  final LanguageProvider language;
  final String appVersion;
  final bool isDebug;

  const _SettingsShortcutsAndAboutTab({
    required this.colors,
    required this.theme,
    required this.language,
    required this.appVersion,
    required this.isDebug,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'key': 'Ctrl + Enter', 'desc': language.t('shortcut_translate_now')},
      {'key': 'Ctrl + 1', 'desc': language.t('shortcut_tab_text')},
      {'key': 'Ctrl + 2', 'desc': language.t('shortcut_tab_doc')},
      {'key': 'Ctrl + 3', 'desc': language.t('shortcut_tab_history')},
      {'key': 'Ctrl + 4', 'desc': language.t('shortcut_tab_studio')},
      {'key': 'Ctrl + K', 'desc': language.t('shortcut_cmd_palette')},
      {'key': 'Ctrl + Shift + L', 'desc': language.t('shortcut_toggle_theme')},
      {'key': 'Ctrl + ,', 'desc': language.t('shortcut_open_settings')},
      {'key': 'Ctrl + Shift + S', 'desc': language.t('shortcut_screen_snip')},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Keyboard Shortcuts Card
          BentoCard(
            colors: colors,
            padding: const EdgeInsets.all(18),
            borderRadius: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.keyboard_rounded,
                        color: colors.accentCyan, size: 19),
                    const SizedBox(width: 8),
                    Text(
                      language.t('tab_settings_shortcuts'),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Column(
                  children: items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: colors.subCardBg,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: colors.subCardBorder),
                            ),
                            child: Text(
                              item['key']!,
                              style: TextStyle(
                                color: colors.accentCyan,
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              item['desc']!,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Section 2: About & System Diagnostics Card
          BentoCard(
            colors: colors,
            padding: const EdgeInsets.all(20),
            borderRadius: 14,
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primaryGlow.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/app_icon.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'JA Translate',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bento Frosted Glass Desktop Edition',
                  style: TextStyle(
                    color: colors.accentCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                PillBadge(
                  label: 'Version $appVersion (Build 2026)',
                  color: colors.accentPurple,
                  bg: colors.accentPurple.withValues(alpha: 0.15),
                  border: colors.accentPurple.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
                const SizedBox(height: 16),
                Divider(color: colors.subCardBorder, height: 1),
                const SizedBox(height: 16),
                _buildInfoRow(language.t('about_author'),
                    'Jabil Vietnam - Automation & Tooling'),
                const SizedBox(height: 8),
                _buildInfoRow(language.t('about_runtime_mode'),
                    language.t('about_mutex_active')),
                const SizedBox(height: 8),
                _buildInfoRow(
                    language.t('about_os'),
                    theme.isWin11
                        ? 'Windows 11 (Mica / Acrylic DWM)'
                        : 'Windows 10 (Aero Glass DWM)'),
                const SizedBox(height: 8),
                _buildInfoRow(language.t('about_hardware'),
                    '${theme.perfLabel} (${theme.cpuCores} Cores Detected)'),
                const SizedBox(height: 8),
                _buildInfoRow(language.t('about_update_engine'),
                    language.t('about_ota_engine_desc')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            title,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
