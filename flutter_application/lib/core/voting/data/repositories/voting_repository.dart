// lib/core/voting/data/repositories/voting_repository.dart
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/i_voting_repository.dart';

@LazySingleton(as: IVotingRepository)
class VotingRepository implements IVotingRepository {
  final SupabaseClient _supabaseClient;

  VotingRepository(this._supabaseClient);

  @override
  Future<Either<String, bool>> vote({
    required String entityId,
    required EntityType entityType,
    required VoteType? voteType,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        return const Left('User must be logged in to vote');
      }

      final existingVote = await _supabaseClient
          .from('votes')
          .select()
          .eq('entity_id', entityId)
          .eq('entity_type', entityType.name)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingVote != null) {
        if (voteType == null) {
          // Remove vote
          await _supabaseClient
              .from('votes')
              .delete()
              .eq('entity_id', entityId)
              .eq('entity_type', entityType.name)
              .eq('user_id', userId);
        } else {
          // Update vote
          await _supabaseClient
              .from('votes')
              .update({'vote_type': voteType.name})
              .eq('entity_id', entityId)
              .eq('entity_type', entityType.name)
              .eq('user_id', userId);
        }
      } else if (voteType != null) {
        // Insert new vote
        await _supabaseClient.from('votes').insert({
          'entity_id': entityId,
          'entity_type': entityType.name,
          'user_id': userId,
          'vote_type': voteType.name,
        });
      }

      return const Right(true);
    } catch (e) {
      return Left('Error updating vote: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Map<String, int>>> getVoteCounts({
    required String entityId,
    required EntityType entityType,
  }) async {
    try {
      final response = await _supabaseClient
          .from('votes')
          .select('vote_type')
          .eq('entity_id', entityId)
          .eq('entity_type', entityType.name);

      final votes = (response as List<dynamic>);
      final upvotes = votes.where((v) => v['vote_type'] == 'upvote').length;
      final downvotes = votes.where((v) => v['vote_type'] == 'downvote').length;

      return Right({'upvotes': upvotes, 'downvotes': downvotes});
    } catch (e) {
      return Left('Error fetching vote counts: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, VoteType?>> getUserVote({
    required String entityId,
    required EntityType entityType,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) return const Right(null);

      final response = await _supabaseClient
          .from('votes')
          .select('vote_type')
          .eq('entity_id', entityId)
          .eq('entity_type', entityType.name)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return const Right(null);

      debugPrint(response.toString());

      return Right(
        response['vote_type'] == 'upvote' ? VoteType.upvote : VoteType.downvote,
      );
    } catch (e) {
      return Left('Error fetching user vote: ${e.toString()}');
    }
  }
}