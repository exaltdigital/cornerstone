// =============================================================
//  EXALT DIGITAL — CONFIGURATION
//  This is the only file you need to edit for the frontend.
//  Fill in each value below. Comments tell you where to find
//  each one.
//
//  For backend secrets (Google Ads, Stripe secret key, etc.)
//  see supabase/.env.example — those are set in the
//  Supabase dashboard under Project Settings → Edge Functions.
// =============================================================

window.ExaltConfig = {

  // ── Supabase ───────────────────────────────────────────────
  // Find at: supabase.com/dashboard → your project → Settings → API
  supabase: {
    url:     'https://gczopudgxfciatvtxhll.supabase.co',    // ← already correct
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdjem9wdWRneGZjaWF0dnR4aGxsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5NzgwMzgsImV4cCI6MjA5MTU1NDAzOH0.Qc4hAZ0AqFAgNcPcRkNk2SUvs4uR2hwk9m2JeZ7lIV0', // ← already correct
  },

  // ── Stripe monthly plan payment links ─────────────────────
  // Create at: dashboard.stripe.com/payment-links
  // Set each as a RECURRING MONTHLY subscription in AUD.
  // Important: enable "Allow customers to adjust quantity" = OFF
  // After creating each link paste the full URL below.
  stripe: {
    plan100: 'https://buy.stripe.com/cNi6oI9WweIJ1utd8x67S01',   // Starter   — A$100/month
    plan200: 'https://buy.stripe.com/dRm4gA7Oo5897SR8Sh67S02',   // Growth    — A$200/month
    plan400: 'https://buy.stripe.com/5kQ8wQ1q07ghgpn7Od67S03',   // Pro       — A$400/month
    plan700:  'https://buy.stripe.com/9B66oI5GgdEFc979Wl67S06',    // Abundant   — A$700/month
    plan1300: 'https://buy.stripe.com/fZu14o6Kk7ghehf6K967S05',    // Sovereign  — A$1,300/month
  },

}
