all: build/ncdns-install.exe

MAKENSIS ?= makensis
NSISFLAGS ?= -V2

NCDNS_REPO ?= github.com/hlandau/ncdns
NCDNS_PRODVER ?= 
ifeq ($(NCDNS_PRODVER),)
	ifneq ($(GOPATH),)
		NCDNS_PRODVER=$(shell git -C "$(GOPATH)/src/$(NCDNS_REPO)" describe --all --abbrev=99 |grep -E '^v[0-9]' )
	endif
endif
ifeq ($(NCDNS_PRODVER),)
	NCDNS_PRODVER=0.0.0.1
endif

build/ncdns-install.exe: ncdns.nsi artifacts/ncdns.exe artifacts/ncdns.conf
	@mkdir -p build/
	$(MAKENSIS) $(NSISFLAGS) -DPOSIX_BUILD=1 -DNCDNS_PRODVER=$(NCDNS_PRODVER) "$<"

clean:
	rm build/ncdns-install.exe
