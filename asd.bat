
@echo off
setlocal
title FIX AND PUBLISH WEBSITE ON GITHUB PAGES
color 0A

echo ==========================================
echo       GITHUB PAGES AUTO DEPLOY
echo ==========================================
echo.

git --version >nul 2>&1
if errorlevel 1 (
 echo Git is not installed.
 pause
 exit /b 1
)

git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
 echo Run this file inside your Git project folder.
 pause
 exit /b 1
)

if not exist index.html (
 echo ERROR: index.html not found in project root.
 echo Your website may need a framework-specific build.
 pause
 exit /b 1
)

git remote get-url origin >nul 2>&1
if errorlevel 1 (
 echo No GitHub remote named origin found.
 pause
 exit /b 1
)

for /f "delims=" %%B in ('git branch --show-current') do set BRANCH=%%B

if "%BRANCH%"=="" (
 echo No current branch found.
 pause
 exit /b 1
)

echo Creating GitHub Pages workflow...

if not exist ".github\workflows" mkdir ".github\workflows"

set "WF=.github\workflows\pages.yml"

> "%WF%" echo name: Deploy Website
>> "%WF%" echo on:
>> "%WF%" echo   push:
>> "%WF%" echo   workflow_dispatch:
>> "%WF%" echo permissions:
>> "%WF%" echo   contents: read
>> "%WF%" echo   pages: write
>> "%WF%" echo   id-token: write
>> "%WF%" echo concurrency:
>> "%WF%" echo   group: pages
>> "%WF%" echo   cancel-in-progress: true
>> "%WF%" echo jobs:
>> "%WF%" echo   deploy:
>> "%WF%" echo     environment:
>> "%WF%" echo       name: github-pages
>> "%WF%" echo       url: ${{ steps.deployment.outputs.page_url }}
>> "%WF%" echo     runs-on: ubuntu-latest
>> "%WF%" echo     steps:
>> "%WF%" echo       - uses: actions/checkout@v4
>> "%WF%" echo       - uses: actions/configure-pages@v5
>> "%WF%" echo       - uses: actions/upload-pages-artifact@v3
>> "%WF%" echo         with:
>> "%WF%" echo           path: .
>> "%WF%" echo       - name: Deploy to GitHub Pages
>> "%WF%" echo         id: deployment
>> "%WF%" echo         uses: actions/deploy-pages@v4

echo.> .nojekyll

echo Adding project files...
git add -A
if errorlevel 1 goto ERROR

git diff --cached --quiet
if errorlevel 1 (
 git commit -m "Configure GitHub Pages deployment"
 if errorlevel 1 goto ERROR
)

echo.
echo Uploading to GitHub...
git push -u origin "%BRANCH%"
if errorlevel 1 goto ERROR

echo.
echo ==========================================
echo FILES UPLOADED SUCCESSFULLY!
echo ==========================================
echo.
echo NOW COMPLETE THE SETTINGS BELOW:
echo 1. Open your GitHub repository.
echo 2. Go to Settings.
echo 3. Click Pages.
echo 4. Under Build and deployment,
echo    select GitHub Actions as Source.
echo 5. Open the Actions tab.
echo 6. Wait for deployment to finish.
echo.
echo Your website will then be published!
echo.
pause
exit /b 0

:ERROR
echo.
echo ERROR: Something went wrong.
echo Check GitHub authentication and settings.
pause
exit /b 1
