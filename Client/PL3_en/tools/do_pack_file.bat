::res_pack.bat  

cd ..
set D=\res
set E=\res_encode

set DSRC=%cd%%D%
set ESRC=%cd%%E%

cd tools/bin  
  
pack_files.bat -i %DSRC% -o %ESRC% -ek utugames -es liuxutao  