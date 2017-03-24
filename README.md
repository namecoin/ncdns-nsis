
NSIS installer scripts for ncdns.

Put the following files in `artifacts/`:

  - ncdns.exe
  - dnssec-keygen.exe and its dependencies (libdns.dll, libisc.dll, libeay32.dll and libxml2.dll). These files can be sourced here:
    - (from BIND 9.11.0) These files can be found in this archive: https://ftp.isc.org/isc/bind/9.11.0/BIND9.11.0.x86.zip
    - For latest version, find the latest BIND 9 release under https://ftp.isc.org/isc/bind/ and download
      `BIND{version}.x86.zip`.

