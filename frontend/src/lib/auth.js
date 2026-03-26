/**
 * AGENT360.IN — Auth Module
 * Handles signup, login, and session state
 */

let _currentTab = 'login';

function openAuth(tab = 'login') {
  document.getElementById('authOverlay').classList.add('open');
  switchTab(tab);
  document.body.style.overflow = 'hidden';
}

function closeAuth() {
  document.getElementById('authOverlay').classList.remove('open');
  document.body.style.overflow = '';
  document.getElementById('auth-msg').textContent = '';
}

function switchTab(tab) {
  _currentTab = tab;
  document.getElementById('tLogin').classList.toggle('on', tab === 'login');
  document.getElementById('tSignup').classList.toggle('on', tab === 'signup');
  document.getElementById('mTitle').textContent   = tab === 'login' ? 'Welcome Back' : 'Start Investing';
  document.getElementById('mSubmit').textContent  = tab === 'login' ? 'Log In' : 'Create Free Account';
  document.getElementById('mNameWrap').style.display = tab === 'signup' ? 'block' : 'none';
  document.getElementById('auth-msg').textContent = '';
}

async function handleAuth() {
  const email = document.getElementById('mEmail').value.trim();
  const pass  = document.getElementById('mPass').value;
  const msgEl = document.getElementById('auth-msg');
  const btn   = document.getElementById('mSubmit');

  if (!email || !pass) {
    msgEl.textContent = 'Please fill all fields.';
    msgEl.className = 'auth-err';
    return;
  }
  if (pass.length < 8) {
    msgEl.textContent = 'Password must be at least 8 characters.';
    msgEl.className = 'auth-err';
    return;
  }

  btn.disabled = true;
  btn.textContent = _currentTab === 'login' ? 'Logging in…' : 'Creating account…';
  msgEl.textContent = '';

  try {
    let result;
    if (_currentTab === 'login') {
      result = await DB.signIn(email, pass);
    } else {
      const name = document.getElementById('mName').value.trim();
      result = await DB.signUp(email, pass, name);
    }

    if (result && result.demo) {
      // Demo mode — Supabase not yet connected
      await new Promise(r => setTimeout(r, 1100));
      closeAuth();
      showToast(_currentTab === 'login'
        ? '👋 Welcome back to Agent360!'
        : '🎉 Account created! Let\'s find your first property.');
    } else {
      closeAuth();
      showToast(_currentTab === 'login'
        ? '👋 Welcome back!'
        : '🎉 Account created! Explore properties now.');
    }
  } catch (err) {
    msgEl.textContent = err.message || 'Something went wrong. Please try again.';
    msgEl.className = 'auth-err';
  }

  btn.disabled = false;
  btn.textContent = _currentTab === 'login' ? 'Log In' : 'Create Free Account';
}

// Close on backdrop click
document.getElementById('authOverlay').addEventListener('click', e => {
  if (e.target === e.currentTarget) closeAuth();
});
