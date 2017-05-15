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

_NCDNS_64BIT=
ifeq ($(NCDNS_64BIT),1)
	_NCDNS_64BIT=-DNCDNS_64BIT=1
endif

_NO_NAMECOIN_CORE=
ifeq ($(NO_NAMECOIN_CORE),1)
	_NO_NAMECOIN_CORE=-DNO_NAMECOIN_CORE
endif

_NO_DNSSEC_TRIGGER=
ifeq ($(NO_DNSSEC_TRIGGER),1)
	_NO_DNSSEC_TRIGGER=-DNO_DNSSEC_TRIGGER
endif

build/ncdns-install.exe: ncdns.nsi artifacts/ncdns.exe artifacts/ncdns.conf
	@mkdir -p build/
	$(MAKENSIS) $(NSISFLAGS) -DPOSIX_BUILD=1 -DNCDNS_PRODVER=$(NCDNS_PRODVER) $(_NCDNS_64BIT) $(_NO_NAMECOIN_CORE) $(_NO_DNSSEC_TRIGGER) "$<"

clean:
	rm build/ncdns-install.exe
