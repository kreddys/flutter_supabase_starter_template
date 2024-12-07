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
}