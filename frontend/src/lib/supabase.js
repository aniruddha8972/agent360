/**
 * AGENT360.IN — Supabase Client
 * ─────────────────────────────────────────────
 * Replace SUPABASE_URL and SUPABASE_ANON_KEY with
 * your project values from:
 *   https://supabase.com → Settings → API
 * ─────────────────────────────────────────────
 */

const SUPABASE_URL      = 'YOUR_SUPABASE_URL';       // e.g. https://xyzabcdef.supabase.co
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';  // starts with eyJ...

let _supa = null;

function getSupabase() {
  if (_supa) return _supa;
  try {
    if (SUPABASE_URL === 'YOUR_SUPABASE_URL') {
      console.warn('[Agent360] Supabase not configured — running in demo mode. Edit frontend/src/lib/supabase.js to connect.');
      return null;
    }
    _supa = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    return _supa;
  } catch (e) {
    console.error('[Agent360] Supabase init failed:', e);
    return null;
  }
}

// ── DATABASE HELPERS ──────────────────────────

const DB = {

  // Auth
  async signUp(email, password, fullName) {
    const db = getSupabase();
    if (!db) return { demo: true };
    const { data, error } = await db.auth.signUp({
      email, password,
      options: { data: { full_name: fullName } }
    });
    if (error) throw error;
    // Upsert profile row (trigger also does this, belt+suspenders)
    if (data.user) {
      await db.from('investors').upsert({
        id: data.user.id,
        email,
        full_name: fullName,
        created_at: new Date().toISOString()
      }, { onConflict: 'id' });
    }
    return data;
  },

  async signIn(email, password) {
    const db = getSupabase();
    if (!db) return { demo: true };
    const { data, error } = await db.auth.signInWithPassword({ email, password });
    if (error) throw error;
    return data;
  },

  async signOut() {
    const db = getSupabase();
    if (!db) return;
    await db.auth.signOut();
  },

  async getSession() {
    const db = getSupabase();
    if (!db) return null;
    const { data } = await db.auth.getSession();
    return data.session;
  },

  // Newsletter
  async subscribe(email) {
    const db = getSupabase();
    if (!db) return { demo: true };
    const { error } = await db.from('newsletter').upsert(
      { email, subscribed_at: new Date().toISOString(), is_active: true },
      { onConflict: 'email' }
    );
    if (error) throw error;
    return { ok: true };
  },

  // Properties
  async getProperties(filters = {}) {
    const db = getSupabase();
    if (!db) return null;
    let q = db.from('properties').select('*').eq('status', 'funding');
    if (filters.city)  q = q.eq('city', filters.city);
    if (filters.type)  q = q.eq('property_type', filters.type);
    if (filters.limit) q = q.limit(filters.limit);
    const { data, error } = await q.order('featured', { ascending: false });
    if (error) throw error;
    return data;
  },

  // Holdings (portfolio)
  async getHoldings(investorId) {
    const db = getSupabase();
    if (!db) return null;
    const { data, error } = await db
      .from('holdings')
      .select('*, properties(name, city, state, property_type, expected_yield)')
      .eq('investor_id', investorId)
      .eq('status', 'active');
    if (error) throw error;
    return data;
  },

  // Transactions
  async getTransactions(investorId, limit = 20) {
    const db = getSupabase();
    if (!db) return null;
    const { data, error } = await db
      .from('transactions')
      .select('*, properties(name, city)')
      .eq('investor_id', investorId)
      .order('transaction_date', { ascending: false })
      .limit(limit);
    if (error) throw error;
    return data;
  },

  // Watchlist
  async addToWatchlist(investorId, propertyId) {
    const db = getSupabase();
    if (!db) return { demo: true };
    const { error } = await db.from('watchlist').upsert(
      { investor_id: investorId, property_id: propertyId },
      { onConflict: 'investor_id,property_id' }
    );
    if (error) throw error;
    return { ok: true };
  },

  // Lead / contact
  async submitLead(name, email, phone, message) {
    const db = getSupabase();
    if (!db) return { demo: true };
    const { error } = await db.from('leads').insert({
      name, email, phone, message, source: 'website', created_at: new Date().toISOString()
    });
    if (error) throw error;
    return { ok: true };
  }
};
