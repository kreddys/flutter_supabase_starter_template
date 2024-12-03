create type vote_type as enum ('upvote', 'downvote');
create type entity_type as enum ('article', 'comment', 'event'); -- add more types as needed

create table votes (
  id uuid default uuid_generate_v4() primary key,
  entity_type entity_type not null,
  entity_id uuid not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  vote_type vote_type not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  -- Composite unique constraint to prevent multiple votes on same entity by same user
  unique(entity_type, entity_id, user_id)
);

-- Add RLS policies
alter table votes enable row level security;

create policy "Users can manage their own votes"
  on votes for all
  using (auth.uid() = user_id);

-- Create an update trigger for updated_at
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger update_votes_updated_at
  before update on votes
  for each row
  execute function update_updated_at_column();