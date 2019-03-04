SET PATH_SRC=%cd%
SET PATH_DST=Z:\lua\
SET FILE_DST=Z:\lua_bin.rar

cd %PATH_SRC%
md %PATH_DST%
del %FILE_DST%

xcopy *.lua %PATH_DST% /s /q
xcopy *.txt %PATH_DST% /s /q

"%PROGRAMFILES%\WinRAR\WinRAR" a -r %FILE_DST% %PATH_DST%
rd %PATH_DST% /s /q
