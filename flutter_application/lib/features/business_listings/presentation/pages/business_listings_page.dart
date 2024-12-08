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

class BusinessListingsView extends StatelessWidget {
  const BusinessListingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Business Directory',
          style: context.textTheme.titleMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business),
            onPressed: () {
              // TODO: Navigate to business registration form
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(),
          TagFilter(
            tags: const ['All', 'IT', 'Agriculture', 'Manufacturing', 'Services'],
            selectedTag: context.watch<BusinessListingsCubit>().state.selectedCategory ?? 'All',
            onTagSelected: (category) {
              context.read<BusinessListingsCubit>().filterByCategory(category);
            },
            padding: const EdgeInsets.symmetric(horizontal: Spacing.s8),
          ),
          const SizedBox(height: 8.0),
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

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search businesses...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          context.read<BusinessListingsCubit>().searchBusinesses(value);
        },
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
      tags: [business.category],
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