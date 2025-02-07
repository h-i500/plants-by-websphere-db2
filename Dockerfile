##########################################
# Stage 1: Builder - Maven でアプリケーションをビルド
##########################################
FROM maven:3.8.5-openjdk-8 AS builder
WORKDIR /usr/src/app

# 依存関係解決のためにまずpom.xmlをコピー（キャッシュ対策）
COPY pom.xml .
RUN mvn dependency:go-offline

# ソースコードをコピーし、クリーンビルド
COPY src/ ./src/
RUN mvn clean package

##########################################
# Stage 2: Runtime - Liberty イメージに成果物と設定を配置
##########################################
FROM websphere-liberty:kernel

# --- JDBC ドライバ (Db2) の配置 ---
RUN mkdir -p /opt/ibm/wlp/usr/shared/resources/Db2
COPY wlp/usr/shared/resources/Db2/db2jcc4.jar /opt/ibm/wlp/usr/shared/resources/Db2/
USER root
RUN chown 1001:0 /opt/ibm/wlp/usr/shared/resources/Db2/*.jar
USER 1001

# --- サーバ設定 (server.xml) の配置 ---
COPY wlp/config/server.xml /config
USER root
RUN chown 1001:0 /config/server.xml
USER 1001

# Liberty の設定スクリプトを実行して設定を反映
RUN configure.sh

# --- ビルド成果物 (EAR) の配置 ---
# builder ステージで生成されたEARを最終イメージにコピー
COPY --from=builder /usr/src/app/target/plants-by-websphere-jee6-mysql.ear /opt/ibm/wlp/usr/servers/defaultServer/apps

# （必要に応じてEXPOSEやCMDなどを追加）
