FROM centos:7

RUN mkdir /out

# helmfile
ENV HELMFILE_VERSION 0.118.5
RUN curl --silent -LO https://github.com/roboll/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_linux_amd64 && \
  mv helmfile_linux_amd64 /out/helmfile && \
  chmod +x /out/helmfile

# kubectl
ENV KUBECTL_VERSION 1.16.0
RUN curl --silent -LO  https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
  mv kubectl /out/kubectl && \
  chmod +x /out/kubectl

# helm 3
ENV HELM3_VERSION 3.2.1
RUN curl --silent -f -L https://get.helm.sh/helm-v${HELM3_VERSION}-linux-386.tar.gz | tar xzv && \
  mv linux-386/helm /out/helm


# git
ENV GIT_VERSION 2.21.1
RUN yum install -y curl-devel expat-devel gettext-devel openssl-devel zlib-devel && \
    yum install -y gcc perl-ExtUtils-MakeMaker make
RUN cd /usr/src  && \
    curl --silent -LO https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz  && \
    tar xzf git-${GIT_VERSION}.tar.gz  && \
    cd git-${GIT_VERSION} && \
    make prefix=/usr/local/git all  && \
    make prefix=/usr/local/git install

# Downloading gcloud package
RUN curl --silent https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz > /tmp/google-cloud-sdk.tar.gz

# Installing the package
RUN mkdir -p /usr/local/gcloud \
  && tar -C /usr/local/gcloud -xvf /tmp/google-cloud-sdk.tar.gz \
  && /usr/local/gcloud/google-cloud-sdk/install.sh && \
  /usr/local/gcloud/google-cloud-sdk/bin/gcloud components install beta && \
  /usr/local/gcloud/google-cloud-sdk/bin/gcloud components update

# add additional CLIs

ARG PULUMI_VERSION=2.3.0
RUN curl --silent --location --output /dev/stdout \
         https://get.pulumi.com/releases/sdk/pulumi-v${PULUMI_VERSION}-linux-x64.tar.gz | \
    tar --extract --file=/dev/stdin --directory=/out \
        --strip-components=1 --gunzip pulumi

ARG HUB_VERSION=2.14.2
RUN curl --silent --location --output /dev/stdout \
    	 https://github.com/github/hub/releases/download/v${HUB_VERSION}/hub-linux-amd64-${HUB_VERSION}.tgz | \
    tar --extract --file=/dev/stdin --directory=/out \
        --strip-components=2 --gunzip hub-linux-amd64-${HUB_VERSION}/bin/hub

ARG JQ_VERSION=1.6
RUN curl --silent --location --output /out/jq \
         https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 && \
    chmod +x /out/jq

ARG YQ_VERSION=3.3.0
RUN curl --silent --location --output /out/yq \
         https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 && \
    chmod +x /out/yq

# kustomize
ENV KUSTOMIZE_VERSION 3.6.1
RUN curl --silent -f -L https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz | tar xzv && \
  mv kustomize /out && \
  chmod +x /out/kustomize

# jenkins-x
ENV JX_VERSION 2.1.40-jxlabs-nos-1
RUN curl --silent -f -L https://github.com/nuxeo/jxlabs-nos-jx/releases/download/v${JX_VERSION}/jxlabs-nos-jx-linux-amd64.tar.gz | tar xvfCz - /out jx && \
  chmod +x /out/jx

# use a multi stage image so we don't include all the build tools above
FROM centos:7
# need to copy the whole git source else it doesn't clone the helm plugin repos below
COPY --from=0 /usr/local/git /usr/local/git
COPY --from=0 /usr/bin/make /usr/bin/make
COPY --from=0 /out /usr/local/bin
COPY --from=0 /usr/local/gcloud /usr/local/gcloud

ENV NODEJS_VERSION=12
RUN curl -f --silent --location https://rpm.nodesource.com/setup_${NODEJS_VERSION}.x | bash - && \
  yum install -y nodejs && yum clean all && \
  npm install -g pnpm

ENV PATH /usr/local/bin:/usr/local/git/bin:$PATH:/usr/local/gcloud/google-cloud-sdk/bin

ENV HELM_PLUGINS /root/.cache/helm/plugins/
ENV JX_HELM3 "true"

ENV HELM_DIFF_VERSION 3.1.1
ENV HELM_GCS_VERSION 0.3.1
ENV HELM_GIT_VERSION 0.7.0
ENV HELM_X_VERSION 0.8.0
RUN yum install -y wget && yum clean all && \
    /usr/local/bin/helm plugin install https://github.com/databus23/helm-diff --version ${HELM_DIFF_VERSION} && \
    /usr/local/bin/helm plugin install https://github.com/aslafy-z/helm-git --version ${HELM_GIT_VERSION} && \
    /usr/local/bin/helm plugin install https://github.com/hayorov/helm-gcs --version v${HELM_GCS_VERSION} && \
    /usr/local/bin/helm plugin install https://github.com/mumoshu/helm-x --version v${HELM_X_VERSION}

RUN mkdir -p /root/.jx/plugins/bin && \
    ln -s /usr/local/bin/helm $HOME/.jx/plugins/bin/helm-${HELM3_VERSION}

