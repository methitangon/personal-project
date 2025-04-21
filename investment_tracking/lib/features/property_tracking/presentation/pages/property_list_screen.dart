import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:investment_tracking/core/di/injection_container.dart';
import '../manager/property_list_notifier.dart';
import '../widgets/property_list_item.dart';

class PropertyListScreen extends StatelessWidget {
  const PropertyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PropertyListNotifier>(
      create: (_) => sl<PropertyListNotifier>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Property Rent Status'),
          actions: [
            Consumer<PropertyListNotifier>(
              builder: (context, notifier, child) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh List',
                  onPressed: notifier.isLoading
                      ? null
                      : () => notifier.fetchProperties(),
                );
              },
            ),
          ],
        ),
        body: Consumer<PropertyListNotifier>(
          builder: (context, notifier, child) {
            if (notifier.isLoading && notifier.properties.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (notifier.error != null && notifier.properties.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${notifier.error}\n\nPlease check calendar permissions and event names, then try refreshing.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            Widget errorWidget = const SizedBox.shrink();
            if (notifier.error != null && notifier.properties.isNotEmpty) {
              errorWidget = Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Error refreshing: ${notifier.error}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return Column(
              children: [
                errorWidget,
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => notifier.fetchProperties(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: notifier.properties.length,
                      itemBuilder: (context, index) {
                        final propertyInfo = notifier.properties[index];
                        return PropertyListItem(
                          propertyInfo: propertyInfo,
                          onMarkAsPaid: () => notifier
                              .markPropertyAsPaid(propertyInfo.property.id),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
