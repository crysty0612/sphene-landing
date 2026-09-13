document.addEventListener('DOMContentLoaded', () => {
  // Service Worker Registration for PWA
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/sw.js').catch(err => {
      console.log('SW registration skipped:', err);
    });
  }

  // PWA Install Prompt handling
  let deferredPrompt;
  const pwaInstallBtns = document.querySelectorAll('.btn-pwa-install');
  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    deferredPrompt = e;
    pwaInstallBtns.forEach(b => b.style.display = 'inline-flex');
  });

  pwaInstallBtns.forEach(btn => {
    btn.addEventListener('click', async () => {
      if (deferredPrompt) {
        deferredPrompt.prompt();
        const { outcome } = await deferredPrompt.userChoice;
        if (outcome === 'accepted') {
          console.log('User accepted Sphene PWA install');
        }
        deferredPrompt = null;
      } else {
        alert("To install Sphene on your home screen / desktop:\n\n• On Chrome/Edge: Click the Install icon in the address bar.\n• On iOS Safari: Tap Share -> 'Add to Home Screen'.\n• On Android: Tap Menu -> 'Add to Home screen' or 'Install App'.");
      }
    });
  });

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

  // Pricing Cycle Switcher (Monthly / Annually)
  const cycleToggle = document.getElementById('billingCycleToggle');
  if (cycleToggle) {
    const proAmount = document.getElementById('proAmount');
    const proPeriod = document.getElementById('proPeriod');
    const enterpriseAmount = document.getElementById('enterpriseAmount');
    const enterprisePeriod = document.getElementById('enterprisePeriod');

    cycleToggle.addEventListener('change', () => {
      if (cycleToggle.checked) {
        // Annual (20% off)
        if (proAmount) proAmount.innerText = '$4';
        if (proPeriod) proPeriod.innerText = '/ month (billed annually)';
        if (enterpriseAmount) enterpriseAmount.innerText = '$15';
        if (enterprisePeriod) enterprisePeriod.innerText = '/ month (billed annually)';
      } else {
        // Monthly
        if (proAmount) proAmount.innerText = '$5';
        if (proPeriod) proPeriod.innerText = '/ month';
        if (enterpriseAmount) enterpriseAmount.innerText = '$19';
        if (enterprisePeriod) enterprisePeriod.innerText = '/ month';
      }
    });
  }

  // Stripe Checkout Modal
  const checkoutModal = document.getElementById('checkoutModal');
  const openModalBtns = document.querySelectorAll('.btn-open-checkout');
  const closeModalBtns = document.querySelectorAll('.modal-close, .modal-backdrop');

  openModalBtns.forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const planName = btn.getAttribute('data-plan') || 'Sphene Pro';
      const planPrice = btn.getAttribute('data-price') || '$5/mo';
      
      const modalPlanTitle = document.getElementById('modalPlanTitle');
      const modalPlanPrice = document.getElementById('modalPlanPrice');
      if (modalPlanTitle) modalPlanTitle.innerText = planName;
      if (modalPlanPrice) modalPlanPrice.innerText = planPrice;

      if (checkoutModal) checkoutModal.classList.add('active');
    });
  });

  closeModalBtns.forEach(btn => {
    btn.addEventListener('click', (e) => {
      if (e.target === checkoutModal || e.target.classList.contains('modal-close')) {
        if (checkoutModal) checkoutModal.classList.remove('active');
      }
    });
  });
});
