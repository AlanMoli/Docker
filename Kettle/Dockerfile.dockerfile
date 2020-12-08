FROM ubuntu:16.04

RUN apt-get update && \
    # 安装程序
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --force-yes --no-install-recommends \
    openjdk-8-jdk \
    wget unzip inetutils-ping \
    supervisor \
    fonts-wqy-microhei ttf-wqy-zenhei \
    xfce4 xfce4-goodies \
    x11vnc xvfb \
    libwebkitgtk-1.0-0 && \
    # 删除不必要的文件和缓存
    apt-get autoclean && \
    apt-get autoremove && \
    rm -rf /var/cache/apt/* && \
    rm -rf /var/lib/apt/lists/*

# 设置环境变量
ENV PDI_RELEASE=8.2 \ 
    PDI_VERSION=8.2.0.0-342 \
    PENTAHO_JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    PENTAHO_HOME=/opt/pentaho \
    VNC_PW=vncpassword

# 创建相关目录
RUN mkdir $PENTAHO_HOME \
    $PENTAHO_HOME/docker-entrypoint.d \
    $PENTAHO_HOME/templates \
    $PENTAHO_HOME/scripts

# 下载 kettle
# RUN wget --progress=dot:giga -c\
#     https://sourceforge.net/projects/pentaho/files/Pentaho%20${PDI_RELEASE}/client-tools/pdi-ce-${PDI_VERSION}.zip \
#     -O /tmp/pdi-ce-${PDI_VERSION}.zip && \
COPY pdi-ce-${PDI_VERSION}.zip $PENTAHO_HOME/

RUN unzip -q ${PENTAHO_HOME}/pdi-ce-${PDI_VERSION}.zip -d $PENTAHO_HOME && \
    rm ${PENTAHO_HOME}/pdi-ce-${PDI_VERSION}.zip


# 添加 kettle 环境变量
ENV KETTLE_HOME=$PENTAHO_HOME/data-integration \
    PATH=$KETTLE_HOME:$PATH

# 中文支持
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends locales && \
    locale-gen zh_CN.UTF-8 && \
    dpkg-reconfigure --frontend noninteractive locales && \
    apt-get autoclean && \
    apt-get autoremove && \
    rm -rf /var/cache/apt/* && \
    rm -rf /var/lib/apt/lists/*

ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8 \
    TZ="Asia/Shanghai"

# 时区配置
RUN echo $TZ > /etc/timezone && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    # 配置 VNC 密码
    mkdir ~/.vnc && \
    touch ~/.vnc/passwd && \
    x11vnc -storepasswd $VNC_PW ~/.vnc/passwd

# 复制模板文件
COPY carte-*.config.xml $PENTAHO_HOME/templates/
COPY docker-entrypoint.sh $PENTAHO_HOME/scripts/
COPY startup.sh $PENTAHO_HOME/docker-entrypoint.d/
COPY supervisord.conf /root/

# 给脚本文件添加执行权限
RUN chmod +x $PENTAHO_HOME/scripts/docker-entrypoint.sh && \
    chmod +x $PENTAHO_HOME/docker-entrypoint.d/startup.sh

EXPOSE 5900 8080

WORKDIR $KETTLE_HOME

ENTRYPOINT [ "../scripts/docker-entrypoint.sh" ]

CMD [ "carte.sh", "carte.config.xml" ]