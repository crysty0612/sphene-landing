document.addEventListener('DOMContentLoaded', () => {
  // Service Worker Registration for PWA
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/sw.js').catch(err => {
      console.log('SW registration skipped:', err);
    });
  }

  // -------------------------------------------------------------
  // Proactive PWA Installation UX -> Routes to local.sphene.app
  // -------------------------------------------------------------
  let landingInstallPrompt = null;
  window.addEventListener('beforeinstallprompt', (e) => {
    // Intercept native browser prompt that would install public presentation site
    e.preventDefault();
    landingInstallPrompt = e;
    showLandingInstallBanner();
  });

  function showLandingInstallBanner() {
    const isStandalone = (window.matchMedia && window.matchMedia('(display-mode: standalone)').matches) ||
                         window.navigator.standalone === true;
    if (isStandalone) return;

    try {
      const dismissedAt = localStorage.getItem('sphene_landing_pwa_dismissed_time');
      if (dismissedAt && (Date.now() - parseInt(dismissedAt, 10)) < 7 * 24 * 60 * 60 * 1000) {
        return;
      }
    } catch (_) {}

    if (document.getElementById('sphene-landing-pwa-banner')) return;

    const banner = document.createElement('div');
    banner.id = 'sphene-landing-pwa-banner';
    banner.className = 'sphene-landing-pwa-banner';
    banner.innerHTML = `
      <div class="landing-pwa-card">
        <button class="landing-pwa-close" id="btn-close-landing-pwa" title="Dismiss" aria-label="Dismiss">✕</button>
        <div class="landing-pwa-body">
          <div class="landing-pwa-icon-wrap">
            <img src="/assets/icons/icon-192.png" alt="Sphene Sovereign Logo" class="landing-pwa-icon" width="42" height="42">
          </div>
          <div class="landing-pwa-text">
            <div class="landing-pwa-title-row">
              <span class="landing-pwa-title">Install Sphene App</span>
              <span class="landing-pwa-badge">100% Offline</span>
            </div>
            <p class="landing-pwa-desc">Get the native standalone app with zero cloud servers, on-device hardware encryption, and instant launch.</p>
          </div>
        </div>
        <div class="landing-pwa-actions">
          <button type="button" id="btn-dismiss-landing-pwa" class="btn btn-secondary btn-sm" style="font-size:12px; padding:6px 12px;">Maybe Later</button>
          <a href="https://local.sphene.app/?install=true" id="btn-install-landing-pwa" class="btn btn-emerald btn-sm" style="font-weight:700; font-size:12.5px; padding:6px 14px; gap:6px;">
            <span>📲</span> Install App Now
          </a>
        </div>
      </div>
    `;

    document.body.appendChild(banner);

    const closeBtn = document.getElementById('btn-close-landing-pwa');
    const dismissBtn = document.getElementById('btn-dismiss-landing-pwa');
    const dismissHandler = () => {
      try {
        localStorage.setItem('sphene_landing_pwa_dismissed_time', Date.now().toString());
      } catch (_) {}
      banner.style.transition = 'all 0.3s ease';
      banner.style.opacity = '0';
      banner.style.transform = 'translateY(20px)';
      setTimeout(() => banner.remove(), 300);
    };

    if (closeBtn) closeBtn.addEventListener('click', dismissHandler);
    if (dismissBtn) dismissBtn.addEventListener('click', dismissHandler);
  }

  // Mobile proactive trigger
  const isMobileClient = /android|iphone|ipad|ipod/i.test(navigator.userAgent || '');
  if (isMobileClient) {
    setTimeout(() => {
      showLandingInstallBanner();
    }, 1500);
  }

  // Standalone detection on sphene.app
  const isAppStandalone = (window.matchMedia && window.matchMedia('(display-mode: standalone)').matches) ||
                          window.navigator.standalone === true;
  if (isAppStandalone) {
    const launchBanner = document.createElement('div');
    launchBanner.style.cssText = 'position:fixed; top:0; left:0; right:0; z-index:99999; background:linear-gradient(90deg,#065f46,#0284c7); color:#fff; padding:10px 16px; text-align:center; font-size:13px; font-weight:600; display:flex; align-items:center; justify-content:center; gap:12px; box-shadow:0 4px 12px rgba(0,0,0,0.5);';
    launchBanner.innerHTML = `
      <span>🚀 You are viewing the presentation website in app mode.</span>
      <a href="https://local.sphene.app/?source=pwa" style="background:#fff; color:#0f172a; padding:4px 12px; border-radius:6px; text-decoration:none; font-weight:700;">Open Sovereign Vault ↗</a>
    `;
    document.body.appendChild(launchBanner);
  }

  // Copy to clipboard
  const copyBtns = document.querySelectorAll('.copy-btn');
  copyBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const targetId = btn.getAttribute('data-target');
      const textToCopy = targetId ? document.getElementById(targetId).innerText : btn.parentElement.querySelector('code').innerText;
      
      navigator.clipboard.writeText(textToCopy).then(() => {
        const originalText = btn.innerText;
        btn.innerText = 'Copied!';
        btn.style.color = '#10b981';
        setTimeout(() => {
          btn.innerText = originalText;
          btn.style.color = '';
        }, 2000);
      });
    });
  });

  // -------------------------------------------------------------
  // Smart LAN & Local Vault Discovery
  // -------------------------------------------------------------
  const VAULT_STORAGE_KEY = 'sphene_vault_url';
  const navSlots = document.querySelectorAll('.nav-vault-slot');

  function renderVaultButton(url) {
    navSlots.forEach(slot => {
      slot.innerHTML = `
        <a href="${url}" target="_blank" rel="noopener noreferrer" class="vault-status-pill" title="Connected to local vault: ${url}">
          <span class="pulse-dot"></span> Vault Live
        </a>
      `;
    });
  }

  const savedVault = localStorage.getItem(VAULT_STORAGE_KEY);
  if (savedVault) {
    renderVaultButton(savedVault);
  }

  // Smart Discovery Probe on Demand (Defensive against automated crawlers / headless bots)
  async function probeCandidate(url) {
    // Avoid network probes when running under automated crawlers or headless bots
    if (typeof navigator !== 'undefined' && navigator.webdriver) {
      return false;
    }
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 1200);
      const res = await fetch(`${url}/api/v1/health`, { signal: controller.signal, mode: 'cors' }).catch(() => null);
      clearTimeout(timeoutId);
      if (!res || !res.ok) return false;
      const data = await res.json().catch(() => null);
      if (data && (data.status === 'healthy' || data.engine === 'sphene-kernel')) {
        return true;
      }
    } catch (e) {}
    return false;
  }

  // Only probe localhost automatically if already running on local development host
  const isLocalHost = typeof window !== 'undefined' && (
    window.location.hostname === 'localhost' || 
    window.location.hostname === '127.0.0.1' || 
    window.location.hostname === '0.0.0.0'
  );
  if (!savedVault && isLocalHost && !(typeof navigator !== 'undefined' && navigator.webdriver)) {
    probeCandidate('http://localhost:8743').then(alive => {
      if (alive) {
        localStorage.setItem(VAULT_STORAGE_KEY, 'http://localhost:8743');
        renderVaultButton('http://localhost:8743');
      }
    }).catch(() => {});
  }

  // Modal handlers
  const connectModal = document.getElementById('vault-connect-modal');
  const openModalBtns = document.querySelectorAll('.btn-open-connect-modal');
  const closeModalBtns = document.querySelectorAll('.btn-close-connect-modal');
  const testConnBtn = document.getElementById('btn-test-connect');
  const vaultHostInput = document.getElementById('vault-host-input');
  const vaultPortInput = document.getElementById('vault-port-input');
  const vaultStatusMsg = document.getElementById('vault-status-msg');

  function openConnectModal() {
    if (connectModal) {
      connectModal.classList.add('active');
      const cur = localStorage.getItem(VAULT_STORAGE_KEY);
      if (cur && vaultHostInput) {
        try {
          const u = new URL(cur);
          vaultHostInput.value = u.hostname;
          if (vaultPortInput) vaultPortInput.value = u.port || '8743';
        } catch (e) {
          vaultHostInput.value = cur;
        }
      }
    }
  }

  function closeConnectModal() {
    if (connectModal) connectModal.classList.remove('active');
  }

  openModalBtns.forEach(btn => btn.addEventListener('click', (e) => {
    e.preventDefault();
    openConnectModal();
  }));

  closeModalBtns.forEach(btn => btn.addEventListener('click', (e) => {
    e.preventDefault();
    closeConnectModal();
  }));

  if (testConnBtn && vaultHostInput) {
    testConnBtn.addEventListener('click', async () => {
      const host = vaultHostInput.value.trim() || 'localhost';
      const port = vaultPortInput ? vaultPortInput.value.trim() || '8743' : '8743';
      const fullUrl = host.includes('://') ? host : `http://${host}:${port}`;

      if (vaultStatusMsg) {
        vaultStatusMsg.className = 'vault-status-msg info';
        vaultStatusMsg.innerText = `Connecting to ${fullUrl}...`;
      }

      const isAlive = await probeCandidate(fullUrl);
      if (isAlive) {
        localStorage.setItem(VAULT_STORAGE_KEY, fullUrl);
        renderVaultButton(fullUrl);
        if (vaultStatusMsg) {
          vaultStatusMsg.className = 'vault-status-msg success';
          vaultStatusMsg.innerHTML = `✓ Connected to Sphene Kernel! Saved to your device.`;
        }
        setTimeout(() => closeConnectModal(), 1500);
      } else {
        // If fetch failed due to browser mixed-content (HTTPS page querying HTTP LAN)
        localStorage.setItem(VAULT_STORAGE_KEY, fullUrl);
        renderVaultButton(fullUrl);
        if (vaultStatusMsg) {
          vaultStatusMsg.className = 'vault-status-msg success';
          vaultStatusMsg.innerHTML = `✓ Saved <strong>${fullUrl}</strong>! Click "Open Vault" above to launch directly.`;
        }
        setTimeout(() => closeConnectModal(), 2000);
      }
    });
  }
});

// -------------------------------------------------------------
// Interactive Feature Tabs
// -------------------------------------------------------------
document.querySelectorAll('.feature-tab-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const target = btn.getAttribute('data-tab');
    document.querySelectorAll('.feature-tab-btn').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.feature-tab-panel').forEach(p => p.classList.remove('active'));
    btn.classList.add('active');
    const panel = document.getElementById(target);
    if (panel) panel.classList.add('active');
  });
});

// -------------------------------------------------------------
// Plugin Catalog Filtering
// -------------------------------------------------------------
document.querySelectorAll('.plugin-filter-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const filter = btn.getAttribute('data-filter');
    document.querySelectorAll('.plugin-filter-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');

    document.querySelectorAll('.plugin-card').forEach(card => {
      const cat = card.getAttribute('data-category');
      if (filter === 'all' || cat === filter) {
        card.style.display = 'flex';
      } else {
        card.style.display = 'none';
      }
    });
  });
});

// -------------------------------------------------------------
// Screenshot Gallery Filtering & Lightbox
// -------------------------------------------------------------
document.querySelectorAll('.gallery-tab-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const filter = btn.getAttribute('data-filter');
    document.querySelectorAll('.gallery-tab-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');

    document.querySelectorAll('.gallery-item').forEach(item => {
      const cat = item.getAttribute('data-category') || '';
      if (filter === 'all' || cat.includes(filter)) {
        item.style.display = 'flex';
      } else {
        item.style.display = 'none';
      }
    });
  });
});

const lightbox = document.getElementById('sphene-lightbox');
const lightboxImg = document.getElementById('lightbox-img');
const lightboxTitle = document.getElementById('lightbox-title');
const lightboxDesc = document.getElementById('lightbox-desc');
const lightboxClose = document.getElementById('lightbox-close');

function openLightbox(src, title, desc) {
  if (!lightbox) return;
  lightboxImg.src = src;
  lightboxTitle.innerText = title;
  lightboxDesc.innerText = desc || '';
  lightbox.classList.add('active');
  document.body.style.overflow = 'hidden';
}

function closeLightbox() {
  if (!lightbox) return;
  lightbox.classList.remove('active');
  lightboxImg.src = '';
  document.body.style.overflow = '';
}

document.querySelectorAll('[data-lightbox-src]').forEach(el => {
  el.addEventListener('click', () => {
    const src = el.getAttribute('data-lightbox-src');
    const title = el.getAttribute('data-lightbox-title') || 'Sphene Application Preview';
    const desc = el.getAttribute('data-lightbox-desc') || '';
    openLightbox(src, title, desc);
  });
});

if (lightboxClose) {
  lightboxClose.addEventListener('click', closeLightbox);
}

if (lightbox) {
  lightbox.addEventListener('click', (e) => {
    if (e.target === lightbox || e.target.classList.contains('sphene-lightbox-img-box')) {
      closeLightbox();
    }
  });
  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && lightbox.classList.contains('active')) {
      closeLightbox();
    }
  });
}

