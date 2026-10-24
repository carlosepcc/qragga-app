import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PORT = 3000;
const HOST = '0.0.0.0';

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(`<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>QRagga — Flutter Barcode & QR Utility</title>
  <style>
    :root {
      --primary: #6750A4;
      --on-primary: #FFFFFF;
      --surface: #FEF7FF;
      --surface-container: #F3EDF7;
      --on-surface: #1D1B20;
      --outline: #79747E;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      margin: 0;
      padding: 0;
      background: var(--surface);
      color: var(--on-surface);
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      box-sizing: border-box;
    }
    .container {
      max-width: 680px;
      margin: 32px 16px;
      background: #FFFFFF;
      border-radius: 28px;
      box-shadow: 0 4px 24px rgba(0,0,0,0.06);
      padding: 36px 32px;
      border: 1px solid #EADDFF;
    }
    .badge {
      display: inline-block;
      background: #E8DEF8;
      color: #1D192B;
      padding: 6px 14px;
      border-radius: 100px;
      font-size: 13px;
      font-weight: 600;
      margin-bottom: 16px;
    }
    h1 {
      margin: 0 0 10px 0;
      font-size: 26px;
      font-weight: 800;
      color: #21005D;
    }
    p {
      margin: 0 0 16px 0;
      line-height: 1.6;
      color: #49454F;
      font-size: 15px;
    }
    .card {
      background: var(--surface-container);
      border-radius: 16px;
      padding: 20px;
      margin: 20px 0;
    }
    .card h3 {
      margin: 0 0 10px 0;
      font-size: 16px;
      color: var(--primary);
    }
    ul {
      margin: 8px 0 0 0;
      padding-left: 20px;
      color: #49454F;
      font-size: 14px;
      line-height: 1.6;
    }
    pre {
      background: #1E1B2E;
      color: #F8FAFC;
      padding: 14px 16px;
      border-radius: 12px;
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
      font-size: 13px;
      overflow-x: auto;
      margin: 10px 0;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="badge">🚀 Proyecto Flutter Listo</div>
    <h1>QRagga — Offline Barcodes & QR</h1>
    <p>La aplicación ha sido completamente migrada a <strong>Flutter (Material 3)</strong> conservando todas las capacidades de generación y escaneo de códigos 1D/2D.</p>
    
    <div class="card">
      <h3>📁 Estructura Flutter disponible en este repositorio:</h3>
      <ul>
        <li><strong>pubspec.yaml</strong>: Dependencias (<code>barcode_widget</code>, <code>barcode</code>, <code>qr_flutter</code>, <code>mobile_scanner</code>, <code>shared_preferences</code>, etc.)</li>
        <li><strong>android/</strong>: Configuración Gradle y AndroidManifest con permisos de cámara y guardado</li>
        <li><strong>ios/</strong>: Runner con Info.plist de permisos</li>
        <li><strong>lib/models/</strong>: Barcodes 2D (QR, Aztec, DataMatrix, PDF417) y 1D (Code 128, Code 39, EAN-13, EAN-8, UPC-A, Codabar, ITF)</li>
        <li><strong>lib/screens/</strong>: Creator, Scanner, Card Designer, History y Settings</li>
        <li><strong>lib/services/</strong>: Persistencia offline y copias de seguridad JSON</li>
      </ul>
    </div>

    <p><strong>Para ejecutar en Android Studio:</strong></p>
    <pre>flutter pub get
flutter run</pre>
  </div>
</body>
</html>`);
});

server.listen(PORT, HOST, () => {
  console.log(`Flutter preview server listening on http://${HOST}:${PORT}`);
});
