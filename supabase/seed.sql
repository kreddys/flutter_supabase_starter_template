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

-- Create role enum
create type user_role as enum ('user', 'admin', 'moderator');

-- Create user_roles table
create table user_roles (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references auth.users(id) on delete cascade not null,
    role user_role default 'user'::user_role not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique(user_id, role)
);

-- Add RLS policies
alter table user_roles enable row level security;

-- Users can view their own roles
create policy "Users can view their own roles"
    on user_roles for select
    using (auth.uid() = user_id);

-- Create updated_at trigger
create trigger update_user_roles_updated_at
    before update on user_roles
    for each row
    execute function update_updated_at_column();

-- Create index
create index user_roles_user_id_idx on user_roles(user_id);

-- Create enum for business status
create type business_status as enum ('pending', 'approved', 'rejected');

-- Create businesses table
create table businesses (
    id uuid default uuid_generate_v4() primary key,
    name text not null,
    description text,
    category text not null,
    address text,
    phone text,
    email text,
    website text,
    rating decimal(3,2) default 0.0,
    is_verified boolean default false,
    is_member boolean default false,
    images text[], -- Array of image URLs
    location point, -- For storing latitude and longitude
    operating_hours text,
    is_open boolean default false,
    status business_status default 'pending',
    owner_id uuid references auth.users(id) on delete cascade,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Add RLS policies
alter table businesses enable row level security;

-- Policy for reading businesses (public access)
create policy "Anyone can view approved businesses"
    on businesses for select
    using (status = 'approved');

-- Policy for business owners to manage their listings
create policy "Business owners can manage their own listings"
    on businesses for all
    using (auth.uid() = owner_id);

-- Create updated_at trigger
create trigger update_businesses_updated_at
    before update on businesses
    for each row
    execute function update_updated_at_column();

-- Create index for common queries
create index businesses_category_idx on businesses(category);
create index businesses_status_idx on businesses(status);
create index businesses_owner_id_idx on businesses(owner_id);

-- Create a base admin role check function
create or replace function is_admin()
returns boolean as $$
begin
  return exists (
    select 1 
    from user_roles 
    where user_id = auth.uid() 
    and role = 'admin'
  );
end;
$$ language plpgsql security definer;

-- Now create new policies using the function
create policy "Admins can manage all businesses"
on businesses for all
using (
  is_admin()
  or auth.uid() = owner_id -- Allow business owners to manage their own
);

create policy "Admins can manage roles"
on user_roles for all
using (is_admin());

-- Add a public read policy for businesses if needed
create policy "Anyone can view businesses"
on businesses for select
using (true);

-- Create a function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';
-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create timestamp update function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Articles table (main table)
CREATE TABLE IF NOT EXISTS articles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ghost_id TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    html_content TEXT NOT NULL,
    published_at TIMESTAMP WITH TIME ZONE,
    image_url TEXT,
    slug TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Authors reference table
CREATE TABLE IF NOT EXISTS authors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ghost_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    email TEXT,
    profile_image TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tags reference table
CREATE TABLE IF NOT EXISTS tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ghost_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Junction table for articles and authors
CREATE TABLE IF NOT EXISTS article_authors (
    article_id UUID REFERENCES articles(id) ON DELETE CASCADE,
    author_id UUID REFERENCES authors(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (article_id, author_id)
);

-- Junction table for articles and tags
CREATE TABLE IF NOT EXISTS article_tags (
    article_id UUID REFERENCES articles(id) ON DELETE CASCADE,
    tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (article_id, tag_id)
);

-- Create triggers for updating timestamps
CREATE TRIGGER update_articles_updated_at
    BEFORE UPDATE ON articles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_authors_updated_at
    BEFORE UPDATE ON authors
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tags_updated_at
    BEFORE UPDATE ON tags
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_article_authors_updated_at
    BEFORE UPDATE ON article_authors
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_article_tags_updated_at
    BEFORE UPDATE ON article_tags
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_articles_ghost_id ON articles(ghost_id);
CREATE INDEX IF NOT EXISTS idx_articles_slug ON articles(slug);
CREATE INDEX IF NOT EXISTS idx_authors_ghost_id ON authors(ghost_id);
CREATE INDEX IF NOT EXISTS idx_tags_ghost_id ON tags(ghost_id);

-- Enable Row Level Security
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE authors ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE article_authors ENABLE ROW LEVEL SECURITY;
ALTER TABLE article_tags ENABLE ROW LEVEL SECURITY;

-- Create policies for public read access
CREATE POLICY "Public read access for articles"
    ON articles FOR SELECT TO public USING (true);

CREATE POLICY "Public read access for authors"
    ON authors FOR SELECT TO public USING (true);

CREATE POLICY "Public read access for tags"
    ON tags FOR SELECT TO public USING (true);

CREATE POLICY "Public read access for article_authors"
    ON article_authors FOR SELECT TO public USING (true);

CREATE POLICY "Public read access for article_tags"
    ON article_tags FOR SELECT TO public USING (true);