# 🏛 Agent360.in — Real Estate Investment Platform

> India's simplest fractional real estate investment platform.
> Own premium properties from ₹5,000. Earn monthly rental income.

---

## 📁 Project Structure

```
agent360/
├── frontend/
│   ├── public/
│   │   └── index.html          ← Main website (open this in browser)
│   └── src/
│       ├── styles/
│       │   └── main.css        ← All styles
│       └── lib/
│           ├── supabase.js     ← ⚡ EDIT THIS: add your Supabase keys
│           ├── auth.js         ← Login / signup logic
│           ├── calculator.js   ← ROI calculator
│           ├── newsletter.js   ← Email subscription
│           ├── ui.js           ← Navbar, toast, scroll reveal
│           └── app.js          ← Main app entry, data loading
├── backend/
│   └── supabase/
│       ├── migrations/
│       │   └── 001_initial_schema.sql  ← Run this in Supabase SQL Editor
│       └── functions/
│           ├── send-welcome-email/     ← Email new subscribers
│           └── distribute-rental-payout/ ← Monthly rental distribution
├── docs/
│   └── LAUNCH-GUIDE.md
└── README.md  ← You are here
```

---

## ⚡ Quick Start (5 Steps)

### Step 1 — Create Supabase Project
1. Go to **https://supabase.com** → New Project
2. Name it `agent360`, choose a region close to India (Mumbai/Singapore)
3. Wait ~2 minutes for project to spin up

### Step 2 — Set Up Database
1. In Supabase dashboard → **SQL Editor**
2. Paste the contents of `backend/supabase/migrations/001_initial_schema.sql`
3. Click **Run** — all tables, policies, triggers, and sample data will be created ✅

### Step 3 — Connect Frontend to Supabase
1. In Supabase → **Settings → API**
2. Copy your **Project URL** and **anon/public key**
3. Open `frontend/src/lib/supabase.js` and replace:

```js
const SUPABASE_URL      = 'https://YOUR_PROJECT_ID.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1...';
```

### Step 4 — Run Locally
Just open `frontend/public/index.html` in your browser — no build step needed!

Or use a local server:
```bash
cd frontend/public
npx serve .
# → http://localhost:3000
```

### Step 5 — Deploy to agent360.in

**Option A: Vercel (Recommended — Free)**
```bash
npm install -g vercel
cd frontend/public
vercel deploy --name agent360
# Then add domain agent360.in in Vercel dashboard
```

**Option B: Netlify (Free)**
- Drag the `frontend/public` folder to https://app.netlify.com/drop
- Settings → Domain → Add `agent360.in`

**Option C: cPanel / Traditional Hosting**
- Upload everything inside `frontend/public/` to `public_html/`
- Upload `frontend/src/` to `public_html/src/`

**DNS Records** (at your domain registrar):
```
Type    Name    Value
A       @       76.76.21.21       (Vercel)
CNAME   www     cname.vercel-dns.com
```

---

## 🗄️ Database Tables

| Table | Purpose |
|-------|---------|
| `investors` | User profiles linked to Supabase Auth |
| `properties` | Property listings with financials |
| `holdings` | Each investor's fractional ownership |
| `transactions` | All money movements (buy, rental, withdraw) |
| `rental_payouts` | Monthly rent distribution ledger |
| `kyc_documents` | KYC file uploads per investor |
| `newsletter` | Email subscriber list |
| `watchlist` | Investor saved properties |
| `blog_posts` | CMS for Market Insights section |
| `leads` | Contact form submissions |
| `notifications` | In-app notifications per investor |

---

## 🔧 Backend Functions

### Email Welcome (send-welcome-email)
Sends a branded welcome email when someone subscribes to the newsletter.

```bash
# Deploy
supabase functions deploy send-welcome-email

# Set secrets
supabase secrets set RESEND_API_KEY=re_xxxx

# Set up webhook: Supabase → Database → Webhooks
# Table: newsletter, Event: INSERT, URL: your function URL
```

### Rental Distribution (distribute-rental-payout)
Runs on the 1st of every month to calculate and distribute rental income to all investors.

```bash
# Deploy
supabase functions deploy distribute-rental-payout

# Schedule (runs 9am on 1st of every month)
# Set up in Supabase → Database → Cron Jobs
# Schedule: 0 9 1 * *
# Function: distribute-rental-payout
```

---

## 🔒 Security

- **Row Level Security** enabled on all 11 tables
- Users can only read/write their own data
- Properties and blog posts are publicly readable
- Newsletter inserts are open (email only, no auth required)
- Service Role key only used in Edge Functions (never in frontend)

---

## 📈 SEO Features (Built-in)

- ✅ Optimised `<title>` and `<meta description>`
- ✅ Open Graph + Twitter Card tags
- ✅ JSON-LD structured data (RealEstateAgent schema)
- ✅ Semantic HTML5 heading hierarchy (H1→H2→H3)
- ✅ Canonical URL
- ✅ Mobile-first responsive (Google ranking signal)
- ✅ Fast load (no heavy framework, single HTML file)
- ✅ Blog section with SEO keyword articles

**Target Keywords:**
- fractional real estate investment india (8,400/mo)
- invest in commercial property small amount (5,200/mo)
- real estate investment beginners india (12,000/mo)
- NRI property investment india guide (4,800/mo)

---

## 🚀 Roadmap

### Phase 1 — Launch (Done ✅)
- Full landing page with all sections
- Supabase Auth + user profiles
- Newsletter capture
- ROI Calculator
- Portfolio tracker UI
- Blog / Market Insights

### Phase 2 — Growth (Month 2-3)
- [ ] Dashboard page (post-login)
- [ ] Admin panel for listing properties
- [ ] Razorpay payment integration
- [ ] WhatsApp OTP via Twilio
- [ ] Email automation (welcome series)
- [ ] Referral program

### Phase 3 — Scale (Month 4-6)
- [ ] Mobile app (React Native)
- [ ] SEBI SM-REIT registration
- [ ] Secondary market (resell units)
- [ ] AI investment advisor
- [ ] Live property valuations API

---

## 📞 Support & Resources

| Resource | Link |
|----------|------|
| Supabase Docs | https://supabase.com/docs |
| Vercel Deployment | https://vercel.com/docs |
| Resend Email | https://resend.com |
| Razorpay Docs | https://razorpay.com/docs |
| SEBI Website | https://sebi.gov.in |

---

*© 2025 Agent360 Realty Pvt. Ltd. All rights reserved.*
*Investments subject to market risk. SEBI registered.*
