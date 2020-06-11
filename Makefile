include Makefile.include

## Add your make instructions here

PROJECT_PREFIX=github.com/templ-project
PROJECT=go

MODE = mod
# MODE = app
init: init-$(SHELL_IS) ##
	go mod init $(PROJECT_PREFIX)/$(PROJECT)
	echo include Makefile.$(MODE).include > Makefile

init-bash:
	rm -rf go.mod
	rm -rf go.sum
ifeq ($(MODE),mod)
	cp -rdf .mod/* .; rm -rf .mod
else
	mv .app src
endif

init-powershell:
	$(POWERSHELL) -File ./.scripts/make.ps1 -Action Init -Mode $(MODE)
