@echo off
echo Starting deployment...
echo.

echo Adding all changes...
git add .
if %errorlevel% neq 0 (
    echo Error: Failed to add files
    pause
    exit /b 1
)

echo.
echo Committing changes...
git commit -m "update"
if %errorlevel% neq 0 (
    echo Error: Failed to commit changes
    pause
    exit /b 1
)

echo.
echo Pushing to remote repository...
git push
if %errorlevel% neq 0 (
    echo Error: Failed to push changes
    pause
    exit /b 1
)

echo.
echo Deployment completed successfully!
pause
