#!/bin/bash

set -e
set -u
set -o pipefail

function main() {
	echo "-----> Installing Tesseract - SJP:i"
	#apt-get update -y
	#apt-get install -y yum
	# (Estimated Time of Completion: 45 minutes)
	# Instructions taken (and slightly modified) from https://github.com/EisenVault/install-tesseract-redhat-centos/blob/master/install-tesseract.sh
	#cd /opt
	# The following line will take 30 minutes to install.
	#yum -y update
	#yum -y install libstdc++ autoconf automake libtool autoconf-archive pkg-config gcc gcc-c++ make libjpeg-devel libpng-devel libtiff-devel zlib-devel
	#yum group install -y "Development Tools"


	# Install Leptonica from Source
	wget --no-cookies --no-check-certificate  http://www.leptonica.org/source/leptonica-1.78.0.tar.gz
	
	tar -zxvf leptonica-1.78.0.tar.gz
	cd leptonica-1.78.0
	#./autobuild
	./configure
	make -j
	make install
	cd ..
	# Delete tar.gz file if you like


	# Sanity checks
	# check if libpng is installed: type "whereis libpng" and expect to see a directory; a blank line is not good
	# check if leptonica is installed: type "ls /usr/local/include" and expect to see "leptonica"


	# Install Tesseract from Source
	wget https://github.com/tesseract-ocr/tesseract/archive/4.0.0-beta.1.tar.gz
	tar -zxvf 4.0.0-beta.1.tar.gz
	cd tesseract-4.0.0-beta.1/
	./autogen.sh
	PKG_CONFIG_PATH=/usr/local/lib/pkgconfig LIBLEPT_HEADERSDIR=/usr/local/include ./configure --with-extra-includes=/usr/local/include --with-extra-libraries=/usr/local/lib
	LDFLAGS="-L/usr/local/lib" CFLAGS="-I/usr/local/include" make -j
	make install
	ldconfig
	cd ..
	# Delete tar.gz file if you like


	# Download and install tesseract language files (Tesseract 4 traineddata files)
	wget https://github.com/tesseract-ocr/tessdata/raw/master/osd.traineddata
	wget https://github.com/tesseract-ocr/tessdata/raw/master/equ.traineddata
	wget https://github.com/tesseract-ocr/tessdata/raw/master/eng.traineddata
	wget https://github.com/tesseract-ocr/tessdata/raw/master/chi_sim.traineddata
	# download another other languages you like
	mv *.traineddata /usr/local/share/tessdata

	
	
	
  echo "-----> Installing Tesseract - SJP:f"
	
	
  if [[ "${CF_STACK:-}" != "cflinuxfs3" ]]; then
    echo "       **ERROR** Unsupported stack"
    echo "                 See https://docs.cloudfoundry.org/devguide/deploy-apps/stacks.html for more info"
    exit 1
  fi

  local version expected_sha dir
  version="1.15.5"
  expected_sha="fd04494f7a2dd478b0d31cb949aae7f154749cae1242581b1574f7e590b3b7e6"
  dir="/tmp/go${version}"

  mkdir -p "${dir}"

  if [[ ! -f "${dir}/go/bin/go" ]]; then
    local url
    url="https://buildpacks.cloudfoundry.org/dependencies/go/go_${version}_linux_x64_${CF_STACK}_${expected_sha:0:8}.tgz"

    echo "-----> Download go ${version}"
    curl "${url}" \
      --silent \
      --location \
      --retry 15 \
      --retry-delay 2 \
      --output "/tmp/go.tgz"

    local sha
    sha="$(shasum -a 256 /tmp/go.tgz | cut -d ' ' -f 1)"

    if [[ "${sha}" != "${expected_sha}" ]]; then
      echo "       **ERROR** SHA256 mismatch: got ${sha}, expected ${expected_sha}"
      exit 1
    fi

    tar xzf "/tmp/go.tgz" -C "${dir}"
    rm "/tmp/go.tgz"
  fi

  if [[ ! -f "${dir}/bin/go" ]]; then
    echo "       **ERROR** Could not download go"
    exit 1
  fi

  GoInstallDir="${dir}"
  export GoInstallDir
}

main "${@:-}"
