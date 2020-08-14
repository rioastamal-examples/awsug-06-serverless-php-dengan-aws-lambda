#!/bin/bash
#
realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

BASE_DIR=$( dirname "$0" )
ABS_DIR=$( realpath $BASE_DIR )

echo "> Creating zip file into build/function.zip ..."
mkdir -p $ABS_DIR/build

composer dumpautoload

chmod +x $ABS_DIR/bootstrap

rm -r $ABS_DIR/build/*.zip

cd $ABS_DIR && zip -q -r build/function.zip index.php bootstrap src/ vendor/
echo "< Lambda function has been zipped."