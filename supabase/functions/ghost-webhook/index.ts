import { serve } from "https://deno.land/std@0.208.0/http/server.ts";

// Interfaces for Ghost webhook payload
interface GhostAuthor {
  id: string;
  name: string;
  slug: string;
  email: string | null;
  profile_image: string | null;
}

interface GhostTag {
  id: string;
  name: string;
  slug: string;
  description: string | null;
}

interface GhostWebhookPayload {
  post: {
    current: {
      id: string;
      title: string;
      html: string;
      slug: string;
      feature_image: string | null;
      custom_excerpt: string | null;
      published_at: string;
      created_at: string;
      updated_at: string;
      tags: GhostTag[];
      authors: GhostAuthor[];
      plaintext: string | null;
    };
  };
}

// Logger class for consistent logging
class AppLogger {
  static debug(message: string, data?: any) {
    console.log(`[DEBUG] ${new Date().toISOString()} - ${message}`, data ? JSON.stringify(data, null, 2) : '');
  }

  static info(message: string, data?: any) {
    console.log(`[INFO] ${new Date().toISOString()} - ${message}`, data ? JSON.stringify(data, null, 2) : '');
  }

  static error(message: string, error?: any) {
    console.error(`[ERROR] ${new Date().toISOString()} - ${message}`, error ? JSON.stringify(error, null, 2) : '');
  }
}

serve(async (req) => {
  const requestId = crypto.randomUUID();
  AppLogger.info(`Starting webhook processing`, { requestId });

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  if (!supabaseUrl || !supabaseKey) {
    AppLogger.error(`Environment variables missing`, { requestId });
    throw new Error('Missing required environment variables');
  }

  try {
    const payload: GhostWebhookPayload = await req.json();
    AppLogger.info(`Received webhook payload`, {
      requestId,
      postId: payload.post?.current?.id,
      title: payload.post?.current?.title
    });

    if (!payload.post?.current) {
      AppLogger.error(`Invalid payload structure`, { requestId });
      throw new Error('Invalid webhook payload structure');
    }

    const post = payload.post.current;
    const articleId = crypto.randomUUID();

    // Insert Article first
    AppLogger.info(`Inserting article`, { requestId, articleId, title: post.title });
    const articleResponse = await fetch(`${supabaseUrl}/rest/v1/articles`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseKey,
        'Authorization': `Bearer ${supabaseKey}`,
        'Prefer': 'return=representation'
      },
      body: JSON.stringify({
        id: articleId,
        ghost_id: post.id,
        title: post.title,
        description: post.custom_excerpt || post.plaintext?.substring(0, 200) || '',
        html_content: post.html,
        published_at: post.published_at,
        image_url: post.feature_image,
        slug: post.slug,
        created_at: post.created_at,
        updated_at: post.updated_at
      })
    });

    if (!articleResponse.ok) {
      const errorText = await articleResponse.text();
      AppLogger.error(`Failed to insert article`, { requestId, error: errorText });
      throw new Error(`Failed to insert article: ${errorText}`);
    }

    // Process Authors
    AppLogger.info(`Processing authors`, { requestId, authorCount: post.authors.length });
    const authorPromises = post.authors.map(async (author) => {
      try {
        AppLogger.debug(`Processing author`, { requestId, authorId: author.id, name: author.name });
        
        const authorResponse = await fetch(`${supabaseUrl}/rest/v1/article_authors`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseKey,
            'Authorization': `Bearer ${supabaseKey}`,
            'Prefer': 'return=representation'
          },
          body: JSON.stringify({
            id: crypto.randomUUID(),
            article_id: articleId,
            ghost_id: author.id,
            name: author.name,
            slug: author.slug,
            email: author.email,
            profile_image: author.profile_image,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          })
        });

        if (!authorResponse.ok) {
          const errorText = await authorResponse.text();
          throw new Error(`Failed to insert author: ${errorText}`);
        }

        AppLogger.debug(`Author inserted successfully`, { requestId, authorId: author.id });
      } catch (error) {
        AppLogger.error(`Error processing author`, { 
          requestId, 
          authorId: author.id, 
          error: error.message 
        });
        throw error;
      }
    });

    // Process Tags
    AppLogger.info(`Processing tags`, { requestId, tagCount: post.tags.length });
    const tagPromises = post.tags.map(async (tag) => {
      try {
        AppLogger.debug(`Processing tag`, { requestId, tagId: tag.id, name: tag.name });

        const tagResponse = await fetch(`${supabaseUrl}/rest/v1/article_tags`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseKey,
            'Authorization': `Bearer ${supabaseKey}`,
            'Prefer': 'return=representation'
          },
          body: JSON.stringify({
            id: crypto.randomUUID(),
            article_id: articleId,
            ghost_id: tag.id,
            name: tag.name,
            slug: tag.slug,
            description: tag.description,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          })
        });

        if (!tagResponse.ok) {
          const errorText = await tagResponse.text();
          throw new Error(`Failed to insert tag: ${errorText}`);
        }

        AppLogger.debug(`Tag inserted successfully`, { requestId, tagId: tag.id });
      } catch (error) {
        AppLogger.error(`Error processing tag`, { 
          requestId, 
          tagId: tag.id, 
          error: error.message 
        });
        throw error;
      }
    });

    // Wait for all promises to resolve
    await Promise.all([...authorPromises, ...tagPromises]);
    AppLogger.info(`All operations completed successfully`, { requestId });

    return new Response(JSON.stringify({
      success: true,
      message: 'Article and related data processed successfully',
      articleId: articleId
    }), {
      headers: { "Content-Type": "application/json" },
      status: 200
    });

  } catch (error) {
    AppLogger.error(`Error processing webhook`, { 
      requestId, 
      error: error.message,
      stack: error.stack 
    });
    
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      headers: { "Content-Type": "application/json" },
      status: 500
    });
  }
});