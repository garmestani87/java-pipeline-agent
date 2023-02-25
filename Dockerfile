FROM adoptopenjdk/openjdk11:x86_64-alpine-jdk-11.0.18_10-slim
#FROM openjdk:8u212-jdk-alpine

ARG MAVEN_VERSION=3.6.3
ARG USER_HOME_DIR="/root"
ARG SHA=c35a1803a6e70a126e80b2b3ae33eed961f83ed74d18fcd16909b2d44d7dada3203f1ffe726c17ef8dcca2dcaa9fca676987befeadc9b9f759967a8cb77181c0
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

RUN apk add curl \
  && mkdir -p /usr/share/maven \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && rm -f /usr/bin/mvn \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn


COPY kubectl /usr/bin
RUN chmod 777 /usr/bin
RUN mkdir /root/.kube/
COPY docker-18.09.0.tgz /
RUN  pwd && tar xzvf docker-18.09.0.tgz \
  && mv docker/docker /usr/local/bin \
  && rm -r docker docker-18.09.0.tgz

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

COPY mvn-entrypoint.sh /usr/local/bin/mvn-entrypoint.sh
COPY settings-docker.xml /usr/share/maven/conf/
COPY settings.xml /usr/share/maven/conf/

ENTRYPOINT ["/usr/local/bin/mvn-entrypoint.sh"]
CMD ["mvn"]