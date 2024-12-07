import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cubit/business_listings_cubit.dart';
import '../cubit/business_listings_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amaravati_chamber/core/extensions/build_context_extensions.dart';
import 'package:amaravati_chamber/core/constants/spacings.dart';

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
          _CategoryFilter(),
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
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search businesses...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(business.name[0]),
        ),
        title: Row(
          children: [
            Text(business.name),
            if (business.isVerified)
              const Icon(Icons.verified, color: Colors.blue, size: 16),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(business.category),
            Text(business.description),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
        onTap: () {
          // TODO: Navigate to detailed business profile
        },
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s8),
      child: Row(
        children: [
          _buildCategoryChip(context, 'All'),
          _buildCategoryChip(context, 'IT'),
          _buildCategoryChip(context, 'Agriculture'),
          _buildCategoryChip(context, 'Manufacturing'),
          _buildCategoryChip(context, 'Services'),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
      child: FilterChip(
        label: Text(category),
        selected: context.watch<BusinessListingsCubit>().state.selectedCategory == category,
        onSelected: (selected) {
          if (selected) {
            context.read<BusinessListingsCubit>().filterByCategory(category);
          }
        },
      ),
    );
  }
}