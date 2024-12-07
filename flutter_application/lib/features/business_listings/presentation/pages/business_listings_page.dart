import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amaravati_chamber/core/constants/spacings.dart';
import 'package:amaravati_chamber/core/extensions/build_context_extensions.dart';
import 'package:amaravati_chamber/features/business_listings/presentation/cubit/business_listings_cubit.dart';
import 'package:amaravati_chamber/features/business_listings/presentation/cubit/business_listings_state.dart';

class BusinessListingsPage extends StatelessWidget {
  const BusinessListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BusinessListingsCubit()..loadBusinessListings(),
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
          'Business Listings',
          style: context.textTheme.titleMedium,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocBuilder<BusinessListingsCubit, BusinessListingsState>(
          builder: (context, state) {
            switch (state.status) {
              case BusinessListingsStatus.initial:
              case BusinessListingsStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case BusinessListingsStatus.failure:
                return Center(
                  child: Text(
                    state.errorMessage ?? 'Something went wrong',
                    style: context.textTheme.bodyLarge,
                  ),
                );
              case BusinessListingsStatus.success:
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.s16),
                    child: Center(
                      child: Text(
                        'Business Listings Coming Soon!',
                        style: context.textTheme.headlineSmall,
                      ),
                    ),
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}