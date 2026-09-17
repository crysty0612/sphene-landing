/**
 * Sphene Plugins UI Controller
 * Manages category panes, real-time search, and the separated detail inspector modal.
 */
document.addEventListener('DOMContentLoaded', () => {
  const plugins = window.SPHENE_PLUGINS || [];
  const panesContainer = document.getElementById('pluginPanesContainer');
  const searchInput = document.getElementById('pluginSearchInput');
  const filterTabs = document.querySelectorAll('.plugin-tab-btn');
  const modalOverlay = document.getElementById('pluginDetailModal');

  if (!panesContainer || !plugins.length) return;

  // Active Category State
  let activeCategory = 'all';
  let searchQuery = '';
  let currentModalPluginIndex = 0;

  // Define Category Metadata
  const categories = [
    { id: 'visual', name: 'Visual & Canvas', icon: '🎨', desc: 'Infinite vector canvas, SVG flowcharts, knowledge graphs, and high-fidelity PDF publishing.' },
    { id: 'ai', name: 'Sovereign AI', icon: '🧠', desc: 'Zero-host-RAM intelligence, vector cosine backlinks, and Aegis-governed autonomous agents.' },
    { id: 'ingestion', name: 'Knowledge & Importers', icon: '📥', desc: 'Bridges for Kindle, Readwise, Google Keep, Google Drive, and 1-click desktop vault migration.' },
    { id: 'security', name: 'Security & Backup', icon: '🛡️', desc: 'Signed Git snapshots, sub-millisecond AST linters, soft-delete bins, and 4-zone Aegis boundaries.' },
    { id: 'reading', name: 'Focus & Reading', icon: '📖', desc: 'KaTeX formula engines, floating outlines, interactive task matrices, and 5 curated themes.' }
  ];

  // Render Panes Function
  function renderPluginHub() {
    panesContainer.innerHTML = '';

    // Filter plugins by search query if any
    const filteredPlugins = plugins.filter(p => {
      const matchSearch = searchQuery === '' || 
        p.name.toLowerCase().includes(searchQuery) ||
        p.tagline.toLowerCase().includes(searchQuery) ||
        p.overview.toLowerCase().includes(searchQuery) ||
        p.categoryName.toLowerCase().includes(searchQuery) ||
        p.bestFor.toLowerCase().includes(searchQuery);
      
      const matchCategory = activeCategory === 'all' || p.category === activeCategory;
      return matchSearch && matchCategory;
    });

    if (filteredPlugins.length === 0) {
      panesContainer.innerHTML = `
        <div style="text-align: center; padding: 60px 20px; background: rgba(15, 23, 42, 0.5); border: 1px dashed var(--border-subtle); border-radius: 16px;">
          <div style="font-size: 36px; margin-bottom: 12px;">🔍</div>
          <h4 style="font-size: 18px; color: var(--text-primary); margin-bottom: 6px;">No plugins found matching "${searchQuery}"</h4>
          <p style="color: var(--text-muted); font-size: 14px;">Try searching for "drawing", "Kindle", "LaTeX", "Git", or "AI"</p>
        </div>
      `;
      return;
    }

    // Determine which categories to render
    const categoriesToRender = activeCategory === 'all' 
      ? categories.filter(cat => filteredPlugins.some(p => p.category === cat.id))
      : categories.filter(cat => cat.id === activeCategory);

    categoriesToRender.forEach(cat => {
      const catPlugins = filteredPlugins.filter(p => p.category === cat.id);
      if (catPlugins.length === 0) return;

      const paneSection = document.createElement('div');
      paneSection.className = 'plugin-pane-section';

      // Section Header
      const headerHtml = `
        <div class="plugin-pane-header">
          <h3><span>${cat.icon}</span> ${cat.name}</h3>
          <span class="pane-desc">${cat.desc}</span>
        </div>
      `;

      // Spotlight (Flagship) plugin is the first with an image or first plugin
      const spotlightPlugin = catPlugins.find(p => p.image) || catPlugins[0];
      const siblingPlugins = catPlugins.filter(p => p.id !== spotlightPlugin.id);

      let spotlightMediaHtml = '';
      if (spotlightPlugin.image) {
        spotlightMediaHtml = `
          <div class="spotlight-preview-crop" data-inspect-id="${spotlightPlugin.id}" title="Click to inspect ${spotlightPlugin.name}">
            <img src="${spotlightPlugin.image}" alt="${spotlightPlugin.name} Visual Preview" loading="lazy">
          </div>
        `;
      }

      const spotlightCardHtml = `
        <div class="plugin-spotlight-card">
          <div>
            <div class="plugin-spotlight-header">
              <div class="spotlight-icon-wrap">${spotlightPlugin.icon}</div>
              <span class="spotlight-badge">${spotlightPlugin.badge}</span>
            </div>
            <h4>${spotlightPlugin.name}</h4>
            <p class="plugin-spotlight-desc">${spotlightPlugin.tagline}</p>
            ${spotlightMediaHtml}
          </div>
          <div class="spotlight-meta-row">
            <span class="spotlight-metric">⚡ Tested: ${spotlightPlugin.specs.latency}</span>
            <button class="btn-inspect-specs" data-inspect-id="${spotlightPlugin.id}">
              Inspect Specs &amp; Details &rarr;
            </button>
          </div>
        </div>
      `;

      // Sibling compact list
      let siblingsHtml = '<div class="plugin-compact-list">';
      siblingPlugins.forEach(sibling => {
        siblingsHtml += `
          <div class="plugin-compact-card" data-inspect-id="${sibling.id}">
            <div class="compact-card-left">
              <div class="compact-card-icon">${sibling.icon}</div>
              <div class="compact-card-info">
                <h5>${sibling.name}</h5>
                <p>${sibling.tagline}</p>
              </div>
            </div>
            <div class="compact-card-right">
              <span class="compact-card-badge">${sibling.badge}</span>
              <span class="compact-card-arrow">&rarr;</span>
            </div>
          </div>
        `;
      });
      siblingsHtml += '</div>';

      // Assemble Layout
      paneSection.innerHTML = headerHtml + `
        <div class="plugin-pane-layout">
          ${spotlightCardHtml}
          ${siblingsHtml}
        </div>
      `;

      panesContainer.appendChild(paneSection);
    });

    // Attach click listeners to open detail modal
    attachModalTriggers();
  }

  // Attach Modal Trigger Handlers
  function attachModalTriggers() {
    document.querySelectorAll('[data-inspect-id]').forEach(el => {
      el.addEventListener('click', (e) => {
        e.preventDefault();
        const pluginId = el.getAttribute('data-inspect-id');
        openPluginDetail(pluginId);
      });
    });
  }

  // Open Plugin Detail Modal
  function openPluginDetail(pluginId) {
    const idx = plugins.findIndex(p => p.id === pluginId);
    if (idx === -1) return;
    currentModalPluginIndex = idx;
    renderModalContent(plugins[idx]);

    modalOverlay.classList.add('active');
    document.body.style.overflow = 'hidden';
    history.replaceState(null, '', `#${pluginId}`);
  }

  // Render Modal Content
  function renderModalContent(plugin) {
    document.getElementById('modalPluginIcon').textContent = plugin.icon;
    document.getElementById('modalPluginTitle').textContent = plugin.name;
    document.getElementById('modalPluginCatBadge').textContent = plugin.categoryName;
    document.getElementById('modalPluginBadge').textContent = plugin.badge;
    document.getElementById('modalPluginOverview').textContent = plugin.overview;

    // Media Box
    const mediaContainer = document.getElementById('modalMediaContainer');
    if (plugin.image) {
      mediaContainer.style.display = 'block';
      mediaContainer.innerHTML = `
        <div class="modal-media-box" data-lightbox-src="${plugin.image}" data-lightbox-title="${plugin.name}" title="Click to view full screen">
          <img src="${plugin.image}" alt="${plugin.name} Interface Screenshot">
        </div>
      `;
      // Re-attach lightbox trigger if lightbox is available
      if (typeof openLightbox === 'function') {
        mediaContainer.querySelector('.modal-media-box').addEventListener('click', () => {
          openLightbox(plugin.image, plugin.name, plugin.overview);
        });
      }
    } else {
      mediaContainer.style.display = 'none';
      mediaContainer.innerHTML = '';
    }

    // Specifications Grid
    document.getElementById('modalSpecLatency').textContent = plugin.specs.latency;
    document.getElementById('modalSpecRam').textContent = plugin.specs.hostRam;
    document.getElementById('modalSpecEngine').textContent = plugin.specs.engine;

    // Capabilities Checklist
    const capList = document.getElementById('modalCapabilitiesList');
    capList.innerHTML = plugin.capabilities.map(cap => `
      <li><span class="bullet-check">✓</span> <span>${cap}</span></li>
    `).join('');

    // Best For & Shortcut
    document.getElementById('modalBestForText').textContent = plugin.bestFor;
    document.getElementById('modalShortcutText').textContent = plugin.shortcut;

    // Counter
    document.getElementById('modalCounter').textContent = `${currentModalPluginIndex + 1} of ${plugins.length}`;
  }

  // Close Modal
  function closePluginModal() {
    modalOverlay.classList.remove('active');
    document.body.style.overflow = '';
    history.replaceState(null, '', window.location.pathname);
  }

  // Modal Navigation
  function navigateModal(step) {
    currentModalPluginIndex = (currentModalPluginIndex + step + plugins.length) % plugins.length;
    renderModalContent(plugins[currentModalPluginIndex]);
  }

  // Modal Event Listeners
  const closeBtn = document.getElementById('closePluginModalBtn');
  if (closeBtn) closeBtn.addEventListener('click', closePluginModal);

  modalOverlay.addEventListener('click', (e) => {
    if (e.target === modalOverlay) closePluginModal();
  });

  document.getElementById('modalPrevBtn').addEventListener('click', () => navigateModal(-1));
  document.getElementById('modalNextBtn').addEventListener('click', () => navigateModal(1));

  window.addEventListener('keydown', (e) => {
    if (!modalOverlay.classList.contains('active')) return;
    if (e.key === 'Escape') closePluginModal();
    if (e.key === 'ArrowLeft') navigateModal(-1);
    if (e.key === 'ArrowRight') navigateModal(1);
  });

  // Filter Tabs Event Listeners
  filterTabs.forEach(btn => {
    btn.addEventListener('click', () => {
      filterTabs.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      activeCategory = btn.getAttribute('data-category');
      renderPluginHub();
    });
  });

  // Search Input Event Listener
  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      searchQuery = e.target.value.toLowerCase().trim();
      renderPluginHub();
    });
  }

  // Initial Render
  renderPluginHub();

  // Check URL Hash for direct deep-link
  if (window.location.hash) {
    const targetId = window.location.hash.substring(1);
    if (targetId) openPluginDetail(targetId);
  }
});
