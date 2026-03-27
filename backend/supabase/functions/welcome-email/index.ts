// AGENT360 — Edge Function: welcome-email
// Triggered on newsletter INSERT via Supabase Webhook
// Deploy: supabase functions deploy welcome-email
// Set: supabase secrets set RESEND_API_KEY=re_xxxx

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

const RESEND_KEY = Deno.env.get('RESEND_API_KEY')!;
const FROM = 'Agent360 <hello@agent360.in>';

serve(async (req) => {
  const { record } = await req.json();
  const { email, name } = record;
  const first = name ? name.split(' ')[0] : 'Investor';

  const html = `<!DOCTYPE html>
<html><head><meta charset="UTF-8"/></head>
<body style="font-family:-apple-system,BlinkMacSystemFont,sans-serif;background:#050709;margin:0;padding:40px 0;">
  <div style="max-width:580px;margin:0 auto;background:#0D1420;border-radius:20px;overflow:hidden;border:1px solid rgba(255,255,255,0.08);">
    <div style="padding:36px 40px;text-align:center;background:linear-gradient(135deg,#0D1420,#121B2E);border-bottom:1px solid rgba(255,255,255,0.06);">
      <h1 style="color:#fff;font-family:Georgia,serif;font-size:32px;margin:0;letter-spacing:-0.5px;">
        Agent<span style="color:#C9982A">360</span>
      </h1>
      <p style="color:rgba(255,255,255,.4);font-size:11px;margin:8px 0 0;text-transform:uppercase;letter-spacing:2px;">Real Estate Investment Platform</p>
    </div>
    <div style="padding:40px;">
      <h2 style="font-family:Georgia,serif;font-size:26px;color:#fff;margin-bottom:16px;">Welcome, ${first}! 🏛</h2>
      <p style="color:rgba(255,255,255,.6);line-height:1.8;margin-bottom:24px;font-size:15px;">
        You're now part of India's smartest real estate investment community. Every Tuesday, you'll receive:
      </p>
      <div style="background:rgba(255,255,255,.04);border-radius:12px;padding:20px 24px;margin-bottom:28px;border:1px solid rgba(255,255,255,.06);">
        <div style="color:rgba(255,255,255,.7);line-height:2.2;font-size:14px;">
          🏢 &nbsp;New premium property listings with full yield data<br/>
          📊 &nbsp;Weekly market analysis from our research team<br/>
          💡 &nbsp;Beginner-friendly investment tips and guides<br/>
          📋 &nbsp;Tax & legal updates for property investors<br/>
          🎯 &nbsp;Exclusive pre-launch access to new properties
        </div>
      </div>
      <div style="text-align:center;margin:32px 0;">
        <a href="https://agent360.in" style="display:inline-block;background:linear-gradient(135deg,#C9982A,#A87020);color:#000;padding:15px 36px;border-radius:50px;text-decoration:none;font-weight:700;font-size:15px;letter-spacing:.3px;">
          Explore Properties →
        </a>
      </div>
      <div style="background:rgba(201,152,42,.08);border:1px solid rgba(201,152,42,.2);border-radius:10px;padding:16px 20px;margin-bottom:24px;">
        <p style="color:rgba(201,152,42,.9);font-size:13px;margin:0;line-height:1.6;">
          <strong>🎁 Welcome Offer:</strong> Use code <strong>WELCOME500</strong> for ₹500 off your first investment of ₹10,000 or more. Valid for 7 days.
        </p>
      </div>
      <p style="color:rgba(255,255,255,.3);font-size:12px;line-height:1.7;">
        Investments in real estate are subject to market risks. Please read all documents carefully before investing. Agent360 is SEBI registered.
      </p>
    </div>
    <div style="background:rgba(0,0,0,.3);padding:20px 40px;text-align:center;border-top:1px solid rgba(255,255,255,.06);">
      <p style="color:rgba(255,255,255,.25);font-size:11px;margin:0;">
        © 2025 Agent360 Realty Pvt. Ltd. · 
        <a href="https://agent360.in" style="color:rgba(201,152,42,.6);">agent360.in</a> · 
        <a href="https://agent360.in/unsubscribe?email=${encodeURIComponent(email)}" style="color:rgba(255,255,255,.25);">Unsubscribe</a>
      </p>
    </div>
  </div>
</body></html>`;

  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${RESEND_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ from: FROM, to: [email], subject: '🏛 Welcome to Agent360 — Your Real Estate Journey Starts Now', html })
  });

  const data = await res.json();
  return new Response(JSON.stringify({ ok: true, data }), { headers: { 'Content-Type': 'application/json' } });
});
