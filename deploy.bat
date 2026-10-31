@echo off
setlocal EnableExtensions
title GITHUB PAGES - AUTO DEPLOY
color 0A

echo.
echo ========================================================
echo           GITHUB PAGES AUTO DEPLOY SYSTEM
echo ========================================================
echo.

REM ========================================================
REM 1. CHECK REQUIRED TOOLS
REM ========================================================

where git >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git is not installed or not in PATH.
    echo Install Git, then reopen this terminal.
    goto FAILED
)

git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Run this file inside your Git project folder.
    goto FAILED
)

git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo [ERROR] No Git remote named origin was found.
    echo Add your GitHub repository as the origin remote.
    goto FAILED
)

for /f "delims=" %%B in ('git branch --show-current') do set "BRANCH=%%B"

if not defined BRANCH (
    echo [ERROR] No current Git branch was found.
    goto FAILED
)

echo [OK] Git is installed.
echo [OK] Git project detected.
echo [OK] GitHub origin remote detected.
echo [OK] Current branch: %BRANCH%
echo.

REM ========================================================
REM 2. FIND REPOSITORY AND GITHUB PAGES URL
REM ========================================================

for /f "tokens=1-5 delims=|" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$u=(git remote get-url origin).Trim(); if($u -match 'github\.com[:/](?<owner>[^/]+)/(?<repo>[^/]+?)(?:\.git)?$') { $o=$Matches.owner; $r=$Matches.repo; $base='https://github.com/'+$o+'/'+$r; if($r -ieq ($o+'.github.io')) { $page='https://'+$r+'/' } else { $page='https://'+$o+'.github.io/'+$r+'/' }; Write-Output ($o+'|'+$r+'|'+$base+'|'+$page+'|'+$base+'/actions') } else { exit 1 }" 2^>nul') do (
    set "OWNER=%%A"
    set "REPO=%%B"
    set "REPO_URL=%%C"
    set "PAGES_URL=%%D"
    set "ACTIONS_URL=%%E"
)

if not defined REPO_URL (
    echo [ERROR] Could not determine the GitHub repository.
    echo Make sure origin points to a GitHub repository.
    goto FAILED
)

echo [OK] Repository: %OWNER%/%REPO%
echo [INFO] Website URL: %PAGES_URL%
echo.

REM ========================================================
REM 3. VERIFY STATIC WEBSITE ENTRY POINT
REM ========================================================

if not exist "index.html" (
    echo [ERROR] index.html was not found in the project root.
    echo.
    echo This script currently supports static websites.
    echo For React, Vite, Vue, Angular or other frameworks,
    echo configure the appropriate build command and output folder.
    goto FAILED
)

REM ========================================================
REM 4. CREATE GITHUB PAGES WORKFLOW
REM ========================================================

echo [STEP 1/4] Configuring GitHub Pages workflow...

if not exist ".github\workflows" mkdir ".github\workflows"
if not exist ".github\workflows" (
    echo [ERROR] Could not create the workflow directory.
    goto FAILED
)

set "WF=.github\workflows\pages.yml"

> "%WF%" echo name: Deploy Website
>> "%WF%" echo on:
>> "%WF%" echo   push:
>> "%WF%" echo     branches:
>> "%WF%" echo       - main
>> "%WF%" echo       - master
>> "%WF%" echo       - develop
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
>> "%WF%" echo       - name: Checkout repository
>> "%WF%" echo         uses: actions/checkout@v4
>> "%WF%" echo       - name: Configure Pages
>> "%WF%" echo         uses: actions/configure-pages@v5
>> "%WF%" echo       - name: Upload website files
>> "%WF%" echo         uses: actions/upload-pages-artifact@v3
>> "%WF%" echo         with:
>> "%WF%" echo           path: .
>> "%WF%" echo       - name: Publish website
>> "%WF%" echo         id: deployment
>> "%WF%" echo         uses: actions/deploy-pages@v4

if errorlevel 1 (
    echo [ERROR] Could not create the workflow.
    goto FAILED
)

if not exist ".nojekyll" type nul > ".nojekyll"

echo [OK] Workflow configured.
echo.

REM ========================================================
REM 5. STAGE, COMMIT AND PUSH ALL PROJECT CHANGES
REM ========================================================

echo [STEP 2/4] Checking project changes...
git add -A
if errorlevel 1 goto GIT_ERROR

git diff --cached --quiet
if errorlevel 1 (
    echo [INFO] Changes detected. Creating commit...
    git commit -m "Update website and configure GitHub Pages"
    if errorlevel 1 goto GIT_ERROR
) else (
    echo [INFO] No staged changes to commit.
)

echo.
echo [STEP 3/4] Pushing files to GitHub...
git push -u origin "%BRANCH%"
if errorlevel 1 goto GIT_ERROR

echo.
echo [OK] Files pushed successfully.
echo [INFO] GitHub Actions will handle deployment.
echo.

REM ========================================================
REM 6. DISPLAY CLICKABLE LINKS
REM ========================================================

echo ========================================================
echo                 DEPLOYMENT LINKS
echo ========================================================
echo.
echo Repository:
echo %REPO_URL%
echo.
echo GitHub Actions:
echo %ACTIONS_URL%
echo.
echo Website:
echo %PAGES_URL%
echo.
echo ========================================================
echo.

REM Open the repository and deployment status.
start "" "%REPO_URL%"
start "" "%ACTIONS_URL%"

echo [STEP 4/4] Waiting for GitHub Pages deployment...
echo.
echo Check the Actions page in your browser.
echo Wait until the deployment workflow succeeds.
echo Then open the Website link above.
echo.
echo NOTE: On first use, enable GitHub Pages with
echo GitHub Actions as the deployment source.
echo.
echo This script does not claim the website is live
echo until you verify the deployment succeeded.
echo.
pause
exit /b 0

:GIT_ERROR
echo.
echo [ERROR] A Git operation failed.
echo Check the error shown above.
echo Verify your GitHub authentication and permissions.
goto FAILED

:FAILED
echo.
echo ========================================================
echo                 DEPLOYMENT STOPPED
echo ========================================================
echo.
pause
exit /b 1