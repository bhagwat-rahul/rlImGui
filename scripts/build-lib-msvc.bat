@echo off
rem Builds rlImGui as an MSVC static library for Windows x64 (rlImGui-x86_64-pc-windows-msvc.lib).
rem Locates the newest Visual Studio install and calls vcvars64.bat itself, so it must run on
rem Windows with the "Desktop development with C++" workload installed (e.g. windows-latest).
rem
rem Usage: build-lib-msvc.bat [out-dir]

setlocal

set "OUT_DIR=%~1"
if "%OUT_DIR%"=="" set "OUT_DIR=%CD%"

set "RAYLIB_DIR=raylib"
set "IMGUI_DIR=imgui"

if not exist "%RAYLIB_DIR%" (
	echo error: missing dependency directory '%RAYLIB_DIR%' 1>&2
	exit /b 1
)
if not exist "%IMGUI_DIR%" (
	echo error: missing dependency directory '%IMGUI_DIR%' 1>&2
	exit /b 1
)

set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
	echo error: Visual Studio Installer ^(vswhere.exe^) not found 1>&2
	exit /b 1
)
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSROOT=%%i"
if not defined VSROOT (
	echo error: no Visual Studio installation with the C++ workload found 1>&2
	exit /b 1
)
call "%VSROOT%\VC\Auxiliary\Build\vcvars64.bat" >nul
if errorlevel 1 exit /b 1

set "BUILD_DIR=%OUT_DIR%\.build-msvc"
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
mkdir "%BUILD_DIR%"

for %%s in (rlImGui.cpp "%IMGUI_DIR%\imgui.cpp" "%IMGUI_DIR%\imgui_demo.cpp" "%IMGUI_DIR%\imgui_draw.cpp" "%IMGUI_DIR%\imgui_tables.cpp" "%IMGUI_DIR%\imgui_widgets.cpp") do (
	cl -nologo -O2 -std:c++17 -EHsc -DNDEBUG -DPLATFORM_DESKTOP -DGRAPHICS_API_OPENGL_33 -DIMGUI_DISABLE_OBSOLETE_FUNCTIONS -DIMGUI_DISABLE_OBSOLETE_KEYIO -D_WINSOCK_DEPRECATED_NO_WARNINGS -D_CRT_SECURE_NO_WARNINGS -I. -I"%IMGUI_DIR%" -I"%RAYLIB_DIR%\src" -I"%RAYLIB_DIR%\src\external" -I"%RAYLIB_DIR%\src\external\glfw\include" -c "%%s" -Fo"%BUILD_DIR%\"
	if errorlevel 1 exit /b 1
)

lib -nologo -out:"%OUT_DIR%\rlImGui-x86_64-pc-windows-msvc.lib" "%BUILD_DIR%\*.obj"
if errorlevel 1 exit /b 1

rmdir /s /q "%BUILD_DIR%"

echo built %OUT_DIR%\rlImGui-x86_64-pc-windows-msvc.lib
exit /b 0
