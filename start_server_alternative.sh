#!/bin/sh
executable_name="valheim_server.x86_64"
export DOORSTOP_ENABLE=TRUE
export DOORSTOP_INVOKE_DLL_PATH="${PWD}/BepInEx/core/BepInEx.Preloader.dll"
export DOORSTOP_CORLIB_OVERRIDE_PATH=./unstripped_corlib
if [ ! -x "$1" -a ! -x "$executable_name" ]; then
    echo "Please open run.sh in a text editor and configure executable name."
    exit 1
fi

doorstop_libs="${PWD}/doorstop_libs"
arch=""
executable_path=""
lib_postfix=""

os_type=`uname -s`
case $os_type in
    Linux*)
        executable_path="${PWD}/${executable_name}"
        lib_postfix="so"
        ;;
    Darwin*)
        executable_name=`basename "${executable_name}" .app`
        real_executable_name=`defaults read "${PWD}/${executable_name}.app/Contents/Info" CFBundleExecutable`
        executable_path="${PWD}/${executable_name}.app/Contents/MacOS/${real_executable_name}"
        lib_postfix="dylib"
        ;;
    *)
        echo "Cannot identify OS (got $(uname -s))!"
        echo "Please create an issue at https://github.com/BepInEx/BepInEx/issues."
        exit 1
        ;;
esac

# Special case: if there is an arg, use that as executable path
# Linux: arg is path to the executable
# MacOS: arg is path to the .app folder which we need to resolve to the exectuable
if [ -n "$1" ]; then
    case $os_type in
        Linux*)
            executable_path="$1"
            ;;
        Darwin*)
            # Special case: allow to specify path to the executable within .app
            full_path_part=`echo "$1" | grep "\.app/Contents/MacOS"`
            if [ -z "$full_path_part" ]; then
                executable_name=`basename "$1" .app`
                real_executable_name=`defaults read "$1/Contents/Info" CFBundleExecutable`
                executable_path="$1/Contents/MacOS/${real_executable_name}"
            else
                executable_path="$1"
            fi
            ;;
    esac
fi

executable_type=`LD_PRELOAD="" file -b "${executable_path}"`;

case $executable_type in
    *64-bit*)
        arch="x64"
        ;;
    *32-bit*|*i386*)
        arch="x86"
        ;;
    *)
        echo "Cannot identify executable type (got ${executable_type})!"
        echo "Please create an issue at https://github.com/BepInEx/BepInEx/issues."
        exit 1
        ;;
esac

doorstop_libname=libdoorstop_${arch}.${lib_postfix}
export LD_LIBRARY_PATH="${doorstop_libs}":${LD_LIBRARY_PATH}
export LD_PRELOAD=$doorstop_libname:$LD_PRELOAD
export DYLD_LIBRARY_PATH="${doorstop_libs}"
export DYLD_INSERT_LIBRARIES="${doorstop_libs}/$doorstop_libname"

export templdpath=$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH
export SteamAppId=892970

./valheim_server.x86_64 -name "Valheim Plus Unix" -port 27006 -world "306070" -password "password" -savedir "/home/SAVEDIRPATH"


export LD_LIBRARY_PATH=$templdpath