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
BUILD_COMMIT = $(shell git log --format="%%h" -n 1)
ifeq ($(OSFLAG),WIN32)
	BUILD_DATE = $(shell $(POWERSHELL) -Command 'Get-Date -Format "dddd MM/dd/yyyy HH:mm K"')
	BUILD_VARS = set GOOS=$(BUILD_OS); set GOARCH=$(BUILD_ARCH);
else
	BUILD_DATE = $(shell date --utc)
	BUILD_VARS = GOOS=$(BUILD_OS) GOARCH=$(BUILD_ARCH)
endif
ifeq ($(BUILD_OS),windows)
	BUILD_EXT = .exe
else
	BUILD_EXT =
endif

ifneq ($(BUILD_VERSION),)
BUILD_VERSION_FLAG = $(PROJECT_PREFIX)/$(PROJECT)/src/cli.VersionName=$(BUILD_VERSION)
else
BUILD_VERSION_FLAG = $(PROJECT_PREFIX)/$(PROJECT)/src/cli.VersionName=none
endif
BUILD_COMMIT_FLAG = -X $(PROJECT_PREFIX)/$(PROJECT)/src/cli.GitCommit=$(BUILD_COMMIT)
BUILD_DATE_FLAG = -X $(PROJECT_PREFIX)/$(PROJECT)/src/cli.BuildDate=$(BUILD_DATE)

GO = go
GO_BUILD = $(GO) build -trimpath -ldflags="-X $(BUILD_VERSION_FLAG) -X $(BUILD_COMMIT_FLAG) -X '$(BUILD_DATE_FLAG)'"

#
# Instructions
#


CLEAN_FULL=
clean: clean-$(SHELL_IS) ## Clean all build/temp folders

clean-bash:
ifneq ($(CLEAN_FULL),)
	rm -rf ./build
else
	rm -rf ./build/$(BUILD_OS)/$(BUILD_ARCH)
endif

clean-powershell:
ifneq ($(CLEAN_FULL),)
	$(POWERSHELL) -Command 'if (Test-Path ".\go.mod" -PathType Container) { Remove-Item -Path .\build -Recurse -Force }'
else
	$(POWERSHELL) -Command 'if (Test-Path ".\go.mod" -PathType Container) { Remove-Item -Path .\build\$(BUILD_OS)\$(BUILD_ARCH) -Recurse -Force }'
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
	# curl --insecure -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh \
	# 	| sh -s -- -b $$(go env GOPATH)/bin \
	# 	$$(curl -sSL https://github.com/golangci/golangci-lint/releases | grep "releases/tag" | head -n 1 | awk -F '>' '{print $$2}' | awk -F '<' '{print $$1}')

	[ -f .git/hooks/pre-commit ] || ln -s .scripts/git-hooks/pre-commit.sh .git/hooks/pre-commit
	chmod 755 .git/hooks/pre-commit

# https://winaero.com/blog/create-symbolic-link-windows-10-powershell/
configure-powershell:
	@$(POWERSHELL) -Command '\
		if (-not (Test-Path ".\.git\hooks\pre-commit" -PathType Leaf)) { \
			Write-Host -ForegroundColor Green "The following (and final) step requires elevated rights. Unfortunately Windows does not allow creating symlinks unless running the command with eleveated rights."; \
			Write-Host -ForegroundColor Green "We will open a PowerShell console running with Administrator rigths. Please run the following command in that console, then close it."; \
			$$MyCwd = (Get-Location).Path; \
			Write-Host ''; \
			Write-Host -ForegroundColor Yellow  "Set-Location $$MyCwd; New-Item -ItemType SymbolicLink -Path .\.git\hooks\pre-commit -Target .\.scripts\pre-commit.sh;"; \
			Write-Host ''; \
			Write-Host 'Press Enter to continue'; \
			Read-Host ''; \
			Start-Process -FilePath "powershell" -Verb RunAs; \
		} \
	'

build: test clean build-$(SHELL_IS) ## Build Application BUILD_OS=? BUILD_ARCH=?
	$(BUILD_VARS) $(GO_BUILD) -o "build/$(BUILD_OS)/$(BUILD_ARCH)/main$(BUILD_EXT)" ./src/main.go

build-bash:
	mkdir -p build/$(BUILD_OS)/$(BUILD_ARCH)


build-powershell:
	$(POWERSHELL) -Command 'New-Item -Type Directory -Path .\build\$(BUILD_OS)\$(BUILD_ARCH) -Force'


init: init-$(SHELL_IS)
	go mod init $(PROJECT_PREFIX)/$(PROJECT)

init-bash:
	rm -rf go.mod

init-powershell:
	$(POWERSHELL) -Command 'if (Test-Path ".\go.mod" -PathType Leaf) { Remove-Item -Path .\go.mod -Force; }'


install: build ## Install Application
	@echo 'Install Instructions'


run: ## Run Application

uninstall: ## Uninstall Application
	@echo 'Uninstall Instructions'


TEST_COMMAND_OPTIONS=-v
TEST_COMMAND=go test -tags=unit -timeout 30s -short -coverprofile=".coverage.out" $(TEST_COMMAND_OPTIONS)
TEST_COVERAGE_COMMAND_OPTIONS=-o .coverage.html
TEST_COVERAGE_COMMAND=go tool cover -html=".coverage.out" $(TEST_COVERAGE_COMMAND_OPTIONS)
test: test-$(SHELL_IS) ## Run Tests
	$(TEST_COVERAGE_COMMAND)

# test-bash:
# 	$(TEST_COMMAND) ./...

test-bash:
	find ./src -iname "*_test.go" | while read f; do echo $$(dirname $$f)/...; done | uniq | xargs $(TEST_COMMAND)

# test-powershell:
# 	$(TEST_COMMAND) .\...

test-powershell:
	$(POWERSHELL) -Command ' \
		$$tests = Get-Childitem -Path .\src -Include *_test.go -File -Recurse -ErrorAction SilentlyContinue | ForEach { "." + (Split-Path -Path $$_).Replace((Get-Location).Path, "") + "\..." }  | Sort-Object -Unique; \
		$(TEST_COMMAND) $$tests \
	'
