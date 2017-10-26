@echo off

rem ***************************************************************************
rem
rem ANT startup file
rem
rem Copyright 2003-2004 by John Wiley & Sons Inc. All Rights Reserved.
rem
rem ***************************************************************************

if "%JAVA_HOME%"=="" goto noJavaHomeErr

rem
rem Force using the local Ant...
rem
set MY_ANT_HOME=%ANT_HOME%
set ANT_HOME=./ant
echo Starting Ant...
echo System ANT_HOME=%MY_ANT_HOME%
echo Using local ANT_HOME=%ANT_HOME%
call "%ANT_HOME%\bin\ant.bat" %1 %2 %3 %4 %5 %6
set ANT_HOME=%MY_ANT_HOME%
goto done

:noJavaHomeErr
echo ERROR: JAVA_HOME not found in your environment.
echo Please, set the JAVA_HOME variable in your environment to match
echo the location of the Java Virtual Machine you want to use.
goto done

:done
