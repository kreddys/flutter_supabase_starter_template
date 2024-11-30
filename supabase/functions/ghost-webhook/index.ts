import { serve } from "https://deno.land/std@0.182.0/http/server.ts";

// UUID generation function
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

// Interface definitions remain the same
interface GhostWebhookPayload {
  post: {
    current: {
      id: string;
      title: string;
      html: string;
      slug: string;
      feature_image: string | null;
      excerpt: string;
      published_at: string;
      primary_author: {
        name: string;
      };
    };
  };
}

interface SupabaseArticle {
  id: string;
  ghost_id: string; // Added to store original Ghost ID
  title: string;
  description: string;
  author: string;
  published_at: string;
  image_url: string;
  html_content: string;
  slug: string;
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  const requestStartTime = performance.now();
  const debugLog: any[] = [];

  function addDebugLog(message: string, data?: any) {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] ${message}`, data || '');
    debugLog.push({ timestamp, message, data });
  }

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    addDebugLog('Received webhook request', {
      method: req.method,
      headers: Object.fromEntries(req.headers.entries())
    });

    const payload = await req.json() as GhostWebhookPayload;
    addDebugLog('Parsed webhook payload', payload);

    if (!payload.post?.current) {
      throw new Error('Invalid webhook payload: No post data received');
    }

    const post = payload.post.current;

    // Validate required fields with detailed logging
    const requiredFields = ['id', 'title', 'html', 'slug', 'published_at'];
    const fieldValidation = requiredFields.map(field => ({
      field,
      present: Boolean(post[field]),
      value: post[field]
    }));
    addDebugLog('Field validation results', fieldValidation);

    const missingFields = fieldValidation.filter(f => !f.present).map(f => f.field);
    if (missingFields.length > 0) {
      throw new Error(`Missing required fields: ${missingFields.join(', ')}`);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY');

    if (!supabaseUrl || !supabaseKey) {
      throw new Error('Missing environment variables: SUPABASE_URL or SUPABASE_ANON_KEY');
    }

    // Generate UUID and transform data
    const newUUID = generateUUID();
    addDebugLog('Generated UUID', newUUID);

    const article: SupabaseArticle = {
      id: newUUID,
      ghost_id: post.id, // Store original Ghost ID
      title: post.title,
      description: post.excerpt || '',
      author: post.primary_author?.name || 'Amaravati Chamber',
      published_at: post.published_at,
      image_url: post.feature_image || '',
      html_content: post.html,
      slug: post.slug,
    };

    addDebugLog('Transformed article data', article);

    // Insert/update article in Supabase
    const response = await fetch(`${supabaseUrl}/rest/v1/articles`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseKey,
        'Authorization': `Bearer ${supabaseKey}`,
        'Prefer': 'resolution=merge-duplicates'
      },
      body: JSON.stringify(article)
    });

    const responseText = await response.text();
    addDebugLog('Supabase API response', {
      status: response.status,
      statusText: response.statusText,
      body: responseText
    });

    if (!response.ok) {
      throw new Error(`Failed to insert/update article: ${responseText}`);
    }

    const requestDuration = performance.now() - requestStartTime;
    addDebugLog('Request completed', {
      duration: `${requestDuration.toFixed(2)}ms`,
      success: true
    });

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Article synced successfully',
        articleId: article.id,
        ghostId: article.ghost_id,
        debug: debugLog,
        duration: requestDuration
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    );

  } catch (error) {
    const requestDuration = performance.now() - requestStartTime;
    addDebugLog('Error processing webhook', {
      error: error.message,
      stack: error.stack,
      duration: `${requestDuration.toFixed(2)}ms`
    });

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
        debug: debugLog,
        duration: requestDuration,
        timestamp: new Date().toISOString()
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: error.message.includes('Invalid webhook payload') ? 400 : 500
      }
    );
  }
});