import 'dart:async';
import 'dart:math';

import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/config.dart';
import 'package:skyward/providers/state.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/font_family.dart';
import 'package:skyward/views/theme_preview.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeColorItem extends ConsumerWidget {
  const ThemeColorItem({super.key});

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    int color,
  ) async {
    final appLocalizations = context.appLocalizations;
    final res = await dialogs.showMessage(
      message: TextSpan(
        text: appLocalizations.deleteTip(appLocalizations.color),
      ),
      destructive: true,
      confirmText: appLocalizations.delete,
    );
    if (res != true || !context.mounted) {
      return;
    }
    ref.read(themeSettingProvider.notifier).update((state) {
      final primaryColors = List<int>.from(state.primaryColors)..remove(color);
      var primaryColor = state.primaryColor;
      if (primaryColor == color) {
        primaryColor = primaryColors.contains(defaultPrimaryColor)
            ? defaultPrimaryColor
            : null;
      }
      return state.copyWith(
        primaryColors: primaryColors,
        primaryColor: primaryColor,
      );
    });
  }

  void _showColorSheet(
    BuildContext context,
    Color initialColor,
    ValueChanged<int> onConfirmed,
  ) {
    showSheet<void>(
      context: context,
      props: const SheetProps(detents: [0.9]),
      builder: (_) => _CustomColorSheet(
        initialColor: initialColor,
        onConfirmed: (color) {
          if (context.mounted) {
            onConfirmed(color);
          }
        },
      ),
    );
  }

  void _handleAdd(BuildContext context, WidgetRef ref) {
    final primaryColor = ref.read(themeSettingProvider).primaryColor;
    _showColorSheet(
      context,
      primaryColor != null
          ? Color(primaryColor)
          : ref.read(dynamicColorProvider).accentColor,
      (color) => _update(
        ref,
        (state) => state.copyWith(
          primaryColors: state.primaryColors.contains(color)
              ? state.primaryColors
              : [...state.primaryColors, color],
          primaryColor: color,
        ),
      ),
    );
  }

  void _handleEdit(BuildContext context, WidgetRef ref, int color) {
    _showColorSheet(
      context,
      Color(color),
      (edited) => _update(ref, (state) {
        final index = state.primaryColors.indexOf(color);
        if (edited == color || index == -1) {
          return state;
        }
        final primaryColors = List<int>.from(state.primaryColors);
        if (primaryColors.contains(edited)) {
          primaryColors.removeAt(index);
        } else {
          primaryColors[index] = edited;
        }
        return state.copyWith(
          primaryColors: primaryColors,
          primaryColor: state.primaryColor == color
              ? edited
              : state.primaryColor,
        );
      }),
    );
  }

  void _update(WidgetRef ref, ThemeProps Function(ThemeProps state) update) {
    ref.read(themeSettingProvider.notifier).update(update);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(
      themeSettingProvider.select(
        (state) => ThemeColorsSelectorState(
          primaryColor: state.primaryColor,
          primaryColors: state.primaryColors,
          colorStyle: state.colorStyle,
          isDefault:
              state.primaryColor == defaultPrimaryColor &&
              intListEquality.equals(
                state.primaryColors,
                defaultPrimaryColors,
              ) &&
              state.colorStyle == ColorStyle.vivid,
        ),
      ),
    );
    return _ColorSwatches(
      colors: [null, ...themeColors.primaryColors],
      selected: themeColors.primaryColor,
      onSelect: (color) =>
          _update(ref, (state) => state.copyWith(primaryColor: color)),
      onEdit: (color) => _handleEdit(context, ref, color),
      onDelete: (color) => _handleDelete(context, ref, color),
      onAdd: () => _handleAdd(context, ref),
    );
  }
}

/// Whether the colors on screen are still the shipped ones, so the page can
/// offer a reset only when there is something to reset.
bool themeColorsAreDefault(ThemeProps state) =>
    state.primaryColor == defaultPrimaryColor &&
    intListEquality.equals(state.primaryColors, defaultPrimaryColors) &&
    state.colorStyle == ColorStyle.vivid;

class ColorStyleItem extends ConsumerWidget {
  const ColorStyleItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(
      themeSettingProvider.select((state) => state.colorStyle),
    );
    return ListItem<ColorStyle>.options(
      leading: const IconWell(AppGlyphs.palette),
      title: Text(context.appLocalizations.colorStyle),
      options: ColorStyle.values,
      value: style,
      textBuilder: (style) => style.label,
      onChanged: (style) => ref
          .read(themeSettingProvider.notifier)
          .update((state) => state.copyWith(colorStyle: style)),
    );
  }
}

class _ColorSwatches extends ConsumerWidget {
  const _ColorSwatches({
    required this.colors,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  static const double _minGap = 6;

  // Lines the dots, not their selection rings, up with the rows' text.
  static const double _inset = 16 - (_ColorSwatch.size - _ColorSwatch.dot) / 2;

  final List<int?> colors;
  final int? selected;
  final ValueChanged<int?> onSelect;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final level = context.raisedSurfaceLevel;
    final systemColor = ref
        .watch(dynamicColorProvider)
        .seedOf(Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.all(_inset),
      decoration: ShapeDecoration(
        color: level.colorOf(colorScheme),
        shape: AppShape.xl,
      ),
      child: SurfaceScope(
        level: level,
        child: LayoutBuilder(
          builder: (_, constraints) {
            const cell = _ColorSwatch.size;
            final width = constraints.maxWidth;
            final columns = max(
              1,
              ((width + _minGap) / (cell + _minGap)).floor(),
            );
            final gap = columns > 1
                ? ((width - columns * cell) / (columns - 1)).floorToDouble()
                : 0.0;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final color in colors)
                  _ColorSwatch(
                    color: color == null ? null : Color(color),
                    systemColor: systemColor,
                    isSelected: color == selected,
                    label: color == null
                        ? appLocalizations.followSystem
                        : Color(color).hex,
                    onPressed: () => onSelect(color),
                    menuItems: color == null
                        ? null
                        : [
                            CommonPopupMenuItem(
                              glyph: AppGlyphs.edit,
                              label: appLocalizations.edit,
                              onPressed: () => onEdit(color),
                            ),
                            CommonPopupMenuItem(
                              danger: true,
                              glyph: AppGlyphs.delete,
                              label: appLocalizations.delete,
                              onPressed: () => onDelete(color),
                            ),
                          ],
                  ),
                _AddColorButton(onPressed: onAdd),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatefulWidget {
  const _ColorSwatch({
    required this.color,
    required this.systemColor,
    required this.isSelected,
    required this.label,
    required this.onPressed,
    this.menuItems,
  });

  static const double size = 44;
  static const double dot = 32;
  static const double _ring = 2.5;
  static const _duration = Duration(milliseconds: 200);

  static const double _badge = 20;

  /// Null follows the system's accent color, [systemColor].
  final Color? color;
  final Color systemColor;
  final bool isSelected;
  final String label;
  final VoidCallback onPressed;
  final List<CommonPopupMenuItem>? menuItems;

  @override
  State<_ColorSwatch> createState() => _ColorSwatchState();
}

class _ColorSwatchState extends State<_ColorSwatch> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final fill = color ?? widget.systemColor;
    final selected = widget.isSelected;
    final check = ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final swatch = Semantics(
      button: true,
      selected: selected,
      label: widget.label,
      child: SizedBox.square(
        dimension: _ColorSwatch.size,
        child: Material(
          type: MaterialType.transparency,
          shape: AppShape.circle,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: AppShape.circle,
            onTap: widget.onPressed,
            onFocusChange: (value) => setState(() => _focused = value),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  opacity: selected || _focused ? 1 : 0,
                  duration: _ColorSwatch._duration,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: AppShape.circle.copyWith(
                        side: BorderSide(
                          color: selected ? fill : context.colorScheme.primary,
                          width: _ColorSwatch._ring,
                        ),
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                SizedBox.square(
                  dimension: _ColorSwatch.dot,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: fill,
                      shape: AppShape.circle,
                    ),
                  ),
                ),
                if (color == null)
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: _EyedropperBadge(size: _ColorSwatch._badge),
                  ),
                AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: _ColorSwatch._duration,
                  curve: Curves.easeOutBack,
                  child: GlyphIcon(
                    AppGlyphs.check,
                    size: 18,
                    fill: 1,
                    color: check,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final menuItems = widget.menuItems;
    if (menuItems == null) {
      return swatch;
    }
    return ContextMenuRegion(menuItems: menuItems, child: swatch);
  }
}

class _EyedropperBadge extends StatelessWidget {
  const _EyedropperBadge({required this.size});

  static const double _gap = 2;

  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(_gap),
      decoration: ShapeDecoration(
        color: context.surfaceLevel.colorOf(colorScheme),
        shape: AppShape.circle,
      ),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: context.raisedSurfaceLevel.colorOf(colorScheme),
          shape: AppShape.circle,
        ),
        child: Center(
          child: GlyphIcon(
            AppGlyphs.eyedropper,
            size: size - _gap * 2 - 4,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _AddColorButton extends StatelessWidget {
  const _AddColorButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Tooltip(
      message: context.appLocalizations.add,
      child: Semantics(
        button: true,
        child: SizedBox.square(
          dimension: _ColorSwatch.size,
          child: Material(
            type: MaterialType.transparency,
            shape: AppShape.circle,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: AppShape.circle,
              onTap: onPressed,
              child: Center(
                child: Container(
                  width: _ColorSwatch.dot,
                  height: _ColorSwatch.dot,
                  decoration: ShapeDecoration(
                    color: context.raisedSurfaceLevel.colorOf(colorScheme),
                    shape: AppShape.circle,
                  ),
                  child: GlyphIcon(
                    AppGlyphs.add,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FontFamilyRow extends ConsumerWidget {
  const FontFamilyRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final fontFamily = ref.watch(
      themeSettingProvider.select((state) => state.fontFamily),
    );
    return ListItem(
      leading: const IconWell(AppGlyphs.font),
      title: Text(appLocalizations.fontFamily),
      subtitle: Text(
        fontFamily ?? appLocalizations.defaultText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle.subheadline
            .of(context)
            .copyWith(fontFamily: fontFamily),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Text(
            'Aa',
            style: AppTextStyle.headline
                .of(context)
                .copyWith(fontFamily: fontFamily),
          ),
          GlyphIcon(
            AppGlyphs.chevronForward,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
      onTap: () => showExtend(context, builder: (_) => const FontFamilyView()),
    );
  }
}

final _floatingBarProvider = appSettingProvider.select(
  (state) => state.navigationBarStyle != NavigationBarStyle.docked,
);

final _capsuleBarProvider = appSettingProvider.select(
  (state) => state.navigationBarStyle == NavigationBarStyle.capsule,
);

final _liquidGlassProvider = themeSettingProvider.select(
  (state) => state.liquidGlass != LiquidGlassMode.none,
);

class _CustomColorSheet extends StatefulWidget {
  const _CustomColorSheet({
    required this.initialColor,
    required this.onConfirmed,
  });

  final Color initialColor;

  /// Runs once the sheet has closed, so retheming every page cannot stall it.
  final ValueChanged<int> onConfirmed;

  @override
  State<_CustomColorSheet> createState() => _CustomColorSheetState();
}

class _CustomColorSheetState extends State<_CustomColorSheet> {
  late final _controller = ValueNotifier<Color>(widget.initialColor);

  void _confirm() {
    final color = _controller.value.toARGB32();
    final onConfirmed = widget.onConfirmed;
    unawaited(
      ModalRoute.of(context)!.completed.whenComplete(() => onConfirmed(color)),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    // Clears Android's edge back-swipe zone; exclusion rects stop at 200 dp.
    final gestureInsets = MediaQuery.systemGestureInsetsOf(context);
    return CommonScaffold(
      title: appLocalizations.customColor,
      confirmationAction: IconButtonData(
        glyph: AppGlyphs.check,
        tooltip: appLocalizations.confirm,
        onPressed: _confirm,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          max(16, gestureInsets.left),
          context.contentTopPadding,
          max(16, gestureInsets.right),
          20 + context.bottomInset,
        ),
        children: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (_, color, _) => _CustomColorPreview(
              color: color,
              onChanged: (color) => _controller.value = color,
            ),
          ),
          const SizedBox(height: 16),
          Palette(controller: _controller),
        ],
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TonalButtonTheme(
      size: TonalButtonSize.section,
      child: ElasticPress(
        child: IconButton(
          tooltip: context.appLocalizations.reset,
          onPressed: onPressed,
          icon: const GlyphIcon(AppGlyphs.reset),
        ),
      ),
    );
  }
}

class _CustomColorPreview extends ConsumerWidget {
  const _CustomColorPreview({required this.color, required this.onChanged});

  static const Size _screenSize = Size(96, 128);
  static const double _scale = 0.75;

  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final floatingBar = ref.watch(_floatingBarProvider);
    final capsuleBar = ref.watch(_capsuleBarProvider);
    final liquidGlass = ref.watch(_liquidGlassProvider);
    final level = context.raisedSurfaceLevel;
    Widget screen(Brightness brightness) => ExcludeSemantics(
      child: SizedBox.fromSize(
        size: _screenSize * _scale,
        child: ClipRSuperellipse(
          borderRadius: AppRadius.md,
          child: FittedBox(
            child: SizedBox.fromSize(
              size: _screenSize,
              child: MiniScreen(
                colorScheme: ref.watch(
                  genColorSchemeProvider(brightness, color: color),
                ),
                floatingBar: floatingBar,
                capsule: capsuleBar,
                liquidGlass: liquidGlass,
              ),
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: level.colorOf(context.colorScheme),
        shape: AppShape.xl,
      ),
      child: SurfaceScope(
        level: level,
        child: Row(
          spacing: 12,
          children: [
            screen(Brightness.light),
            screen(Brightness.dark),
            Expanded(
              child: HexColorField(color: color, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }
}

class TextScaleCard extends ConsumerStatefulWidget {
  const TextScaleCard({super.key});

  static const _step = 0.05;

  @override
  ConsumerState<TextScaleCard> createState() => _TextScaleCardState();
}

class _TextScaleCardState extends ConsumerState<TextScaleCard> {
  double? _draft;

  void _update(TextScale Function(TextScale textScale) update) {
    setState(() => _draft = null);
    ref
        .read(themeSettingProvider.notifier)
        .update((state) => state.copyWith(textScale: update(state.textScale)));
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final textScale = ref.watch(
      themeSettingProvider.select((state) => state.textScale),
    );
    final systemScale = systemTextScaleOf(
      context,
    ).clamp(minTextScale, maxTextScale).toDouble();
    final scale = _draft ?? (textScale.enable ? textScale.scale : systemScale);
    final percent = '${(scale * 100).round()}%';
    final level = context.raisedSurfaceLevel;
    final divisions = ((maxTextScale - minTextScale) / TextScaleCard._step)
        .round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            spacing: 8,
            children: [
              SegmentedControl<bool>(
                segments: [
                  (false, appLocalizations.followSystem),
                  (true, appLocalizations.custom),
                ],
                value: textScale.enable,
                onChanged: (value) =>
                    _update((state) => state.copyWith(enable: value)),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: ShapeDecoration(
                  color: level.colorOf(colorScheme),
                  shape: AppShape.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        Expanded(
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topLeft,
                            child: MediaQuery(
                              data: MediaQuery.of(
                                context,
                              ).copyWith(textScaler: TextScaler.linear(scale)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 4,
                                children: [
                                  Text(
                                    'Aa',
                                    style: AppTextStyle.title3.of(context),
                                  ),
                                  Text(
                                    appLocalizations.textScalePreview,
                                    style: AppTextStyle.subheadline
                                        .of(context)
                                        .copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: ShapeDecoration(
                            color: level.next.colorOf(colorScheme),
                            shape: AppShape.full,
                          ),
                          child: Text(
                            percent,
                            style: AppTextStyle.subheadline
                                .of(context, emphasized: true)
                                .copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    MediaQuery.withNoTextScaling(
                      child: Row(
                        spacing: 12,
                        children: [
                          ExcludeSemantics(
                            child: Text(
                              'A',
                              style: AppTextStyle.footnote
                                  .of(context)
                                  .copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderDefaultsM3(context),
                              child: Slider(
                                key: const ValueKey('textScaleSlider'),
                                padding: EdgeInsets.zero,
                                min: minTextScale,
                                max: maxTextScale,
                                divisions: divisions,
                                value: scale,
                                label: percent,
                                onChanged: textScale.enable
                                    ? (value) => setState(() => _draft = value)
                                    : null,
                                onChangeEnd: (value) => _update(
                                  (state) => state.copyWith(scale: value),
                                ),
                              ),
                            ),
                          ),
                          ExcludeSemantics(
                            child: Text(
                              'A',
                              style: AppTextStyle.title2
                                  .of(context)
                                  .copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          if (textScale.enable && textScale.scale != 1)
                            _ResetButton(
                              onPressed: () =>
                                  _update((state) => state.copyWith(scale: 1)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
