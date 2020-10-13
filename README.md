
NSIS installer scripts for ncdns.

Put the following files in `artifacts/`:

  - ncdns.exe
  - `ctlpop.ps1`
  - `certinject.exe`
  - dnssec-keygen.exe and its dependencies (libdns.dll, libisc.dll, libeay32.dll and libxml2.dll). These files can be sourced here:
    - (from BIND 9.11.0) These files can be found in this archive: https://ftp.isc.org/isc/bind/9.11.0/BIND9.11.0.xp.zip
    - For latest version, find the latest BIND 9 release under https://ftp.isc.org/isc/bind/ and download
      `BIND{version}.xp.zip`.
  - dnssec_trigger_setup.exe
  - namecoin-win32-setup-unsigned.exe / namecoin-win64-setup-unsigned.exe

  - Optionally, add `ncdt.exe` and `ncdumpzone.exe` from ncdns.
  - `generate_nmc_cert.exe` and `q.exe` will also be copied if they are present.

Build flags:

  - `make NCDNS_64BIT=1` — make a 64-bit build.
  - `make NCDNS_PRODVER=0.0.0.1` — set ncdns product version.

Licenced under the MIT License.
