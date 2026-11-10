import 'package:skyward/common/common.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/page_large_title.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

/// Standalone privacy policy page, reachable from the About page.
/// Required for app store listings (e.g. Google Play).
class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  static const _maxContentWidth = 720.0;
  static const _mobileGutter = 16.0;
  static const _desktopGutter = 24.0;
  static const _desktopTopPadding = 48.0;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    // The five tabs keep their heading fixed in the page; this detail page
    // does the same on a phone instead of falling back to a plain Material
    // AppBar that looks unlike the rest of the app.
    final largeTitle =
        ViewScope.isMobileOf(context) && !context.isInCompactSheet;
    final statusBarTop = MediaQuery.paddingOf(context).top;
    final isMobile = context.isMobileView;
    final gutter = isMobile ? _mobileGutter : _desktopGutter;
    final vertical = isMobile ? 16.0 : _desktopTopPadding;
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            gutter,
            largeTitle ? 0 : vertical,
            gutter,
            vertical,
          ),
          children: [
            _PolicySection(
              title: appLocalizations.privacyPolicyDataCollectionTitle,
              content: appLocalizations.privacyPolicyDataCollectionContent,
            ),
            _PolicySection(
              title: appLocalizations.privacyPolicyDataUseTitle,
              content: appLocalizations.privacyPolicyDataUseContent,
            ),
            _PolicySection(
              title: appLocalizations.privacyPolicyDataSharingTitle,
              content: appLocalizations.privacyPolicyDataSharingContent,
            ),
            _PolicySection(
              title: appLocalizations.privacyPolicyDataSecurityTitle,
              content: appLocalizations.privacyPolicyDataSecurityContent,
            ),
            _PolicySection(
              title: appLocalizations.privacyPolicyDataRetentionTitle,
              content: appLocalizations.privacyPolicyDataRetentionContent,
            ),
            _PolicySection(
              title: appLocalizations.privacyPolicyContactTitle,
              content: appLocalizations.privacyPolicyContactContent,
            ),
          ],
        ),
      ),
    );
    return CommonScaffold(
      title: appLocalizations.privacyPolicy,
      largeTitle: largeTitle,
      body: largeTitle
          ? PageLargeTitle(
              title: appLocalizations.privacyPolicy,
              statusBarTop: statusBarTop,
              body: body,
            )
          : body,
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;

  const _PolicySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyle.headline.of(context)),
          const SizedBox(height: 8),
          Text(content, style: AppTextStyle.subheadline.of(context)),
        ],
      ),
    );
  }
}
