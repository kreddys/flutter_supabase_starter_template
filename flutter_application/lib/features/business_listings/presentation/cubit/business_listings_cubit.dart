import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/monitoring/sentry_monitoring.dart';
import 'business_listings_state.dart';

class BusinessListingsCubit extends Cubit<BusinessListingsState> {
  final SupabaseClient _supabaseClient;

  BusinessListingsCubit(this._supabaseClient) : super(const BusinessListingsState());

  Future<void> loadBusinessListings() async {
    try {
      AppLogger.info('Loading business listings');
      emit(state.copyWith(status: BusinessListingsStatus.loading));
      
      final response = await _supabaseClient
          .from('businesses')
          .select()
          .order('name');

      final businesses = (response as List)
          .map((business) => Business.fromJson(business))
          .toList();

      AppLogger.info('Successfully loaded ${businesses.length} businesses');
      await SentryMonitoring.addBreadcrumb(
        message: 'Businesses loaded successfully',
        data: {'count': businesses.length},
      );

      emit(state.copyWith(
        status: BusinessListingsStatus.success,
        businesses: businesses,
        filteredBusinesses: businesses,
      ));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load business listings',
        error: e,
        stackTrace: stackTrace,
      );
      await SentryMonitoring.captureException(e, stackTrace);
      
      emit(
        state.copyWith(
          status: BusinessListingsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> createBusiness(Business business) async {
    try {
      AppLogger.info('Creating new business', error: business.name);
      await SentryMonitoring.addBreadcrumb(
        message: 'Creating new business',
        data: {'businessName': business.name},
      );
      
      emit(state.copyWith(status: BusinessListingsStatus.loading));
      
      await _supabaseClient
          .from('businesses')
          .insert(business.toJson());

      await loadBusinessListings();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to create business',
        error: e,
        stackTrace: stackTrace,
      );
      await SentryMonitoring.captureException(
        e, 
        stackTrace,
        tagValue: 'create_business_error',
      );
      
      emit(state.copyWith(
        status: BusinessListingsStatus.failure,
        errorMessage: 'Failed to create business: ${e.toString()}',
      ));
    }
  }

  Future<void> updateBusiness(Business business) async {
    try {
      AppLogger.info('Updating business', error: business.id);
      await SentryMonitoring.addBreadcrumb(
        message: 'Updating business',
        data: {'businessId': business.id},
      );
      
      emit(state.copyWith(status: BusinessListingsStatus.loading));
      
      await _supabaseClient
          .from('businesses')
          .update(business.toJson())
          .eq('id', business.id);

      await loadBusinessListings();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to update business',
        error: e,
        stackTrace: stackTrace,
      );
      await SentryMonitoring.captureException(
        e, 
        stackTrace,
        tagValue: 'update_business_error',
      );
      
      emit(state.copyWith(
        status: BusinessListingsStatus.failure,
        errorMessage: 'Failed to update business: ${e.toString()}',
      ));
    }
  }

  Future<void> deleteBusiness(String businessId) async {
    try {
      AppLogger.info('Deleting business', error: businessId);
      await SentryMonitoring.addBreadcrumb(
        message: 'Deleting business',
        data: {'businessId': businessId},
      );
      
      emit(state.copyWith(status: BusinessListingsStatus.loading));
      
      await _supabaseClient
          .from('businesses')
          .delete()
          .eq('id', businessId);

      await loadBusinessListings();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to delete business',
        error: e,
        stackTrace: stackTrace,
      );
      await SentryMonitoring.captureException(
        e, 
        stackTrace,
        tagValue: 'delete_business_error',
      );
      
      emit(state.copyWith(
        status: BusinessListingsStatus.failure,
        errorMessage: 'Failed to delete business: ${e.toString()}',
      ));
    }
  }

  void searchBusinesses(String query) {
    AppLogger.debug('Searching businesses', error: query);
    final filteredList = state.businesses.where((business) {
      return business.name.toLowerCase().contains(query.toLowerCase()) ||
          business.description.toLowerCase().contains(query.toLowerCase()) ||
          business.category.toLowerCase().contains(query.toLowerCase());
    }).toList();

    emit(state.copyWith(
      searchQuery: query,
      filteredBusinesses: filteredList,
    ));
  }

  void filterByCategory(String category) {
    AppLogger.debug('Filtering by category', error: category);
    final filteredList = state.businesses.where((business) {
      return business.category == category;
    }).toList();

    emit(state.copyWith(
      selectedCategory: category,
      filteredBusinesses: filteredList,
    ));
  }
}