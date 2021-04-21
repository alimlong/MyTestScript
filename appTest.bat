@echo off
setlocal enabledelayedexpansion

if not "%~1"=="" goto :start

echo usage:
echo appTest apk_filename
goto :end

:start
set file_name=%1

rem set package_name=%file_name:~,-4%
echo start to process apk %1
set aapt_cmd=D:\AndroidSDK\sdk\build-tools\28.0.3\aapt.exe
rem echo %aapt_cmd%
set /a num=0

for /f "usebackq tokens=1 delims=#" %%i in (`%aapt_cmd% dump badging %1 ^| findstr "package launchable"`) do (
    set apk_info!num!=%%i
    set /a num=num+1
)


for /f "usebackq tokens=2 delims='" %%i in (`echo %apk_info0%`) do set package_name=%%i

for /f "usebackq tokens=2 delims='" %%i in (`echo %apk_info1%`) do set launch_activity=%%i


echo %1 launch activity is %launch_activity%

echo 1. start to install apk
adb install %1
if not errorlevel 0 (
echo **********install failed********
goto :end
)

timeout 5

echo 2. launch %package_name%/%launch_activity%
adb shell am start -n %package_name%/%launch_activity%
if not errorlevel 0 (
echo **********lauch failed********
goto :end
)

timeout 5
echo 3. monkey test
adb shell monkey -p %package_name% --throttle 300 --pct-touch 75 100

timeout 10
adb shell am force-stop %package_name%

:end
setlocal disabledelayedexpansion

