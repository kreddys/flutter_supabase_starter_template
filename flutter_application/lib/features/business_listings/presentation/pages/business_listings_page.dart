import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cubit/business_listings_cubit.dart';
import '../cubit/business_listings_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amaravati_chamber/core/extensions/build_context_extensions.dart';
import 'package:amaravati_chamber/core/constants/spacings.dart';
import 'package:amaravati_chamber/core/widgets/tag_filter.dart';
import 'package:amaravati_chamber/core/widgets/content_card.dart';

class BusinessListingsPage extends StatelessWidget {
  const BusinessListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BusinessListingsCubit(Supabase.instance.client)
        ..loadBusinessListings(),
      child: const BusinessListingsView(),
    );
  }
}

class BusinessListingsView extends StatefulWidget {
  const BusinessListingsView({super.key});

  @override
  State<BusinessListingsView> createState() => _BusinessListingsViewState();
}

class _BusinessListingsViewState extends State<BusinessListingsView> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        context.read<BusinessListingsCubit>().searchBusinesses('');
      }
    });
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: _isSearching
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _toggleSearch,
            )
          : null,
      centerTitle: true,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search businesses...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              onChanged: (value) {
                context.read<BusinessListingsCubit>().searchBusinesses(value);
              },
            )
          : Text(
              'Business Directory',
              style: Theme.of(context).textTheme.titleMedium,
            ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            _isSearching ? Icons.clear : Icons.search,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: _isSearching
              ? () {
                  _searchController.clear();
                  context.read<BusinessListingsCubit>().searchBusinesses('');
                }
              : _toggleSearch,
        ),
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.add_business),
            onPressed: () {
              // TODO: Navigate to business registration form
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          if (!_isSearching) TagFilter(
            tags: const ['All', 'IT', 'Agriculture', 'Manufacturing', 'Services'],
            selectedTag: context.watch<BusinessListingsCubit>().state.selectedCategory ?? 'All',
            onTagSelected: (category) {
              context.read<BusinessListingsCubit>().filterByCategory(category);
            },
            padding: const EdgeInsets.symmetric(horizontal: Spacing.s8),
          ),
          if (!_isSearching) const SizedBox(height: 8.0),
          Expanded(
            child: BlocBuilder<BusinessListingsCubit, BusinessListingsState>(
              builder: (context, state) {
                switch (state.status) {
                  case BusinessListingsStatus.initial:
                  case BusinessListingsStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case BusinessListingsStatus.failure:
                    return Center(
                      child: Text(state.errorMessage ?? 'Something went wrong'),
                    );
                  case BusinessListingsStatus.success:
                    if (state.filteredBusinesses.isEmpty) {
                      return const Center(
                        child: Text('No businesses found'),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: state.filteredBusinesses.length,
                      itemBuilder: (context, index) {
                        final business = state.filteredBusinesses[index];
                        return BusinessCard(business: business);
                      },
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BusinessCard extends StatelessWidget {
  final Business business;

  const BusinessCard({required this.business, super.key});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: business.name,
      description: business.description,
      imageUrl: business.images.isNotEmpty ? business.images.first : null,
      date: DateTime.now(), // You might want to add a createdAt field to Business model
      tags: [], // Empty list to hide tags
      onTap: () {
        // TODO: Navigate to detailed business profile
      },
      footer: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (business.isVerified)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(
                Icons.verified,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () => launchUrl(Uri.parse('tel:${business.phone}')),
          ),
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () {
              // TODO: Show location on map
            },
          ),
        ],
      ),
    );
  }
}