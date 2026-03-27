# 🏛 Agent360.in — Real Estate Investment Platform v2.0

**India's smartest fractional real estate platform**  
Obsidian + Burnished Gold design · Full Supabase backend · Production-ready

---

## 📁 Structure

```
agent360-ultimate/
├── frontend/
│   └── index.html              ← Complete website (single file, deploy this)
└── backend/
    ├── config/
    │   └── .env.example        ← Environment variables template
    └── supabase/
        ├── migrations/
        │   └── 001_schema.sql  ← Full database schema (run in SQL Editor)
        └── functions/
            ├── welcome-email/  ← Sends branded welcome email on subscribe
            └── rental-payout/  ← Monthly rental distribution engine
```

---

## ⚡ Setup in 3 Steps

### Step 1 — Supabase Database
1. Go to https://supabase.com → New Project (name: `agent360`, region: Singapore)
2. **SQL Editor** → paste `backend/supabase/migrations/001_schema.sql` → **Run**
3. **Settings → API** → copy `Project URL` and `anon/public` key

### Step 2 — Connect Frontend
Open `frontend/index.html`, find these lines (~line 430):
```js
const SUPA_URL = 'YOUR_SUPABASE_URL';
const SUPA_KEY = 'YOUR_SUPABASE_ANON_KEY';
```
Replace with your actual values.

### Step 3 — Deploy to Vercel
1. Go to vercel.com → New Project → Upload `frontend/index.html`
2. Settings → Domains → Add `agent360.in`
3. Update DNS at GoDaddy: `A @ 76.76.21.21` and `CNAME www cname.vercel-dns.com`

---

## 🗄️ Database (12 Tables)

| Table | Purpose |
|-------|---------|
| `investors` | User profiles, KYC, bank details |
| `properties` | Property listings with full financials |
| `holdings` | Fractional ownership records |
| `transactions` | All money movements |
| `rental_payouts` | Monthly rent distribution ledger |
| `kyc_documents` | KYC file uploads |
| `newsletter` | Email subscribers |
| `watchlist` | Saved properties |
| `blog_posts` | Market insights CMS |
| `notifications` | In-app alerts |
| `leads` | Contact form submissions |
| `property_valuations` | Historical value tracking |

---

## 🔧 Edge Functions

### `welcome-email`
Sends branded welcome email when someone subscribes to newsletter.
```bash
supabase functions deploy welcome-email
supabase secrets set RESEND_API_KEY=re_xxxx
# Add webhook in Supabase: Database → Webhooks → newsletter INSERT
```

### `rental-payout`
Distributes rental income to all investors on the 1st of every month.
```bash
supabase functions deploy rental-payout
# Add cron in Supabase: Database → Cron Jobs → "0 9 1 * *"
```

---

## 🎨 UI Features
- **Cursor glow** — subtle gold gradient follows mouse
- **Animated mesh background** — layered radial gradients + dot grid
- **Floating orbs** — colour-shifting blurs with drift animation
- **Market ticker** — live-feeling horizontal scroll
- **CountUp** — animated number counters on scroll
- **Donut chart** — dynamic SVG showing returns breakdown
- **Range sliders** — gold-filled, glow on thumb hover
- **Progress bars** — shimmer animation + scroll-triggered reveal
- **3D property cards** — float + rotate animations on hero
- **Scroll reveal** — staggered entrance for every section
- **Toast notifications** — auth success/error feedback
- **Modal** — Escape key + backdrop click to close

---

## 🔒 Security
- Row Level Security on all 12 tables
- Users can only access their own data
- Properties, blog and payouts are publicly readable
- Service role key only used in Edge Functions

---

## 📈 SEO Built-In
- Meta title, description, keywords
- Open Graph + Twitter Card
- JSON-LD (RealEstateAgent schema)
- Canonical URL
- Semantic HTML5

---

*© 2025 Agent360 Realty Pvt. Ltd. · agent360.in*  
*SEBI Registered · Investments subject to market risk*
