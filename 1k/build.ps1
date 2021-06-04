#
# Copyright (c) 2021 Bytedance Inc.
#

# Install nasm
curl https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/win64/nasm-2.15.05-win64.zip -o nasm-2.15.05-win64.zip
Expand-Archive -Path nasm-2.15.05-win64.zip -DestinationPath .\
ls -R nasm-2.15.05
$nasm_bin = (Resolve-Path .\nasm-2.15.05).Path
$env:Path = "$nasm_bin;$env:Path"
nasm -v

# Parse openssl checkout tag, such as OpenSSL_1_1_1k
$BUILD_PROPS = ConvertFrom-StringData (Get-Content build.properties -raw)
$openssl_ver = $BUILD_PROPS.'openssl_ver'
$openssl_config_options_msw=$BUILD_PROPS.'openssl_config_options_msw'

$openssl_ver = ([Regex]::Replace($openssl_ver, '\.', '_'))
$openssl_release_tag="OpenSSL_$openssl_ver"

echo $openssl_config_options_msw
$OPENSSL_CONFIG_OPTIONS=($openssl_config_options_msw -split ' ')

# OPENSSL_CONFIG_ALL_OPTIONS
$OPENSSL_CONFIG_ALL_OPTIONS=@()

# Determine build target & config options
if($env:BUILD_ARCH -eq "x86_64") {
    $OPENSSL_CONFIG_ALL_OPTIONS += 'VC-WIN64A'
}
else {
    $OPENSSL_CONFIG_ALL_OPTIONS += 'VC-WIN32'
}

$OPENSSL_CONFIG_ALL_OPTIONS += $OPENSSL_CONFIG_OPTIONS

# Checkout openssl
git clone -q https://github.com/openssl/openssl
cd openssl
git checkout $openssl_release_tag

# Config & Build
$openssl_src_root=(Resolve-Path .\).Path
$INSTALL_NAME="openssl_windows_${env:BUILD_ARCH}"
$openssl_install_dir="$openssl_src_root\$INSTALL_NAME"
$OPENSSL_CONFIG_ALL_OPTIONS += "--prefix=$openssl_install_dir", "--openssldir=$openssl_install_dir"
mkdir "$openssl_install_dir"
echo ("OPENSSL_CONFIG_ALL_OPTIONS=$OPENSSL_CONFIG_ALL_OPTIONS, Count={0}" -f $OPENSSL_CONFIG_ALL_OPTIONS.Count)
perl Configure $OPENSSL_CONFIG_ALL_OPTIONS
nmake
nmake install

# Delete files what we don't want
del "$openssl_install_dir\html" -recurse
del "$openssl_install_dir\lib\engines-1_1" -recurse
del "$openssl_install_dir\bin\*.pl"
del "$openssl_install_dir\bin\*.pdb"
del "$openssl_install_dir\bin\*.exe"
cd ..

# Export INSTALL_NAME for uploading
echo "INSTALL_NAME=$INSTALL_NAME" >> ${env:GITHUB_ENV}