include Makefile.include

## Add your make instructions here

PROJECT_PREFIX=github.com/templ-project
PROJECT=go

<<<<<<< HEAD
MODE = mod
# MODE = app
init: init-$(SHELL_IS) ##
=======
GIT_CERT_IGNORE =
GIT_CERT_IGNORE_COMMAND =
ifneq ($(GIT_CERT_IGNORE),)
	GIT_CERT_IGNORE_COMMAND = git config http.sslVerify false
endif

# https://gist.github.com/asukakenji/f15ba7e588ac42795f421b48b8aede63
BUILD_OS = linux
BUILD_ARCH = amd64
# GIT_REV_LIST = $(shell git rev-list --tags --max-count=1)
# BUILD_VERSION = $(shell git describe --tags $(GIT_REV_LIST))
BUILD_VERSION = $(shell git for-each-ref refs/tags --sort=-taggerdate --format='%%(refname)' --count=1)
ifeq ($(BUILD_VERSION),)
BUILD_VERSION=dev-$(shell git branch | grep "*" | cut -d ' ' -f 2)
endif
BUILD_COMMIT = $(shell git log --format="%h" -n 1)

BUILD_DATE = $(shell date --utc +%Y%m%d%H%M%S)
BUILD_PATH = ./dist/$(BUILD_OS)/$(BUILD_ARCH)
BUILD_VARS = GOOS=$(BUILD_OS) GOARCH=$(BUILD_ARCH)
BUILD_SRC = ./src/main.go
BUILD_BIN = $(BUILD_PATH)/main
ifeq ($(OSFLAG),WIN32)
BUILD_DATE = $(shell $(POWERSHELL) -Command 'Get-Date -Format "yyyyMMddHHmmss"')
# BUILD_PATH = .\dist\$(BUILD_OS)\$(BUILD_ARCH)
# BUILD_VARS = set GOOS="$(BUILD_OS)"; set GOARCH="$(BUILD_ARCH)";
# BUILD_SRC = .\main.go
# BUILD_BIN = $(BUILD_PATH)\main
endif

ifeq ($(BUILD_OS),windows)
	BUILD_EXT = .exe
else
	BUILD_EXT =
endif

BUILD_VERSION_FLAG = $(PROJECT_PREFIX)/$(PROJECT)/src/pkg/ver.VersionName=$(BUILD_VERSION)
BUILD_COMMIT_FLAG = $(PROJECT_PREFIX)/$(PROJECT)/src/pkg/ver.GitCommit=$(BUILD_COMMIT)
BUILD_DATE_FLAG = $(PROJECT_PREFIX)/$(PROJECT)/src/pkg/ver.BuildDate=$(BUILD_DATE)

GO := GOOS=$(BUILD_OS) GOARCH=$(BUILD_ARCH) go build -trimpath
GO_LDFLAGS = -X $(BUILD_VERSION_FLAG) -X $(BUILD_COMMIT_FLAG) -X '$(BUILD_DATE_FLAG)'

#
# Instructions
#

build: test clean build-$(SHELL_IS) ## Build Application BUILD_OS=? BUILD_ARCH=? #$(BUILD_SRC)

build-run:
	$(GO) -ldflags "$(GO_LDFLAGS)" -o $(BUILD_BIN)$(BUILD_EXT) $(BUILD_SRC)

build-bash: build-bash-mkdir build-run

build-bash-mkdir:
	mkdir -p dist/$(BUILD_OS)/$(BUILD_ARCH)

build-powershell: GO = $(POWERSHELL) -File ./.scripts/make.ps1 -Action Build -Command "go build -trimpath" -GoOs $(BUILD_OS) -GoArch $(BUILD_ARCH)
build-powershell: BUILD_SRC = -Src ./src/main.go
build-powershell: build-powershell-mkdir build-run

build-powershell-mkdir:
	$(POWERSHELL) -File ./.scripts/make.ps1 -Action MkDir -Path dist\$(BUILD_OS)\$(BUILD_ARCH)

CLEAN_FULL=
clean: clean-$(SHELL_IS) ## Clean all dist/temp folders

clean-bash:
ifneq ($(CLEAN_FULL),)
	rm -rf ./dist
else
	rm -rf $(BUILD_PATH)
endif

clean-powershell:
ifneq ($(CLEAN_FULL),)
	$(POWERSHELL) -File ./.scripts/make.ps1 -Action RmDir -Path .\dist
else
	$(POWERSHELL) -File ./.scripts/make.ps1 -Action RmDir -Path $(BUILD_PATH)
endif


configure: configure-$(SHELL_IS) ## Configure and Init the code dependencies
	$(GIT_CERT_IGNORE_COMMAND)
	go get -u golang.org/x/lint/golint

	go get golang.org/x/tools/cmd/goimports

	go get github.com/fzipp/gocyclo

	go get -t -v ./...

configure-bash:
	chmod 755 .scripts/pre-commit.sh
	[ -f .git/hooks/pre-commit ] || ln -s .scripts/pre-commit.sh .git/hooks/pre-commit

	go get -v -u github.com/go-lintpack/lintpack/...
	lintpack build -o gocritic github.com/go-critic/go-critic/checkers

	go get -v github.com/go-critic/go-critic/...
ifeq ($(IN_TRAVIS),)
ifeq ($(OSFLAG),WIN32)
	cd $$GOPATH/src/github.com/go-critic/go-critic; make gocritic
else
	cd $(shell go env GOPATH)/src/github.com/go-critic/go-critic && make gocritic
endif
endif

	curl --insecure -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $$(go env GOPATH)/bin $$(curl -sSL https://github.com/golangci/golangci-lint/releases | grep "releases/tag" | head -n 1 | awk -F '>' '{print $$2}' | awk -F '<' '{print $$1}')

# https://winaero.com/blog/create-symbolic-link-windows-10-powershell/
configure-powershell:
	$(POWERSHELL) -File ./.scripts/make.ps1 -Action Configure

	go get -v -u github.com/go-lintpack/lintpack/...
	lintpack build -o gocritic github.com/go-critic/go-critic/checkers

	go get -v github.com/go-critic/go-critic/...
ifeq ($(IN_TRAVIS),)
	cd $(shell go env GOPATH)/src/github.com/go-critic/go-critic && make gocritic
endif

init: init-$(SHELL_IS)
>>>>>>> b4e818fac047b934a25f02b19f9f62ce68978cf1
	go mod init $(PROJECT_PREFIX)/$(PROJECT)
	echo include Makefile.$(MODE).include > Makefile

init-bash:
	rm -rf go.mod
	rm -rf go.sum
ifeq ($(MODE),mod)
	cp .mod/* .
else
	mv .app src
endif
	rm -rf .app .mod

init-powershell:
	$(POWERSHELL) -File ./.scripts/make.ps1 -Action Init -Mode $(MODE)
ifeq ($(MODE),mod)
	cp .mod/* .
else
	mv .app src
endif
	$(POWERSHELL) -File ./.scripts/make.ps1 -Action RmDir -Path .\.app
	$(POWERSHELL) -File ./.scripts/make.ps1 -Action RmDir -Path .\.mod

