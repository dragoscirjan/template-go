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
	cp src/* .
	rm main.go
endif
	make init-$(OSFLAG)

init-LINUX:
	grep "$(PROJECT_PREFIX)/$(PROJECT)" . -Rin | awk -F ':' '{ print git $$1 }' | while read f; do sed -e 's|github.com/templ-project/go|$(PROJECT_PREFIX)/$(PROJECT)|g' -i $$f; done

init-OSX:
	grep "$(PROJECT_PREFIX)/$(PROJECT)" . -Rin | awk -F ':' '{ print git $$1 }' | while read f; do sed -i -e 's|github.com/templ-project/go|$(PROJECT_PREFIX)/$(PROJECT)|g' $$f; done

init-powershell:
	$(POWERSHELL) -File ./.scripts/make.ps1 -Action Init -Mode $(MODE) -Project $(PROJECT_PREFIX)/$(PROJECT)
	$(POWERSHELL) -File ./.scripts/make.ps1 -Action RmDir -Path .\.mod

