#!/bin/bash -ex

# Usage:
# createvirtualenv /path/to/python /output/path/for/venv
# * param1: Python binary to use for the virtualenv
# * param2: Path to the virtualenv to create
createvirtualenv () {
    PYTHON=$1
    VENVPATH=$2
    if $PYTHON -m virtualenv --version; then
        VIRTUALENV="$PYTHON -m virtualenv --never-download"
    elif $PYTHON -m venv -h>/dev/null; then
        VIRTUALENV="$PYTHON -m venv"
    elif command -v virtualenv; then
        VIRTUALENV="$(command -v virtualenv) -p $PYTHON --never-download"
    else
        echo "Cannot test without virtualenv"
        exit 1
    fi
    $VIRTUALENV $VENVPATH
    if [ "Windows_NT" = "$OS" ]; then
        . $VENVPATH/Scripts/activate
    else
        . $VENVPATH/bin/activate
    fi
    # Upgrade to the latest versions of pip setuptools wheel so that
    # pip can always download the latest cryptography+cffi wheels.
    python -m pip install --upgrade pip setuptools wheel
}

# Usage:
# testinstall /path/to/python /path/to/.whl/or/.egg ["no-virtualenv"]
# * param1: Python binary to test
# * param2: Path to the wheel or egg file to install
# * param3 (optional): If set to a non-empty string, don't create a virtualenv. Used in manylinux containers.
testinstall () {
    PYTHON=$1
    RELEASE=$2
    NO_VIRTUALENV=$3

    if [ -z "$NO_VIRTUALENV" ]; then
        createvirtualenv $PYTHON venvtestinstall
        PYTHON=python
    fi

    if [[ $RELEASE == *.egg ]]; then
        $PYTHON -m easy_install $RELEASE
    else
        $PYTHON -m pip install --upgrade $RELEASE
    fi
    cd tools
    $PYTHON fail_if_no_c.py
    $PYTHON -m pip uninstall -y pymongo
    cd ..

    if [ -z "$NO_VIRTUALENV" ]; then
        deactivate
        rm -rf venvtestinstall
    fi
}
