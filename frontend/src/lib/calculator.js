/**
 * AGENT360.IN — Real Estate ROI Calculator
 * Computes: rental income + property appreciation
 */

function calcRE() {
  const amt   = +document.getElementById('cAmt').value;
  const yld   = +document.getElementById('cYield').value;
  const app   = +document.getElementById('cApp').value;
  const yrs   = +document.getElementById('cYrs').value;

  // Update display labels
  document.getElementById('cAmtV').textContent   = amt.toLocaleString('en-IN');
  document.getElementById('cYieldV').textContent  = yld.toFixed(1);
  document.getElementById('cAppV').textContent    = app.toFixed(1);
  document.getElementById('cYrsV').textContent    = yrs;

  // Calculations
  const monthlyRent  = (amt * yld / 100) / 12;
  const totalRent    = monthlyRent * 12 * yrs;
  const propVal      = amt * Math.pow(1 + app / 100, yrs);
  const total        = propVal + totalRent;
  const returns      = total - amt;

  // Format Indian currency
  function fmt(v) {
    if (v >= 1e7)  return '₹' + (v / 1e7).toFixed(2) + 'Cr';
    if (v >= 1e5)  return '₹' + (v / 1e5).toFixed(2) + 'L';
    if (v >= 1000) return '₹' + (v / 1000).toFixed(1) + 'K';
    return '₹' + Math.round(v).toLocaleString('en-IN');
  }

  // Update result panel
  document.getElementById('reTotal').textContent   = fmt(total);
  document.getElementById('reSub').textContent     = `Invested ${fmt(amt)} · Total returns ${fmt(returns)} (${Math.round(returns / amt * 100)}%)`;
  document.getElementById('reMonthly').textContent = fmt(monthlyRent) + '/mo';
  document.getElementById('rePropVal').textContent = fmt(propVal);

  // Bar widths
  const invPct = Math.round(amt / total * 100);
  const renPct = Math.round(totalRent / total * 100);
  const appPct = Math.max(0, 100 - invPct - renPct);

  document.getElementById('rbInv').style.width    = invPct + '%';
  document.getElementById('rbRen').style.width    = renPct + '%';
  document.getElementById('rbApp').style.width    = appPct + '%';
  document.getElementById('rbInvPct').textContent = invPct + '%';
  document.getElementById('rbRenPct').textContent = renPct + '%';
  document.getElementById('rbAppPct').textContent = appPct + '%';
}

// Run on load
calcRE();
