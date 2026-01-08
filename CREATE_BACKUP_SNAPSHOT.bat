@echo off
setlocal
set "BACKUP_DIR=Backups"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

set "TIMESTAMP=%date:~10,4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "TIMESTAMP=%TIMESTAMP: =0%"

echo Creating backup snapshot: %TIMESTAMP%...

powershell -Command "Compress-Archive -Path 'lib', 'pubspec.yaml', 'README.md' -DestinationPath '%BACKUP_DIR%\Backup_%TIMESTAMP%.zip'"

echo Done! Backup saved in '%BACKUP_DIR%' folder.
pause
