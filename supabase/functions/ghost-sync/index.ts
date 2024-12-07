// ghost-sync/index.ts

import { serve } from "https://deno.land/std@0.208.0/http/server.ts";

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

interface GhostPost {
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
}

interface GhostResponse {
  posts: GhostPost[];
  meta: {
    pagination: {
      page: number;
      limit: number;
      pages: number;
      total: number;
      next: number | null;
      prev: number | null;
    }
  }
}

class AppLogger {
  static info(message: string, data?: any) {
    console.log(JSON.stringify({
      level: 'INFO',
      timestamp: new Date().toISOString(),
      message,
      data: data || null
    }));
  }

  static error(message: string, error?: any) {
    console.error(JSON.stringify({
      level: 'ERROR',
      timestamp: new Date().toISOString(),
      message,
      error: error ? (error.stack || error.message || error) : null
    }));
  }

  static debug(message: string, data?: any) {
    console.debug(JSON.stringify({
      level: 'DEBUG',
      timestamp: new Date().toISOString(),
      message,
      data: data || null
    }));
  }
}

async function fetchAllPosts(appUrl: string, appKey: string): Promise<GhostPost[]> {
  try {
    AppLogger.info('Starting to fetch all posts from Ghost API');
    let allPosts: GhostPost[] = [];
    let currentPage = 1;
    let hasMorePages = true;

    while (hasMorePages) {
      AppLogger.debug(`Fetching page ${currentPage}`);
      const response = await fetch(
        `${appUrl}/ghost/api/content/posts/?key=${appKey}&include=authors,tags&page=${currentPage}`,
        {
          headers: {
            'Content-Type': 'application/json'
          }
        }
      );

      if (!response.ok) {
        const errorText = await response.text();
        AppLogger.error(`Failed to fetch page ${currentPage}`, {
          status: response.status,
          error: errorText
        });
        throw new Error(`Failed to fetch posts: ${errorText}`);
      }

      const data: GhostResponse = await response.json();
      allPosts = [...allPosts, ...data.posts];

      AppLogger.info(`Fetched page ${currentPage}`, {
        postsInPage: data.posts.length,
        totalPosts: data.meta.pagination.total,
        currentTotal: allPosts.length
      });

      hasMorePages = currentPage < data.meta.pagination.pages;
      currentPage++;
    }

    AppLogger.info(`Successfully fetched all posts`, {
      totalPosts: allPosts.length
    });

    return allPosts;
  } catch (error) {
    AppLogger.error('Error in fetchAllPosts', error);
    throw error;
  }
}

async function processPost(
  post: GhostPost,
  supabaseUrl: string,
  supabaseKey: string,
  requestId: string
): Promise<string> {
  try {
    AppLogger.debug(`Processing post: ${post.title}`, { postId: post.id, requestId });

    // Check if article exists
    const checkResponse = await fetch(
      `${supabaseUrl}/rest/v1/articles?ghost_id=eq.${post.id}`,
      {
        headers: {
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`,
        }
      }
    );

    const existingArticles = await checkResponse.json();
    const exists = existingArticles.length > 0;
    const articleId = exists ? existingArticles[0].id : crypto.randomUUID();

    AppLogger.debug(`Article ${exists ? 'exists' : 'is new'}`, { articleId, ghostId: post.id });

    // Insert or update article
    const method = exists ? 'PATCH' : 'POST';
    const endpoint = exists
      ? `${supabaseUrl}/rest/v1/articles?id=eq.${articleId}`
      : `${supabaseUrl}/rest/v1/articles`;

    const articleData = {
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
    };

    const articleResponse = await fetch(endpoint, {
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseKey,
        'Authorization': `Bearer ${supabaseKey}`,
      },
      body: JSON.stringify(articleData)
    });

    if (!articleResponse.ok) {
      const errorText = await articleResponse.text();
      AppLogger.error(`Failed to ${exists ? 'update' : 'create'} article`, {
        articleId,
        error: errorText
      });
      throw new Error(errorText);
    }

    // Fetch existing relationships
    const [existingAuthorsResponse, existingTagsResponse] = await Promise.all([
      fetch(`${supabaseUrl}/rest/v1/article_authors?article_id=eq.${articleId}`, {
        headers: {
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`,
        }
      }),
      fetch(`${supabaseUrl}/rest/v1/article_tags?article_id=eq.${articleId}`, {
        headers: {
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`,
        }
      })
    ]);

    const existingAuthors = await existingAuthorsResponse.json();
    const existingTags = await existingTagsResponse.json();

    // Filter authors and tags to create
    const newAuthors = post.authors.filter(
      author => !existingAuthors.some(existing => existing.ghost_id === author.id)
    );
    const newTags = post.tags.filter(
      tag => !existingTags.some(existing => existing.ghost_id === tag.id)
    );

    // Create relationships for new authors and tags
    const relationshipPromises = [
      ...newAuthors.map(author =>
        fetch(`${supabaseUrl}/rest/v1/article_authors`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseKey,
            'Authorization': `Bearer ${supabaseKey}`,
          },
          body: JSON.stringify({
            id: crypto.randomUUID(),
            article_id: articleId,
            ghost_id: author.id,
            name: author.name,
            slug: author.slug,
            email: author.email,
            profile_image: author.profile_image
          })
        })
      ),
      ...newTags.map(tag =>
        fetch(`${supabaseUrl}/rest/v1/article_tags`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseKey,
            'Authorization': `Bearer ${supabaseKey}`,
          },
          body: JSON.stringify({
            id: crypto.randomUUID(),
            article_id: articleId,
            ghost_id: tag.id,
            name: tag.name,
            slug: tag.slug,
            description: tag.description
          })
        })
      )
    ];

    await Promise.all(relationshipPromises);
    AppLogger.info(`Successfully processed article`, { articleId, title: post.title });

    return articleId;
  } catch (error) {
    AppLogger.error(`Failed to process post`, { postId: post.id, error });
    throw error;
  }
}


serve(async (req) => {
  const requestId = crypto.randomUUID();
  AppLogger.info(`Starting Ghost sync`, { requestId });

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const appUrl = Deno.env.get('APP_URL');
  const appKey = Deno.env.get('APP_KEY');

  if (!supabaseUrl || !supabaseKey || !appUrl || !appKey) {
    AppLogger.error('Missing required environment variables');
    return new Response(JSON.stringify({
      success: false,
      error: 'Missing required environment variables'
    }), {
      headers: { "Content-Type": "application/json" },
      status: 500
    });
  }

  try {
    const posts = await fetchAllPosts(appUrl, appKey);
    const processed: string[] = [];

    AppLogger.info(`Starting to process ${posts.length} posts`, { requestId });

    for (const post of posts) {
      const articleId = await processPost(
        post,
        supabaseUrl,
        supabaseKey,
        requestId
      );
      processed.push(articleId);
    }

    AppLogger.info(`Ghost sync completed successfully`, {
      requestId,
      processedCount: processed.length,
      totalPosts: posts.length
    });

    return new Response(JSON.stringify({
      success: true,
      message: `Processed ${processed.length} articles`,
      processed: processed
    }), {
      headers: { "Content-Type": "application/json" },
      status: 200
    });

  } catch (error) {
    AppLogger.error(`Ghost sync failed`, { requestId, error });

    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      headers: { "Content-Type": "application/json" },
      status: 500
    });
  }
});