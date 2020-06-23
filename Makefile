include Makefile.include

## Add your make instructions here

PROJECT_PREFIX=github.com/templ-project
PROJECT=go

MODE = mod
# MODE = app
init: init-$(SHELL_IS) ##
	go mod init $(PROJECT_PREFIX)/$(PROJECT)
	echo include Makefile.$(MODE).include > Makefile

	rm README.md
	cp README_TEMPLATE.md README.md

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

