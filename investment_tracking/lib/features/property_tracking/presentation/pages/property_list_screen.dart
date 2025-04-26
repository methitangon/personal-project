import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:investment_tracking/core/di/injection_container.dart';
import '../../domain/entities/rental_event.dart';
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
          title: const Text('Monthly Rental Events'),
          actions: [
            Consumer<PropertyListNotifier>(
              builder: (context, notifier, child) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Events',
                  onPressed:
                      notifier.isLoading ? null : () => notifier.fetchEvents(),
                );
              },
            ),
          ],
        ),
        body: Consumer<PropertyListNotifier>(
          builder: (context, notifier, child) {
            if (notifier.isLoading && notifier.rentalEvents.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (notifier.error != null && notifier.rentalEvents.isEmpty) {
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
            if (notifier.error != null && notifier.rentalEvents.isNotEmpty) {
              errorWidget = Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Error refreshing: ${notifier.error}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              );
            }

            if (!notifier.isLoading &&
                notifier.error == null &&
                notifier.rentalEvents.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No rental events (starting with 🏠) found for the current month.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              );
            }

            return Column(
              children: [
                errorWidget,
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => notifier.fetchEvents(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: notifier.rentalEvents.length,
                      itemBuilder: (context, index) {
                        final rentalEvent = notifier.rentalEvents[index];
                        return PropertyListItem(
                          propertyInfo: rentalEvent,
                          rentalEvent: rentalEvent,
                          onMarkAsPaid: () =>
                              notifier.markEventPaid(rentalEvent),
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
