import 'package:skyward/common/common.dart';
import 'package:material_ui/material_ui.dart';

import 'service_status.dart';

/// The services in one card: the grid says whether the outside world is
/// reachable, and tapping a service opens its list. The connection,
/// request and DNS counts used to sit underneath as links; they are
/// not on the dashboard any more, and those lists stay in the tools
/// pages, as with the rest of the dashboard subtraction.
class NetworkOverviewCard extends StatelessWidget {
  const NetworkOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ServiceStatusCard(
      title: context.appLocalizations.networkOverview,
    );
  }
}
