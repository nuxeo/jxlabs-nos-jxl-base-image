FROM centos:7

ENV PATH /usr/local/bin:$PATH

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

ENV PATH /usr/local/git/bin:$PATH

# gcloud
RUN curl --silent https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz > /tmp/google-cloud-sdk.tar.gz

RUN mkdir -p /usr/local/gcloud \
  && tar -C /usr/local/gcloud -xvf /tmp/google-cloud-sdk.tar.gz \
  && /usr/local/gcloud/google-cloud-sdk/install.sh && \
  /usr/local/gcloud/google-cloud-sdk/bin/gcloud components install beta && \
  /usr/local/gcloud/google-cloud-sdk/bin/gcloud components update

ENV PATH /usr/local/gcloud/google-cloud-sdk/bin:$PATH

# helmfile
ENV HELMFILE_VERSION 0.132.0
RUN curl --silent -o /usr/local/bin/helmfile -L https://github.com/roboll/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_linux_amd64 && \
  chmod +x /usr/local/bin/helmfile

# kubectl
ENV KUBECTL_VERSION 1.16.0
RUN curl --silent -o /usr/local/bin/kubectl -LO  https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
  chmod +x /usr/local/bin/kubectl


# helm 3
ENV HELM3_VERSION 3.2.1
RUN curl --silent -f -L https://get.helm.sh/helm-v${HELM3_VERSION}-linux-386.tar.gz | \
  tar --gzip --extract --file=/dev/stdin --strip-components=1 --directory=/usr/local/bin linux-386/helm && \
  chmod +x /usr/local/bin/helm

ENV HELM_PLUGINS /usr/local/helm/plugins

ENV HELM_DIFF_VERSION 3.1.1
ENV HELM_GCS_VERSION 0.3.1
ENV HELM_GIT_VERSION 0.7.0
ENV HELM_X_VERSION 0.8.0

RUN yum install -y wget && yum clean all && \
    XDG_DATA_HOME=/usr/local helm plugin install https://github.com/databus23/helm-diff --version ${HELM_DIFF_VERSION} && \
    XDG_DATA_HOME=/usr/local helm plugin install https://github.com/aslafy-z/helm-git --version ${HELM_GIT_VERSION} && \
    XDG_DATA_HOME=/usr/local helm plugin install https://github.com/hayorov/helm-gcs --version v${HELM_GCS_VERSION} && \
    XDG_DATA_HOME=/usr/local helm plugin install https://github.com/mumoshu/helm-x --version v${HELM_X_VERSION}

# add additional CLIs

ENV PULUMI_VERSION 2.3.0
RUN curl --silent --location --output /dev/stdout \
         https://get.pulumi.com/releases/sdk/pulumi-v${PULUMI_VERSION}-linux-x64.tar.gz | \
    tar --extract --file=/dev/stdin --directory=/usr/local/bin \
        --strip-components=1 --gunzip pulumi

ENV HUB_VERSION 2.14.2
RUN curl --silent --location --output /dev/stdout \
    	 https://github.com/github/hub/releases/download/v${HUB_VERSION}/hub-linux-amd64-${HUB_VERSION}.tgz | \
    tar --extract --file=/dev/stdin --directory=/usr/local/bin \
        --strip-components=2 --gunzip hub-linux-amd64-${HUB_VERSION}/bin/hub

ENV JQ_VERSION 1.6
RUN curl --silent --location --output /usr/local/bin/jq \
         https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 && \
    chmod +x /usr/local/bin/jq

ENV YQ_VERSION 3.3.0
RUN curl --silent --location --output /usr/local/bin/yq \
    https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq

# kustomize
ENV KUSTOMIZE_VERSION 3.6.1
RUN curl --silent -f -L https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz | tar xfCz - /usr/local/bin && \
  chmod +x /usr/local/bin/kustomize

# use a multi stage image so we don't include all the build tools above
FROM centos:7

ENV NODEJS_VERSION 12
RUN curl -f --silent --location https://rpm.nodesource.com/setup_${NODEJS_VERSION}.x | bash - && \
  yum install -y nodejs && yum clean all && \
  npm install -g pnpm

COPY --from=0 /usr/local /usr/local
COPY --from=0 /usr/bin/make /usr/local/bin/make

ENV PATH /usr/local/git/bin:/usr/local/gcloud/google-cloud-sdk/bin:/usr/local/bin:$PATH
ENV HELM_PLUGINS /usr/local/helm/plugins
ENV JX_HELM3 true

