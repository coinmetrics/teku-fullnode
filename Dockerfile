FROM ubuntu:20.04 as builder

RUN set -ex; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		curl \
		openjdk-11-jdk-headless \
	; \
	rm -rf /var/lib/apt/lists/*

RUN set -ex; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		git \
	; \
	rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 -s /bin/bash teku
USER teku

ARG VERSION
RUN if test ${#VERSION} -ge 40 ; \
    then \
      echo Checking out commit $VERSION && \
      git clone https://github.com/ConsenSys/teku.git /home/teku/teku && \
      cd /home/teku/teku && git reset --hard $VERSION ; \
    else \
      echo Checking out branch $VERSION && \
      git clone --depth 1 -b ${VERSION} https://github.com/ConsenSys/teku.git /home/teku/teku ; \
    fi


RUN set -ex; \
	cd /home/teku/teku; \
	./gradlew distTar installDist

FROM ubuntu:20.04

RUN set -ex; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		openjdk-11-jre-headless \
	; \
	rm -rf /var/lib/apt/lists/*

# After a successful build, distribution packages are available in build/distributions.

COPY --from=builder /home/teku/teku/build/install/teku /opt/

RUN useradd -m -u 1000 -s /bin/bash teku
USER teku
WORKDIR /opt
ENTRYPOINT [ "./bin/teku" ]

