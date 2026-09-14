/**
 * Sphene 3D Crystal Gemstone Interactive Controller
 * Provides buttery-smooth 3D parallax tilt, dynamic facet specular glare,
 * and adamantine dispersion glow tracking the user's cursor.
 */
(function() {
  document.addEventListener('DOMContentLoaded', () => {
    const gem = document.getElementById('heroGem3D');
    const container = document.querySelector('.hero-gem-container');
    const glare = document.querySelector('.gem-glare');
    const glow = document.querySelector('.hero-gem-glow');

    if (!gem || !container) return;

    let targetRotX = 0;
    let targetRotY = 0;
    let currentRotX = 0;
    let currentRotY = 0;
    let isHovered = false;

    // Track mouse over entire window for subtle ambient response,
    // with heightened responsiveness when hovering near the hero.
    window.addEventListener('mousemove', (e) => {
      const rect = container.getBoundingClientRect();
      const gemCenterX = rect.left + rect.width / 2;
      const gemCenterY = rect.top + rect.height / 2;

      const distX = e.clientX - gemCenterX;
      const distY = e.clientY - gemCenterY;

      // Check if mouse is hovering in the vicinity
      const dist = Math.sqrt(distX * distX + distY * distY);
      isHovered = dist < 450;

      // Calculate tilt angles (max +- 28 deg when close, +- 10 deg when far)
      const maxAngle = isHovered ? 26 : 10;
      const normX = Math.max(-1, Math.min(1, distX / (window.innerWidth * 0.4)));
      const normY = Math.max(-1, Math.min(1, distY / (window.innerHeight * 0.4)));

      targetRotY = normX * maxAngle;
      targetRotX = -normY * maxAngle;

      // Shift dynamic specular glare point
      if (glare) {
        const glareX = 50 - normX * 35;
        const glareY = 40 - normY * 30;
        glare.style.background = `radial-gradient(circle at ${glareX}% ${glareY}%, rgba(255, 255, 255, 0.75) 0%, transparent 55%)`;
        glare.style.opacity = isHovered ? '0.75' : '0.45';
      }

      // Intensify ambient dispersion glow on proximity
      if (glow && isHovered) {
        const glowOpacity = Math.max(0.6, 1.0 - (dist / 500));
        glow.style.opacity = glowOpacity.toFixed(2);
      }
    });

    // Reset softly on mouse leave
    document.addEventListener('mouseleave', () => {
      targetRotX = 0;
      targetRotY = 0;
      if (glare) glare.style.opacity = '0.45';
    });

    // Mobile touch tracking
    container.addEventListener('touchmove', (e) => {
      if (e.touches.length > 0) {
        const touch = e.touches[0];
        const rect = container.getBoundingClientRect();
        const gemCenterX = rect.left + rect.width / 2;
        const gemCenterY = rect.top + rect.height / 2;
        const distX = touch.clientX - gemCenterX;
        const distY = touch.clientY - gemCenterY;
        targetRotY = (distX / (rect.width / 2)) * 20;
        targetRotX = -(distY / (rect.height / 2)) * 20;
      }
    }, { passive: true });

    container.addEventListener('touchend', () => {
      targetRotX = 0;
      targetRotY = 0;
    });

    // Spring physics render loop
    function animate() {
      // Smooth lerp (0.08 interpolation coefficient)
      currentRotX += (targetRotX - currentRotX) * 0.08;
      currentRotY += (targetRotY - currentRotY) * 0.08;

      const scale = isHovered ? 1.08 : 1.0;

      gem.style.transform = `perspective(850px) rotateX(${currentRotX.toFixed(2)}deg) rotateY(${currentRotY.toFixed(2)}deg) scale3d(${scale}, ${scale}, ${scale})`;

      requestAnimationFrame(animate);
    }

    animate();
  });
})();
