import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../core/theme/app_glass_tokens.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme_colors.dart';

/// Режим выбора в [ChipDropdown].
enum ChipDropdownMode {
  /// Один пункт, меню закрывается после выбора.
  single,

  /// Несколько пунктов, «Все» сбрасывает выбор.
  multi,
}

/// Пункт меню под чипом.
class ChipDropdownEntry {
  const ChipDropdownEntry({
    required this.id,
    required this.label,
    this.isReset = false,
  });

  final String id;
  final String label;
  final bool isReset;
}

/// Секция меню (опциональный заголовок).
class ChipDropdownSection {
  const ChipDropdownSection({
    required this.entries,
    this.title,
    this.searchable = false,
  });

  final String? title;
  final List<ChipDropdownEntry> entries;

  /// Участвует в фильтрации по строке поиска (если включён [searchPlaceholder]).
  final bool searchable;
}

/// Чип + выпадающее меню по тапу.
class ChipDropdown extends StatefulWidget {
  const ChipDropdown({
    super.key,
    required this.chipBuilder,
    required this.sections,
    required this.mode,
    this.selectedId,
    this.selectedIds = const {},
    this.onSingleSelected,
    this.onMultiChanged,
    this.menuWidth,
    this.maxMenuHeight = 360,
    this.closesOnSelect,
    this.searchPlaceholder,
  });

  final Widget Function(VoidCallback onToggle) chipBuilder;
  final List<ChipDropdownSection> sections;
  final ChipDropdownMode mode;
  final String? selectedId;
  final Set<String> selectedIds;
  final ValueChanged<ChipDropdownEntry>? onSingleSelected;
  final void Function(Set<String> selectedIds, ChipDropdownEntry entry)?
      onMultiChanged;
  final double? menuWidth;
  final double maxMenuHeight;
  final bool? closesOnSelect;

  /// Поиск вверху меню (например, города).
  final String? searchPlaceholder;

  bool get _closesOnSelect => closesOnSelect ?? mode == ChipDropdownMode.single;

  bool get _hasSearch => searchPlaceholder != null;

  @override
  State<ChipDropdown> createState() => _ChipDropdownState();
}

class _ChipDropdownState extends State<ChipDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  OverlayEntry? _entry;

  /// Актуальный мультиселект для overlay (не ждём rebuild родителя).
  Set<String> _multiSelectedIds = {};

  bool get _isOpen => _entry != null;

  // ignore: unused_element — заглушка для hot reload после удаления анимации.
  AnimationController? get _menuAnim => null;

  @override
  void initState() {
    super.initState();
    _multiSelectedIds = Set<String>.from(widget.selectedIds);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(ChipDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode == ChipDropdownMode.multi &&
        widget.selectedIds != oldWidget.selectedIds) {
      _multiSelectedIds = Set<String>.from(widget.selectedIds);
      _scheduleOverlayRebuild();
    }
  }

  void _scheduleOverlayRebuild() {
    if (_entry == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _entry != null) _entry!.markNeedsBuild();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _detachOverlay();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    _scheduleOverlayRebuild();
  }

  void _toggle() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _detachOverlay() {
    _entry?.remove();
    _entry = null;
  }

  /// Алиас для hot reload после переименования.
  void _removeOverlay() => _closeOverlay();

  void _closeOverlay() {
    _detachOverlay();
    if (mounted) setState(() {});
  }

  void _handleTap(ChipDropdownEntry entry) {
    if (widget.mode == ChipDropdownMode.single) {
      widget.onSingleSelected?.call(entry);
      if (widget._closesOnSelect) _removeOverlay();
      return;
    }

    final next = Set<String>.from(_multiSelectedIds);
    if (entry.isReset) {
      next.clear();
    } else if (next.contains(entry.id)) {
      next.remove(entry.id);
    } else {
      next.add(entry.id);
    }
    setState(() => _multiSelectedIds = next);
    widget.onMultiChanged?.call(next, entry);
    _scheduleOverlayRebuild();
  }

  bool _isSelected(ChipDropdownEntry entry) {
    if (widget.mode == ChipDropdownMode.single) {
      return entry.id == widget.selectedId;
    }
    if (entry.isReset) return _multiSelectedIds.isEmpty;
    return _multiSelectedIds.contains(entry.id);
  }

  void _showOverlay() {
    if (_isOpen) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isOpen) return;
      _insertOverlay();
    });
  }

  void _insertOverlay() {
    if (_isOpen) return;

    if (widget.mode == ChipDropdownMode.multi) {
      _multiSelectedIds = Set<String>.from(widget.selectedIds);
    }

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached || !renderBox.hasSize) {
      return;
    }

    _searchController.clear();
    if (widget._hasSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isOpen && mounted) _searchFocusNode.requestFocus();
      });
    }

    final chipOrigin = renderBox.localToGlobal(Offset.zero);
    final chipSize = renderBox.size;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final inset = AppSpacing.paddingGlobal;
    final menuWidth = widget.menuWidth ?? (screenWidth - inset * 2);
    final menuLeft = widget.menuWidth != null ? inset : chipOrigin.dx;
    final menuTop = chipOrigin.dy + chipSize.height + AppSpacing.s8;

    _entry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeOverlay,
                behavior: HitTestBehavior.opaque,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            Positioned(
              left: menuLeft,
              top: menuTop,
              width: menuWidth,
              child: Material(
                type: MaterialType.transparency,
                child: _GlassDropdownPanel(
                  child: _buildMenu(overlayContext, menuWidth),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_entry!);
    setState(() {});
  }

  Widget _buildMenu(BuildContext context, double menuWidth) {
    final query = _searchController.text.trim().toLowerCase();
    final children = <Widget>[
      if (widget._hasSearch)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s12,
            AppSpacing.s8,
            AppSpacing.s12,
            AppSpacing.s8,
          ),
          child: _DropdownSearchField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            placeholder: widget.searchPlaceholder!,
          ),
        ),
      for (var i = 0; i < widget.sections.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.s4),
        ..._sectionWidgets(context, widget.sections[i], query),
      ],
    ];

    return SizedBox(
      width: menuWidth,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxMenuHeight),
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.s8),
          shrinkWrap: true,
          children: children,
        ),
      ),
    );
  }

  List<ChipDropdownEntry> _entriesForSection(
    ChipDropdownSection section,
    String query,
  ) {
    if (!widget._hasSearch || !section.searchable || query.isEmpty) {
      return section.entries;
    }
    return section.entries
        .where((e) => e.label.toLowerCase().contains(query))
        .toList();
  }

  List<Widget> _sectionWidgets(
    BuildContext context,
    ChipDropdownSection section,
    String query,
  ) {
    final entries = _entriesForSection(section, query);
    if (entries.isEmpty) return const [];

    return [
      if (section.title != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s12,
            AppSpacing.s4,
            AppSpacing.s12,
            AppSpacing.s4,
          ),
          child: Text(
            section.title!,
            style: AppTextStyles.text13_400(
              color: AppGlassTokens.navInactiveIcon,
            ),
          ),
        ),
      for (final entry in entries)
        _MenuTile(
          key: ValueKey<String>(entry.id),
          entry: entry,
          selected: _isSelected(entry),
          onTap: () => _handleTap(entry),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return widget.chipBuilder(_toggle);
  }
}

class _DropdownSearchField extends StatelessWidget {
  const _DropdownSearchField({
    required this.controller,
    required this.focusNode,
    required this.placeholder,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;

  static const double _strokeWidth = 0.3;
  static const double _strokeOpacity = 0.12;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: AppRadius.br12,
      borderSide: BorderSide(
        color: AppGlassTokens.navInactiveIcon.withValues(alpha: _strokeOpacity),
        width: _strokeWidth,
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: AppTextStyles.text14_550(color: AppGlassTokens.chipText),
        cursorColor: AppGlassTokens.chipText,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: AppTextStyles.text14_550(
            color: AppGlassTokens.navInactiveIcon,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s12,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          isDense: true,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    super.key,
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final ChipDropdownEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  entry.label,
                  style: AppTextStyles.text18_600(
                    color: AppGlassTokens.chipText,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_rounded,
                  size: 22,
                  color: context.appColors.blue,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Меню чипа: тот же liquid glass, что nav / [GlassChipButton].
class _GlassDropdownPanel extends StatelessWidget {
  const _GlassDropdownPanel({required this.child});

  final Widget child;

  static const double _radius = AppRadius.r12;

  @override
  Widget build(BuildContext context) {
    final glass = LiquidGlass(
      shape: const LiquidRoundedSuperellipse(borderRadius: _radius),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    if (!AppGlassTokens.isLight(context)) {
      return glass;
    }

    return LiquidGlassLayer(
      settings: AppGlassTokens.navBarGlass,
      useBackdropGroup: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_radius),
                  boxShadow: AppGlassTokens.lightNavShadows,
                ),
              ),
            ),
          ),
          glass,
        ],
      ),
    );
  }
}
