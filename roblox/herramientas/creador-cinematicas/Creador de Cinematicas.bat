@echo off
rem Abre el Creador de cinematicas de Heroes of History.
cd /d "%~dp0"
python -c "import anthropic" 2>NUL || (echo Instalando la libreria de Claude, un momento... & python -m pip install --quiet anthropic)
start "" pythonw "%~dp0creador_cinematicas.py"
