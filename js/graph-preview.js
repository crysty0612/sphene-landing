(function() {
  const canvas = document.getElementById('heroGraphCanvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');

  let width, height;
  function resize() {
    width = canvas.width = canvas.parentElement.clientWidth;
    height = canvas.height = canvas.parentElement.clientHeight;
  }
  window.addEventListener('resize', resize);
  resize();

  const nodes = [
    { id: 'mesh', label: 'Distributed Mesh', x: 0, y: 0, vx: 0, vy: 0, radius: 10, color: '#38bdf8', category: 'architecture' },
    { id: 'db', label: 'Database Migration', x: 0, y: 0, vx: 0, vy: 0, radius: 8, color: '#10b981', category: 'lessons' },
    { id: 'hermes', label: 'Hermes Agent Memory', x: 0, y: 0, vx: 0, vy: 0, radius: 12, color: '#a855f7', category: 'agent' },
    { id: 'aegis', label: 'Aegis Crypto Shield', x: 0, y: 0, vx: 0, vy: 0, radius: 9, color: '#f59e0b', category: 'security' },
    { id: 'daily', label: 'Daily Note: Today', x: 0, y: 0, vx: 0, vy: 0, radius: 7, color: '#ec4899', category: 'daily' },
    { id: 'zettel', label: 'Zettelkasten Method', x: 0, y: 0, vx: 0, vy: 0, radius: 8, color: '#38bdf8', category: 'concept' },
    { id: 'ingest', label: 'Ingestion Worker', x: 0, y: 0, vx: 0, vy: 0, radius: 7, color: '#a855f7', category: 'agent' },
    { id: 'tasks', label: 'Interactive Checklists', x: 0, y: 0, vx: 0, vy: 0, radius: 6, color: '#10b981', category: 'features' },
    { id: 'vault', label: 'Plaintext Markdown', x: 0, y: 0, vx: 0, vy: 0, radius: 9, color: '#38bdf8', category: 'substrate' }
  ];

  const links = [
    { source: 'mesh', target: 'db' },
    { source: 'mesh', target: 'zettel' },
    { source: 'hermes', target: 'mesh' },
    { source: 'hermes', target: 'daily' },
    { source: 'hermes', target: 'ingest' },
    { source: 'aegis', target: 'vault' },
    { source: 'vault', target: 'mesh' },
    { source: 'vault', target: 'tasks' },
    { source: 'db', target: 'tasks' },
    { source: 'zettel', target: 'daily' }
  ];

  // Random initial positions around center
  nodes.forEach(n => {
    n.x = (width / 2) + (Math.random() - 0.5) * 260;
    n.y = (height / 2) + (Math.random() - 0.5) * 180;
  });

  let hoveredNode = null;
  let draggedNode = null;
  let mouse = { x: 0, y: 0 };

  canvas.addEventListener('mousemove', e => {
    const rect = canvas.getBoundingClientRect();
    mouse.x = e.clientX - rect.left;
    mouse.y = e.clientY - rect.top;

    if (draggedNode) {
      draggedNode.x = mouse.x;
      draggedNode.y = mouse.y;
      return;
    }

    hoveredNode = null;
    for (const node of nodes) {
      const dx = mouse.x - node.x;
      const dy = mouse.y - node.y;
      if (Math.sqrt(dx * dx + dy * dy) < node.radius + 6) {
        hoveredNode = node;
        canvas.style.cursor = 'pointer';
        return;
      }
    }
    canvas.style.cursor = 'default';
  });

  canvas.addEventListener('mousedown', () => {
    if (hoveredNode) {
      draggedNode = hoveredNode;
    }
  });

  window.addEventListener('mouseup', () => {
    draggedNode = null;
  });

  function tick() {
    // Center gravity
    const cx = width / 2;
    const cy = height / 2;

    nodes.forEach(n => {
      if (n === draggedNode) return;
      n.vx += (cx - n.x) * 0.0008;
      n.vy += (cy - n.y) * 0.0008;

      // Node repulsion
      nodes.forEach(other => {
        if (n === other) return;
        const dx = n.x - other.x;
        const dy = n.y - other.y;
        const dist = Math.sqrt(dx * dx + dy * dy) || 1;
        if (dist < 180) {
          const force = (180 - dist) / 180 * 0.12;
          n.vx += (dx / dist) * force;
          n.vy += (dy / dist) * force;
        }
      });

      // Damping
      n.vx *= 0.88;
      n.vy *= 0.88;

      n.x += n.vx;
      n.y += n.vy;

      // Bounds
      n.x = Math.max(n.radius + 10, Math.min(width - n.radius - 10, n.x));
      n.y = Math.max(n.radius + 10, Math.min(height - n.radius - 10, n.y));
    });

    // Spring links
    links.forEach(l => {
      const s = nodes.find(n => n.id === l.source);
      const t = nodes.find(n => n.id === l.target);
      if (!s || !t) return;

      const dx = t.x - s.x;
      const dy = t.y - s.y;
      const dist = Math.sqrt(dx * dx + dy * dy) || 1;
      const targetDist = 110;
      const force = (dist - targetDist) * 0.002;

      if (s !== draggedNode) {
        s.vx += (dx / dist) * force;
        s.vy += (dy / dist) * force;
      }
      if (t !== draggedNode) {
        t.vx -= (dx / dist) * force;
        t.vy -= (dy / dist) * force;
      }
    });
  }

  function draw() {
    ctx.clearRect(0, 0, width, height);

    // Draw Links
    links.forEach(l => {
      const s = nodes.find(n => n.id === l.source);
      const t = nodes.find(n => n.id === l.target);
      if (!s || !t) return;

      const isConnected = hoveredNode && (hoveredNode.id === s.id || hoveredNode.id === t.id);

      ctx.beginPath();
      ctx.moveTo(s.x, s.y);
      ctx.lineTo(t.x, t.y);
      ctx.strokeStyle = isConnected ? 'rgba(56, 189, 248, 0.8)' : 'rgba(255, 255, 255, 0.12)';
      ctx.lineWidth = isConnected ? 2.2 : 1;
      ctx.stroke();
    });

    // Draw Nodes
    nodes.forEach(n => {
      const isHovered = hoveredNode && hoveredNode.id === n.id;

      // Glow halo
      if (isHovered) {
        ctx.beginPath();
        ctx.arc(n.x, n.y, n.radius + 10, 0, Math.PI * 2);
        ctx.fillStyle = 'rgba(56, 189, 248, 0.2)';
        ctx.fill();
      }

      // Core circle
      ctx.beginPath();
      ctx.arc(n.x, n.y, n.radius, 0, Math.PI * 2);
      ctx.fillStyle = n.color;
      ctx.shadowColor = n.color;
      ctx.shadowBlur = isHovered ? 18 : 6;
      ctx.fill();
      ctx.shadowBlur = 0;

      // Label
      ctx.font = isHovered ? '600 13px -apple-system, sans-serif' : '500 11px -apple-system, sans-serif';
      ctx.fillStyle = isHovered ? '#ffffff' : '#94a3b8';
      ctx.textAlign = 'center';
      ctx.fillText(n.label, n.x, n.y + n.radius + 15);
    });

    tick();
    requestAnimationFrame(draw);
  }

  draw();
})();
