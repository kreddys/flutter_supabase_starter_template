import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { cron } from "https://deno.land/x/deno_cron/cron.ts";

// Reuse the same interfaces from ghost-webhook
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

interface SyncResult {
  postId: string;
  success: boolean;
  articleId?: string;
  error?: string;
}

// Reuse the AppLogger class
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

async function upsertAuthors(supabaseUrl: string, supabaseKey: string, authors: GhostAuthor[], requestId: string) {
  const authorPromises = authors.map(async (author) => {
    try {
      AppLogger.debug(`Attempting to upsert author`, {
        requestId,
        authorId: author.id,
        authorData: author
      });

      // First try to update existing record
      const authorResponse = await fetch(`${supabaseUrl}/rest/v1/authors?ghost_id=eq.${author.id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`,
          'Prefer': 'return=representation'
        },
        body: JSON.stringify({
          ghost_id: author.id,
          name: author.name,
          slug: author.slug,
          email: author.email,
          profile_image: author.profile_image
        })
      });

      // Read the response text once and store it
      const responseText = await authorResponse.text();
      let authorData;

      if (authorResponse.ok) {
        try {
          // Try to parse the response text if it's not empty
          authorData = responseText ? JSON.parse(responseText) : null;
        } catch (parseError) {
          AppLogger.error(`Failed to parse author response`, {
            requestId,
            authorId: author.id,
            responseText,
            error: parseError
          });
        }
      }

      // If no existing record found or update returned no content, create new record
      if (!authorData || (Array.isArray(authorData) && authorData.length === 0)) {
        AppLogger.debug(`No existing author found or empty update result, creating new record`, {
          requestId,
          authorId: author.id
        });

        const insertResponse = await fetch(`${supabaseUrl}/rest/v1/authors`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseKey,
            'Authorization': `Bearer ${supabaseKey}`,
            'Prefer': 'return=representation'
          },
          body: JSON.stringify({
            ghost_id: author.id,
            name: author.name,
            slug: author.slug,
            email: author.email,
            profile_image: author.profile_image
          })
        });

        // Read and store the insert response
        const insertResponseText = await insertResponse.text();

        if (!insertResponse.ok) {
          throw new Error(`Failed to insert author (Status ${insertResponse.status}): ${insertResponseText}`);
        }

        try {
          authorData = JSON.parse(insertResponseText);
        } catch (parseError) {
          throw new Error(`Failed to parse insert response: ${parseError.message}`);
        }
      }

      // Validate the final author data
      if (!Array.isArray(authorData) || authorData.length === 0) {
        throw new Error(`Invalid author response format. Received: ${JSON.stringify(authorData)}`);
      }

      AppLogger.debug(`Successfully upserted author`, {
        requestId,
        authorId: author.id,
        supabaseId: authorData[0].id
      });

      return authorData[0].id;
    } catch (error) {
      AppLogger.error(`Error upserting author`, {
        requestId,
        authorId: author.id,
        error: {
          message: error.message,
          stack: error.stack,
          name: error.name
        }
      });
      throw error;
    }
  });

  try {
    return await Promise.all(authorPromises);
  } catch (error) {
    AppLogger.error(`Failed to upsert authors batch`, {
      requestId,
      error: {
        message: error.message,
        stack: error.stack
      }
    });
    throw error;
  }
}

async function upsertTags(supabaseUrl: string, supabaseKey: string, tags: GhostTag[], requestId: string) {
  const tagPromises = tags.map(async (tag) => {
    try {
      AppLogger.debug(`Attempting to upsert tag`, {
        requestId,
        tagId: tag.id,
        tagData: tag
      });

      // First try to update existing record
      const tagResponse = await fetch(`${supabaseUrl}/rest/v1/tags?ghost_id=eq.${tag.id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`,
          'Prefer': 'return=representation'
        },
        body: JSON.stringify({
          ghost_id: tag.id,
          name: tag.name,
          slug: tag.slug,
          description: tag.description
        })
      });

      // Read the response text once and store it
      const responseText = await tagResponse.text();
      let tagData;

      if (tagResponse.ok) {
        try {
          // Try to parse the response text if it's not empty
          tagData = responseText ? JSON.parse(responseText) : null;
        } catch (parseError) {
          AppLogger.error(`Failed to parse tag response`, {
            requestId,
            tagId: tag.id,
            responseText,
            error: parseError
          });
        }
      }

      // If no existing record found or update returned no content, create new record
      if (!tagData || (Array.isArray(tagData) && tagData.length === 0)) {
        AppLogger.debug(`No existing tag found or empty update result, creating new record`, {
          requestId,
          tagId: tag.id
        });

        const insertResponse = await fetch(`${supabaseUrl}/rest/v1/tags`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseKey,
            'Authorization': `Bearer ${supabaseKey}`,
            'Prefer': 'return=representation'
          },
          body: JSON.stringify({
            ghost_id: tag.id,
            name: tag.name,
            slug: tag.slug,
            description: tag.description
          })
        });

        // Read and store the insert response
        const insertResponseText = await insertResponse.text();

        if (!insertResponse.ok) {
          throw new Error(`Failed to insert tag (Status ${insertResponse.status}): ${insertResponseText}`);
        }

        try {
          tagData = JSON.parse(insertResponseText);
        } catch (parseError) {
          throw new Error(`Failed to parse insert response: ${parseError.message}`);
        }
      }

      // Validate the final tag data
      if (!Array.isArray(tagData) || tagData.length === 0) {
        throw new Error(`Invalid tag response format. Received: ${JSON.stringify(tagData)}`);
      }

      AppLogger.debug(`Successfully upserted tag`, {
        requestId,
        tagId: tag.id,
        supabaseId: tagData[0].id
      });

      return tagData[0].id;
    } catch (error) {
      AppLogger.error(`Error upserting tag`, {
        requestId,
        tagId: tag.id,
        error: {
          message: error.message,
          stack: error.stack,
          name: error.name
        }
      });
      throw error;
    }
  });

  try {
    return await Promise.all(tagPromises);
  } catch (error) {
    AppLogger.error(`Failed to upsert tags batch`, {
      requestId,
      error: {
        message: error.message,
        stack: error.stack
      }
    });
    throw error;
  }
}

async function createArticleRelations(
  supabaseUrl: string, 
  supabaseKey: string, 
  articleId: string, 
  authorIds: string[], 
  tagIds: string[], 
  requestId: string
) {
  try {
    // First, delete existing relations
    await fetch(`${supabaseUrl}/rest/v1/article_authors?article_id=eq.${articleId}`, {
      method: 'DELETE',
      headers: {
        'apikey': supabaseKey,
        'Authorization': `Bearer ${supabaseKey}`
      }
    });

    await fetch(`${supabaseUrl}/rest/v1/article_tags?article_id=eq.${articleId}`, {
      method: 'DELETE',
      headers: {
        'apikey': supabaseKey,
        'Authorization': `Bearer ${supabaseKey}`
      }
    });

    // Create new author relations
    const authorRelations = authorIds.map(authorId => ({
      article_id: articleId,
      author_id: authorId
    }));

    if (authorRelations.length > 0) {
      const authorRelationResponse = await fetch(`${supabaseUrl}/rest/v1/article_authors`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`
        },
        body: JSON.stringify(authorRelations)
      });

      if (!authorRelationResponse.ok) {
        throw new Error(`Failed to create author relations: ${await authorRelationResponse.text()}`);
      }
    }

    // Create new tag relations
    const tagRelations = tagIds.map(tagId => ({
      article_id: articleId,
      tag_id: tagId
    }));

    if (tagRelations.length > 0) {
      const tagRelationResponse = await fetch(`${supabaseUrl}/rest/v1/article_tags`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`
        },
        body: JSON.stringify(tagRelations)
      });

      if (!tagRelationResponse.ok) {
        throw new Error(`Failed to create tag relations: ${await tagRelationResponse.text()}`);
      }
    }
  } catch (error) {
    AppLogger.error(`Error creating article relations`, { requestId, articleId, error });
    throw error;
  }
}

async function processPost(supabaseUrl: string, supabaseKey: string, post: GhostPost, requestId: string) {
  try {
    // 1. Insert/Update Authors
    const authorIds = await upsertAuthors(supabaseUrl, supabaseKey, post.authors, requestId);

    // 2. Insert/Update Tags
    const tagIds = await upsertTags(supabaseUrl, supabaseKey, post.tags, requestId);

    // 3. Insert/Update Article
    const articleResponse = await fetch(`${supabaseUrl}/rest/v1/articles`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseKey,
        'Authorization': `Bearer ${supabaseKey}`,
        'Prefer': 'return=representation',
      },
      body: JSON.stringify({
        ghost_id: post.id,
        title: post.title,
        description: post.custom_excerpt || post.plaintext?.substring(0, 200) || '',
        html_content: post.html,
        published_at: post.published_at,
        image_url: post.feature_image,
        slug: post.slug,
        created_at: post.created_at,
        updated_at: post.updated_at
      }),
    });

    let articleData: any[];

    if (articleResponse.status === 409) {
      AppLogger.info(`Article with ghost_id ${post.id} already exists, updating instead`);
      
      const updateResponse = await fetch(
        `${supabaseUrl}/rest/v1/articles?ghost_id=eq.${post.id}`,
        {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseKey,
            'Authorization': `Bearer ${supabaseKey}`,
            'Prefer': 'return=representation',
          },
          body: JSON.stringify({
            title: post.title,
            description: post.custom_excerpt || post.plaintext?.substring(0, 200) || '',
            html_content: post.html,
            published_at: post.published_at,
            image_url: post.feature_image,
            slug: post.slug,
            updated_at: post.updated_at
          }),
        }
      );

      if (!updateResponse.ok) {
        const updateResponseText = await updateResponse.text();
        throw new Error(`Failed to update article (Status ${updateResponse.status}): ${updateResponseText}`);
      }

      const updateResponseText = await updateResponse.text();
      try {
        articleData = JSON.parse(updateResponseText);
      } catch (parseError) {
        throw new Error(`Failed to parse update response: ${parseError.message}`);
      }
    } else {
      if (!articleResponse.ok) {
        const articleResponseText = await articleResponse.text();
        throw new Error(`Failed to insert article (Status ${articleResponse.status}): ${articleResponseText}`);
      }

      const articleResponseText = await articleResponse.text();
      try {
        articleData = JSON.parse(articleResponseText);
      } catch (parseError) {
        throw new Error(`Failed to parse insert response: ${parseError.message}`);
      }
    }

    if (!Array.isArray(articleData) || articleData.length === 0) {
      throw new Error(`Invalid article response format. Expected array with data`);
    }

    const articleId = articleData[0].id;

    // 4. Create relations
    await createArticleRelations(supabaseUrl, supabaseKey, articleId, authorIds, tagIds, requestId);

    return articleId;
  } catch (error) {
    AppLogger.error(`Error processing post`, {
      requestId,
      postId: post.id,
      error: {
        message: error.message,
        stack: error.stack,
        name: error.name
      }
    });
    throw error;
  }
}

async function performSync() {
  const requestId = crypto.randomUUID();
  AppLogger.info(`Starting scheduled sync`, { requestId });

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const ghostUrl = Deno.env.get('GHOST_URL');
  const ghostKey = Deno.env.get('GHOST_KEY');

  if (!supabaseUrl || !supabaseKey || !ghostUrl || !ghostKey) {
    AppLogger.error(`Environment variables missing`, { requestId });
    return;
  }

  try {
    // Fetch posts from Ghost API
    const ghostApiUrl = `${ghostUrl}/ghost/api/content/posts/?key=${ghostKey}&include=authors,tags&formats=html,plaintext&limit=all`;
    const ghostResponse = await fetch(ghostApiUrl);

    if (!ghostResponse.ok) {
      throw new Error(`Failed to fetch posts from Ghost: ${ghostResponse.statusText}`);
    }

    const ghostData = await ghostResponse.json();
    const posts = ghostData.posts as GhostPost[];

    AppLogger.info(`Fetched ${posts.length} posts from Ghost`, { requestId });

    // Process each post
    const results: SyncResult[] = [];
    for (const post of posts) {
      try {
        const articleId = await processPost(supabaseUrl, supabaseKey, post, requestId);
        results.push({ postId: post.id, success: true, articleId });
      } catch (error) {
        results.push({ postId: post.id, success: false, error: error.message });
        // Continue processing other posts even if one fails
        continue;
      }
    }

    AppLogger.info(`Sync completed`, { requestId, results });
  } catch (error) {
    AppLogger.error(`Error processing sync`, { 
      requestId, 
      error: {
        message: error.message,
        stack: error.stack,
        name: error.name
      }
    });
  }
}

// Schedule the sync to run every hour
cron("0 * * * *", async () => {
  try {
    await performSync();
  } catch (error) {
    AppLogger.error("Scheduled sync failed", { error });
  }
});

serve(async (req) => {
  try {
    await performSync();
    return new Response(JSON.stringify({
      success: true,
      message: 'Sync triggered successfully'
    }), {
      headers: { "Content-Type": "application/json" },
      status: 200
    });
  } catch (error) {
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      headers: { "Content-Type": "application/json" },
      status: 500
    });
  }
});