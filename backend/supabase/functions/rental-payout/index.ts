// AGENT360 — Edge Function: rental-payout
// Distributes monthly rental income to all investors
// Schedule: 0 9 1 * * (9am on 1st of every month)
// Deploy: supabase functions deploy rental-payout

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPA_URL          = Deno.env.get('SUPABASE_URL')!;
const SUPA_SERVICE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const PLATFORM_FEE_PCT  = 0.10;

serve(async (req) => {
  const db = createClient(SUPA_URL, SUPA_SERVICE_KEY);
  const { propertyId } = await req.json().catch(() => ({}));

  let propQuery = db.from('properties').select('*').eq('status', 'active');
  if (propertyId) propQuery = propQuery.eq('id', propertyId);
  const { data: properties, error } = await propQuery;
  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 });

  const monthKey = new Date().toISOString().substring(0, 7) + '-01';
  const results  = [];

  for (const p of properties) {
    try {
      const grossRent   = (p.total_value * (p.expected_yield / 100)) / 12;
      const platformFee = grossRent * PLATFORM_FEE_PCT;
      const netRent     = grossRent - platformFee;
      const totalUnits  = p.total_units || 1;
      const perUnit     = netRent / totalUnits;

      const { data: holdings } = await db
        .from('holdings').select('id,investor_id,units_owned')
        .eq('property_id', p.id).eq('status', 'active');

      if (!holdings?.length) continue;

      // Record payout
      await db.from('rental_payouts').upsert({
        property_id: p.id, payout_month: monthKey,
        gross_rent_collected: grossRent, platform_fee_amount: platformFee,
        net_distributable: netRent, per_unit_payout: perUnit,
        total_units_eligible: totalUnits, total_investors_paid: holdings.length,
        total_disbursed: holdings.reduce((s, h) => s + h.units_owned * perUnit, 0),
        status: 'completed', processed_at: new Date().toISOString()
      }, { onConflict: 'property_id,payout_month' });

      // Create transactions
      const txns = holdings.map(h => ({
        investor_id: h.investor_id, property_id: p.id, holding_id: h.id,
        type: 'rental_income', status: 'completed',
        amount: +(h.units_owned * perUnit).toFixed(2),
        units: h.units_owned, price_per_unit: perUnit,
        description: `Rental income — ${new Date().toLocaleString('en-IN', {month:'long', year:'numeric'})}`,
        transaction_date: new Date().toISOString()
      }));
      await db.from('transactions').insert(txns);

      results.push({ property: p.name, investorsPaid: holdings.length, netRent: netRent.toFixed(2) });
    } catch(err) {
      console.error(`Payout failed for ${p.name}:`, err);
    }
  }

  return new Response(JSON.stringify({ ok: true, results }), { headers: { 'Content-Type': 'application/json' } });
});
