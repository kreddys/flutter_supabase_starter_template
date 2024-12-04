// lib/core/voting/data/repositories/voting_repository.dart
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/i_voting_repository.dart';
import '../../../../core/monitoring/sentry_monitoring.dart';
import 'package:sentry/sentry.dart';

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
    final transaction = SentryMonitoring.startTransaction(
      'voting_operation',
      'vote',
    );

    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      
      await SentryMonitoring.addBreadcrumb(
        message: 'Attempting to vote',
        category: 'voting',
        data: {
          'entity_id': entityId,
          'entity_type': entityType.name,
          'vote_type': voteType?.name,
          'user_id': userId,
        },
      );

      if (userId == null) {
        transaction.finish(status: const SpanStatus.unauthenticated());
        return const Left('User must be logged in to vote');
      }

      final existingVote = await _supabaseClient
          .from('votes')
          .select()
          .eq('entity_id', entityId)
          .eq('entity_type', entityType.name)
          .eq('user_id', userId)
          .maybeSingle();

      await SentryMonitoring.addBreadcrumb(
        message: 'Existing vote check',
        category: 'voting',
        data: {
          'existing_vote': existingVote?.toString(),
        },
      );

      if (existingVote != null) {
        if (voteType == null) {
          // Remove vote
          await SentryMonitoring.addBreadcrumb(
            message: 'Removing vote',
            category: 'voting',
          );
          
          await _supabaseClient
              .from('votes')
              .delete()
              .eq('entity_id', entityId)
              .eq('entity_type', entityType.name)
              .eq('user_id', userId);
        } else {
          // Update vote
          await SentryMonitoring.addBreadcrumb(
            message: 'Updating vote',
            category: 'voting',
            data: {'new_vote_type': voteType.name},
          );
          
          await _supabaseClient
              .from('votes')
              .update({'vote_type': voteType.name})
              .eq('entity_id', entityId)
              .eq('entity_type', entityType.name)
              .eq('user_id', userId);
        }
      } else if (voteType != null) {
        // Insert new vote
        await SentryMonitoring.addBreadcrumb(
          message: 'Inserting new vote',
          category: 'voting',
          data: {'vote_type': voteType.name},
        );
        
        await _supabaseClient.from('votes').insert({
          'entity_id': entityId,
          'entity_type': entityType.name,
          'user_id': userId,
          'vote_type': voteType.name,
        });
      }

      transaction.finish(status: const SpanStatus.ok());
      return const Right(true);
    } catch (e, stackTrace) {
      transaction.finish(status: const SpanStatus.internalError());
      
      await SentryMonitoring.captureException(
        e,
        stackTrace,
        tagValue: 'voting_failure',
      );
      
      return Left('Error updating vote: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Map<String, int>>> getVoteCounts({
    required String entityId,
    required EntityType entityType,
  }) async {
    final transaction = SentryMonitoring.startTransaction(
      'get_vote_counts',
      'voting',
    );

    try {
      await SentryMonitoring.addBreadcrumb(
        message: 'Fetching vote counts',
        category: 'voting',
        data: {
          'entity_id': entityId,
          'entity_type': entityType.name,
        },
      );

      final response = await _supabaseClient
          .from('votes')
          .select('vote_type')
          .eq('entity_id', entityId)
          .eq('entity_type', entityType.name);

      final votes = (response as List<dynamic>);
      final upvotes = votes.where((v) => v['vote_type'] == 'upvote').length;
      final downvotes = votes.where((v) => v['vote_type'] == 'downvote').length;

      await SentryMonitoring.addBreadcrumb(
        message: 'Vote counts retrieved',
        category: 'voting',
        data: {
          'upvotes': upvotes,
          'downvotes': downvotes,
          'total_votes': votes.length,
        },
      );

      transaction.finish(status: const SpanStatus.ok());
      return Right({'upvotes': upvotes, 'downvotes': downvotes});
    } catch (e, stackTrace) {
      transaction.finish(status: const SpanStatus.internalError());
      
      await SentryMonitoring.captureException(
        e,
        stackTrace,
        tagValue: 'vote_counts_failure',
      );
      
      return Left('Error fetching vote counts: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, VoteType?>> getUserVote({
    required String entityId,
    required EntityType entityType,
  }) async {
    final transaction = SentryMonitoring.startTransaction(
      'get_user_vote',
      'voting',
    );

    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      
      await SentryMonitoring.addBreadcrumb(
        message: 'Fetching user vote',
        category: 'voting',
        data: {
          'entity_id': entityId,
          'entity_type': entityType.name,
          'user_id': userId,
        },
      );

      if (userId == null) {
        transaction.finish(status: const SpanStatus.unauthenticated());
        return const Right(null);
      }

      final response = await _supabaseClient
          .from('votes')
          .select('vote_type')
          .eq('entity_id', entityId)
          .eq('entity_type', entityType.name)
          .eq('user_id', userId)
          .maybeSingle();

      await SentryMonitoring.addBreadcrumb(
        message: 'User vote retrieved',
        category: 'voting',
        data: {
          'vote_data': response?.toString(),
        },
      );

      transaction.finish(status: const SpanStatus.ok());
      
      if (response == null) return const Right(null);

      return Right(
        response['vote_type'] == 'upvote' ? VoteType.upvote : VoteType.downvote,
      );
    } catch (e, stackTrace) {
      transaction.finish(status: const SpanStatus.internalError());
      
      await SentryMonitoring.captureException(
        e,
        stackTrace,
        tagValue: 'get_user_vote_failure',
      );
      
      return Left('Error fetching user vote: ${e.toString()}');
    }
  }
}