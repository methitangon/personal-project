import 'package:investment_tracking/features/property_tracking/domain/entities/payment_status.dart';
import 'package:equatable/equatable.dart';

class RentalEvent extends Equatable {
  final String eventId;
  final String calendarId;
  final String title;
  final String propertyName;
  final DateTime? start;
  final DateTime? end;
  final PaymentStatus status;

  const RentalEvent({
    required this.eventId,
    required this.calendarId,
    required this.title,
    required this.propertyName,
    required this.start,
    required this.end,
    required this.status,
  });

  @override
  List<Object?> get props =>
      [eventId, calendarId, title, propertyName, start, end, status];
}
