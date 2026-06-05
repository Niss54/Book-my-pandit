import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/pandit_repository_impl.dart';
import '../../di/service_locator.dart';
import '../../domain/repositories/pandit_repository.dart';
import '../providers/auth_provider.dart';
import '../../models/pandit_model.dart';
import '../widgets/main_scaffold.dart';

class PanditListingScreen extends StatefulWidget {
  final PanditRepository? panditRepository;

  const PanditListingScreen({super.key, this.panditRepository});

  @override
  State<PanditListingScreen> createState() => _PanditListingScreenState();
}

class _PanditListingScreenState extends State<PanditListingScreen> {
  late Future<List<PanditModel>> _panditsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Marriage',
    'Puja',
    'Astrology',
    'Vastu',
    'Griha Pravesh',
  ];

  @override
  void initState() {
    super.initState();
    final repository = widget.panditRepository ?? getIt<PanditRepository>();
    _panditsFuture = repository.getActivePandits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reloadPandits() async {
    final repository = widget.panditRepository ?? getIt<PanditRepository>();
    setState(() {
      _panditsFuture = repository.getActivePandits();
    });
    await _panditsFuture;
  }

  List<PanditModel> _filterPandits(List<PanditModel> pandits) {
    var filtered = pandits;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(query) ||
              p.expertise.toLowerCase().contains(query))
          .toList();
    }

    // Apply category
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((p) => p.expertise.toLowerCase().contains(_selectedCategory.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9F8),
        appBar: AppBar(
          title: const Text('Available Pandits', style: TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            // Search Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by name or expertise...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF8F4E00)),
                  filled: true,
                  fillColor: const Color(0xFFFAF9F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Category Filter Chips
            Container(
              color: Colors.white,
              height: 48,
              padding: const EdgeInsets.only(bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : 'All';
                        });
                      },
                      selectedColor: const Color(0xFF8F4E00),
                      backgroundColor: const Color(0xFFFFF6ED),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF8F4E00),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: BorderSide.none,
                    ),
                  );
                },
              ),
            ),

            // List
            Expanded(
              child: FutureBuilder<List<PanditModel>>(
                future: _panditsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF8F4E00)));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
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

                  final allPandits = snapshot.data ?? [];
                  final pandits = _filterPandits(allPandits);

                  if (pandits.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty || _selectedCategory != 'All'
                                ? 'No pandits match your search.'
                                : 'No pandits available currently.',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
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
                              onTap: () => context.push('/pandit_details', extra: pandit),
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
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
            ),
          ],
        ),
      ),
    );
  }
}
