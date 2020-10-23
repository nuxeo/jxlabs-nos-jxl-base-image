include make.d/version.mk

clean-build:
	rm -rf jx bdd-jx

init:
	mkdir -p build

bddjx: init
	git clone https://github.com/jenkins-x/bdd-jx.git
	cd bdd-jx && ./build-bddjx-linux.sh
	cp bdd-jx/build/bddjx-linux build

jx:
	git clone -b multicluster https://github.com/jenkins-x/jx.git
	cd jx && make linux
	cp jx/build/linux/jx build

promote~%: dry-run ?= false
promote~%: verbose ?= $(dry-run)

promote: promote~jxlabs-nos-jxl promote~nos-helmfile

promote~nos-helmfile:
	jx step create pr regex \
	  --dry-run=$(dry-run) --verbose=$(verbose) \
	  --version=${version}
	  --repo=https://github.com/nuxeo/nos.git --version=$(version) \
	  --regex="^helmfile-version := (?P<version>.*)$$" \
	  --files=Makefile
	jx step create pr regex \
	  --dry-run=$(dry-run) --verbose=$(verbose) \
	  --version=$(version) \
	  --repo=https://github.com/nuxeo/nos.git --version=$(version) \
	  --regex="^FROM .*/jxlabs-nos-jxl-base-image:(?P<version>.*)$$" \
	  --files=Dockefile

promote~jxlabs-nos-jxl:
	jx step create pr regex \
	--repo=https://github.com/nuxeo/jxlabs-nos-jxl.git \
	--version=${version} \
	--regex="^FROM .*/jxlabs-nos-jxl-base-image:(?P<version>.*)$$" \
	--file=Dockerfile
