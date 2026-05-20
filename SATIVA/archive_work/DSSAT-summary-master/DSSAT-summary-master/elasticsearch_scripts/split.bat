@echo off
setLocal EnableDelayedExpansion

del uploader.bat
del eval-part*
set limit=100000
set file=eval.json
set lineCounter=0
set filenameCounter=1
set uploaderFile=uploader.bat
set quote=brute
set name=
set extension=
echo curl -k -i --raw -o mapping.log -X PUT "http://localhost:9200/evaluation" -H "Content-Type: application/json" -H "User-Agent: Fiddler" -H "Host: localhost:9200" --data-binary @es_eval_mapping.json>>!uploaderFile! 

for %%a in (%file%) do (
	set "name=%%~na"
	set "extension=%%~xa"
)

for /f "tokens=*" %%a in (%file%) do (
	set splitFile=!name!-part!filenameCounter!!extension!
	set line=%%a
	if !lineCounter! gtr !limit! ( 
		if "!line:~2,5!" equ "!quote!" (
			set /a filenameCounter=!filenameCounter! + 1
			set lineCounter=0
			echo Created !splitFile!.
			echo curl -k -i --raw -o !splitFile!.log -X POST "http://localhost:9200/evaluation/_bulk?pretty" -H "Content-Type: application/json" -H "User-Agent: Fiddler" -H "Host: localhost:9200" --data-binary @!splitFile!>>!uploaderFile!
		)
	)
	echo !line!>> !splitFile!
	set /a lineCounter=!lineCounter! + 1

)
echo pause>>!uploaderFile!

