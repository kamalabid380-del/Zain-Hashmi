# Static file server for the Zain Hashmi offline copy.
# Serves zain-hashmi-site/ at http://127.0.0.1:80020/ and opens the browser.

$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot 'zain-hashmi-site'
$rootFull = [System.IO.Path]::GetFullPath($root).TrimEnd('\')
$port = 3000
$url = "http://127.0.0.1:$port/"

$mime = @{
  '.html'='text/html; charset=utf-8'; '.htm'='text/html; charset=utf-8'
  '.css'='text/css; charset=utf-8'; '.js'='application/javascript; charset=utf-8'
  '.json'='application/json'; '.xml'='application/xml'; '.txt'='text/plain; charset=utf-8'
  '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'; '.png'='image/png'; '.gif'='image/gif'
  '.webp'='image/webp'; '.avif'='image/avif'; '.svg'='image/svg+xml'; '.ico'='image/x-icon'
  '.woff'='font/woff'; '.woff2'='font/woff2'; '.ttf'='font/ttf'; '.eot'='application/vnd.ms-fontobject'
  '.mp4'='video/mp4'; '.webm'='video/webm'; '.map'='application/json'
}

$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $port)
try {
  $listener.Start()
} catch {
  # Already running: just bring the page up.
  Start-Process $url
  exit 0
}

Start-Process $url

while ($true) {
  $client = $listener.AcceptTcpClient()
  try {
    $stream = $client.GetStream()
    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII, $false, 4096, $true)
    $requestLine = $reader.ReadLine()
    if ([string]::IsNullOrWhiteSpace($requestLine)) { $client.Close(); continue }
    while ($true) {
      $h = $reader.ReadLine()
      if ([string]::IsNullOrEmpty($h)) { break }
    }

    $parts = $requestLine -split ' '
    $method = $parts[0]
    $rawPath = $parts[1]
    if ($rawPath -notmatch '^/') { $rawPath = '/' }
    $path = [System.Uri]::UnescapeDataString(($rawPath -split '\?')[0])
    $path = $path -replace '/', '\'
    $full = [System.IO.Path]::GetFullPath($rootFull + $path)

    $status = '200 OK'
    $body = $null
    $type = 'application/octet-stream'

    if (-not $full.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
      $status = '403 Forbidden'
      $body = [System.Text.Encoding]::UTF8.GetBytes('403 Forbidden')
      $type = 'text/plain; charset=utf-8'
    } elseif (Test-Path -LiteralPath $full -PathType Container) {
      if (-not $path.EndsWith('\')) {
        $location = $url.TrimEnd('/') + ($path -replace '\\','/') + '/'
        $header = "HTTP/1.1 301 Moved Permanently`r`nLocation: $location`r`nContent-Length: 0`r`nConnection: close`r`n`r`n"
        $hb = [System.Text.Encoding]::ASCII.GetBytes($header)
        $stream.Write($hb, 0, $hb.Length); $stream.Flush(); $client.Close(); continue
      }
      $full = Join-Path $full 'index.html'
    }

    if ($null -eq $body) {
      if (Test-Path -LiteralPath $full -PathType Leaf) {
        $body = [System.IO.File]::ReadAllBytes($full)
        $ext = [System.IO.Path]::GetExtension($full).ToLower()
        if ($mime.ContainsKey($ext)) { $type = $mime[$ext] }
      } else {
        $status = '404 Not Found'
        $body = [System.Text.Encoding]::UTF8.GetBytes('404 Not Found')
        $type = 'text/plain; charset=utf-8'
      }
    }

    $header = "HTTP/1.1 $status`r`nContent-Type: $type`r`nContent-Length: $($body.Length)`r`nCache-Control: no-cache`r`nConnection: close`r`n`r`n"
    $hb = [System.Text.Encoding]::ASCII.GetBytes($header)
    $stream.Write($hb, 0, $hb.Length)
    if ($method -ne 'HEAD') { $stream.Write($body, 0, $body.Length) }
    $stream.Flush()
  } catch {
    # Ignore malformed or aborted requests.
  } finally {
    $client.Close()
  }
}
