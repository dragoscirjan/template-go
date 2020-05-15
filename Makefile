include Makefile.template

## Add your make instructions here

PROJECT=template-go

GIT_CERT_IGNORE =
GIT_CERT_IGNORE_COMMAND =
ifneq($(GIT_CERT_IGNORE),)
	GIT_CERT_IGNORE_COMMAND = git config http.sslVerify false
endif

clean: ## Clean all build/temp folders

configure: #configure-$(SHELL_IS) ## Configure and Init the code dependencies
	$(GIT_CERT_IGNORE_COMMAND)
	bash -c 'bash ./.scripts/pre-commit.sh --install'

configure-bash:
	[ -f .git/hooks/pre-commit ] || ln -s .scripts/pre-commit.sh .git/hooks/pre-commit
	chmod 755 .git/hooks/pre-commit

# https://winaero.com/blog/create-symbolic-link-windows-10-powershell/
configure-powershell: req_root
	$(POWERSHELL) -Command '\
		New-Item -ItemType SymbolicLink -Path ".\.git\hooks\pre-commit" -Target ".\.scripts\pre-commit.sh" \
	'

test: ## Run Tests
	@echo "Run Tests"

build: test ## Build Application
	@echo 'Build instructions'

install: build ## Install Application
	@echo 'Install Instructions'

uninstall: ## Uninstall Application
	@echo 'Uninstall Instructions'

init:
	go mod init github.com/dragoscirjan/$(PROJECT)
