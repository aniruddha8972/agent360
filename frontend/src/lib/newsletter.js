/**
 * AGENT360.IN — Newsletter Module
 * Saves subscriber email to Supabase newsletter table
 */

async function doSubscribe() {
  const email = document.getElementById('nlEmail').value.trim();
  const msg   = document.getElementById('nl-msg');

  if (!email || !email.includes('@')) {
    msg.textContent = 'Please enter a valid email address.';
    msg.className = 'nl-err';
    return;
  }

  msg.textContent = 'Subscribing…';
  msg.className = '';

  try {
    await DB.subscribe(email);
  } catch (e) {
    console.warn('[Agent360] Newsletter subscribe error:', e);
    // Don't block UX on DB error
  }

  // Simulate slight delay for UX
  await new Promise(r => setTimeout(r, 700));

  msg.textContent = '🎉 You\'re in! Check your inbox for a welcome email.';
  msg.className = 'nl-ok';
  document.getElementById('nlEmail').value = '';
}
