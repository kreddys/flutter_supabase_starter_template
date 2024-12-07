import { serve } from "https://deno.land/std@0.208.0/http/server.ts";

// Interfaces
interface GhostWebhookPayload {
  post: {
    current: {
      id: string;
      title: string;
      html: string;
      slug: string;
      feature_image: string | null;
      excerpt: string | null;
      published_at: string;
      tags: Array<{
        id: string;
        name: string;
        slug: string;
      }>;
      authors: Array<{
        name: string;
      }>;
    };
  };
}

interface SupabaseArticle {
  id: string;
  ghost_id: string;
  title: string;
  description: string;
  author: string;
  published_at: string;
  image_url: string;
  html_content: string;
  slug: string;
  tags: string[];
}

// Helper function to generate UUID
function generateUUID(): string {
  return crypto.randomUUID();
}

// Helper function for debug logging
function addDebugLog(message: string, data?: any) {
  console.log(`[${new Date().toISOString()}] ${message}`, data ? JSON.stringify(data) : '');
}

serve(async (req) => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  if (!supabaseUrl || !supabaseKey) {
    throw new Error('Missing required environment variables');
  }

  try {
    const payload: GhostWebhookPayload = await req.json();
    addDebugLog('Parsed webhook payload', payload);

    if (!payload.post?.current) {
      throw new Error('Invalid webhook payload structure');
    }

    const post = payload.post.current;
    
    // Extract tags from the post
    const tags = post.tags?.map(tag => tag.name) || [];
    addDebugLog('Extracted tags', tags);

    const article: SupabaseArticle = {
      id: generateUUID(),
      ghost_id: post.id,
      title: post.title,
      description: post.excerpt || '',
      author: post.authors?.[0]?.name || 'Amaravati Chamber',
      published_at: post.published_at,
      image_url: post.feature_image || '',
      html_content: post.html,
      slug: post.slug,
      tags: tags
    };

    // Insert/update article
    const articleResponse = await fetch(`${supabaseUrl}/rest/v1/articles`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseKey,
        'Authorization': `Bearer ${supabaseKey}`,
        'Prefer': 'resolution=merge-duplicates'
      },
      body: JSON.stringify(article)
    });

    if (!articleResponse.ok) {
      throw new Error(`Failed to insert/update article: ${await articleResponse.text()}`);
    }

    // Process tags
    if (tags.length > 0) {
      const tagPromises = tags.map(async (tagName) => {
        // Insert tag
        await fetch(`${supabaseUrl}/rest/v1/article_tags`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseKey,
            'Authorization': `Bearer ${supabaseKey}`,
            'Prefer': 'resolution=merge-duplicates'
          },
          body: JSON.stringify({
            name: tagName,
            slug: tagName.toLowerCase().replace(/\s+/g, '-')
          })
        });

        // Create article-tag relationship
        await fetch(`${supabaseUrl}/rest/v1/article_tag_relations`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseKey,
            'Authorization': `Bearer ${supabaseKey}`,
            'Prefer': 'resolution=merge-duplicates'
          },
          body: JSON.stringify({
            article_id: article.id,
            tag_name: tagName
          })
        });
      });

      await Promise.all(tagPromises);
      addDebugLog('Processed tags and relationships', { tagCount: tags.length });
    }

    return new Response(JSON.stringify({
      success: true,
      message: 'Article processed successfully',
      articleId: article.id
    }), {
      headers: { "Content-Type": "application/json" },
      status: 200
    });

  } catch (error) {
    addDebugLog('Error processing webhook', { error: error.message });
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      headers: { "Content-Type": "application/json" },
      status: 500
    });
  }
});