@echo off
call "..\config.bat"
%LUA% "..\..\convert_iso_countries.lua" countries.xml "%OUTPUT%\rafalh\conf\countries.xml"
pause