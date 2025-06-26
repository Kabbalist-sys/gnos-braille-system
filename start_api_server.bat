@echo off
echo Starting Gnos Braille System API Server...
echo.
echo Python environment: C:/Users/emasa/AppData/Local/Microsoft/WindowsApps/python3.13.exe
echo.
echo The API will be available at:
echo   Health Check: http://localhost:5000/health
echo   Demo: http://localhost:5000/api/braille/demo
echo   Documentation: See API_DOCUMENTATION.md
echo.
echo Press Ctrl+C to stop the server
echo.

C:/Users/emasa/AppData/Local/Microsoft/WindowsApps/python3.13.exe braille_api.py --server

pause
