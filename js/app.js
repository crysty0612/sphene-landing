document.addEventListener('DOMContentLoaded', () => {
  // Service Worker Registration for PWA
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/sw.js').catch(err => {
      console.log('SW registration skipped:', err);
    });
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
        <div style="display:inline-flex; align-items:center; gap:6px;">
          <a href="${url}" target="_blank" rel="noopener noreferrer" class="btn btn-vault-live btn-sm" title="Launch connected vault: ${url}">
            🟢 Open Vault
          </a>
          <button class="btn btn-secondary btn-sm btn-clear-vault" title="Settings / Change Vault" style="padding: 6px 9px; font-size: 11px;">⚙️</button>
        </div>
      `;
      const clearBtn = slot.querySelector('.btn-clear-vault');
      if (clearBtn) {
        clearBtn.addEventListener('click', (e) => {
          e.preventDefault();
          openConnectModal();
        });
      }
    });
  }

  const savedVault = localStorage.getItem(VAULT_STORAGE_KEY);
  if (savedVault) {
    renderVaultButton(savedVault);
  }

  // Smart Discovery Probe on Load
  async function probeCandidate(url) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 1200);
      const res = await fetch(`${url}/api/v1/health`, { signal: controller.signal, mode: 'cors' });
      clearTimeout(timeoutId);
      const data = await res.json();
      if (data.status === 'healthy' || data.engine === 'sphene-kernel') {
        return true;
      }
    } catch (e) {}
    return false;
  }

  // If no saved vault, probe localhost if running on desktop or same machine
  if (!savedVault) {
    probeCandidate('http://localhost:8743').then(alive => {
      if (alive) {
        localStorage.setItem(VAULT_STORAGE_KEY, 'http://localhost:8743');
        renderVaultButton('http://localhost:8743');
      }
    });
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
