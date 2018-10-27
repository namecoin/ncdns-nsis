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

NCDNS_PRODVER_W=$(shell echo "$(NCDNS_PRODVER)" | sed 's/^v//' | sed 's/$$/.0/')

_NO_NAMECOIN_CORE=
ifeq ($(NO_NAMECOIN_CORE),1)
	_NO_NAMECOIN_CORE=-DNO_NAMECOIN_CORE
endif

_NO_DNSSEC_TRIGGER=
ifeq ($(NO_DNSSEC_TRIGGER),1)
	_NO_DNSSEC_TRIGGER=-DNO_DNSSEC_TRIGGER
endif

_NCDNS_64BIT=
_BUILD=build32
GOARCH=386
BINDARCH=x86
MARARCH=32
ifeq ($(NCDNS_64BIT),1)
	_NCDNS_64BIT=-DNCDNS_64BIT=1
	_BUILD=build64
	GOARCH=amd64
	BINDARCH=x64
	MARARCH=64
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


### NCDNS
##############################################################################
NCDNS_ARCFN=ncdns-$(NCDNS_PRODVER)-windows_$(GOARCH).tar.gz

$(ARTIFACTS)/$(NCDNS_ARCFN):
	mkdir -p "$(ARTIFACTS)"
	wget -O "$@" "https://github.com/namecoin/ncdns/releases/download/$(NCDNS_PRODVER)/$(NCDNS_ARCFN)"

EXES=ncdns ncdumpzone generate_nmc_cert ncdt tlsrestrict_chromium_tool
EXES_A=$(foreach k,$(EXES),$(ARTIFACTS)/$(k).exe)

$(ARTIFACTS)/ncdns.exe: $(ARTIFACTS)/$(NCDNS_ARCFN)
	(cd "$(ARTIFACTS)"; tar zxvf "$(NCDNS_ARCFN)"; mv ncdns-$(NCDNS_PRODVER)-windows_$(GOARCH)/bin/* ./; rm -rf ncdns-$(NCDNS_PRODVER)-windows_$(GOARCH);)


### DNSSEC-KEYGEN
##############################################################################
# When bumping the BIND version, make sure to test whether its Visual C++
# dependency has changed version, and change the detection functions in the
# NSIS script accordingly.  Also make sure you test both the 32-bit and 64-bit
# versions for bumped Visual C++ dependencies; sometimes they might be bumped
# independently.  Also make sure you test for *multiple* Visual C++
# dependencies; sometimes a single program might link against multiple Visual
# C++ dependencies.
BINDV=9.13.3
$(ARTIFACTS)/BIND$(BINDV).$(BINDARCH).zip:
	wget -O "$@" "https://ftp.isc.org/isc/bind/$(BINDV)/BIND$(BINDV).$(BINDARCH).zip"

KGFILES=dnssec-keygen.exe libisc.dll libdns.dll libeay32.dll libxml2.dll
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


### Q
##############################################################################
$(ARTIFACTS)/q.exe:
	(cd "$(ARTIFACTS)"; GOOS=windows GOARCH=$(GOARCH) go build github.com/miekg/exdns/q;)

### MAR-TOOLS
##############################################################################
# When bumping the mar-tools version, make sure to test whether its Visual C++
# dependency has changed version, and change the detection functions in the
# NSIS script accordingly.
MARV=8.5a4
$(ARTIFACTS)/mar-tools-win32.zip:
	wget -O "$@" "https://dist.torproject.org/torbrowser/$(MARV)/mar-tools-win32.zip"
$(ARTIFACTS)/mar-tools-win64.zip:
	wget -O "$@" "https://dist.torproject.org/torbrowser/$(MARV)/mar-tools-win64.zip"

MARFILES=nss-certutil.exe freebl3.dll mozglue.dll nss3.dll nssdbm3.dll softokn3.dll
MARFILES_T32=$(foreach k,$(MARFILES),../tmp32/mar-tools/$(k))
MARFILES_A32=$(foreach k,$(MARFILES),$(ARTIFACTS)/mar-tools-32/$(k))
MARFILES_T64=$(foreach k,$(MARFILES),../tmp64/mar-tools/$(k))
MARFILES_A64=$(MARFILES_A32) $(foreach k,$(MARFILES),$(ARTIFACTS)/mar-tools-64/$(k))

$(ARTIFACTS)/mar-tools-32/nss-certutil.exe: $(ARTIFACTS)/mar-tools-win32.zip
	(cd "$(ARTIFACTS)"; mkdir tmp32; cd tmp32; unzip "../mar-tools-win32.zip"; mv mar-tools/certutil.exe mar-tools/nss-certutil.exe; cd ..; mkdir mar-tools-32; cd mar-tools-32; mv $(MARFILES_T32) .; cd ..; rm -rf tmp32;)

$(ARTIFACTS)/mar-tools-64/nss-certutil.exe: $(ARTIFACTS)/mar-tools-win64.zip
	(cd "$(ARTIFACTS)"; mkdir tmp64; cd tmp64; unzip "../mar-tools-win64.zip"; mv mar-tools/certutil.exe mar-tools/nss-certutil.exe; cd ..; mkdir mar-tools-64; cd mar-tools-64; mv $(MARFILES_T64) .; cd ..; rm -rf tmp64;)

.NOTPARALLEL: $(MARFILES_A32)
.NOTPARALLEL: $(MARFILES_A64)

### INSTALLER
##############################################################################
$(OUTFN): ncdns.nsi $(NEUTRAL_ARTIFACTS)/ncdns.conf $(EXES_A) $(KGFILES_A) $(ARTIFACTS)/$(DNSSEC_TRIGGER_FN) $(ARTIFACTS)/$(NAMECOIN_FN) $(ARTIFACTS)/q.exe $(MARFILES_A$(MARARCH))
	@mkdir -p "$(BUILD)/bin"
	$(MAKENSIS) $(NSISFLAGS) -DPOSIX_BUILD=1 -DNCDNS_PRODVER=$(NCDNS_PRODVER_W) \
		$(_NCDNS_64BIT) $(_NO_NAMECOIN_CORE) $(_NO_DNSSEC_TRIGGER) \
		-DARTIFACTS=$(BUILD)/artifacts \
		-DNEUTRAL_ARTIFACTS=artifacts \
		-DDNSSEC_TRIGGER_FN=$(DNSSEC_TRIGGER_FN) \
		-DNAMECOIN_FN=$(NAMECOIN_FN) \
		-DOUTFN="$(OUTFN)" "$<"

clean:
	rm -rf "$(BUILD)"
