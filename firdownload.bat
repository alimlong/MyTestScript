@echo off
rem setlocal enabledelayedexpansion
rem download android apks from fir
rem Date:2020/5/5
rem Author:alimlong
chcp 65001
rem 设置参数
::--------------global settings---------------------
set UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36 Edge/18.18363"
set base_url=http://fir-download.fircli.cn/
set apk_path=apps
set out_path=%~dp0
set files=
::---------------------------------------------------

rem 判断传入参数

set /a param_num=0
set /a p1=0
set /a p2=0

:loop

if [%1] == [] goto :ret
set /a param_num+=1
if %param_num% equ 1 (set p1=%1)
if %param_num% equ 2 (set p2=%~1)
shift
goto :loop
:ret

rem 参数为0，打印帮助信息
if %param_num% equ 0 call:help

rem 根据不同的参数，进入不同处理逻辑，分别是直接参数输入APP code或者通过文件传入多个APP code
if %param_num% equ 1 (
    call:apk_download %p1%
) else (
    set opt=%p1:-=/%
    if "%opt%" == "/f" (
        for /f "eol=# tokens=1,2" %%i in (%p2%) do (call:apk_download %%i %%j)
    )  else (
        echo bad arguments
    )
)

rem files待处理的apk文件列表，循环调用test.bat处理每一个apk文件
if not "%files%" == "" (
    rem echo %files%
    for %%i in (%files%) do (call appTest.bat %%i)
)

@goto :end

rem apk下载函数，首先通过app code获取到app的id，token，release id等信息，然后下载apk文件
::---------func apk_download------------------
rem setlocal enabledelayedexpansion
:apk_download
rem echo enter apk_download func
echo.

::SETLOCAL

set app_name=%1
if not [%2] == [] (
set app_name=%2
)

set app_id=

echo Try to download %app_name%

rem 请求http://fir-download.fircli.cn/[appcode]接口获取APP信息
for /f "usebackq delims=#" %%i in (`curl -s -A %UA% %base_url%%1`) do (set info=%%i)


for /f "usebackq tokens=3 delims=:" %%i in (`echo %info%^|grep -o ^"\^"app\^":{\^"id\^":\^"[a-z0-9]*\^"^"`) do (set app_id=%%~i)
for /f "usebackq tokens=3 delims=:" %%j in (`echo %info%^|grep -o ^"\^"master\^":{\^"id\^":\^"[a-z0-9]*\^"^"`) do (set release_id=%%~j)
for /f "usebackq tokens=2 delims=:" %%k in (`echo %info%^|grep -o ^"\"token\":\"[a-z0-9]*\"^"`) do (set token=%%~k)

rem 判断app信息是否获取成功，未获取到结束函数
if "%app_id%" == "" (
echo %info%
goto :end_apk_func
)
echo start to download apk, wait for a moment...

rem 判断文件是否已经下载，未下载调用http://fir-download.fircli.cn/apps/5d54b25ef9454844061d90f5/install?short=ydvr&download_token=282c0ac34ade82a1730b974d7e2e9b42&release_id=5e8fe15d23389f1ea697b310接口下载apk文件，命名为release id
if not exist %out_path%%release_id%.apk (
    curl -sL -A %UA% -o %out_path%%release_id%.apk %base_url%%apk_path%/%app_id%/install?short=%1^&download_token=%token%^&release_id=%release_id%
    if errorlevel 0 (
        echo %app_name% download succeed!
        set files=%files% %release_id%.apk
    ) else (
        echo %app_name% download failed!
    )
) else (
    echo %release_id%.apk is existed, not need to download duplicate!
    set files=%files% %release_id%.apk
)
rem setlocal disabledelayedexpansion
:end_apk_func
::ENDLOCAL
goto :eof
::----------end apk_download-----------------


rem 打印帮助信息
::---------func help------------------
:help
echo download android apk from fir platform
echo usage:
echo %~nx0 [/f file] [code]
echo.
echo   /f	Read codes from a file
goto :eof
::----------end help---------------


:end
chcp 936
