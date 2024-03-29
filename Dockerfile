FROM ubuntu:focal
LABEL maintainer="ariffjenong <arifbuditantodablekk@gmail.com>"
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /cirrus

RUN apt-get -yqq update \
    && mkdir -p rom \
    && mkdir -p script \
    && apt-get install --no-install-recommends -yqq adb pigz autoconf automake axel bc bison build-essential ccache clang cmake curl expat expect fastboot flex g++ g++-multilib gawk gcc gcc-multilib git gnupg gperf htop imagemagick locales libncurses5 lib32ncurses5-dev lib32z1-dev libtinfo5 libc6-dev libcap-dev libexpat1-dev libgmp-dev '^liblz4-.*' '^liblzma.*' libmpc-dev libmpfr-dev libncurses5-dev libnl-route-3-dev libprotobuf-dev libsdl1.2-dev libssl-dev libtool libxml-simple-perl libxml2 libxml2-utils lld lsb-core lzip '^lzma.*' lzop maven nano ncftp ncurses-dev openssh-server patch patchelf pkg-config pngcrush pngquant protobuf-compiler python2.7 python3-apt python-all-dev python re2c rclone rsync schedtool screen squashfs-tools subversion sudo tar texinfo tmate tzdata unzip w3m wget xsltproc zip zlib1g-dev zram-config zstd \
    && curl --create-dirs -L -o /usr/local/bin/repo -O -L https://raw.githubusercontent.com/geopd/git-repo/main/repo \
    && chmod a+rx /usr/local/bin/repo \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
    && echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && /usr/sbin/locale-gen \
    && git clone https://github.com/akhilnarang/scripts script \
    && TZ=Asia/Jakarta \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN git clone https://github.com/mirror/make \
    && cd make && ./bootstrap && ./configure && make CFLAGS="-O3 -Wno-error" \
    && sudo install ./make /usr/bin/make

RUN git clone https://github.com/ninja-build/ninja.git \
    && cd ninja && git reset --hard f404f00 && ./configure.py --bootstrap \
    && sudo install ./ninja /usr/bin/ninja

RUN git clone https://github.com/google/kati.git \
    && cd kati && git reset --hard ac01665 && make ckati \
    && sudo install ./ckati /usr/bin/ckati

RUN git clone https://github.com/google/nsjail.git \
    && cd nsjail && git reset --hard e678c25 && make nsjail \
    && sudo install ./nsjail /usr/bin/nsjail

RUN axel -a -n 10 https://github.com/facebook/zstd/releases/download/v1.5.2/zstd-1.5.2.tar.gz \
    && tar xvzf zstd-1.5.2.tar.gz && cd zstd-1.5.2 \
    && sudo make install

RUN git clone https://github.com/google/brotli.git \
    && cd brotli && mkdir out && cd out && ../configure-cmake --disable-debug \
    && make CFLAGS="-O3" && sudo make install

RUN curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip \
    && unzip rclone-current-linux-amd64.zip && cd rclone-*-linux-amd64 \
    && sudo cp rclone /usr/bin/ && sudo chown root:root /usr/bin/rclone \
    && sudo chmod 755 /usr/bin/rclone

WORKDIR /cirrus/rom

RUN repo init --depth=1 --no-repo-verify -u https://github.com/LineageOS/android.git -b lineage-19.1 -g default,-mips,-darwin,-notdefault \
    && git clone https://github.com/ariffjenong/local_manifest.git --depth=1 -b LOS19 .repo/local_manifests \
    && repo sync external/lottie external/ims external/icing external/icu system/linkerconfig system/libvintf system/libbase external/json-c external/ant-wireless/hidl external/ant-wireless/ant_service external/ant-wireless/ant_native external/ant-wireless/ant_client hardware/qcom-caf/common hardware/qcom-caf/wlan hardware/qcom-caf/vr hardware/qcom-caf/thermal lineage/scripts vendor/codeaurora/telephony lineage/crowdin android device/lineage/atv device/lineage/car device/lineage/sepolicy external/bash external/chromium-webview external/exfatprogs external/htop external/libncurses external/nano external/tinyxml hardware/lineage/interfaces hardware/lineage/livedisplay external/vim prebuilts/runtime prebuilts/rust build/make system/apex system/bt system/core system/media device/qcom/sepolicy device/qcom/sepolicy-legacy-um hardware/qcom-caf/msm8998/audio hardware/qcom/audio bionic art sdk prebuilts/extract-tools prebuilts/tools-lineage vendor/lineage frameworks/native frameworks/av frameworks/base kernel/sony/msm8998 device/sony/maple_dsds device/sony/yoshino-common vendor/sony/maple_dsds -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j24

WORKDIR /cirrus/script

RUN bash setup/android_build_env.sh

WORKDIR /cirrus

RUN rm zstd-1.5.2.tar.gz rclone-current-linux-amd64.zip \
    && rm -rf brotli kati make ninja nsjail rclone-v1.58.0-linux-amd64 script zstd-1.5.2

VOLUME ["/cirrus/ccache", "/cirrus/rom"]
ENTRYPOINT ["/bin/bash"]
