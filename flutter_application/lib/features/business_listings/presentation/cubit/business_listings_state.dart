import 'package:equatable/equatable.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/monitoring/sentry_monitoring.dart';

enum BusinessListingsStatus { initial, loading, success, failure }

class BusinessListingsState extends Equatable {
  const BusinessListingsState({
    this.status = BusinessListingsStatus.initial,
    this.businesses = const [],
    this.filteredBusinesses = const [],
    this.selectedCategory,
    this.searchQuery = '',
    this.errorMessage,
  });

  final BusinessListingsStatus status;
  final List<Business> businesses;
  final List<Business> filteredBusinesses;
  final String? selectedCategory;
  final String searchQuery;
  final String? errorMessage;

  @override
  List<Object?> get props => [
        status,
        businesses,
        filteredBusinesses,
        selectedCategory,
        searchQuery,
        errorMessage,
      ];

  BusinessListingsState copyWith({
    BusinessListingsStatus? status,
    List<Business>? businesses,
    List<Business>? filteredBusinesses,
    String? selectedCategory,
    String? searchQuery,
    String? errorMessage,
  }) {
    return BusinessListingsState(
      status: status ?? this.status,
      businesses: businesses ?? this.businesses,
      filteredBusinesses: filteredBusinesses ?? this.filteredBusinesses,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class Point {
  final double x;
  final double y;

  Point(this.x, this.y);

  @override
  String toString() => '($x,$y)';
}

class Business {
  final String id;
  final String name;
  final String description;
  final String category;
  final String address;
  final String phone;
  final String email;
  final String website;
  final double rating;
  final bool isVerified;
  final bool isMember;
  final List<String> images;
  final Point? location;
  final String operatingHours;
  final bool isOpen;

  Business({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
    this.rating = 0.0,
    this.isVerified = false,
    this.isMember = false,
    this.images = const [],
    this.location,
    this.operatingHours = '',
    this.isOpen = false,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    Point? locationPoint;
    if (json['location'] != null) {
      try {
        final String pointStr = json['location'] as String;
        final coords = pointStr
            .replaceAll('(', '')
            .replaceAll(')', '')
            .split(',')
            .map((e) => double.parse(e.trim()))
            .toList();
        locationPoint = Point(coords[0], coords[1]);
      } catch (e, stackTrace) {
        // Replace print with proper logging and Sentry capture
        AppLogger.error(
          'Error parsing location point',
          error: e,
          stackTrace: StackTrace.current,
        );
        SentryMonitoring.captureException(
          e,
          stackTrace,
          tagValue: 'location_parse_failure',
        );
      }
    }

    return Business(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      website: json['website'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isVerified: json['is_verified'] as bool? ?? false,
      isMember: json['is_member'] as bool? ?? false,
      images: List<String>.from(json['images'] as List? ?? []),
      location: locationPoint,
      operatingHours: json['operating_hours'] as String? ?? '',
      isOpen: json['is_open'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'rating': rating,
      'is_verified': isVerified,
      'is_member': isMember,
      'images': images,
      'location': location != null ? '(${location!.x},${location!.y})' : null,
      'operating_hours': operatingHours,
      'is_open': isOpen,
    };
  }

  // Helper getters for coordinates
  double? get latitude => location?.y;
  double? get longitude => location?.x;
}