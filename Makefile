MAKENSIS ?= makensis
NSISFLAGS ?= -V2

NCDNS_REPO ?= github.com/namecoin/ncdns
NCDNS_PRODVER ?= 
ifeq ($(NCDNS_PRODVER),)
	ifneq ($(GOPATH),)
		NCDNS_PRODVER=$(shell git -C "$(GOPATH)/src/$(NCDNS_REPO)" describe --all --abbrev=99 |grep -E '^v[0-9]')
	endif
endif
ifeq ($(NCDNS_PRODVER),)
	NCDNS_PRODVER=0.0.0
endif

# Remove leading v
NCDNS_PRODVER_1TUP=$(shell echo "$(NCDNS_PRODVER)" | sed 's/^v//')
# Append ".0" until the version is a 4-tuple
ifneq ($(shell echo "$(NCDNS_PRODVER_1TUP)" | grep -E '^[0-9]+$$'),)
	NCDNS_PRODVER_2TUP=$(shell echo "$(NCDNS_PRODVER_1TUP)" | sed 's/$$/.0/')
else
	NCDNS_PRODVER_2TUP=$(NCDNS_PRODVER_1TUP)
endif
ifneq ($(shell echo "$(NCDNS_PRODVER_2TUP)" | grep -E '^[0-9]+\.[0-9]+$$'),)
	NCDNS_PRODVER_3TUP=$(shell echo "$(NCDNS_PRODVER_2TUP)" | sed 's/$$/.0/')
else
	NCDNS_PRODVER_3TUP=$(NCDNS_PRODVER_2TUP)
endif
ifneq ($(shell echo "$(NCDNS_PRODVER_3TUP)" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$$'),)
	NCDNS_PRODVER_W=$(shell echo "$(NCDNS_PRODVER_3TUP)" | sed 's/$$/.0/')
else
	NCDNS_PRODVER_W=$(NCDNS_PRODVER_3TUP)
endif

_NO_NAMECOIN_CORE=
ifeq ($(NO_NAMECOIN_CORE),1)
	_NO_NAMECOIN_CORE=-DNO_NAMECOIN_CORE
endif

_NO_ELECTRUM_NMC=
ifeq ($(NO_ELECTRUM_NMC),1)
	_NO_ELECTRUM_NMC=-DNO_ELECTRUM_NMC
endif

_NO_DNSSEC_TRIGGER=
ifeq ($(NO_DNSSEC_TRIGGER),1)
	_NO_DNSSEC_TRIGGER=-DNO_DNSSEC_TRIGGER
endif

_NCDNS_LOGGING=
ifeq ($(NCDNS_LOGGING),1)
	_NCDNS_LOGGING=-DENABLE_LOGGING
endif

_NCDNS_64BIT=
_BUILD=build32
GOARCH=386
BINDARCH=x86
ifeq ($(NCDNS_64BIT),1)
	_NCDNS_64BIT=-DNCDNS_64BIT=1
	_BUILD=build64
	GOARCH=amd64
	BINDARCH=x64
endif
BUILD ?= $(_BUILD)

NEUTRAL_ARTIFACTS = artifacts
ARTIFACTS = $(BUILD)/artifacts

NCARCH=win32
ifeq ($(NCDNS_64BIT),1)
  NCARCH=win64
endif
OUTFN := $(BUILD)/bin/ncdns-$(NCDNS_PRODVER)-$(NCARCH)-install.exe

all: $(OUTFN)


### DNSSEC-KEYGEN
##############################################################################
# When bumping the BIND version, make sure to test whether its Visual C++
# dependency has changed version, and change the detection functions in the
# NSIS script accordingly.  Also make sure you test both the 32-bit and 64-bit
# versions for bumped Visual C++ dependencies; sometimes they might be bumped
# independently.  Also make sure you test for *multiple* Visual C++
# dependencies; sometimes a single program might link against multiple Visual
# C++ dependencies.
BINDV=9.17.11
$(ARTIFACTS)/BIND$(BINDV).$(BINDARCH).zip:
	wget -O "$@" "https://ftp.isc.org/isc/bind/$(BINDV)/BIND$(BINDV).$(BINDARCH).zip"

KGFILES=dnssec-keygen.exe libcrypto-1_1-x64.dll libdns.dll libisc.dll libisccfg.dll libssl-1_1-x64.dll libxml2.dll nghttp2.dll uv.dll
KGFILES_T=$(foreach k,$(KGFILES),tmp/$(k))
KGFILES_A=$(foreach k,$(KGFILES),$(ARTIFACTS)/$(k))

$(ARTIFACTS)/dnssec-keygen.exe: $(ARTIFACTS)/BIND$(BINDV).$(BINDARCH).zip
	(cd "$(ARTIFACTS)"; mkdir tmp; cd tmp; unzip "../BIND$(BINDV).$(BINDARCH).zip"; cd ..; mv $(KGFILES_T) .; rm -rf tmp;)

.NOTPARALLEL: $(KGFILES_A)


### DNSSEC-TRIGGER
##############################################################################
DNSSEC_TRIGGER_VER=0.17
DNSSEC_TRIGGER_FN=dnssec_trigger_setup_$(DNSSEC_TRIGGER_VER).exe
DNSSEC_TRIGGER_URL=https://www.nlnetlabs.nl/downloads/dnssec-trigger/
#DNSSEC_TRIGGER_URL=https://www.nlnetlabs.nl/~wouter/

$(ARTIFACTS)/$(DNSSEC_TRIGGER_FN):
	wget -O "$@" "$(DNSSEC_TRIGGER_URL)$(DNSSEC_TRIGGER_FN)"


### NAMECOIN
##############################################################################
NAMECOIN_VER=0.13.99
NAMECOIN_VER_TAG=-name-tab-beta1-notreproduced
NAMECOIN_FN=namecoin-$(NAMECOIN_VER)-$(NCARCH)-setup-unsigned.exe

$(ARTIFACTS)/$(NAMECOIN_FN):
	wget -O "$@" "https://namecoin.org/files/namecoin-core-$(NAMECOIN_VER)$(NAMECOIN_VER_TAG)/$(NAMECOIN_FN)"


### ELECTRUM-NMC
##############################################################################
ELECTRUM_NMC_FN=electrum-nmc-setup.exe


### INSTALLER
##############################################################################
$(OUTFN): ncdns.nsi $(NEUTRAL_ARTIFACTS)/ncdns.conf $(KGFILES_A) $(ARTIFACTS)/$(DNSSEC_TRIGGER_FN) $(ARTIFACTS)/$(NAMECOIN_FN) $(ARTIFACTS)/q.exe
	@mkdir -p "$(BUILD)/bin"
	$(MAKENSIS) $(NSISFLAGS) -DPOSIX_BUILD=1 -DNCDNS_PRODVER=$(NCDNS_PRODVER_W) \
		$(_NCDNS_64BIT) $(_NO_NAMECOIN_CORE) $(_NO_ELECTRUM_NMC) $(_NO_DNSSEC_TRIGGER) $(_NCDNS_LOGGING) \
		-DARTIFACTS=$(BUILD)/artifacts \
		-DNEUTRAL_ARTIFACTS=artifacts \
		-DDNSSEC_TRIGGER_FN=$(DNSSEC_TRIGGER_FN) \
		-DNAMECOIN_FN=$(NAMECOIN_FN) \
		-DELECTRUM_NMC_FN=$(ELECTRUM_NMC_FN) \
		-DOUTFN="$(OUTFN)" "$<"

clean:
	rm -rf "$(BUILD)"
