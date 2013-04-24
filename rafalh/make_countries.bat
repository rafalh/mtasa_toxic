@echo off
call "..\config.bat"
%LUA% "..\..\tools\convert_iso_countries.lua" countries.xml "%OUTPUT%\rafalh\conf\countries.xml"
pause