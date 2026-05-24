@echo off
SET PATH=C:\Users\Owner\AppData\Local\nodejs;%PATH%
cd /d "C:\Users\Owner\OneDrive\Documentos\Claude\Projects\nova-charlotte"
node node_modules\next\dist\bin\next dev --port 3000
