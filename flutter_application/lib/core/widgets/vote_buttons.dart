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
    required this.userVote, // This should represent ONLY the current user's vote
    required this.upvotes,
    required this.downvotes,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    // The icon and color should only change based on userVote
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            // Only show filled icon if THIS user has upvoted
            userVote == 1 ? Icons.thumb_up : Icons.thumb_up_outlined,
            size: 20,
            // Only show green if THIS user has upvoted
            color: userVote == 1 
                ? Theme.of(context).colorScheme.primary 
                : null,
          ),
          onPressed: () => onVote(
            userVote == 1 ? null : VoteType.upvote,
          ),
        ),
        // Show total upvotes count
        Text('$upvotes'),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            // Only show filled icon if THIS user has downvoted
            userVote == -1 ? Icons.thumb_down : Icons.thumb_down_outlined,
            size: 20,
            // Only show red if THIS user has downvoted
            color: userVote == -1
                ? Theme.of(context).colorScheme.error
                : null,
          ),
          onPressed: () => onVote(
            userVote == -1 ? null : VoteType.downvote,
          ),
        ),
        // Show total downvotes count
        Text('$downvotes'),
      ],
    );
  }
}