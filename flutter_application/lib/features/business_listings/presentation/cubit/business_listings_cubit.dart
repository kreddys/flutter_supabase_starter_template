import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'business_listings_state.dart';

class BusinessListingsCubit extends Cubit<BusinessListingsState> {
  final SupabaseClient _supabaseClient;

  BusinessListingsCubit(this._supabaseClient) : super(const BusinessListingsState());

  Future<void> loadBusinessListings() async {
    try {
      emit(state.copyWith(status: BusinessListingsStatus.loading));
      
      final response = await _supabaseClient
          .from('businesses')
          .select()
          .order('name');

      final businesses = (response as List)
          .map((business) => Business.fromJson(business))
          .toList();

      emit(state.copyWith(
        status: BusinessListingsStatus.success,
        businesses: businesses,
        filteredBusinesses: businesses,
      ));
    } catch (e) {
      emit(
        state.copyWith(
          status: BusinessListingsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void searchBusinesses(String query) {
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
    final filteredList = state.businesses.where((business) {
      return business.category == category;
    }).toList();

    emit(state.copyWith(
      selectedCategory: category,
      filteredBusinesses: filteredList,
    ));
  }

  Future<void> createBusiness(Business business) async {
    try {
      emit(state.copyWith(status: BusinessListingsStatus.loading));
      
      await _supabaseClient
          .from('businesses')
          .insert({
            'name': business.name,
            'description': business.description,
            'category': business.category,
            'address': business.address,
            'phone': business.phone,
            'email': business.email,
            'website': business.website,
            'rating': business.rating,
            'is_verified': business.isVerified,
            'is_member': business.isMember,
            'images': business.images,
            'location': business.location,
            'operating_hours': business.operatingHours,
            'is_open': business.isOpen,
          });

      // Reload the business listings after creating
      await loadBusinessListings();
    } catch (e) {
      emit(state.copyWith(
        status: BusinessListingsStatus.failure,
        errorMessage: 'Failed to create business: ${e.toString()}',
      ));
    }
  }

  Future<void> updateBusiness(Business business) async {
    try {
      emit(state.copyWith(status: BusinessListingsStatus.loading));
      
      await _supabaseClient
          .from('businesses')
          .update({
            'name': business.name,
            'description': business.description,
            'category': business.category,
            'address': business.address,
            'phone': business.phone,
            'email': business.email,
            'website': business.website,
            'rating': business.rating,
            'is_verified': business.isVerified,
            'is_member': business.isMember,
            'images': business.images,
            'location': business.location,
            'operating_hours': business.operatingHours,
            'is_open': business.isOpen,
          })
          .eq('id', business.id);

      // Reload the business listings after updating
      await loadBusinessListings();
    } catch (e) {
      emit(state.copyWith(
        status: BusinessListingsStatus.failure,
        errorMessage: 'Failed to update business: ${e.toString()}',
      ));
    }
  }

  Future<void> deleteBusiness(String businessId) async {
    try {
      emit(state.copyWith(status: BusinessListingsStatus.loading));
      
      await _supabaseClient
          .from('businesses')
          .delete()
          .eq('id', businessId);

      // Reload the business listings after deleting
      await loadBusinessListings();
    } catch (e) {
      emit(state.copyWith(
        status: BusinessListingsStatus.failure,
        errorMessage: 'Failed to delete business: ${e.toString()}',
      ));
    }
  }

}