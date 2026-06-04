import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../../models/booking_model.dart';
import '../widgets/main_scaffold.dart';

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  bool _hasFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasFetched) {
      _hasFetched = true;
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<BookingProvider>().fetchUserBookings(user.id);
      }
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year • $hour:$minute';
  }

  Color _statusColor(String status) {
    switch (status) {
      case BookingModel.statusConfirmed:
        return const Color(0xFF2E7D32);
      case BookingModel.statusPending:
        return const Color(0xFFE65100);
      case BookingModel.statusCompleted:
        return const Color(0xFF1565C0);
      case BookingModel.statusCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case BookingModel.statusConfirmed:
        return Icons.check_circle;
      case BookingModel.statusPending:
        return Icons.access_time;
      case BookingModel.statusCompleted:
        return Icons.done_all;
      case BookingModel.statusCancelled:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildBookingCard(BookingModel booking) {
    final color = _statusColor(booking.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_statusIcon(booking.status), color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pandit Booking',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(booking.date),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${booking.amount}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF8F4E00),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(List<BookingModel> bookings, String emptyMessage) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) => _buildBookingCard(bookings[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final allBookings = booking.userBookings ?? [];
    final now = DateTime.now();
    final upcoming = allBookings.where((b) =>
        b.date.isAfter(now) &&
        b.status != BookingModel.statusCancelled &&
        b.status != BookingModel.statusCompleted).toList();
    final past = allBookings.where((b) =>
        b.date.isBefore(now) ||
        b.status == BookingModel.statusCancelled ||
        b.status == BookingModel.statusCompleted).toList();

    return MainScaffold(
      currentIndex: 1,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xFFFAF9F8),
          appBar: AppBar(
            title: const Text(
              'My Bookings',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            bottom: const TabBar(
              labelColor: Color(0xFF8F4E00),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF8F4E00),
              tabs: [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
              ],
            ),
          ),
          body: booking.isLoadingBookings
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF8F4E00)))
              : TabBarView(
                  children: [
                    _buildBookingList(upcoming, 'No upcoming bookings.'),
                    _buildBookingList(past, 'No past bookings.'),
                  ],
                ),
        ),
      ),
    );
  }
}
