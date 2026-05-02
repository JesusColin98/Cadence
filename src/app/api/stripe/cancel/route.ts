// FILE: src/app/api/stripe/cancel/route.ts
import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import Stripe from "stripe";
import { isStripeConfigured, stripe } from "@/lib/stripe";
import { assertSupabaseConfig } from "@/lib/supabase/config";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { createSupabaseAdminClient } from "@/lib/supabase/admin";

export async function POST(request: Request) {
  try {
    const payload = (await request.json().catch(() => null)) as
      | { action?: string }
      | null;
    const action = payload?.action;

    if (action !== "cancel" && action !== "resume") {
      return NextResponse.json(
        { error: "Invalid subscription action." },
        { status: 400 },
      );
    }

    if (!isStripeConfigured()) {
      return NextResponse.json(
        { error: "Stripe billing is not configured yet." },
        { status: 503 },
      );
    }

    const {
      user,
      error: userError,
    } = await getAuthenticatedUser(request);

    if (userError) {
      throw userError;
    }

    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const meta = (user.user_metadata ?? {}) as Record<string, unknown>;
    const subscriptionId = meta.stripe_subscription_id as string | undefined;

    if (!subscriptionId) {
      return NextResponse.json(
        { error: "No active subscription found." },
        { status: 400 },
      );
    }

    const updated = await stripe.subscriptions.update(subscriptionId, {
      cancel_at_period_end: action === "cancel",
    });

    let metadataSynced = true;

    try {
      // Sync state back to user metadata immediately instead of waiting for the webhook.
      const admin = createSupabaseAdminClient();
      const { data, error: adminReadError } = await admin.auth.admin.getUserById(
        user.id,
      );

      if (adminReadError) {
        throw adminReadError;
      }

      const existing = (data?.user?.user_metadata ?? {}) as Record<string, unknown>;
      const { error: adminUpdateError } = await admin.auth.admin.updateUserById(
        user.id,
        {
          user_metadata: {
            ...existing,
            stripe_cancel_at_period_end: updated.cancel_at_period_end,
            stripe_cancel_at: updated.cancel_at
              ? new Date(updated.cancel_at * 1000).toISOString()
              : null,
          },
        },
      );

      if (adminUpdateError) {
        throw adminUpdateError;
      }
    } catch (metadataError) {
      metadataSynced = false;
      console.error("Stripe subscription metadata sync error:", metadataError);
    }

    return NextResponse.json({
      cancel_at_period_end: updated.cancel_at_period_end,
      cancel_at: updated.cancel_at,
      metadataSynced,
    });
  } catch (err) {
    console.error("Stripe cancel error:", err);
    return NextResponse.json(
      { error: getSubscriptionUpdateErrorMessage(err) },
      { status: 500 },
    );
  }
}

function getSubscriptionUpdateErrorMessage(error: unknown) {
  if (error instanceof Stripe.errors.StripeError) {
    return error.message;
  }

  if (error instanceof Error && error.message.trim()) {
    return error.message;
  }

  return "Failed to update subscription.";
}

async function getAuthenticatedUser(request: Request) {
  const accessToken = getBearerToken(request);

  if (accessToken) {
    const { supabaseUrl, supabasePublishableKey } = assertSupabaseConfig();
    const supabase = createClient(supabaseUrl, supabasePublishableKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });
    const {
      data: { user },
      error,
    } = await supabase.auth.getUser(accessToken);

    return { user, error };
  }

  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  return { user, error };
}

function getBearerToken(request: Request) {
  const header = request.headers.get("authorization");
  if (!header?.startsWith("Bearer ")) {
    return null;
  }

  const token = header.slice("Bearer ".length).trim();
  return token || null;
}
