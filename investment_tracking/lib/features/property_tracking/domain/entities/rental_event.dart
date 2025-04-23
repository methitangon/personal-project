import 'package:equatable/equatable.dart';
import 'package:timezone/timezone.dart';
import 'package:investment_tracking/features/property_tracking/domain/entities/payment_status.dart';

class RentalEvent extends Equatable {
  final String eventId;
  final String calendarId;
  final String title;
  final String propertyName;
  final TZDateTime? start;
  final TZDateTime? end;
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
