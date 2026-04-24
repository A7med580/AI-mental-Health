# 1. Activate the Python virtual environment
if (Test-Path ".\.venv\Scripts\Activate.ps1") {
    Write-Host "Activating local .venv..."
    $env:PATH = "$(Get-Location)\.venv\Scripts;" + $env:PATH
} elseif (Test-Path "..\venv\Scripts\Activate.ps1") {
    Write-Host "Activating parent venv..."
    $env:PATH = "$(Get-Item ..\venv\Scripts).FullName;" + $env:PATH
} else {
    Write-Warning "Virtual environment not found."
}

# 2. Start the server
Write-Host "Starting Uvicorn server..."
python -m uvicorn main:app --host 0.0.0.0 --port 8000
