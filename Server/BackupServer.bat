SET PATH_SRC=%cd%
SET PATH_DST=Z:\star\
SET FILE_DST=Z:\StarServer.rar

cd %PATH_SRC%
md %PATH_DST%
del %FILE_DST%

xcopy *.cpp %PATH_DST% /s /q
xcopy *.h %PATH_DST% /s /q
xcopy *.proto %PATH_DST% /s /q
xcopy *.sh %PATH_DST% /s /q

"%PROGRAMFILES%\WinRAR\WinRAR" a -r %FILE_DST% %PATH_DST%
rd %PATH_DST% /S /Q
