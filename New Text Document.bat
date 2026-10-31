
@echo off
title FORCE UPLOAD PROJECT TO GITHUB
color 0A

echo ==========================================
echo       GITHUB FORCE UPLOAD
echo ==========================================
echo.

:: Check Git installation
git --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Git is not installed!
    pause
    exit /b 1
)

:: Check Git repository
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo ERROR: This folder is not a Git repository.
    pause
    exit /b 1
)

:: Get current branch
for /f "delims=" %%B in ('git branch --show-current') do set BRANCH=%%B

if "%BRANCH%"=="" (
    echo ERROR: No Git branch found.
    pause
    exit /b 1
)

echo Current branch: %BRANCH%
echo.

:: Stage entire project
echo [1/4] Adding all project files...
git add -A
if errorlevel 1 goto ERROR

:: Commit changes
echo.
echo [2/4] Creating commit...
git diff --cached --quiet
if errorlevel 1 (
    git commit -m "Force upload: Update entire project"
    if errorlevel 1 goto ERROR
) else (
    echo No new changes to commit.
)

:: Force push to GitHub
echo.
echo [3/4] Force pushing to GitHub...
git push --force-with-lease -u origin "%BRANCH%"
if errorlevel 1 goto ERROR

echo.
echo [4/4] UPLOAD COMPLETED!
echo ==========================================
echo       GITHUB PUSH SUCCESSFUL
echo ==========================================
pause
exit /b 0

:ERROR
echo.
echo ==========================================
echo       UPLOAD FAILED!
echo ==========================================
echo Check your GitHub authentication,
echo remote URL and network connection.
pause
exit /b 1
