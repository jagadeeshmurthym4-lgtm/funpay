// Generate simple icon PNGs for PWA
const { createCanvas } = (() => {
  try { return require('canvas'); } catch(e) { return null; }
})();

const fs = require('fs');
const path = require('path');

// If canvas module isn't available, create SVG icons instead
function createSvgIcon(size) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#ffd700"/>
      <stop offset="100%" style="stop-color:#ff8c42"/>
    </linearGradient>
  </defs>
  <rect width="${size}" height="${size}" rx="${size * 0.2}" fill="url(#bg)"/>
  <text x="50%" y="55%" dominant-baseline="middle" text-anchor="middle" font-size="${size * 0.5}" font-family="sans-serif" fill="#0b0d15">⚡</text>
</svg>`;
}

// Generate SVG icons - they work fine for PWA
const sizes = [192, 512];
sizes.forEach(size => {
  const svg = createSvgIcon(size);
  fs.writeFileSync(path.join(__dirname, `icon-${size}.svg`), svg);
  console.log(`Created icon-${size}.svg`);
});

// Also create a simple HTML page icon generator
const htmlContent = `<!DOCTYPE html>
<html><body>
<canvas id="c"></canvas>
<script>
const sizes = [192, 512];
sizes.forEach(size => {
  const c = document.createElement('canvas');
  c.width = size;
  c.height = size;
  const ctx = c.getContext('2d');
  const grad = ctx.createLinearGradient(0, 0, size, size);
  grad.addColorStop(0, '#ffd700');
  grad.addColorStop(1, '#ff8c42');
  const r = size * 0.2;
  ctx.beginPath();
  ctx.moveTo(r, 0);
  ctx.lineTo(size - r, 0);
  ctx.quadraticCurveTo(size, 0, size, r);
  ctx.lineTo(size, size - r);
  ctx.quadraticCurveTo(size, size, size - r, size);
  ctx.lineTo(r, size);
  ctx.quadraticCurveTo(0, size, 0, size - r);
  ctx.lineTo(0, r);
  ctx.quadraticCurveTo(0, 0, r, 0);
  ctx.closePath();
  ctx.fillStyle = grad;
  ctx.fill();
  ctx.fillStyle = '#0b0d15';
  ctx.font = \`bold \${size * 0.45}px sans-serif\`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('⚡', size/2, size/2 + size * 0.05);
  c.toBlob(blob => {
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = \`icon-\${size}.png\`;
    a.click();
  });
});
<\/script>
</body></html>`;

fs.writeFileSync(path.join(__dirname, 'generate-png-icons.html'), htmlContent);
console.log('Created generate-png-icons.html - open in browser to generate PNG icons');
console.log('Done! SVG icons created. Update manifest.json to use .svg or open the HTML file to generate PNGs.');
