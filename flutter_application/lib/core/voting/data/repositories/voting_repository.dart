import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentry/sentry.dart';
import '../../domain/repositories/i_voting_repository.dart';
import '../../../../core/monitoring/sentry_monitoring.dart';
import '../../../logging/app_logger.dart';

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
      'vote',
      'voting_operation',
    );

    try {

      AppLogger.info('Attempting to vote');
      
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        AppLogger.warning('Vote attempt failed - User not logged in');
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

      if (existingVote != null) {
        if (voteType == null) {
          await _supabaseClient
              .from('votes')
              .delete()
              .eq('entity_id', entityId)
              .eq('entity_type', entityType.name)
              .eq('user_id', userId);
        } else {
          await _supabaseClient
              .from('votes')
              .update({'vote_type': voteType.name})
              .eq('entity_id', entityId)
              .eq('entity_type', entityType.name)
              .eq('user_id', userId);
        }
      } else if (voteType != null) {
        AppLogger.info('Creating new vote');
        await _supabaseClient.from('votes').insert({
          'entity_id': entityId,
          'entity_type': entityType.name,
          'user_id': userId,
          'vote_type': voteType.name,
        });
      }

      AppLogger.info('Vote operation completed successfully');
      transaction.finish(status: const SpanStatus.ok());
      return const Right(true);
    } catch (error, stackTrace) {
          AppLogger.error(
            'Vote operation failed',
            error: error,
            stackTrace: stackTrace,
          );
      transaction.finish(status: const SpanStatus.internalError());
      await SentryMonitoring.captureException(
        error,
        stackTrace,
        tagValue: 'vote_failure',
      );
      return Left('Error updating vote: ${error.toString()}');
    }
  }

  @override
  Future<Either<String, Map<String, int>>> getVoteCounts({
    required String entityId,
    required EntityType entityType,
  }) async {
    final transaction = SentryMonitoring.startTransaction(
      'get_vote_counts',
      'voting_operation',
    );

    try {
      final response = await _supabaseClient
          .from('votes')
          .select('vote_type')
          .eq('entity_id', entityId)
          .eq('entity_type', entityType.name);

      final votes = (response as List<dynamic>);
      final upvotes = votes.where((v) => v['vote_type'] == 'upvote').length;
      final downvotes = votes.where((v) => v['vote_type'] == 'downvote').length;

      transaction.finish(status: const SpanStatus.ok());
      return Right({'upvotes': upvotes, 'downvotes': downvotes});
    } catch (error, stackTrace) {

      AppLogger.error(
        'Failed to fetch vote counts',
        error: error,
        stackTrace: stackTrace,
      );

      transaction.finish(status: const SpanStatus.internalError());
      await SentryMonitoring.captureException(
        error,
        stackTrace,
        tagValue: 'get_vote_counts_failure',
      );
      return Left('Error fetching vote counts: ${error.toString()}');
    }
  }

  @override
  Future<Either<String, VoteType?>> getUserVote({
    required String entityId,
    required EntityType entityType,
  }) async {
    final transaction = SentryMonitoring.startTransaction(
      'get_user_vote',
      'voting_operation',
    );

    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        transaction.finish(status: const SpanStatus.ok());
        return const Right(null);
      }

      final response = await _supabaseClient
          .from('votes')
          .select('vote_type')
          .eq('entity_id', entityId)
          .eq('entity_type', entityType.name)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        transaction.finish(status: const SpanStatus.ok());
        return const Right(null);
      }

      debugPrint(response.toString());

      transaction.finish(status: const SpanStatus.ok());
      return Right(
        response['vote_type'] == 'upvote' ? VoteType.upvote : VoteType.downvote,
      );
    } catch (error, stackTrace) {

      AppLogger.error(
        'Failed to fetch user vote',
        error: error,
        stackTrace: stackTrace,
      );

      transaction.finish(status: const SpanStatus.internalError());
      
      await SentryMonitoring.captureException(
        error,
        stackTrace,
        tagValue: 'get_user_vote_failure',
      );
      return Left('Error fetching user vote: ${error.toString()}');
    }
  }
}