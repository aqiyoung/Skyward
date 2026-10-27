import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:material_ui/material_ui.dart';

import 'form_row.dart';

extension CustomIssueExt on CustomIssue {
  String getMessage(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return switch (this) {
      EmptyNameIssue() => appLocalizations.customIssueEmptyName,
      ReservedNameIssue(:final name) =>
        appLocalizations.customIssueReservedName(name),
      DuplicateNameIssue(:final name) =>
        appLocalizations.customIssueDuplicateName(name),
      CoreRejectedIssue(:final message) =>
        appLocalizations.customIssueCoreRejected(message),
      MissingProxiesIssue(:final names) =>
        appLocalizations.customIssueMissingProxies(names.join(', ')),
      MissingProvidersIssue(:final names) =>
        appLocalizations.customIssueMissingProviders(names.join(', ')),
      NoProxySourceIssue() => appLocalizations.customIssueNoProxySource,
      GroupLoopIssue(:final names) => appLocalizations.customIssueGroupLoop(
        names.join(' › '),
      ),
      InvalidEmptyFallbackIssue(:final name) =>
        appLocalizations.customIssueInvalidEmptyFallback(name),
      InvalidFilterIssue(:final name, :final message) =>
        appLocalizations.customIssueInvalidFilter(name, message),
      InvalidPayloadIssue(:final error) => error.getMessage(context),
      MissingRuleSetIssue(:final name) => appLocalizations.invalidRuleSet(name),
      MissingSubRuleIssue(:final name) => appLocalizations.invalidSubRule(name),
      MissingTargetIssue(:final name) => appLocalizations.invalidPolicy(name),
      MissingDialerIssue(:final name) =>
        appLocalizations.customIssueMissingDialer(name),
      DialerLoopIssue(:final proxy, :final target) =>
        appLocalizations.customIssueDialerLoop(proxy, target),
    };
  }

  /// A new form has these only because it is not filled in yet, so it holds
  /// them back until the first save rather than opening already in error.
  bool get isIncomplete => switch (this) {
    EmptyNameIssue() || NoProxySourceIssue() || CoreRejectedIssue() => true,
    _ => false,
  };
}

extension CustomIssuesExt on Iterable<CustomIssue> {
  String getMessage(BuildContext context) {
    if (length == 1) {
      return first.getMessage(context);
    }
    return map((issue) => '• ${issue.getMessage(context)}').join('\n');
  }
}

Future<void> showSaveBlocked(BuildContext context, String reason) {
  return dialogs.showAlert(
    title: context.appLocalizations.cannotSave,
    message: TextSpan(text: reason),
  );
}

class CustomIssueButton extends StatelessWidget {
  final List<CustomIssue> issues;

  const CustomIssueButton({super.key, required this.issues});

  @override
  Widget build(BuildContext context) {
    return InfoMessageButton(message: issues.getMessage(context));
  }
}

class CustomIssuesBanner extends StatelessWidget {
  final List<CustomIssue> issues;

  const CustomIssuesBanner({super.key, required this.issues});

  @override
  Widget build(BuildContext context) {
    return ErrorBanner(
      message: issues.isEmpty ? null : issues.getMessage(context),
    );
  }
}

class SliverCustomIssuesBanner extends StatelessWidget {
  final List<CustomIssue> issues;

  const SliverCustomIssuesBanner({super.key, required this.issues});

  @override
  Widget build(BuildContext context) {
    return PinnedHeaderSliver(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, context.contentTopPadding, 16, 0),
        child: CustomIssuesBanner(issues: issues),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  final String? message;

  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final message = this.message;
    return AnimatedSize(
      duration: commonDuration,
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : _Banner(
              glyph: AppGlyphs.error,
              message: message,
              color: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
            ),
    );
  }
}

/// A line about something that is neither broken nor at risk: a value the
/// profile already carries that the entries below replace. Left in the page's
/// own surfaces, since colour belongs to what fails or what is selected.
class NoteBanner extends StatelessWidget {
  final String? message;

  const NoteBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final message = this.message;
    return AnimatedSize(
      duration: commonDuration,
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : _Banner(
              glyph: AppGlyphs.info,
              message: message,
              color: context.raisedSurfaceLevel.colorOf(colorScheme),
              foregroundColor: colorScheme.onSurface,
              glyphColor: colorScheme.onSurfaceVariant,
            ),
    );
  }
}

class _Banner extends StatelessWidget {
  final Glyph glyph;
  final String message;
  final Color color;
  final Color foregroundColor;
  final Color? glyphColor;

  const _Banner({
    required this.glyph,
    required this.message,
    required this.color,
    required this.foregroundColor,
    this.glyphColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(color: color, shape: AppShape.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          GlyphIcon(
            glyph,
            size: 20.ap(context),
            color: glyphColor ?? foregroundColor,
          ),
          Expanded(
            child: Text(
              message,
              style: AppTextStyle.subheadline
                  .of(context)
                  .copyWith(color: foregroundColor),
            ),
          ),
        ],
      ),
    );
  }
}
