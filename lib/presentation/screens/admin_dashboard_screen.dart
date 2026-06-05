import 'package:flutter/material.dart';
import '../../di/service_locator.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../models/booking_model.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<List<BookingModel>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    _bookingsFuture = getIt<BookingRepository>().getAllBookings();
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy • HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: FutureBuilder<List<BookingModel>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }

          return ListView.builder(
            itemCount: bookings.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Booking ID: ${booking.id.substring(0, 8)}...', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: booking.status == 'cancelled' ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(booking.status.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Amount: ₹${booking.amount}'),
                      Text('Date: ${_formatDate(booking.date)}'),
                      Text('User ID: ${booking.userId}'),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (booking.status != 'refunded' && booking.status != 'cancelled')
                             ElevatedButton(
                               onPressed: () {
                                 // Call edge function to process refund in future
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   const SnackBar(content: Text('Refund initiation would happen here.'))
                                 );
                               },
                               style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                               child: const Text('Initiate Refund', style: TextStyle(color: Colors.white)),
                             ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
