import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/app.dart';
import 'package:skyward/providers/traffic_statistics.dart';
import 'package:skyward/views/dashboard/widgets/app_usage_sheet.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets(
    'resolved apps use package icons; unidentified traffic does not',
    (tester) async {
      await tester.pumpWidget(
        TestApp(
          overrides: [
            packagesProvider.overrideWith(_InstalledPackages.new),
            appUsageProvider(AppUsagePeriod.today).overrideWith(
              (ref) async => const AppUsage(
                totalUpload: 30,
                totalDownload: 270,
                appCount: 3,
                apps: [
                  AppTraffic(
                    packageName: 'com.facebook.katana',
                    label: 'Facebook',
                    upload: 10,
                    download: 90,
                    percent: 1 / 3,
                  ),
                  AppTraffic(
                    packageName: '',
                    label: 'Unknown',
                    upload: 10,
                    download: 90,
                    percent: 1 / 3,
                  ),
                  AppTraffic(
                    packageName: 'mihomo',
                    label: 'mihomo',
                    upload: 10,
                    download: 90,
                    percent: 1 / 3,
                  ),
                ],
              ),
            ),
          ],
          child: const AppUsageSheet(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Facebook'), findsOneWidget);
      expect(find.byType(PackageIcon), findsOneWidget);
      expect(
        tester.widget<PackageIcon>(find.byType(PackageIcon)).packageName,
        'com.facebook.katana',
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _InstalledPackages extends Packages {
  @override
  List<Package> build() => const [
    Package(
      packageName: 'com.facebook.katana',
      label: 'Facebook',
      system: false,
      internet: true,
      lastUpdateTime: 0,
    ),
  ];
}
