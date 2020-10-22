#!/bin/bash

echo "promoting the new version ${VERSION} to downstream repositories"

jx step create pr regex --regex "(?m)^FROM gcr.io/build-jx-prod/jxlabs-nos-master/jxlabs-nos-jxl-base-image:(?P<version>.*)$" --version ${VERSION} --files Dockerfile --repo https://github.com/nuxeo/jxlabs-nos-jxl.git
