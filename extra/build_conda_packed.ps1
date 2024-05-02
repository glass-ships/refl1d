$ENV_NAME="isolated-base"
$PYTHON_VERSION="3.10"
$DIRNAME="refl1d"

conda activate "base"

conda install -y conda-pack
conda create -n "$ENV_NAME" -q --force -y "python=$PYTHON_VERSION" "nodejs"
conda-pack -n "$ENV_NAME" -f -o "$ENV_NAME.tar.gz"

# unpack the new environment, that contains only python + pip + nodejs
$tmp_target_dir="dist"
mkdir -Force $tmp_target_dir
$tmpdir = Resolve-Path "$tmp_target_dir" | Select-Object -ExpandProperty Path
$destdir="$tmpdir\$DIRNAME"
$envdir = "$destdir\env"
Remove-Item -r -Force "$destdir"
mkdir "$envdir"
tar -xzf "$ENV_NAME.tar.gz" -C "$envdir"

# activate the unpacked environment and install pip packages
conda deactivate
$WORKING_DIRECTORY="$pwd"
echo "WORKING_DIRECTORY=$WORKING_DIRECTORY"
dir .
dir ..
# add our batch script:
Copy-Item .\extra\platform_scripts\refl1d_webview.bat "$destdir"

& "$envdir\python.exe" -m pip install --no-input --no-compile numba
& "$envdir\python.exe" -m pip install --no-input --no-compile git+https://github.com/bumps/bumps@webview
& "$envdir\python.exe" -m pip install --no-input --no-compile git+https://github.com/reflectometry/refl1d@webview
& "$envdir\python.exe" -m pip install --no-compile -r https://raw.githubusercontent.com/bumps/bumps/webview/webview-requirements

# build the client
cd $envdir\Lib\site-packages\bumps\webview\client
& "$envdir\npm.cmd" install
& "$envdir\npm.cmd" link

cd $envdir\Lib\site-packages\refl1d\webview\client
& "$envdir\npm.cmd" link ..\..\..\bumps\webview\client
& "$envdir\npm.cmd" install
& "$envdir\npm.cmd" run build

# remove node_modules after build
rm -r -Force $envdir\Lib\site-packages\bumps\webview\client\node_modules
rm -r -Force $envdir\Lib\site-packages\refl1d\webview\client\node_modules

$version=$(& "$envdir\python.exe" -c "import refl1d; print(refl1d.__version__)")
# zip it back up
cd $tmpdir
Rename-Item "$DIRNAME" "$DIRNAME-$version"
tar -czf "refl1d-webview-Windows-x86_64.tar.gz" "$DIRNAME-$version"
Compress-Archive -Path "$DIRNAME-$version" -DestinationPath "refl1d-webview-Windows-x86_64.zip"
