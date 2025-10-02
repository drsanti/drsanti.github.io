Write-Host "Starting deployment..." -ForegroundColor Green
Write-Host ""

Write-Host "Adding all changes..." -ForegroundColor Yellow
git add .
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to add files" -ForegroundColor Red
    Read-Host "Press Enter to continue"
    exit 1
}

Write-Host ""
Write-Host "Committing changes..." -ForegroundColor Yellow
git commit -m "update"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to commit changes" -ForegroundColor Red
    Read-Host "Press Enter to continue"
    exit 1
}

Write-Host ""
Write-Host "Pushing to remote repository..." -ForegroundColor Yellow
git push
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to push changes" -ForegroundColor Red
    Read-Host "Press Enter to continue"
    exit 1
}

Write-Host ""
Write-Host "Deployment completed successfully!" -ForegroundColor Green
Read-Host "Press Enter to continue"
