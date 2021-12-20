@echo off
if exist .env (
    echo.
    echo *** Okruzenje je od ranije podeseno, postoji folder .env
    echo *** Jupyter mozete koristiti tako sto pokreneta START_JUPYTER.BAT u istom ovom folderu
    echo.
    goto end
)
setlocal EnableDelayedExpansion
set MSG1=0
set MSG2=0
set PY_VERS=3.6,3.7,3.8,3.9
set PY_TEST_VER_LN="import sys; ('%%s.%%s' %% sys.version_info[0:2] in '%PY_VERS%'.split(',')) or quit(100)" 

rem prvo pokusavamo python.exe iz PATH-a
python -c %PY_TEST_VER_LN% 2>nul

if "%ERRORLEVEL%"=="0" (
    set PY_CMD=python
    goto python_found
)

set MSG1=Ne postoji komanda 'python' (Python se ne nalazi u 'PATH' promenljivoj okruzenja)
if "%ERRORLEVEL%"=="100" (
    set MSG1=Postoji komanda 'python' ali verzija nije ni jedna od: %PY_VERS%
)

rem zatim pokusavamo default Python 3 iz py.exe iz PATH-a
py -3 -c %PY_TEST_VER_LN% 2>nul
if "%ERRORLEVEL%"=="0" (
    set PY_CMD=py -3
    goto python_found
)
set MSG2=Ne postoji komanda 'py' (nije instaliran Python ili je instaliran bez 'Python launcher')
if "%ERRORLEVEL%"=="100" (
    set MSG2=Postoji komanda 'py' ali nije instalirana ni jedna od verzija: %PY_VERS%

    rem na kraju pokuvamo konkrente verzije iz py.exe
    for %%V in (%PY_VERS%) do (
        rem echo probam veryiju %%V
        py -%%V -c "quit(0)" 1>nul 2>nul
        if "!ERRORLEVEL%!"=="0" (
            set PY_CMD=py -%%V
            goto python_found
        )
    )
)

rem ako nijedan pokusaj nije uspeo
echo.
echo Podesavanje nije moguce jer nije pronadjena odgovarajuca verzija Python-a:
if not "%MSG1%"=="0" echo   - %MSG1%
if not "%MSG2%"=="0" echo   - %MSG2%
echo.
goto end

:python_found
%PY_CMD% -c "import sys; print('*** Postavlja se virtuelno okruzenje za Python %%s.%%s.%%s koriscenjem Python-a koji se pokrece komandom \'%PY_CMD%\'' %% sys.version_info[0:3])"
%PY_CMD% -m venv .env
call .env\Scripts\activate.bat
echo *** Virtuelno okruzenje je postavljeno u folderu .env
echo.
echo *** Instaliraju se potrebni paketi u virtuelno okruzenje (treba da ste povezani na internet)
python -m pip install --upgrade pip
python -m pip install wheel
python -m pip install library/GDAL-3.3.3-cp39-cp39-win_amd64.whl
python -m pip install library/Fiona-1.8.20-cp39-cp39-win_amd64.whl
python -m pip install -r requirements.txt
echo @echo off > START_JUPYTER.BAT
echo call .env\Scripts\activate.bat >> START_JUPYTER.BAT
echo jupyter notebook >> START_JUPYTER.BAT
echo pause >> START_JUPYTER.BAT


set SCRIPT="%TMP%\idle_shortcut_%RANDOM%.py"
echo import os > %SCRIPT%
echo from win32com.client import Dispatch >> %SCRIPT%
echo folder = os.path.abspath(r'%~dp0 '[:-1]) >> %SCRIPT%
echo sh = Dispatch('WScript.Shell') >> %SCRIPT%
echo st = sh.CreateShortCut(os.path.join(folder, 'START_IDLE.lnk')) >> %SCRIPT%
echo st.Targetpath = os.path.join(folder, '.env/Scripts/pythonw.exe') >> %SCRIPT%
echo st.Arguments = '-m idlelib.idle' >> %SCRIPT%
echo st.WorkingDirectory = folder >> %SCRIPT%
echo st.Description = 'Launches IDLE, the interactive environment for Python' >> %SCRIPT%
echo st.save() >> %SCRIPT%
python %SCRIPT%
del %SCRIPT%
echo.
echo *** Podesavanje je uspesno zavrseno
echo *** Jupyter mozete pokrenuti tako sto pokrenete START_JUPYTER.BAT u istom ovom folderu
echo *** IDLE mozete pokrenuti tako sto pokrenete START_IDLE precicu u istom ovom folderu
echo.
call .env\Scripts\deactivate.bat

:end
pause
