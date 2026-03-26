# Agent360.in — Launch Guide & Traffic Playbook

## ⚡ STEP 1: Connect Supabase (10 minutes)

1. Go to **https://supabase.com** → New Project → name it `agent360`
2. **Settings → API** → copy Project URL and anon key
3. Open `frontend/src/lib/supabase.js` → replace SUPABASE_URL and SUPABASE_ANON_KEY
4. **SQL Editor** → paste `backend/supabase/migrations/001_initial_schema.sql` → Run
5. **Authentication → Providers → Email** → Enable email sign-ups

Done! Newsletter signups and user accounts now save automatically. ✅

---

## 🌐 STEP 2: Go Live on agent360.in

### Fastest: Vercel (Free)
```bash
npm i -g vercel
cd frontend/public
vercel deploy --name agent360
# Dashboard → Domains → Add agent360.in
```

### Alternative: Netlify
- Drag `frontend/public` folder to app.netlify.com/drop
- Settings → Domain → Add agent360.in

### DNS Records
```
Type    Name    Value
A       @       76.76.21.21
CNAME   www     cname.vercel-dns.com
```

---

## 🔍 STEP 3: Google SEO Setup (Free)

### Google Search Console
1. Go to https://search.google.com/search-console
2. Add property → enter https://agent360.in → verify
3. Submit sitemap: https://agent360.in/sitemap.xml

### Google Analytics 4
Add to `<head>` in index.html:
```html
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXX"></script>
<script>
  window.dataLayer=window.dataLayer||[];
  function gtag(){dataLayer.push(arguments);}
  gtag('js',new Date());gtag('config','G-XXXXXXXX');
</script>
```

---

## 📈 STEP 4: SEO Keyword Content Plan

Write one article per week targeting these high-value keywords:

| Keyword | Monthly Searches | Priority |
|---------|-----------------|----------|
| fractional real estate investment india | 8,400 | 🔴 High |
| real estate investment for beginners india | 12,000 | 🔴 High |
| invest in commercial property with small amount | 5,200 | 🔴 High |
| how to invest in REITs india | 9,600 | 🟡 Medium |
| best city to invest in property 2025 india | 6,800 | 🟡 Medium |
| passive income from property india | 7,200 | 🟡 Medium |
| NRI property investment india guide | 4,800 | 🟡 Medium |
| commercial property rental yield india | 3,600 | 🟢 Low |

### 8-Week Content Calendar
- Week 1: "What is fractional real estate? A beginner's guide (2025)"
- Week 2: "Top 5 cities for real estate investment returns in India"
- Week 3: "Commercial vs Residential: Where to invest in 2025?"
- Week 4: "REIT vs Fractional Real Estate: Which is better?"
- Week 5: "How to earn passive income from property without buying one"
- Week 6: "NRI Property Investment in India: Complete 2025 Guide"
- Week 7: "Real estate tax guide: LTCG, STCG, TDS explained simply"
- Week 8: "Bengaluru vs Mumbai: Best city for property investment?"

---

## 📣 STEP 5: Social Media Traffic

### Instagram (Best ROI for real estate)
- City skyline + return % graphics: "₹10,000 → ₹11,400 in Bengaluru"
- Reels: "Property for beginners" explainers (15-30 sec)
- Stories: Live funding progress bar updates

### LinkedIn (HNI + professionals)
- "Why I chose fractional property over FDs" posts
- Market data charts with insights
- Tag real estate journalists and influencers

### Twitter/X
- Daily market update: "Bengaluru office rent up 4% this quarter"
- Hashtags: #RealEstate #InvestInIndia #PropertyInvestment #FractionalRE

### YouTube
- "I invested ₹50,000 in fractional real estate — 6 month update"
- "How Agent360 works" walkthrough
- Property tour videos

---

## 💡 STEP 6: Feature Roadmap

### Month 1 (Launch)
- [x] Full landing page with 6 sections
- [x] Supabase auth + user profiles
- [x] Newsletter with auto-welcome email
- [x] ROI Calculator
- [x] Portfolio tracker
- [x] Blog section
- [ ] Google Analytics setup
- [ ] 4 blog articles live

### Month 2-3 (Grow)
- [ ] Dashboard page for logged-in investors
- [ ] Admin panel for listing new properties
- [ ] Razorpay integration for real investments
- [ ] WhatsApp OTP via Twilio
- [ ] Referral program (Invite friend → earn ₹250)
- [ ] Email drip campaigns via Resend

### Month 4-6 (Scale)
- [ ] Mobile app (React Native)
- [ ] SEBI SM-REIT / AIF registration
- [ ] Secondary market for reselling units
- [ ] AI investment advisor (Claude API)
- [ ] Live property valuations API

---

## 🔒 Security Checklist

- [x] Supabase RLS on all 11 tables
- [x] Auth handled by Supabase (bcrypt)
- [x] Service role key never in frontend
- [ ] Add hCaptcha to auth forms (free: hcaptcha.com)
- [ ] Enable MFA in Supabase Auth settings
- [ ] Add HTTP security headers (CSP, X-Frame-Options)
- [ ] Set up Supabase auto-backup

---

## 📞 Key Resources

- Supabase: https://supabase.com/docs
- Vercel: https://vercel.com/docs
- Resend (email): https://resend.com (3,000 free/month)
- hCaptcha (bot protection): https://hcaptcha.com (free)
- Razorpay: https://razorpay.com/docs
- SEBI: https://sebi.gov.in

**Good luck with agent360.in! 🏛**
