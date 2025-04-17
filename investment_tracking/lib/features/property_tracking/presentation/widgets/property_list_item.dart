import 'package:flutter/material.dart';
import '../../domain/entities/payment_status.dart';
import '../../domain/usecases/get_properties_with_status.dart';

class PropertyListItem extends StatelessWidget {
  final PropertyStatusInfo propertyInfo;

  final VoidCallback onMarkAsPaid;

  const PropertyListItem({
    super.key,
    required this.propertyInfo,
    required this.onMarkAsPaid,
  });

  @override
  Widget build(BuildContext context) {
    Icon statusIcon;
    Color statusColor;
    String statusText;

    switch (propertyInfo.status) {
      case PaymentStatus.paid:
        statusIcon =
            const Icon(Icons.check_circle, color: Colors.green, size: 28);
        statusColor = Colors.green;
        statusText = "Paid";
        break;
      case PaymentStatus.pending:
        statusIcon =
            const Icon(Icons.hourglass_empty, color: Colors.orange, size: 28);
        statusColor = Colors.orange;
        statusText = "Pending";
        break;
      case PaymentStatus.unknown:
      default:
        statusIcon =
            const Icon(Icons.help_outline, color: Colors.grey, size: 28);
        statusColor = Colors.grey;
        statusText = "Unknown";
        break;
    }

    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: statusIcon,
      ),
      title: Text(
        propertyInfo.property.name,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: propertyInfo.status == PaymentStatus.pending
          ? IconButton(
              icon: const Icon(Icons.price_check),
              tooltip: 'Mark as Paid',
              color: Theme.of(context).colorScheme.primary,
              onPressed: onMarkAsPaid,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 16.0,
      ),
    );
  }
}
