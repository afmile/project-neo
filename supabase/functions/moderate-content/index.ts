// =============================================================================
// AI Sentinel - Automatic Content Moderation Edge Function
// Phase 2: OpenAI Integration for Real-Time Content Analysis
// =============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// =============================================================================
// TYPES
// =============================================================================

interface ModerationRequest {
    content: string;
    author_id: string;
    entity_id: string;
    entity_type: "post" | "comment";
    community_id: string;
}

interface OpenAIModerationResponse {
    id: string;
    model: string;
    results: Array<{
        flagged: boolean;
        categories: {
            hate: boolean;
            "hate/threatening": boolean;
            harassment: boolean;
            "harassment/threatening": boolean;
            "self-harm": boolean;
            "self-harm/intent": boolean;
            "self-harm/instructions": boolean;
            sexual: boolean;
            "sexual/minors": boolean;
            violence: boolean;
            "violence/graphic": boolean;
        };
        category_scores: Record<string, number>;
    }>;
}

// =============================================================================
// CORS HEADERS
// =============================================================================

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
};

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

/**
 * Determines priority level based on flagged categories
 */
function getPriority(categories: Record<string, boolean>): "critical" | "high" {
    const criticalCategories = [
        "violence",
        "violence/graphic",
        "self-harm",
        "self-harm/intent",
        "self-harm/instructions",
    ];

    const hasCritical = Object.keys(categories).some(
        (key) => criticalCategories.includes(key) && categories[key]
    );

    return hasCritical ? "critical" : "high";
}

/**
 * Extracts human-readable category names from flagged results
 */
function extractFlaggedCategories(
    categories: Record<string, boolean>
): string[] {
    return Object.entries(categories)
        .filter(([_, flagged]) => flagged)
        .map(([category, _]) => category);
}

/**
 * Formats reason text for the report
 */
function formatReason(categories: string[]): string {
    if (categories.length === 0) return "AI Detection: Unspecified violation";
    return `AI Detection: ${categories.join(", ")}`;
}

/**
 * Calls OpenAI Moderation API
 */
async function moderateContent(
    content: string,
    openaiKey: string
): Promise<OpenAIModerationResponse> {
    const response = await fetch("https://api.openai.com/v1/moderations", {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${openaiKey}`,
        },
        body: JSON.stringify({ input: content }),
    });

    if (!response.ok) {
        const error = await response.text();
        throw new Error(`OpenAI API error: ${response.status} - ${error}`);
    }

    return await response.json();
}

/**
 * Creates a system report in the database
 */
async function createSystemReport(
    supabase: any,
    payload: ModerationRequest,
    flaggedCategories: string[],
    priority: "critical" | "high"
) {
    const reportData = {
        community_id: payload.community_id,
        reporter_id: null, // NULL = System/AI Report
        accused_id: payload.author_id,
        post_id: payload.entity_type === "post" ? payload.entity_id : null,
        comment_id: payload.entity_type === "comment" ? payload.entity_id : null,
        reason: formatReason(flaggedCategories),
        description: `Automatic AI moderation flagged this ${payload.entity_type} for: ${flaggedCategories.join(", ")}`,
        priority: priority,
        status: "pending",
    };

    const { data, error } = await supabase
        .from("community_reports")
        .insert([reportData])
        .select();

    if (error) {
        throw new Error(`Database error: ${error.message}`);
    }

    return data[0];
}

// =============================================================================
// MAIN HANDLER
// =============================================================================

serve(async (req: Request) => {
    // Handle CORS preflight
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        // Validate request method
        if (req.method !== "POST") {
            return new Response(
                JSON.stringify({ error: "Method not allowed" }),
                {
                    status: 405,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
            );
        }

        // Parse request body
        const payload: ModerationRequest = await req.json();

        // Validate required fields
        const requiredFields = [
            "content",
            "author_id",
            "entity_id",
            "entity_type",
            "community_id",
        ];
        const missingFields = requiredFields.filter(
            (field) => !(field in payload)
        );

        if (missingFields.length > 0) {
            return new Response(
                JSON.stringify({
                    error: "Missing required fields",
                    missing: missingFields,
                }),
                {
                    status: 400,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
            );
        }

        // Validate entity_type
        if (!["post", "comment"].includes(payload.entity_type)) {
            return new Response(
                JSON.stringify({ error: "Invalid entity_type. Must be 'post' or 'comment'" }),
                {
                    status: 400,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
            );
        }

        // Get environment variables
        const openaiKey = Deno.env.get("OPENAI_API_KEY");
        const supabaseUrl = Deno.env.get("SUPABASE_URL");
        const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

        if (!openaiKey || !supabaseUrl || !supabaseServiceKey) {
            throw new Error("Missing required environment variables");
        }

        console.log(`[AI Sentinel] Analyzing ${payload.entity_type} ${payload.entity_id}`);

        // Call OpenAI Moderation API
        const moderationResult = await moderateContent(payload.content, openaiKey);
        const result = moderationResult.results[0];

        console.log(`[AI Sentinel] Flagged: ${result.flagged}`);

        // If content is flagged, create a system report
        if (result.flagged) {
            const flaggedCategories = extractFlaggedCategories(result.categories);
            const priority = getPriority(result.categories);

            console.log(
                `[AI Sentinel] Creating ${priority} priority report for categories: ${flaggedCategories.join(", ")}`
            );

            // Initialize Supabase client with service role (bypasses RLS)
            const supabase = createClient(supabaseUrl, supabaseServiceKey, {
                auth: {
                    autoRefreshToken: false,
                    persistSession: false,
                },
            });

            // Create the report
            const report = await createSystemReport(
                supabase,
                payload,
                flaggedCategories,
                priority
            );

            return new Response(
                JSON.stringify({
                    flagged: true,
                    action: "report_created",
                    report_id: report.id,
                    categories: flaggedCategories,
                    priority: priority,
                }),
                {
                    status: 200,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
            );
        } else {
            // Content is clean
            console.log(`[AI Sentinel] Content approved`);

            return new Response(
                JSON.stringify({
                    flagged: false,
                    action: "approved",
                    message: "Content passed moderation",
                }),
                {
                    status: 200,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
            );
        }
    } catch (error) {
        console.error("[AI Sentinel] Error:", error);

        return new Response(
            JSON.stringify({
                error: "Internal server error",
                message: error.message,
            }),
            {
                status: 500,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
        );
    }
});
