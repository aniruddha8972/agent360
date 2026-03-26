-- ═══════════════════════════════════════════════════════════════════
-- AGENT360.IN — SUPABASE SCHEMA
-- Real Estate Investment Platform
--
-- HOW TO USE:
-- 1. Go to https://supabase.com → your project → SQL Editor
-- 2. Paste this entire file and click Run
-- ═══════════════════════════════════════════════════════════════════

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ──────────────────────────────────────────────────────────────────
-- TABLE 1: INVESTORS (user profiles — linked to Supabase Auth)
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS investors (
  id              UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name       TEXT,
  email           TEXT UNIQUE NOT NULL,
  phone           TEXT,
  pan_number      TEXT,
  aadhaar_last4   TEXT,
  kyc_status      TEXT DEFAULT 'pending'
                  CHECK (kyc_status IN ('pending','submitted','verified','rejected')),
  risk_profile    TEXT DEFAULT 'moderate'
                  CHECK (risk_profile IN ('conservative','moderate','aggressive')),
  bank_account    TEXT,
  ifsc_code       TEXT,
  bank_name       TEXT,
  is_nri          BOOLEAN DEFAULT false,
  country         TEXT DEFAULT 'IN',
  referral_code   TEXT UNIQUE DEFAULT SUBSTR(MD5(RANDOM()::TEXT), 1, 8),
  referred_by     TEXT,
  total_invested  NUMERIC(15,2) DEFAULT 0,
  wallet_balance  NUMERIC(15,2) DEFAULT 0,
  avatar_url      TEXT,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- ──────────────────────────────────────────────────────────────────
-- TABLE 2: PROPERTIES (all investment listings)
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS properties (
  id                    UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name                  TEXT NOT NULL,
  slug                  TEXT UNIQUE NOT NULL,
  city                  TEXT NOT NULL,
  state                 TEXT NOT NULL,
  address               TEXT,
  pincode               TEXT,
  property_type         TEXT NOT NULL
                        CHECK (property_type IN ('commercial','residential','mixed','reit','warehouse','hospitality')),
  status                TEXT DEFAULT 'funding'
                        CHECK (status IN ('coming_soon','funding','fully_funded','active','exited')),

  -- Financials
  total_value           NUMERIC(15,2) NOT NULL,
  funded_amount         NUMERIC(15,2) DEFAULT 0,
  min_investment        NUMERIC(10,2) NOT NULL DEFAULT 5000,
  max_investment        NUMERIC(15,2),
  expected_yield        NUMERIC(6,3),          -- annual rental yield %
  expected_appreciation NUMERIC(6,3),          -- annual capital appreciation %
  total_return_target   NUMERIC(6,3),          -- combined IRR target %
  lock_in_years         INTEGER DEFAULT 3,

  -- Property details
  total_area_sqft       NUMERIC(10,2),
  current_occupancy     NUMERIC(5,2) DEFAULT 100,
  tenant_name           TEXT,
  lease_expiry          DATE,
  developer_name        TEXT,
  rera_number           TEXT,
  sebi_registered       BOOLEAN DEFAULT true,

  -- Units
  total_units           INTEGER,
  available_units       INTEGER,
  unit_price            NUMERIC(12,4),

  -- Media
  cover_image_url       TEXT,
  gallery_urls          TEXT[],

  -- Content
  description           TEXT,
  highlights            JSONB,
  documents_url         TEXT,
  faqs                  JSONB,

  -- Display
  featured              BOOLEAN DEFAULT false,
  badge                 TEXT CHECK (badge IN ('hot','new','closing_soon','featured', NULL)),

  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

-- ──────────────────────────────────────────────────────────────────
-- TABLE 3: HOLDINGS (investor → property ownership)
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS holdings (
  id                    UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  investor_id           UUID REFERENCES investors(id) ON DELETE CASCADE,
  property_id           UUID REFERENCES properties(id),
  units_owned           NUMERIC(15,6) NOT NULL,
  amount_invested       NUMERIC(15,2) NOT NULL,
  price_per_unit        NUMERIC(12,4),
  current_value         NUMERIC(15,2),
  ownership_pct         NUMERIC(8,6),          -- % of total property owned
  total_rental_received NUMERIC(15,2) DEFAULT 0,
  pnl                   NUMERIC(15,2) DEFAULT 0,
  pnl_pct               NUMERIC(8,4) DEFAULT 0,
  status                TEXT DEFAULT 'active'
                        CHECK (status IN ('active','exited','locked')),
  invested_at           TIMESTAMPTZ DEFAULT now(),
  exited_at             TIMESTAMPTZ,
  exit_value            NUMERIC(15,2),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

-- ──────────────────────────────────────────────────────────────────
-- TABLE 4: TRANSACTIONS (all money movements)
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
  id               UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  investor_id      UUID REFERENCES investors(id) ON DELETE CASCADE,
  property_id      UUID REFERENCES properties(id),
  holding_id       UUID REFERENCES holdings(id),
  type             TEXT NOT NULL
                   CHECK (type IN ('investment','rental_income','withdrawal','refund','bonus','wallet_topup')),
  amount           NUMERIC(15,2) NOT NULL,
  units            NUMERIC(15,6),
  price_per_unit   NUMERIC(12,4),
  status           TEXT DEFAULT 'completed'
                   CHECK (status IN ('pending','processing','completed','failed','cancelled')),
  payment_method   TEXT,
  payment_ref      TEXT,
  gateway_ref      TEXT,
  notes            TEXT,
  transaction_date TIMESTAMPTZ DEFAULT now()
);

-- ──────────────────────────────────────────────────────────────────
-- TABLE 5: RENTAL PAYOUTS (monthly distribution ledger)
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS rental_payouts (
  id                    UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  property_id           UUID REFERENCES properties(id),
  payout_month          DATE NOT NULL,
  total_rent_collected  NUMERIC(15,2),
  platform_fee          NUMERIC(15,2),
  net_rent              NUMERIC(15,2),
  per_unit_payout       NUMERIC(12,6),
  total_investors_paid  INTEGER,
  status                TEXT DEFAULT 'scheduled'
                        CHECK (status IN ('scheduled','processing','paid','failed')),
  paid_at               TIMESTAMPTZ,
  notes                 TEXT,
  created_at            TIMESTAMPTZ DEFAULT now(),
  UNIQUE(property_id, payout_month)
);

-- ──────────────────────────────────────────────────────────────────
-- TABLE 6: KYC DOCUMENTS
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS kyc_documents (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  investor_id     UUID REFERENCES investors(id) ON DELETE CASCADE,
  doc_type        TEXT NOT NULL CHECK (doc_type IN ('pan','aadhaar_front','aadhaar_back','selfie','bank_statement','cancelled_cheque')),
  file_url        TEXT NOT NULL,
  verified        BOOLEAN DEFAULT false,
  verified_by     TEXT,
  verified_at     TIMESTAMPTZ,
  rejection_note  TEXT,
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- ──────────────────────────────────────────────────────────────────
-- TABLE 7: NEWSLETTER SUBSCRIBERS
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS newsletter (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email           TEXT UNIQUE NOT NULL,
  name            TEXT,
  is_active       BOOLEAN DEFAULT true,
  source          TEXT DEFAULT 'website',
  tags            TEXT[],
  subscribed_at   TIMESTAMPTZ DEFAULT now(),
  unsubscribed_at TIMESTAMPTZ
);

-- ──────────────────────────────────────────────────────────────────
-- TABLE 8: WATCHLIST
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS watchlist (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  investor_id UUID REFERENCES investors(id) ON DELETE CASCADE,
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  added_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE(investor_id, property_id)
);

-- ──────────────────────────────────────────────────────────────────
-- TABLE 9: BLOG POSTS (CMS for Market Insights)
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS blog_posts (
  id               UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  slug             TEXT UNIQUE NOT NULL,
  title            TEXT NOT NULL,
  excerpt          TEXT,
  content          TEXT,
  cover_image_url  TEXT,
  author_name      TEXT,
  author_bio       TEXT,
  category         TEXT CHECK (category IN ('beginner','market','tax','news','nri','legal')),
  tags             TEXT[],
  read_time_mins   INTEGER,
  published        BOOLEAN DEFAULT false,
  published_at     TIMESTAMPTZ,
  seo_title        TEXT,
  seo_description  TEXT,
  seo_keywords     TEXT,
  views            INTEGER DEFAULT 0,
  created_at       TIMESTAMPTZ DEFAULT now(),
  updated_at       TIMESTAMPTZ DEFAULT now()
);

-- ──────────────────────────────────────────────────────────────────
-- TABLE 10: CONTACT / SALES LEADS
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS leads (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name        TEXT,
  email       TEXT NOT NULL,
  phone       TEXT,
  city        TEXT,
  message     TEXT,
  source      TEXT DEFAULT 'website',
  utm_source  TEXT,
  utm_medium  TEXT,
  utm_campaign TEXT,
  status      TEXT DEFAULT 'new'
              CHECK (status IN ('new','contacted','qualified','converted','closed')),
  assigned_to TEXT,
  notes       TEXT,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

-- ──────────────────────────────────────────────────────────────────
-- TABLE 11: NOTIFICATIONS
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  investor_id UUID REFERENCES investors(id) ON DELETE CASCADE,
  type        TEXT NOT NULL,  -- 'rental_paid','kyc_update','new_property','investment_confirmed'
  title       TEXT NOT NULL,
  body        TEXT,
  is_read     BOOLEAN DEFAULT false,
  data        JSONB,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ══════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS)
-- ══════════════════════════════════════════════════════════════════

-- Investors
ALTER TABLE investors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "investor_select_own" ON investors FOR SELECT USING (auth.uid() = id);
CREATE POLICY "investor_insert_own" ON investors FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "investor_update_own" ON investors FOR UPDATE USING (auth.uid() = id);

-- Holdings
ALTER TABLE holdings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "holdings_own" ON holdings USING (auth.uid() = investor_id);

-- Transactions
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "txn_select_own" ON transactions FOR SELECT USING (auth.uid() = investor_id);
CREATE POLICY "txn_insert_own" ON transactions FOR INSERT WITH CHECK (auth.uid() = investor_id);

-- KYC
ALTER TABLE kyc_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "kyc_own" ON kyc_documents USING (auth.uid() = investor_id);

-- Watchlist
ALTER TABLE watchlist ENABLE ROW LEVEL SECURITY;
CREATE POLICY "watchlist_own" ON watchlist USING (auth.uid() = investor_id);

-- Notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notif_own" ON notifications USING (auth.uid() = investor_id);

-- Properties: public readable
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
CREATE POLICY "properties_public_read" ON properties FOR SELECT USING (true);

-- Blog: public readable (published only)
ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "blog_public_read" ON blog_posts FOR SELECT USING (published = true);

-- Rental payouts: public readable
ALTER TABLE rental_payouts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "payouts_public_read" ON rental_payouts FOR SELECT USING (true);

-- Newsletter: public insert only
ALTER TABLE newsletter ENABLE ROW LEVEL SECURITY;
CREATE POLICY "newsletter_insert" ON newsletter FOR INSERT WITH CHECK (true);

-- Leads: public insert only
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
CREATE POLICY "leads_insert" ON leads FOR INSERT WITH CHECK (true);

-- ══════════════════════════════════════════════════════════════════
-- TRIGGERS: auto-timestamps
-- ══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

CREATE TRIGGER t_investors_upd    BEFORE UPDATE ON investors    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER t_properties_upd   BEFORE UPDATE ON properties   FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER t_holdings_upd     BEFORE UPDATE ON holdings     FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER t_blog_upd         BEFORE UPDATE ON blog_posts   FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER t_leads_upd        BEFORE UPDATE ON leads        FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ══════════════════════════════════════════════════════════════════
-- TRIGGER: auto-create investor profile on auth signup
-- ══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION on_auth_user_created()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO investors (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', '')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_new_user ON auth.users;
CREATE TRIGGER on_new_user
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION on_auth_user_created();

-- ══════════════════════════════════════════════════════════════════
-- TRIGGER: update investor total_invested when holding added
-- ══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_investor_total()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE investors
  SET total_invested = (
    SELECT COALESCE(SUM(amount_invested), 0)
    FROM holdings
    WHERE investor_id = NEW.investor_id AND status = 'active'
  )
  WHERE id = NEW.investor_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER t_holding_update_total
  AFTER INSERT OR UPDATE OR DELETE ON holdings
  FOR EACH ROW EXECUTE FUNCTION update_investor_total();

-- ══════════════════════════════════════════════════════════════════
-- INDEXES (performance)
-- ══════════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_holdings_investor    ON holdings(investor_id);
CREATE INDEX IF NOT EXISTS idx_holdings_property    ON holdings(property_id);
CREATE INDEX IF NOT EXISTS idx_holdings_status      ON holdings(status);
CREATE INDEX IF NOT EXISTS idx_txn_investor         ON transactions(investor_id);
CREATE INDEX IF NOT EXISTS idx_txn_date             ON transactions(transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_txn_type             ON transactions(type);
CREATE INDEX IF NOT EXISTS idx_props_status         ON properties(status);
CREATE INDEX IF NOT EXISTS idx_props_city           ON properties(city);
CREATE INDEX IF NOT EXISTS idx_props_featured       ON properties(featured) WHERE featured = true;
CREATE INDEX IF NOT EXISTS idx_blog_published       ON blog_posts(published_at DESC) WHERE published = true;
CREATE INDEX IF NOT EXISTS idx_notif_investor       ON notifications(investor_id, is_read);
CREATE INDEX IF NOT EXISTS idx_payouts_month        ON rental_payouts(payout_month DESC);
CREATE INDEX IF NOT EXISTS idx_watchlist_investor   ON watchlist(investor_id);

-- ══════════════════════════════════════════════════════════════════
-- SEED DATA: Sample properties (remove in production)
-- ══════════════════════════════════════════════════════════════════

INSERT INTO properties (name, slug, city, state, property_type, status, total_value, funded_amount, min_investment, expected_yield, expected_appreciation, total_units, available_units, badge, featured, description)
VALUES
  (
    'DLF Cyber City Tower B',
    'dlf-cyber-city-gurugram',
    'Gurugram', 'Haryana', 'commercial', 'funding',
    480000000, 417600000, 10000, 9.8, 7.0, 48000, 6240, 'hot', true,
    'Grade-A commercial office space in the heart of Gurugram''s IT corridor. Tenanted by Fortune 500 companies with a 9-year lease.'
  ),
  (
    'Sobha Dream Acres',
    'sobha-dream-acres-bangalore',
    'Bengaluru', 'Karnataka', 'residential', 'funding',
    220000000, 74800000, 5000, 7.4, 8.5, 44000, 29040, 'new', true,
    'Premium residential apartments in Bengaluru''s fastest growing tech corridor. High rental demand from IT professionals.'
  ),
  (
    'Hiranandani Business Park',
    'hiranandani-powai-mumbai',
    'Mumbai', 'Maharashtra', 'mixed', 'funding',
    1200000000, 1152000000, 25000, 10.2, 6.0, 48000, 1920, 'closing_soon', true,
    'Iconic mixed-use business park in Powai with retail, office and hospitality segments. Virtually fully funded — join the waitlist.'
  ),
  (
    'Prestige Tech Park',
    'prestige-tech-park-whitefield',
    'Bengaluru', 'Karnataka', 'commercial', 'coming_soon',
    650000000, 0, 10000, 9.2, 7.5, 65000, 65000, 'new', false,
    'Upcoming Grade-A tech park in Whitefield. Pre-register now to get priority access at launch.'
  )
ON CONFLICT (slug) DO NOTHING;

-- ══════════════════════════════════════════════════════════════════
-- SEED DATA: Sample blog posts
-- ══════════════════════════════════════════════════════════════════

INSERT INTO blog_posts (slug, title, excerpt, author_name, category, read_time_mins, published, published_at, seo_title, seo_description)
VALUES
  (
    'fractional-real-estate-india-beginners-guide',
    'Fractional Real Estate: How ₹10,000 Can Make You a Property Owner in India',
    'Everything a first-time investor needs to know about fractional real estate — how it works, SEBI regulations, tax treatment, and which cities offer the best returns.',
    'Agent360 Team', 'beginner', 8, true, now() - interval '10 days',
    'Fractional Real Estate India Beginners Guide 2025 | Agent360',
    'Learn how to invest in real estate starting at ₹10,000. Complete guide on fractional property investment in India.'
  ),
  (
    'top-cities-real-estate-investment-india-2025',
    'Top 5 Indian Cities for Real Estate Investment in 2025',
    'Bengaluru, Pune, Hyderabad, Noida, or Mumbai? Here''s where smart money is flowing and which micro-markets offer the highest yields.',
    'Priya Mehta', 'market', 6, true, now() - interval '5 days',
    'Best Cities to Invest in Real Estate India 2025 | Agent360',
    'Data-driven analysis of top Indian cities for property investment returns in 2025.'
  ),
  (
    'rental-income-tax-fractional-property-india',
    'How is Rental Income from Fractional Property Taxed in India?',
    'A plain-English breakdown of TDS, LTCG, STCG, and Section 24 deductions when you invest through Agent360.',
    'CA Rohan Iyer', 'tax', 5, true, now() - interval '2 days',
    'Rental Income Tax Fractional Real Estate India | Agent360',
    'Understand how rental income and capital gains from fractional real estate are taxed in India.'
  )
ON CONFLICT (slug) DO NOTHING;

-- ✅ Schema setup complete! Your agent360.in backend is ready.
-- Next step: copy SUPABASE_URL and SUPABASE_ANON_KEY into frontend/src/lib/supabase.js
