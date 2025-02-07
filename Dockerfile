##########################################
# Stage 1: Builder - Maven でアプリケーションをビルドする
##########################################
FROM maven:3.8.5-openjdk-8 AS builder
WORKDIR /usr/src/app

# プロジェクト全体をコピーする
COPY . .

# ※ 以下の行は、ビルド前にディレクトリ構成を確認するための一例です（必要に応じて削除）
RUN ls -l /usr/src/app

# pbw-lib を先にビルドしてローカルリポジトリにインストールする（パス修正）
RUN cd pbw-lib && mvn clean install -DskipTests

# 依存関係のダウンロード（go-offline）
RUN mvn dependency:go-offline

# pbw-web などを含む全体のパッケージ作成
RUN mvn clean package -DskipTests

##########################################
# Stage 2: Runtime - Liberty イメージに成果物と設定を配置する
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

# Liberty の設定を反映
RUN configure.sh

# --- ビルド成果物 (EAR) の配置 ---
# ※ 生成された EAR のパスはプロジェクト構成に合わせて調整してください
COPY --from=builder /usr/src/app/target/plants-by-websphere-jee6-mysql.ear /opt/ibm/wlp/usr/servers/defaultServer/apps

# 必要に応じて EXPOSE や CMD などを追加
