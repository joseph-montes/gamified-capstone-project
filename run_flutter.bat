@echo off
set "FLUTTER_DIR=C:\flutter"

echo ===========================================
echo FLUTTER RUN HELPER FOR COMSHOP
echo ===========================================
echo checking for Flutter SDK in %FLUTTER_DIR%...

if not exist "%FLUTTER_DIR%\bin\flutter.bat" (
    echo Flutter SDK not found on C:. 
    echo Downloading portable version of Flutter to C: drive...
    git clone https://github.com/flutter/flutter.git -b stable "%FLUTTER_DIR%"
)

echo.
echo Setting up Flutter...
call "%FLUTTER_DIR%\bin\flutter.bat" config --enable-web

echo.
echo ===========================================
echo Starting your app in Chrome!
echo ===========================================
call "%FLUTTER_DIR%\bin\flutter.bat" run -d chrome

pause
