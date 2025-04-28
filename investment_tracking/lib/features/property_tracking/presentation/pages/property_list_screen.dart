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
      child: Builder(
        builder: (context) => Scaffold(
          appBar: _buildAppBar(context),
          body: _buildBody(context),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final notifier = context.read<PropertyListNotifier>();
    final isLoading = context.select((PropertyListNotifier n) => n.isLoading);

    return AppBar(
      title: const Text('Monthly Rental Events'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Events',
          onPressed: isLoading ? null : notifier.fetchEvents,
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Consumer<PropertyListNotifier>(
      builder: (context, notifier, child) {
        if (notifier.isLoading && notifier.rentalEvents.isEmpty) {
          return _buildLoading();
        }
        if (notifier.error != null && notifier.rentalEvents.isEmpty) {
          return _buildInitialError(notifier.error!);
        }
        if (!notifier.isLoading &&
            notifier.error == null &&
            notifier.rentalEvents.isEmpty) {
          return _buildEmpty(context);
        }
        return _buildContent(context, notifier);
      },
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildInitialError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Error: $error\n\nPlease check calendar permissions and event names, then try refreshing.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
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

  Widget _buildContent(BuildContext context, PropertyListNotifier notifier) {
    Widget refreshErrorWidget = const SizedBox.shrink();
    if (notifier.error != null && notifier.rentalEvents.isNotEmpty) {
      refreshErrorWidget = Padding(
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
        refreshErrorWidget,
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => notifier.fetchEvents(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifier.rentalEvents.length,
              itemBuilder: (context, index) {
                final rentalEvent = notifier.rentalEvents[index];
                return PropertyListItem(
                  rentalEvent: rentalEvent,
                  onMarkAsPaid: () async {
                    try {
                      await notifier.markEventPaid(rentalEvent);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${rentalEvent.propertyName} has been marked as paid.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        final errorMessage =
                            notifier.error ?? 'An unknown error occurred.';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed: $errorMessage'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
