@echo off
title Western Dead Wiki - GitHub Update
color 0E

cd /d "H:\rdr2pf-westerndead"

echo.
echo Checking changes...
git status --short

echo.
set /p message=Enter update description: 

if "%message%"=="" (
    set message=Updated Western Dead Wiki
)

echo.
echo Adding files...
git add .

echo.
echo Creating commit...
git commit -m "%message%"

if errorlevel 1 (
    echo.
    echo No new changes were committed, or Git returned an error.
    pause
    exit /b 1
)

echo.
echo Uploading to GitHub...
git push origin main

if errorlevel 1 (
    echo.
    echo GitHub upload failed.
    pause
    exit /b 1
)

echo.
echo Western Dead Wiki successfully updated on GitHub.
pause