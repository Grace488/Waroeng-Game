#!/usr/bin/env python3
"""
Automated Web Export Script for Waroeng (Godot 4.7)
Runs headless Godot export to build/web/
"""

import os
import sys
import subprocess

PROJECT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BUILD_DIR = os.path.join(PROJECT_DIR, "build", "web")
OUTPUT_HTML = os.path.join(BUILD_DIR, "index.html")

# Common Godot binary paths on the user's system
CANDIDATE_GODOT_PATHS = [
    r"C:\Users\acer\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe",
    r"C:\Users\acer\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe",
]

def find_godot():
    for p in CANDIDATE_GODOT_PATHS:
        if os.path.isfile(p):
            return p
    # Try PATH
    import shutil
    for name in ["godot", "godot4", "Godot_v4.7.2-stable_win64"]:
        which = shutil.which(name)
        if which:
            return which
    return None

def export():
    godot_bin = find_godot()
    if not godot_bin:
        print("ERROR: Godot executable not found!")
        sys.exit(1)

    print("=" * 60)
    print(f"Exporting Waroeng to Web (HTML5/WebAssembly)...")
    print(f"Using Godot: {godot_bin}")
    print(f"Output: {OUTPUT_HTML}")
    print("=" * 60)

    os.makedirs(BUILD_DIR, exist_ok=True)

    cmd = [
        godot_bin,
        "--headless",
        "--path", PROJECT_DIR,
        "--export-release", "Web",
        OUTPUT_HTML,
    ]

    result = subprocess.run(cmd)
    if result.returncode == 0:
        print("\n[OK] Godot Web export completed!")
        enrich_html(OUTPUT_HTML)
        print(f"Files ready in: {BUILD_DIR}")
        print("\nTo test the game in your browser, run:")
        print("  python tools/serve_web.py")
    else:
        print(f"\n[ERROR] Export failed with exit code {result.returncode}")
        sys.exit(result.returncode)

def enrich_html(html_path):
    """Enriches the Godot web player with a modern glassmorphic header, controls guide, and fullscreen toggle."""
    if not os.path.isfile(html_path):
        return

    with open(html_path, "r", encoding="utf-8") as f:
        content = f.read()

    custom_css = """
/* Waroeng Premium Web Styling */
@import url('https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700&display=swap');

body {
    font-family: 'Outfit', sans-serif;
    margin: 0;
    padding: 0;
    background-color: #0d0e15;
    color: #f1f2f6;
    overflow: hidden;
    user-select: none;
}

#canvas {
    display: block;
    image-rendering: pixelated;
    image-rendering: crisp-edges;
}

/* Floating Header Bar */
.waroeng-header {
    position: fixed;
    top: 12px;
    left: 50%;
    transform: translateX(-50%);
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: min(94%, 960px);
    background: rgba(22, 24, 38, 0.75);
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 14px;
    padding: 8px 18px;
    z-index: 100;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
    pointer-events: auto;
    transition: opacity 0.3s ease;
}

.waroeng-brand {
    display: flex;
    align-items: center;
    gap: 10px;
}

.waroeng-title {
    font-size: 1.15rem;
    font-weight: 700;
    letter-spacing: 0.5px;
    background: linear-gradient(135deg, #ff7675, #fab1a0, #fdcb6e);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
}

.waroeng-badge {
    font-size: 0.7rem;
    font-weight: 600;
    text-transform: uppercase;
    background: rgba(233, 69, 96, 0.2);
    color: #ff7675;
    border: 1px solid rgba(233, 69, 96, 0.4);
    padding: 2px 8px;
    border-radius: 20px;
}

.waroeng-actions {
    display: flex;
    align-items: center;
    gap: 8px;
}

.waroeng-btn {
    background: rgba(255, 255, 255, 0.08);
    color: #e4e7eb;
    border: 1px solid rgba(255, 255, 255, 0.15);
    border-radius: 8px;
    padding: 6px 14px;
    font-size: 0.82rem;
    font-weight: 600;
    font-family: inherit;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    gap: 6px;
    transition: all 0.2s ease;
}

.waroeng-btn:hover {
    background: rgba(233, 69, 96, 0.35);
    border-color: #e94560;
    color: #ffffff;
    transform: translateY(-1px);
}

/* Floating Bottom Controls Guide */
.waroeng-controls {
    position: fixed;
    bottom: 12px;
    left: 50%;
    transform: translateX(-50%);
    display: flex;
    align-items: center;
    gap: 14px;
    background: rgba(22, 24, 38, 0.7);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 20px;
    padding: 6px 18px;
    font-size: 0.78rem;
    color: #b2bec3;
    z-index: 100;
    pointer-events: none;
}

.waroeng-controls kbd {
    background: rgba(255, 255, 255, 0.15);
    color: #ffffff;
    padding: 2px 6px;
    border-radius: 4px;
    font-weight: 600;
    font-family: inherit;
}

/* Modal Popup */
.waroeng-modal {
    position: fixed;
    inset: 0;
    background: rgba(8, 9, 14, 0.75);
    backdrop-filter: blur(8px);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 200;
    opacity: 0;
    pointer-events: none;
    transition: opacity 0.25s ease;
}

.waroeng-modal.active {
    opacity: 1;
    pointer-events: auto;
}

.waroeng-modal-card {
    background: #181a29;
    border: 1px solid rgba(255, 255, 255, 0.15);
    border-radius: 18px;
    width: min(90%, 520px);
    padding: 24px;
    box-shadow: 0 20px 50px rgba(0, 0, 0, 0.6);
    transform: translateY(20px);
    transition: transform 0.25s ease;
}

.waroeng-modal.active .waroeng-modal-card {
    transform: translateY(0);
}

.modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 18px;
}

.modal-header h3 {
    margin: 0;
    font-size: 1.25rem;
    color: #ff7675;
}

.modal-close {
    background: none;
    border: none;
    color: #b2bec3;
    font-size: 1.5rem;
    cursor: pointer;
    line-height: 1;
    padding: 0;
}

.modal-close:hover {
    color: #ffffff;
}

.guide-step {
    display: flex;
    gap: 14px;
    margin-bottom: 14px;
    align-items: flex-start;
}

.step-badge {
    background: #e94560;
    color: white;
    font-weight: 700;
    font-size: 0.85rem;
    width: 26px;
    height: 26px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
}

.guide-step h4 {
    margin: 0 0 4px 0;
    font-size: 0.95rem;
    color: #ffffff;
}

.guide-step p {
    margin: 0;
    font-size: 0.83rem;
    color: #b2bec3;
    line-height: 1.4;
}

#status {
    background-color: #0f101d !important;
}

#status-progress {
    accent-color: #e94560;
}
"""

    custom_html = """
		<!-- Waroeng Web Header Bar -->
		<header class="waroeng-header" id="waroengHeader">
			<div class="waroeng-brand">
				<span class="waroeng-title">🍚 Waroeng</span>
				<span class="waroeng-badge">Pixel Art</span>
			</div>
			<div class="waroeng-actions">
				<button class="waroeng-btn" id="btnGuide">📖 Panduan</button>
				<button class="waroeng-btn" id="btnFullscreen">⛶ Layar Penuh</button>
			</div>
		</header>

		<!-- Waroeng Bottom Controls Hint -->
		<div class="waroeng-controls">
			<span>⌨️ Gerak: <kbd>WASD</kbd> / <kbd>Panah</kbd></span>
			<span>🚪 Masuk: <kbd>Spasi</kbd></span>
			<span>🖱️ Pilih & Masak: <kbd>Klik</kbd></span>
		</div>

		<!-- Guide Modal -->
		<div class="waroeng-modal" id="guideModal">
			<div class="waroeng-modal-card">
				<div class="modal-header">
					<h3>📖 Cara Bermain Waroeng</h3>
					<button class="modal-close" id="modalClose">&times;</button>
				</div>
				<div class="modal-body">
					<div class="guide-step">
						<div class="step-badge">1</div>
						<div>
							<h4>Pagi — Jelajahi & Beli Bahan</h4>
							<p>Gunakan tombol panah atau klik lokasi di peta untuk membeli bahan masakan (Pasar Tradisional, Sawah, Hutan).</p>
						</div>
					</div>
					<div class="guide-step">
						<div class="step-badge">2</div>
						<div>
							<h4>Malam — Buka Waroeng</h4>
							<p>Tekan tombol <b>Buka Warung</b>. Layani pelanggan yang duduk dengan memasak hidangan sesuai pesanan sebelum kesabaran mereka habis.</p>
						</div>
					</div>
					<div class="guide-step">
						<div class="step-badge">3</div>
						<div>
							<h4>Keuntungan & Upgrade</h4>
							<p>Dapatkan penghasilan harian, temukan resep rahasia (hidden gems), dan beli upgrade warung untuk mengembangkan usahamu!</p>
						</div>
					</div>
				</div>
			</div>
		</div>

		<script>
		// Setup Interactive Header & Controls
		document.addEventListener('DOMContentLoaded', () => {
			const btnFullscreen = document.getElementById('btnFullscreen');
			const btnGuide = document.getElementById('btnGuide');
			const modal = document.getElementById('guideModal');
			const modalClose = document.getElementById('modalClose');

			if (btnFullscreen) {
				btnFullscreen.addEventListener('click', () => {
					if (!document.fullscreenElement) {
						document.documentElement.requestFullscreen().catch(console.error);
						btnFullscreen.textContent = '🗗 Keluar Penuh';
					} else {
						document.exitFullscreen().catch(console.error);
						btnFullscreen.textContent = '⛶ Layar Penuh';
					}
				});
				document.addEventListener('fullscreenchange', () => {
					if (!document.fullscreenElement) {
						btnFullscreen.textContent = '⛶ Layar Penuh';
					}
				});
			}

			if (btnGuide && modal && modalClose) {
				btnGuide.addEventListener('click', () => modal.classList.add('active'));
				modalClose.addEventListener('click', () => modal.classList.remove('active'));
				modal.addEventListener('click', (e) => {
					if (e.target === modal) modal.classList.remove('active');
				});
			}
		});
		</script>
    """

    # Inject CSS before </style>
    if "</style>" in content and "/* Waroeng Premium Web Styling */" not in content:
        content = content.replace("</style>", custom_css + "\n</style>")

    # Inject HTML before </body>
    if "</body>" in content and "waroeng-header" not in content:
        content = content.replace("</body>", custom_html + "\n</body>")

    with open(html_path, "w", encoding="utf-8") as f:
        f.write(content)

    print("  [Enriched] index.html updated with Waroeng player shell and controls guide.")


if __name__ == "__main__":
    export()
