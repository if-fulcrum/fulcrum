REM ----------------------------------------------------------------------------
REM - For Fulcrum Hinge to be able to write to the Windows equivalent of       -
REM - the /etc/hosts file, this will need to be call via the Elevate program   -
REM ----------------------------------------------------------------------------

echo.             >> c:\windows\system32\drivers\etc\hosts
echo 127.0.0.1 %1 >> c:\windows\system32\drivers\etc\hosts
echo.             >> c:\windows\system32\drivers\etc\hosts
