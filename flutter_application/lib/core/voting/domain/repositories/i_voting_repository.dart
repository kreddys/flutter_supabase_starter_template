// lib/core/voting/domain/repositories/i_voting_repository.dart
import 'package:dartz/dartz.dart';

enum EntityType { article, comment, event }
enum VoteType { upvote, downvote }

abstract class IVotingRepository {
  Future<Either<String, bool>> vote({
    required String entityId,
    required EntityType entityType,
    required VoteType? voteType,
  });

  Future<Either<String, Map<String, int>>> getVoteCounts({
    required String entityId,
    required EntityType entityType,
  });

  Future<Either<String, VoteType?>> getUserVote({
    required String entityId,
    required EntityType entityType,
  });
}