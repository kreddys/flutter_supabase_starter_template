-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create a function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create enums
CREATE TYPE vote_type AS ENUM ('upvote', 'downvote');
CREATE TYPE entity_type AS ENUM ('article', 'comment', 'event'); -- Add more types as needed
CREATE TYPE user_role AS ENUM ('user', 'admin', 'moderator');
CREATE TYPE business_status AS ENUM ('pending', 'approved', 'rejected');

-- Votes table
CREATE TABLE IF NOT EXISTS votes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    entity_type entity_type NOT NULL,
    entity_id UUID NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    vote_type vote_type NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE(entity_type, entity_id, user_id)
);

-- Votes table RLS policies
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own votes"
    ON votes FOR ALL
    USING (auth.uid() = user_id);

CREATE TRIGGER update_votes_updated_at
    BEFORE UPDATE ON votes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- User Roles table
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    role user_role DEFAULT 'user'::user_role NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE(user_id, role)
);

-- User Roles table RLS policies
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own roles"
    ON user_roles FOR SELECT
    USING (auth.uid() = user_id);

CREATE TRIGGER update_user_roles_updated_at
    BEFORE UPDATE ON user_roles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX IF NOT EXISTS user_roles_user_id_idx ON user_roles(user_id);

-- Businesses Categories table
CREATE TABLE IF NOT EXISTS business_categories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TRIGGER update_business_categories_updated_at
    BEFORE UPDATE ON business_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE IF NOT EXISTS businesses (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    address TEXT,
    phone TEXT,
    email TEXT,
    website TEXT,
    rating DECIMAL(3, 2) DEFAULT 0.0,
    is_verified BOOLEAN DEFAULT FALSE,
    is_member BOOLEAN DEFAULT FALSE,
    images TEXT[], -- Array of image URLs
    location POINT, -- For latitude and longitude
    operating_hours TEXT,
    is_open BOOLEAN DEFAULT FALSE,
    status business_status DEFAULT 'pending',
    owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Modify the `owner_id` column to allow NULL values
ALTER TABLE businesses
ALTER COLUMN owner_id DROP NOT NULL;


CREATE TRIGGER update_businesses_updated_at
    BEFORE UPDATE ON businesses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Junction table for businesses and categories
CREATE TABLE IF NOT EXISTS business_category_mappings (
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    category_id UUID REFERENCES business_categories(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (business_id, category_id)
);

CREATE TRIGGER update_business_category_mappings_updated_at
    BEFORE UPDATE ON business_category_mappings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- RLS policies for Businesses and Categories
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_category_mappings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view approved businesses"
    ON businesses FOR SELECT
    USING (status = 'approved');

CREATE POLICY "Business owners can manage their own listings"
    ON businesses FOR ALL
    USING (auth.uid() = owner_id);

CREATE POLICY "Admins can manage all businesses"
    ON businesses FOR ALL
    USING (is_admin() OR auth.uid() = owner_id);

CREATE POLICY "Anyone can view categories"
    ON business_categories FOR SELECT
    USING (true);

CREATE POLICY "Admins can manage categories"
    ON business_categories FOR ALL
    USING (is_admin());

CREATE POLICY "Anyone can view business-category mappings"
    ON business_category_mappings FOR SELECT
    USING (true);

CREATE POLICY "Admins can manage business-category mappings"
    ON business_category_mappings FOR ALL
    USING (is_admin());

-- Admin role check function
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM user_roles 
        WHERE user_id = auth.uid() 
        AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Articles, Authors, and Tags tables
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

CREATE TABLE IF NOT EXISTS tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ghost_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS article_authors (
    article_id UUID REFERENCES articles(id) ON DELETE CASCADE,
    author_id UUID REFERENCES authors(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (article_id, author_id)
);

CREATE TABLE IF NOT EXISTS article_tags (
    article_id UUID REFERENCES articles(id) ON DELETE CASCADE,
    tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (article_id, tag_id)
);

-- Timestamp triggers for articles, authors, and tags
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

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_articles_ghost_id ON articles(ghost_id);
CREATE INDEX IF NOT EXISTS idx_articles_slug ON articles(slug);
CREATE INDEX IF NOT EXISTS idx_authors_ghost_id ON authors(ghost_id);
CREATE INDEX IF NOT EXISTS idx_tags_ghost_id ON tags(ghost_id);
CREATE INDEX IF NOT EXISTS businesses_category_idx ON businesses(name);
CREATE INDEX IF NOT EXISTS business_categories_name_idx ON business_categories(name);
CREATE INDEX IF NOT EXISTS business_category_mappings_idx ON business_category_mappings(business_id, category_id);

-- RLS policies
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE authors ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE article_authors ENABLE ROW LEVEL SECURITY;
ALTER TABLE article_tags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read access for articles"
    ON articles FOR SELECT TO public
    USING (true);

CREATE POLICY "Public read access for authors"
    ON authors FOR SELECT TO public
    USING (true);

CREATE POLICY "Public read access for tags"
    ON tags FOR SELECT TO public
    USING (true);

CREATE POLICY "Public read access for article_authors"
    ON article_authors FOR SELECT TO public
    USING (true);

CREATE POLICY "Public read access for article_tags"
    ON article_tags FOR SELECT TO public
    USING (true);
