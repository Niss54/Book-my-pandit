import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/pandit_repository_impl.dart';
import '../../domain/repositories/pandit_repository.dart';
import '../providers/auth_provider.dart';
import '../../models/pandit_model.dart';

class PanditListingScreen extends StatefulWidget {
  final PanditRepository? panditRepository;

  const PanditListingScreen({super.key, this.panditRepository});

  @override
  State<PanditListingScreen> createState() => _PanditListingScreenState();
}

class _PanditListingScreenState extends State<PanditListingScreen> {
  late Future<List<PanditModel>> _panditsFuture;

  @override
  void initState() {
    super.initState();
    final repository = widget.panditRepository ?? PanditRepositoryImpl();
    _panditsFuture = repository.getActivePandits();
  }

  Future<void> _reloadPandits() async {
    final repository = widget.panditRepository ?? PanditRepositoryImpl();
    setState(() {
      _panditsFuture = repository.getActivePandits();
    });
    await _panditsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8),
      appBar: AppBar(
        title: const Text('Available Pandits', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () {
               context.read<AuthProvider>().signOut();
               context.go('/');
            },
          )
        ],
      ),
      body: FutureBuilder<List<PanditModel>>(
        future: _panditsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to load pandits right now.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _reloadPandits,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final pandits = snapshot.data ?? [];
          if (pandits.isEmpty) {
            return const Center(
              child: Text('No pandits available currently.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _reloadPandits,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pandits.length,
              itemBuilder: (context, index) {
                final pandit = pandits[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8F4E00).withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.push('/checkout', extra: pandit),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: const Color(0xFFFFF6ED),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: pandit.imageUrl.isEmpty
                                    ? const Icon(Icons.person, color: Color(0xFF8F4E00))
                                    : Image.network(
                                        pandit.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, _, __) => const Icon(
                                          Icons.person,
                                          color: Color(0xFF8F4E00),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pandit.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pandit.expertise,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        pandit.rating.toStringAsFixed(1),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '₹${pandit.basePrice}',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: const Color(0xFF8F4E00),
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
