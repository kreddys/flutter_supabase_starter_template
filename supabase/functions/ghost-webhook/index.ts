import { serve } from "https://deno.land/std@0.208.0/http/server.ts";

// Interfaces remain the same
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

// Logger class remains the same
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
    AppLogger.error(`Environment variables missing`, { requestId, supabaseUrl: !!supabaseUrl, supabaseKey: !!supabaseKey });
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
    AppLogger.debug(`Generated article ID`, { requestId, articleId });

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
            'Prefer': 'return=representation, resolution=merge-duplicates'
          },
          body: JSON.stringify({
            id: crypto.randomUUID(), // Added UUID generation
            ghost_id: author.id,
            name: author.name,
            slug: author.slug,
            email: author.email,
            profile_image: author.profile_image,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          })
        });

        const responseText = await authorResponse.text();
        let authorData;
        
        try {
          authorData = responseText ? JSON.parse(responseText) : null;
        } catch (parseError) {
          AppLogger.error(`Failed to parse author response`, {
            requestId,
            authorId: author.id,
            responseText,
            status: authorResponse.status
          });
          throw new Error(`Invalid response from author creation: ${responseText}`);
        }

        if (!authorResponse.ok || !authorData) {
          throw new Error(`Failed to insert author: ${responseText}`);
        }

        AppLogger.debug(`Author inserted`, { requestId, authorId: authorData.id });

        // Create author mapping
        const mappingResponse = await fetch(`${supabaseUrl}/rest/v1/article_author_mappings`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseKey,
            'Authorization': `Bearer ${supabaseKey}`,
            'Prefer': 'return=representation, resolution=merge-duplicates'
          },
          body: JSON.stringify({
            id: crypto.randomUUID(), // Added UUID generation
            article_id: articleId,
            author_id: authorData.id
          })
        });

        if (!mappingResponse.ok) {
          throw new Error(`Failed to create author mapping: ${await mappingResponse.text()}`);
        }

        AppLogger.debug(`Author mapping created`, { requestId, articleId, authorId: authorData.id });
        return authorData;
      } catch (error) {
        AppLogger.error(`Error processing author`, { 
          requestId, 
          authorId: author.id, 
          error: error.message,
          stack: error.stack 
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
            'Prefer': 'return=representation, resolution=merge-duplicates'
          },
          body: JSON.stringify({
            id: crypto.randomUUID(), // Added UUID generation
            ghost_id: tag.id,
            name: tag.name,
            slug: tag.slug,
            description: tag.description,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          })
        });

        const responseText = await tagResponse.text();
        let tagData;
        
        try {
          tagData = responseText ? JSON.parse(responseText) : null;
        } catch (parseError) {
          AppLogger.error(`Failed to parse tag response`, {
            requestId,
            tagId: tag.id,
            responseText,
            status: tagResponse.status
          });
          throw new Error(`Invalid response from tag creation: ${responseText}`);
        }

        if (!tagResponse.ok || !tagData) {
          throw new Error(`Failed to insert tag: ${responseText}`);
        }

        AppLogger.debug(`Tag inserted`, { requestId, tagId: tagData.id });

        // Create tag mapping
        const mappingResponse = await fetch(`${supabaseUrl}/rest/v1/article_tag_mappings`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseKey,
            'Authorization': `Bearer ${supabaseKey}`,
            'Prefer': 'return=representation, resolution=merge-duplicates'
          },
          body: JSON.stringify({
            id: crypto.randomUUID(), // Added UUID generation
            article_id: articleId,
            tag_id: tagData.id
          })
        });

        if (!mappingResponse.ok) {
          throw new Error(`Failed to create tag mapping: ${await mappingResponse.text()}`);
        }

        AppLogger.debug(`Tag mapping created`, { requestId, articleId, tagId: tagData.id });
        return tagData;
      } catch (error) {
        AppLogger.error(`Error processing tag`, { 
          requestId, 
          tagId: tag.id, 
          error: error.message,
          stack: error.stack 
        });
        throw error;
      }
    });

    // Insert Article (remains mostly the same)
    AppLogger.info(`Inserting article`, { requestId, articleId, title: post.title });
    const articleResponse = await fetch(`${supabaseUrl}/rest/v1/articles`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseKey,
        'Authorization': `Bearer ${supabaseKey}`,
        'Prefer': 'return=representation, resolution=merge-duplicates'
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
      throw new Error(`Failed to insert article: ${await articleResponse.text()}`);
    }

    AppLogger.debug(`Article inserted`, { requestId, articleId });

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