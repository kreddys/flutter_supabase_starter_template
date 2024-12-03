import 'package:flutter/material.dart';
import '../voting/domain/repositories/i_voting_repository.dart';

class VoteButtons extends StatelessWidget {
  final String entityId;
  final int userVote; // 0: no vote, 1: upvote, -1: downvote
  final int upvotes;
  final int downvotes;
  final Function(VoteType?) onVote;

  const VoteButtons({
    super.key,
    required this.entityId,
    required this.userVote,
    required this.upvotes,
    required this.downvotes,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            userVote == 1 ? Icons.thumb_up : Icons.thumb_up_outlined,
            size: 20,
            color: userVote == 1
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          onPressed: () => onVote(
            userVote == 1 ? null : VoteType.upvote,
          ),
        ),
        Text('$upvotes'),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            userVote == -1 ? Icons.thumb_down : Icons.thumb_down_outlined,
            size: 20,
            color: userVote == -1
                ? Theme.of(context).colorScheme.error
                : null,
          ),
          onPressed: () => onVote(
            userVote == -1 ? null : VoteType.downvote,
          ),
        ),
        Text('$downvotes'),
      ],
    );
  }
}