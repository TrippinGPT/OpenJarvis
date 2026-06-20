$Root = "D:\AI\TRIPPIN_AI_RELAY"

Write-Host "Starting Trippin AI Relay stack..." -ForegroundColor Magenta

Start-Process powershell -ArgumentList @(
  "-NoExit",
  "-ExecutionPolicy", "Bypass",
  "-Command",
  "cd `"$Root`"; uv run relay serve"
)

Start-Sleep -Seconds 2

Start-Process powershell -ArgumentList @(
  "-NoExit",
  "-ExecutionPolicy", "Bypass",
  "-Command",
  "cd `"$Root\frontend`"; npm run dev"
)

Write-Host "Relay backend and frontend launch commands sent." -ForegroundColor Green
Write-Host "Backend:  http://127.0.0.1:8000" -ForegroundColor Cyan
Write-Host "Frontend: use the Vite URL shown in the frontend window." -ForegroundColor Cyan
