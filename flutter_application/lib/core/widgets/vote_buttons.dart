import 'package:flutter/material.dart';

class VoteButtons extends StatelessWidget {
  final String entityId;
  final bool? userVote;
  final int upvotes;
  final int downvotes;
  final Function(bool?) onVote;

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
            userVote == true ? Icons.thumb_up : Icons.thumb_up_outlined,
            size: 20,
            color: userVote == true
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          onPressed: () => onVote(userVote == true ? null : true),
        ),
        Text('$upvotes'),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            userVote == false ? Icons.thumb_down : Icons.thumb_down_outlined,
            size: 20,
            color: userVote == false
                ? Theme.of(context).colorScheme.error
                : null,
          ),
          onPressed: () => onVote(userVote == false ? null : false),
        ),
        Text('$downvotes'),
      ],
    );
  }
}