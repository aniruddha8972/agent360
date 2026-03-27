-- ═══════════════════════════════════════════════════════════════
-- AGENT360.IN — COMPLETE SUPABASE DATABASE SCHEMA
-- Version: 2.0 | Run this in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ──────────────────────────────────────────────────────────────
-- TABLE 1: INVESTORS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS investors (
  id                UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name         TEXT,
  email             TEXT UNIQUE NOT NULL,
  phone             TEXT,
  date_of_birth     DATE,
  gender            TEXT CHECK (gender IN ('male','female','other','prefer_not_to_say')),

  -- KYC
  pan_number        TEXT,
  aadhaar_last4     TEXT,
  kyc_status        TEXT DEFAULT 'pending'
                    CHECK (kyc_status IN ('pending','submitted','verified','rejected')),
  kyc_submitted_at  TIMESTAMPTZ,
  kyc_verified_at   TIMESTAMPTZ,
  kyc_rejection_reason TEXT,

  -- Bank Details
  bank_name         TEXT,
  bank_account      TEXT,
  ifsc_code         TEXT,
  bank_verified     BOOLEAN DEFAULT false,

  -- Profile
  risk_profile      TEXT DEFAULT 'moderate'
                    CHECK (risk_profile IN ('conservative','moderate','aggressive')),
  investment_goal   TEXT,
  annual_income     TEXT,
  is_nri            BOOLEAN DEFAULT false,
  country           TEXT DEFAULT 'IN',
  avatar_url        TEXT,

  -- Referral
  referral_code     TEXT UNIQUE DEFAULT UPPER(SUBSTR(MD5(RANDOM()::TEXT), 1, 8)),
  referred_by       TEXT,
  referral_earnings NUMERIC(12,2) DEFAULT 0,

  -- Aggregates (updated by triggers)
  total_invested    NUMERIC(15,2) DEFAULT 0,
  total_earnings    NUMERIC(15,2) DEFAULT 0,
  wallet_balance    NUMERIC(12,2) DEFAULT 0,

  -- Flags
  is_active         BOOLEAN DEFAULT true,
  email_verified    BOOLEAN DEFAULT false,
  notifications_enabled BOOLEAN DEFAULT true,

  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now(),
  last_login_at     TIMESTAMPTZ
);

-- ──────────────────────────────────────────────────────────────
-- TABLE 2: PROPERTIES
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS properties (
  id                    UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name                  TEXT NOT NULL,
  slug                  TEXT UNIQUE NOT NULL,

  -- Location
  city                  TEXT NOT NULL,
  state                 TEXT NOT NULL,
  address               TEXT,
  pincode               TEXT,
  latitude              DECIMAL(10,7),
  longitude             DECIMAL(10,7),
  google_maps_url       TEXT,

  -- Classification
  property_type         TEXT NOT NULL
    CHECK (property_type IN ('commercial','residential','mixed','reit','warehouse','hospitality','industrial')),
  status                TEXT DEFAULT 'coming_soon'
    CHECK (status IN ('coming_soon','open','funding','fully_funded','active','exited','cancelled')),
  asset_class           TEXT DEFAULT 'core' CHECK (asset_class IN ('core','core_plus','value_add','opportunistic')),

  -- Financial Details
  total_value           NUMERIC(15,2) NOT NULL,
  funded_amount         NUMERIC(15,2) DEFAULT 0,
  min_investment        NUMERIC(10,2) NOT NULL DEFAULT 5000,
  max_investment        NUMERIC(15,2),
  expected_yield        NUMERIC(6,3),
  expected_appreciation NUMERIC(6,3),
  irr_target            NUMERIC(6,3),
  lock_in_years         INTEGER DEFAULT 3,
  exit_options          TEXT[],

  -- Property Details
  total_area_sqft       NUMERIC(12,2),
  carpet_area_sqft      NUMERIC(12,2),
  floors                INTEGER,
  year_built            INTEGER,
  grade                 TEXT CHECK (grade IN ('A+','A','B+','B')),

  -- Tenancy
  current_occupancy     NUMERIC(5,2) DEFAULT 100,
  tenant_names          TEXT[],
  lease_expiry          DATE,
  wale_years            NUMERIC(4,1),

  -- Developer / Legal
  developer_name        TEXT,
  rera_number           TEXT,
  sebi_registered       BOOLEAN DEFAULT true,
  legal_structure       TEXT DEFAULT 'fractional_ownership',

  -- Units
  total_units           INTEGER,
  available_units       INTEGER,
  unit_price            NUMERIC(12,4),

  -- Media
  cover_image_url       TEXT,
  gallery_urls          TEXT[],
  video_url             TEXT,
  virtual_tour_url      TEXT,

  -- Content
  description           TEXT,
  short_description     TEXT,
  highlights            JSONB,
  risk_factors          JSONB,
  faqs                  JSONB,
  documents             JSONB,

  -- Display
  featured              BOOLEAN DEFAULT false,
  badge                 TEXT CHECK (badge IN ('hot','new','closing_soon','featured','coming_soon', NULL)),
  sort_order            INTEGER DEFAULT 0,

  -- Metadata
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),
  published_at          TIMESTAMPTZ,
  funded_at             TIMESTAMPTZ
);

-- ──────────────────────────────────────────────────────────────
-- TABLE 3: HOLDINGS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS holdings (
  id                    UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  investor_id           UUID REFERENCES investors(id) ON DELETE CASCADE NOT NULL,
  property_id           UUID REFERENCES properties(id) NOT NULL,

  -- Ownership
  units_owned           NUMERIC(15,6) NOT NULL,
  ownership_pct         NUMERIC(10,6),
  amount_invested       NUMERIC(15,2) NOT NULL,
  price_per_unit        NUMERIC(12,4),

  -- Valuations
  current_value         NUMERIC(15,2),
  last_valuation_date   DATE,

  -- Returns
  total_rental_received NUMERIC(15,2) DEFAULT 0,
  total_appreciation    NUMERIC(15,2) DEFAULT 0,
  pnl                   NUMERIC(15,2) DEFAULT 0,
  pnl_pct               NUMERIC(8,4) DEFAULT 0,
  xirr                  NUMERIC(8,4),

  -- Status
  status                TEXT DEFAULT 'active' CHECK (status IN ('active','exited','locked','transferred')),
  lock_in_end_date      DATE,

  -- Exit details
  exit_value            NUMERIC(15,2),
  exit_price_per_unit   NUMERIC(12,4),
  exited_at             TIMESTAMPTZ,

  invested_at           TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

-- ──────────────────────────────────────────────────────────────
-- TABLE 4: TRANSACTIONS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
  id                UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  investor_id       UUID REFERENCES investors(id) ON DELETE CASCADE NOT NULL,
  property_id       UUID REFERENCES properties(id),
  holding_id        UUID REFERENCES holdings(id),

  -- Type & Status
  type              TEXT NOT NULL
    CHECK (type IN ('investment','rental_income','appreciation','withdrawal','refund','bonus','wallet_topup','wallet_withdrawal','platform_fee')),
  status            TEXT DEFAULT 'completed'
    CHECK (status IN ('pending','processing','completed','failed','cancelled','refunded')),

  -- Amount
  amount            NUMERIC(15,2) NOT NULL,
  units             NUMERIC(15,6),
  price_per_unit    NUMERIC(12,4),
  platform_fee      NUMERIC(12,2) DEFAULT 0,
  net_amount        NUMERIC(15,2),

  -- Payment
  payment_method    TEXT,
  payment_ref       TEXT,
  gateway_txn_id    TEXT,
  bank_ref_number   TEXT,

  -- Metadata
  description       TEXT,
  notes             TEXT,
  metadata          JSONB,

  transaction_date  TIMESTAMPTZ DEFAULT now(),
  processed_at      TIMESTAMPTZ,
  failed_at         TIMESTAMPTZ,
  failure_reason    TEXT
);

-- ──────────────────────────────────────────────────────────────
-- TABLE 5: RENTAL PAYOUTS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS rental_payouts (
  id                    UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  property_id           UUID REFERENCES properties(id) NOT NULL,

  payout_month          DATE NOT NULL,
  payout_period         TEXT,

  -- Financials
  gross_rent_collected  NUMERIC(15,2),
  maintenance_deductions NUMERIC(12,2) DEFAULT 0,
  platform_fee_pct      NUMERIC(4,2) DEFAULT 10,
  platform_fee_amount   NUMERIC(12,2),
  net_distributable     NUMERIC(15,2),
  per_unit_payout       NUMERIC(14,8),

  -- Stats
  total_units_eligible  NUMERIC(15,6),
  total_investors_paid  INTEGER,
  total_disbursed       NUMERIC(15,2),

  -- Status
  status                TEXT DEFAULT 'scheduled'
    CHECK (status IN ('scheduled','processing','completed','failed','partially_paid')),
  processed_at          TIMESTAMPTZ,
  notes                 TEXT,
  created_at            TIMESTAMPTZ DEFAULT now(),

  UNIQUE(property_id, payout_month)
);

-- ──────────────────────────────────────────────────────────────
-- TABLE 6: KYC DOCUMENTS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS kyc_documents (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  investor_id     UUID REFERENCES investors(id) ON DELETE CASCADE NOT NULL,
  doc_type        TEXT NOT NULL
    CHECK (doc_type IN ('pan','aadhaar_front','aadhaar_back','selfie','bank_statement','cancelled_cheque','passport','visa','nri_certificate','itr')),
  file_url        TEXT NOT NULL,
  file_size_kb    INTEGER,
  mime_type       TEXT,
  verified        BOOLEAN DEFAULT false,
  verified_by     TEXT,
  verified_at     TIMESTAMPTZ,
  rejection_reason TEXT,
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- ──────────────────────────────────────────────────────────────
-- TABLE 7: NEWSLETTER SUBSCRIBERS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS newsletter (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email           TEXT UNIQUE NOT NULL,
  name            TEXT,
  is_active       BOOLEAN DEFAULT true,
  source          TEXT DEFAULT 'website',
  tags            TEXT[],
  utm_source      TEXT,
  utm_campaign    TEXT,
  ip_address      TEXT,
  subscribed_at   TIMESTAMPTZ DEFAULT now(),
  unsubscribed_at TIMESTAMPTZ,
  last_opened_at  TIMESTAMPTZ
);

-- ──────────────────────────────────────────────────────────────
-- TABLE 8: WATCHLIST
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS watchlist (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  investor_id   UUID REFERENCES investors(id) ON DELETE CASCADE NOT NULL,
  property_id   UUID REFERENCES properties(id) ON DELETE CASCADE NOT NULL,
  notes         TEXT,
  added_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE(investor_id, property_id)
);

-- ──────────────────────────────────────────────────────────────
-- TABLE 9: BLOG POSTS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS blog_posts (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  slug            TEXT UNIQUE NOT NULL,
  title           TEXT NOT NULL,
  subtitle        TEXT,
  excerpt         TEXT,
  content         TEXT,
  cover_image_url TEXT,
  author_name     TEXT,
  author_avatar   TEXT,
  author_bio      TEXT,
  category        TEXT CHECK (category IN ('beginner','market','tax','news','nri','legal','strategy')),
  tags            TEXT[],
  read_time_mins  INTEGER,
  featured        BOOLEAN DEFAULT false,
  published       BOOLEAN DEFAULT false,
  published_at    TIMESTAMPTZ,
  seo_title       TEXT,
  seo_description TEXT,
  seo_keywords    TEXT,
  views           INTEGER DEFAULT 0,
  likes           INTEGER DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- ──────────────────────────────────────────────────────────────
-- TABLE 10: NOTIFICATIONS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  investor_id   UUID REFERENCES investors(id) ON DELETE CASCADE NOT NULL,
  type          TEXT NOT NULL,
  title         TEXT NOT NULL,
  body          TEXT,
  cta_text      TEXT,
  cta_url       TEXT,
  icon          TEXT,
  is_read       BOOLEAN DEFAULT false,
  data          JSONB,
  created_at    TIMESTAMPTZ DEFAULT now(),
  read_at       TIMESTAMPTZ
);

-- ──────────────────────────────────────────────────────────────
-- TABLE 11: LEADS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS leads (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name          TEXT,
  email         TEXT NOT NULL,
  phone         TEXT,
  city          TEXT,
  investment_range TEXT,
  message       TEXT,
  source        TEXT DEFAULT 'website',
  utm_source    TEXT,
  utm_medium    TEXT,
  utm_campaign  TEXT,
  status        TEXT DEFAULT 'new'
    CHECK (status IN ('new','contacted','qualified','converted','closed','spam')),
  assigned_to   TEXT,
  notes         TEXT,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

-- ──────────────────────────────────────────────────────────────
-- TABLE 12: PROPERTY VALUATIONS (historical)
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS property_valuations (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  property_id     UUID REFERENCES properties(id) NOT NULL,
  valuation_date  DATE NOT NULL,
  total_value     NUMERIC(15,2) NOT NULL,
  per_unit_value  NUMERIC(12,4),
  valuation_type  TEXT DEFAULT 'quarterly' CHECK (valuation_type IN ('monthly','quarterly','annual','special')),
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE(property_id, valuation_date)
);

-- ══════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ══════════════════════════════════════════════════════════════

ALTER TABLE investors          ENABLE ROW LEVEL SECURITY;
ALTER TABLE holdings           ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE kyc_documents      ENABLE ROW LEVEL SECURITY;
ALTER TABLE watchlist          ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications      ENABLE ROW LEVEL SECURITY;
ALTER TABLE properties         ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog_posts         ENABLE ROW LEVEL SECURITY;
ALTER TABLE rental_payouts     ENABLE ROW LEVEL SECURITY;
ALTER TABLE newsletter         ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads              ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_valuations ENABLE ROW LEVEL SECURITY;

-- Investors: own row only
CREATE POLICY "investors_select_own"    ON investors FOR SELECT  USING (auth.uid() = id);
CREATE POLICY "investors_insert_own"    ON investors FOR INSERT  WITH CHECK (auth.uid() = id);
CREATE POLICY "investors_update_own"    ON investors FOR UPDATE  USING (auth.uid() = id);

-- Holdings: own only
CREATE POLICY "holdings_own"            ON holdings  USING (auth.uid() = investor_id);

-- Transactions: own only
CREATE POLICY "transactions_select_own" ON transactions FOR SELECT USING (auth.uid() = investor_id);
CREATE POLICY "transactions_insert_own" ON transactions FOR INSERT WITH CHECK (auth.uid() = investor_id);

-- KYC: own only
CREATE POLICY "kyc_own"                 ON kyc_documents USING (auth.uid() = investor_id);

-- Watchlist: own only
CREATE POLICY "watchlist_own"           ON watchlist USING (auth.uid() = investor_id);

-- Notifications: own only
CREATE POLICY "notifications_own"       ON notifications USING (auth.uid() = investor_id);

-- Properties: public read
CREATE POLICY "properties_public_read"  ON properties         FOR SELECT USING (true);

-- Blog: public read (published only)
CREATE POLICY "blog_public_read"        ON blog_posts         FOR SELECT USING (published = true);

-- Rental payouts: public read
CREATE POLICY "payouts_public_read"     ON rental_payouts     FOR SELECT USING (true);

-- Property valuations: public read
CREATE POLICY "valuations_public_read"  ON property_valuations FOR SELECT USING (true);

-- Newsletter: public insert only
CREATE POLICY "newsletter_insert"       ON newsletter         FOR INSERT WITH CHECK (true);

-- Leads: public insert only
CREATE POLICY "leads_insert"            ON leads              FOR INSERT WITH CHECK (true);

-- ══════════════════════════════════════════════════════════════
-- TRIGGERS
-- ══════════════════════════════════════════════════════════════

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

CREATE TRIGGER t_investors_upd    BEFORE UPDATE ON investors     FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER t_properties_upd   BEFORE UPDATE ON properties    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER t_holdings_upd     BEFORE UPDATE ON holdings      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER t_blog_upd         BEFORE UPDATE ON blog_posts    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER t_leads_upd        BEFORE UPDATE ON leads         FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Auto-create investor profile on signup
CREATE OR REPLACE FUNCTION handle_new_signup()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO investors (id, email, full_name, email_verified)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE((NEW.email_confirmed_at IS NOT NULL), false)
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_signup();

-- Auto-update investor aggregates when holding changes
CREATE OR REPLACE FUNCTION sync_investor_totals()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_id UUID;
BEGIN
  v_id := COALESCE(NEW.investor_id, OLD.investor_id);
  UPDATE investors SET
    total_invested = (
      SELECT COALESCE(SUM(amount_invested), 0) FROM holdings
      WHERE investor_id = v_id AND status IN ('active','locked')
    ),
    total_earnings = (
      SELECT COALESCE(SUM(total_rental_received), 0) FROM holdings
      WHERE investor_id = v_id
    )
  WHERE id = v_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER t_holdings_sync
  AFTER INSERT OR UPDATE OR DELETE ON holdings
  FOR EACH ROW EXECUTE FUNCTION sync_investor_totals();

-- Auto-update property funded_amount when holding added
CREATE OR REPLACE FUNCTION sync_property_funded()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_pid UUID;
BEGIN
  v_pid := COALESCE(NEW.property_id, OLD.property_id);
  UPDATE properties SET
    funded_amount = (
      SELECT COALESCE(SUM(amount_invested), 0) FROM holdings
      WHERE property_id = v_pid AND status IN ('active','locked')
    ),
    available_units = GREATEST(0, total_units - (
      SELECT COALESCE(SUM(units_owned), 0) FROM holdings
      WHERE property_id = v_pid AND status IN ('active','locked')
    ))
  WHERE id = v_pid;
  RETURN NEW;
END;
$$;

CREATE TRIGGER t_holdings_property_sync
  AFTER INSERT OR UPDATE OR DELETE ON holdings
  FOR EACH ROW EXECUTE FUNCTION sync_property_funded();

-- Auto-update holding P&L from transaction
CREATE OR REPLACE FUNCTION update_holding_pnl()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.type = 'rental_income' AND NEW.holding_id IS NOT NULL THEN
    UPDATE holdings SET
      total_rental_received = total_rental_received + NEW.amount,
      pnl = pnl + NEW.amount
    WHERE id = NEW.holding_id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER t_txn_update_holding
  AFTER INSERT ON transactions
  FOR EACH ROW EXECUTE FUNCTION update_holding_pnl();

-- ══════════════════════════════════════════════════════════════
-- INDEXES
-- ══════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_holdings_investor      ON holdings(investor_id);
CREATE INDEX IF NOT EXISTS idx_holdings_property      ON holdings(property_id);
CREATE INDEX IF NOT EXISTS idx_holdings_status        ON holdings(status);
CREATE INDEX IF NOT EXISTS idx_txn_investor           ON transactions(investor_id);
CREATE INDEX IF NOT EXISTS idx_txn_date               ON transactions(transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_txn_type               ON transactions(type);
CREATE INDEX IF NOT EXISTS idx_txn_property           ON transactions(property_id);
CREATE INDEX IF NOT EXISTS idx_props_status           ON properties(status);
CREATE INDEX IF NOT EXISTS idx_props_city             ON properties(city);
CREATE INDEX IF NOT EXISTS idx_props_type             ON properties(property_type);
CREATE INDEX IF NOT EXISTS idx_props_featured         ON properties(featured) WHERE featured = true;
CREATE INDEX IF NOT EXISTS idx_blog_published         ON blog_posts(published_at DESC) WHERE published = true;
CREATE INDEX IF NOT EXISTS idx_notif_investor         ON notifications(investor_id, is_read);
CREATE INDEX IF NOT EXISTS idx_payouts_month          ON rental_payouts(payout_month DESC);
CREATE INDEX IF NOT EXISTS idx_watchlist_investor     ON watchlist(investor_id);
CREATE INDEX IF NOT EXISTS idx_newsletter_active      ON newsletter(email) WHERE is_active = true;

-- ══════════════════════════════════════════════════════════════
-- SEED DATA
-- ══════════════════════════════════════════════════════════════

INSERT INTO properties (
  name, slug, city, state, property_type, status,
  total_value, funded_amount, min_investment, expected_yield, expected_appreciation,
  total_units, available_units, badge, featured, grade, current_occupancy,
  tenant_names, developer_name, short_description
) VALUES
(
  'DLF Cyber City Tower B',
  'dlf-cyber-city-gurugram',
  'Gurugram', 'Haryana', 'commercial', 'funding',
  480000000, 417600000, 10000, 9.8, 7.0,
  48000, 6240, 'hot', true, 'A+', 100,
  ARRAY['Microsoft','Accenture','Wipro'],
  'DLF Limited',
  'Grade A+ office space in the heart of Gurugrams tech corridor. Tenanted by Fortune 500 companies.'
),
(
  'Sobha Dream Acres',
  'sobha-dream-acres-bengaluru',
  'Bengaluru', 'Karnataka', 'residential', 'funding',
  220000000, 74800000, 5000, 7.4, 8.5,
  44000, 29040, 'new', true, 'A', 96,
  ARRAY['Residential Tenants'],
  'Sobha Limited',
  'Premium 2/3BHK apartments in Bengalurus fastest-growing tech corridor. High rental demand from IT professionals.'
),
(
  'Hiranandani Business Park',
  'hiranandani-powai-mumbai',
  'Mumbai', 'Maharashtra', 'mixed', 'funding',
  1200000000, 1152000000, 25000, 10.2, 6.0,
  48000, 1920, 'closing_soon', true, 'A+', 99,
  ARRAY['HDFC Life','Nomura','Deutsche Bank'],
  'Hiranandani Group',
  'Iconic mixed-use business park in Powai. Near fully funded — join the waitlist.'
),
(
  'Embassy TechVillage Block 8',
  'embassy-techvillage-bengaluru',
  'Bengaluru', 'Karnataka', 'commercial', 'coming_soon',
  850000000, 0, 10000, 9.5, 8.0,
  85000, 85000, 'coming_soon', false, 'A+', 100,
  ARRAY['Google','Goldman Sachs'],
  'Embassy Group',
  'World-class commercial park anchored by global tech giants. Pre-register for priority access.'
)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO blog_posts (slug, title, excerpt, author_name, category, read_time_mins, published, published_at, featured)
VALUES
(
  'fractional-real-estate-india-beginners-guide-2025',
  'Fractional Real Estate: How ₹10,000 Makes You a Property Owner in India',
  'Everything a first-time investor needs — how fractional ownership works, SEBI regulations, tax treatment, and which cities offer the best returns in 2025.',
  'Agent360 Research Team', 'beginner', 8, true, now() - interval '8 days', true
),
(
  'top-cities-real-estate-investment-india-2025',
  'Top 5 Indian Cities for Real Estate Investment Returns in 2025',
  'Data-driven analysis: where smart money is flowing and which micro-markets deliver the highest rental yields and appreciation.',
  'Priya Mehta', 'market', 6, true, now() - interval '4 days', false
),
(
  'rental-income-tax-fractional-property-india-2025',
  'Rental Income Tax on Fractional Property — Complete 2025 Guide',
  'TDS, LTCG, STCG, and Section 24 deductions explained in plain English for fractional real estate investors.',
  'CA Rohan Iyer', 'tax', 5, true, now() - interval '2 days', false
)
ON CONFLICT (slug) DO NOTHING;

-- ══════════════════════════════════════════════════════════════
-- STORAGE BUCKETS (run separately if needed)
-- ══════════════════════════════════════════════════════════════
-- INSERT INTO storage.buckets (id, name, public) VALUES ('property-images', 'property-images', true) ON CONFLICT DO NOTHING;
-- INSERT INTO storage.buckets (id, name, public) VALUES ('kyc-documents',   'kyc-documents',   false) ON CONFLICT DO NOTHING;
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars',         'avatars',         true) ON CONFLICT DO NOTHING;

-- ✅ Agent360 database setup complete!
-- Next: paste SUPABASE_URL and SUPABASE_ANON_KEY into frontend/index.html
