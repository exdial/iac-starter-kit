# Alpine Docker image with installed:
# terraform, terragrunt
# awscli, google-cloud-sdk
FROM alpine:3.16.0

# Versions of binaries included in image
# terraform
ARG TF_VER=1.2.4
# terragrunt
ARG TG_VER=0.38.3

# Adjust user/group and their id's from outside
# to prevent possible permission conflicts
ARG GID=1000
ARG UID=1000
ARG GROUP=user
ARG USER=user

# Create a regular user to run container in non-root mode
RUN addgroup -g ${GID} -S ${GROUP} \
 && adduser -h /home/${USER} -s /bin/bash -G ${GROUP} -u ${UID} -D ${USER}

# Working directory
WORKDIR /usr/local/bin

# Geting Terraform
ARG TF_URI="https://releases.hashicorp.com/terraform"
RUN wget -q ${TF_URI}/${TF_VER}/terraform_${TF_VER}_linux_amd64.zip \
 && wget -q ${TF_URI}/${TF_VER}/terraform_${TF_VER}_SHA256SUMS \
 && grep terraform_${TF_VER}_linux_amd64.zip terraform_${TF_VER}_SHA256SUMS | \
    sha256sum -c - \
 && unzip terraform_${TF_VER}_linux_amd64.zip && chmod +x terraform \
 && rm terraform_${TF_VER}_linux_amd64.zip terraform_${TF_VER}_SHA256SUMS

# Getting Terragrunt
ARG TG_URI="https://github.com/gruntwork-io/terragrunt/releases/download"
RUN wget -q ${TG_URI}/v${TG_VER}/terragrunt_linux_amd64 \
 && wget -q ${TG_URI}/v${TG_VER}/SHA256SUMS \
 && grep terragrunt_linux_amd64 SHA256SUMS | sha256sum -c - \
 && mv terragrunt_linux_amd64 terragrunt && chmod +x terragrunt \
 && rm SHA256SUMS

WORKDIR /tmp

# Install glibc compatibility for the AWS CLI v2
ARG GLIBC_VERSION=2.31-r0
ARG GLIBC_URI="https://github.com/sgerrand/alpine-pkg-glibc/releases/download"
RUN wget -q https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -O \
    /etc/apk/keys/sgerrand.rsa.pub \
 && wget -q ${GLIBC_URI}/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk \
 && wget -q ${GLIBC_URI}/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk \
 && apk add --no-cache glibc-${GLIBC_VERSION}.apk \
                       glibc-bin-${GLIBC_VERSION}.apk \
 && rm -rf glibc-*.apk /var/cache/apk/*

# Getting AWS CLI
RUN wget -q https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
 && unzip awscli-exe-linux-x86_64.zip \
 && ./aws/install \
 && rm -rf aws /usr/local/aws-cli/v2/*/dist/aws_completer \
           /usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
           /usr/local/aws-cli/v2/*/dist/awscli/examples \
           awscli-exe-linux-x86_64.zip \
 && find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name \
    examples-1.json -delete

# Install python3 for Google Cloud CLI
ENV PYTHONUNBUFFERED=1
RUN apk add --no-cache --update python3

# Getting Google Cloud CLI
WORKDIR /opt
RUN wget -q https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz \
 && tar xf google-cloud-sdk.tar.gz \
 && rm google-cloud-sdk.tar.gz

# Switch current user to a regular one
USER ${USER}

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
