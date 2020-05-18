include Makefile.template

## Add your make instructions here

PROJECT_PREFIX=github.com/dragoscirjan
PROJECT=template-go

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
BUILD_VERSION=none
endif
BUILD_COMMIT = $(shell git log --format="%%h" -n 1)

ifeq ($(OSFLAG),WIN32)
	BUILD_DATE = $(shell $(POWERSHELL) -Command 'Get-Date -Format "yyyyMMddHHmmss"')
	BUILD_PATH = .\dist\$(BUILD_OS)\$(BUILD_ARCH)
	BUILD_VARS = set GOOS="$(BUILD_OS)"; set GOARCH="$(BUILD_ARCH)";
	BUILD_SRC = .\src\main.go
	BUILD_BIN = $(BUILD_PATH)\main
else
	BUILD_DATE = $(shell date --utc)
	BUILD_PATH = ./dist/$(BUILD_OS)/$(BUILD_ARCH)
	BUILD_VARS = GOOS=$(BUILD_OS) GOARCH=$(BUILD_ARCH)
	BUILD_SRC = ./src/main.go
	BUILD_BIN = $(BUILD_PATH)/main
endif

ifeq ($(BUILD_OS),windows)
	BUILD_EXT = .exe
else
	BUILD_EXT =
endif

BUILD_VERSION_FLAG = $(PROJECT_PREFIX)/$(PROJECT)/src.VersionName=$(BUILD_VERSION)
BUILD_COMMIT_FLAG = $(PROJECT_PREFIX)/$(PROJECT)/src.GitCommit=$(BUILD_COMMIT)
BUILD_DATE_FLAG = $(PROJECT_PREFIX)/$(PROJECT)/src.BuildDate=$(BUILD_DATE)

GO := GOOS=$(BUILD_OS) GOARCH=$(BUILD_ARCH) go build -trimpath
GO_LDFLAGS = -X $(BUILD_VERSION_FLAG) -X $(BUILD_COMMIT_FLAG) -X '$(BUILD_DATE_FLAG)'

#
# Instructions
#

#test clean
build: build-$(SHELL_IS) ## Build Application BUILD_OS=? BUILD_ARCH=? #$(BUILD_SRC)

build-run:
	$(GO) -ldflags "$(GO_LDFLAGS)" -o $(BUILD_BIN)$(BUILD_EXT) $(BUILD_SRC)

build-bash: build-bash-mkdir build-run

build-bash-mkdir:
	mkdir -p dist/$(BUILD_OS)/$(BUILD_ARCH)

build-powershell: GO = $(POWERSHELL) -File ./.scripts/make.ps1 -Action Build -Command "go build -trimpath" -GoOs $(BUILD_OS) -GoArch $(BUILD_ARCH)
build-powershell: BUILD_SRC = -Src .\src\main.go
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
	go get github.com/fzipp/gocyclo/...
	go get -u github.com/go-lintpack/lintpack/...
	go get github.com/go-critic/go-critic/...
	echo "cd $$GOPATH/src/github.com/go-critic/go-critic && make gocritic"

configure-bash:
	[ -f .git/hooks/pre-commit ] || ln -s .scripts/git-hooks/pre-commit.sh .git/hooks/pre-commit
	chmod 755 .git/hooks/pre-commit
	curl --insecure -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $$(go env GOPATH)/bin $$(curl -sSL https://github.com/golangci/golangci-lint/releases | grep "releases/tag" | head -n 1 | awk -F '>' '{print $$2}' | awk -F '<' '{print $$1}')

# https://winaero.com/blog/create-symbolic-link-windows-10-powershell/
configure-powershell:
	$(POWERSHELL) -File ./.scripts/make.ps1 -Action Configure


init: init-$(SHELL_IS)
	go mod init $(PROJECT_PREFIX)/$(PROJECT)

init-bash:
	rm -rf go.mod

init-powershell:
	$(POWERSHELL) -File ./.scripts/make.ps1 -Action Init


install: build ## Install Application
	@echo 'Install Instructions'


run: ## Run Application
	go run ...


uninstall: ## Uninstall Application
	@echo 'Uninstall Instructions'


GO_TEST_FLAGS=-tags=unit -timeout 30s -short -coverprofile=.coverage/coverage -v
GO_TEST=go test $(GO_TEST_FLAGS)
GO_COVERAGE_FLAGS=-o .coverage/coverage.html -html=.coverage/coverage
GO_COVERAGE=go tool cover $(GO_COVERAGE_FLAGS)
test: test-$(SHELL_IS) ## Run Tests
	$(GO_COVERAGE)

# test-bash:
# 	$(GO_TEST) ./src/...

test-bash:
	mkdir -p ./.coverage
	find ./src -iname "*_test.go" | while read f; do echo $$(dirname $$f)/...; done | uniq | xargs $(GO_TEST)

# test-powershell:
# 	$(GO_TEST) .\src\...

test-powershell:
	$(POWERSHELL) -File ./.scripts/make.ps1 -Action MkDir -Path .\.coverage
	$(POWERSHELL) -File ./.scripts/make.ps1 -Action Test -Command "$(GO_TEST)"


TEST_PATH=./src/...
test-single:
	$(GO_TEST) $(TEST_PATH)
