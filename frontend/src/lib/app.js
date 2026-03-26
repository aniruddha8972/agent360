/**
 * AGENT360.IN — App Entry
 * Initialises page, loads dynamic data from Supabase if connected
 */

(async function init() {

  // ── CHECK SESSION ──────────────────────────
  try {
    const session = await DB.getSession();
    if (session) {
      // User is logged in — update nav CTA
      const ctaArea = document.querySelector('.nav-cta');
      if (ctaArea) {
        const email = session.user.email;
        const initials = email.substring(0, 2).toUpperCase();
        ctaArea.innerHTML = `
          <div style="display:flex;align-items:center;gap:10px">
            <div style="width:34px;height:34px;border-radius:50%;background:var(--clay);color:#fff;display:flex;align-items:center;justify-content:center;font-size:.75rem;font-weight:700">${initials}</div>
            <button class="btn btn-ghost" onclick="handleSignOut()" style="padding:8px 16px">Sign Out</button>
          </div>
        `;
      }

      // Load real holdings if available
      await loadPortfolio(session.user.id);
    }
  } catch (e) {
    console.warn('[Agent360] Session check failed:', e);
  }

  // ── LOAD PROPERTIES ────────────────────────
  try {
    const props = await DB.getProperties({ limit: 3 });
    if (props && props.length > 0) {
      renderProperties(props);
    }
    // If null (demo mode), static HTML listings remain
  } catch (e) {
    console.warn('[Agent360] Properties load failed:', e);
  }

})();

// ── SIGN OUT ──────────────────────────────────
async function handleSignOut() {
  await DB.signOut();
  showToast('👋 Signed out successfully.');
  setTimeout(() => location.reload(), 1000);
}

// ── RENDER PROPERTIES FROM DB ─────────────────
function renderProperties(properties) {
  const grid = document.getElementById('propertyGrid');
  if (!grid || !properties.length) return;

  const gradients = [
    'linear-gradient(160deg,#B07840,#5C3520)',
    'linear-gradient(160deg,#7A9E7E,#3D5C42)',
    'linear-gradient(160deg,#8B6B8B,#4A2E4A)',
    'linear-gradient(160deg,#6B8B9E,#2E4A5C)',
  ];

  const badges = { hot: 'badge-hot', new: 'badge-new', closing_soon: 'badge-fill' };
  const badgeLabels = { hot: '🔥 Hot', new: '✨ New', closing_soon: '⚡ Closing Soon' };

  grid.innerHTML = properties.map((p, i) => {
    const fundedPct = p.total_value > 0
      ? Math.round((p.funded_amount / p.total_value) * 100)
      : 0;
    const minFmt = p.min_investment >= 1000
      ? '₹' + (p.min_investment / 1000).toFixed(0) + 'K'
      : '₹' + p.min_investment;
    const totalFmt = p.total_value >= 1e7
      ? '₹' + (p.total_value / 1e7).toFixed(0) + ' Cr'
      : '₹' + (p.total_value / 1e5).toFixed(0) + ' L';
    const badgeCls   = badges[p.badge] || 'badge-new';
    const badgeLabel = badgeLabels[p.badge] || '✨ New';
    const grad = gradients[i % gradients.length];
    const ctaLabel = fundedPct >= 95 ? 'Join Waitlist →' : 'Invest Now →';

    return `
      <div class="listing-card reveal">
        <div class="listing-img" style="background:${grad}">
          <div class="listing-badge ${badgeCls}">${badgeLabel}</div>
          <div class="yield-tag">
            <div class="yv">${p.expected_yield?.toFixed(1) || '—'}%</div>
            <div class="yl">Yield</div>
          </div>
        </div>
        <div class="listing-body">
          <div class="listing-name">${p.name}</div>
          <div class="listing-city">📍 ${p.city}, ${p.state}</div>
          <div class="listing-meta">
            <div class="lm-item"><div class="lm-l">Min. Invest</div><div class="lm-v">${minFmt}</div></div>
            <div class="lm-item"><div class="lm-l">Total Value</div><div class="lm-v">${totalFmt}</div></div>
            <div class="lm-item"><div class="lm-l">Type</div><div class="lm-v" style="text-transform:capitalize">${p.property_type}</div></div>
          </div>
          <div class="progress-wrap">
            <div class="progress-label"><span>Funding Progress</span><span>${fundedPct}% Filled</span></div>
            <div class="progress-track"><div class="progress-fill" style="width:${fundedPct}%"></div></div>
          </div>
          <button class="listing-cta" onclick="openAuth('signup')">${ctaLabel}</button>
        </div>
      </div>`;
  }).join('');

  // Re-observe new cards for reveal animation
  grid.querySelectorAll('.reveal').forEach(el => revealObs.observe(el));
}

// ── LOAD PORTFOLIO FROM DB ─────────────────────
async function loadPortfolio(investorId) {
  try {
    const holdings = await DB.getHoldings(investorId);
    if (!holdings || holdings.length === 0) return;

    const holdingsArea = document.querySelector('.port-holdings');
    if (!holdingsArea) return;

    const icons = { commercial:'🏢', residential:'🏘', mixed:'🏗', reit:'📊', warehouse:'🏭' };
    const colors = ['rgba(196,113,74,.12)', 'rgba(74,124,89,.12)', 'rgba(107,90,78,.12)', 'rgba(180,74,42,.1)'];
    const tcolors = ['var(--clay)', 'var(--sage)', 'var(--stone)', 'var(--rust)'];

    const totalInvested = holdings.reduce((s, h) => s + (+h.amount_invested), 0);
    const totalValue    = holdings.reduce((s, h) => s + (+h.current_value || +h.amount_invested), 0);
    const totalPnL      = totalValue - totalInvested;

    // Update summary
    const summaryItems = document.querySelectorAll('.ps-val');
    if (summaryItems[0]) summaryItems[0].textContent = '₹' + (totalInvested/1e5).toFixed(1) + 'L';
    if (summaryItems[1]) summaryItems[1].textContent = '₹' + (totalValue/1e5).toFixed(1) + 'L';

    // Render rows
    const head = holdingsArea.querySelector('.hold-head');
    holdingsArea.innerHTML = '';
    holdingsArea.appendChild(head);

    holdings.forEach((h, i) => {
      const prop = h.properties || {};
      const pnl  = (+h.current_value || +h.amount_invested) - +h.amount_invested;
      const pnlPct = h.amount_invested > 0 ? (pnl / +h.amount_invested * 100).toFixed(1) : 0;
      const isUp = pnl >= 0;
      const icon = icons[prop.property_type] || '🏠';
      const bg   = colors[i % colors.length];
      const tc   = tcolors[i % tcolors.length];

      const row = document.createElement('div');
      row.className = 'hold-row';
      row.innerHTML = `
        <div class="hold-prop">
          <div class="hold-icon" style="background:${bg};color:${tc}">${icon}</div>
          <div>
            <div class="hold-pname">${prop.name || 'Property'}</div>
            <div class="hold-pcity">${prop.city || ''}, ${prop.state || ''}</div>
          </div>
        </div>
        <div class="hold-val">₹${(+h.amount_invested).toLocaleString('en-IN')}</div>
        <div class="hold-val">₹${(+h.current_value || +h.amount_invested).toLocaleString('en-IN')}</div>
        <div class="hold-ret"><span class="pct-badge ${isUp?'pct-up':'pct-dn'}">${prop.expected_yield?.toFixed(1)||'—'}%</span></div>
        <div class="hold-ret ${isUp?'up':'dn'}">${isUp?'+':''}₹${Math.abs(pnl).toLocaleString('en-IN')}</div>
      `;
      holdingsArea.appendChild(row);
    });
  } catch (e) {
    console.warn('[Agent360] Portfolio load failed:', e);
  }
}
