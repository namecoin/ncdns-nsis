
NSIS installer scripts for ncdns.

Put the following files in `build64/artifacts/` or `build32/artifacts/`:

  - `ncdns.exe`
  - `certinject.exe`
  - `dnssec-keygen.exe` and its dependencies (`libcrypto-1_1-x64.dll`, `libdns.dll`, `libisc.dll`, `libisccfg.dll`, `libssl-1_1-x64.dll`, `libxml2.dll`, and `uv.dll`). These files can be sourced here:
    - Find the latest BIND 9.16.x release under https://ftp.isc.org/isc/bind/ and download
      `BIND{version}.x64.zip`.
  - `dnssec_trigger_setup.exe`
  - `namecoin-win32-setup-unsigned.exe` / `namecoin-win64-setup-unsigned.exe`
  - `electrum-nmc-setup.exe`
  - `ncdt.exe` and `ncdumpzone.exe` from ncdns
  - `generate_nmc_cert.exe`
  - `q.exe` from qlib
  - `ncprop279.exe`
  - `winsvcwrap.exe`
  - `python` folder, containing an unzipped Python embeddable package

Put the following files in `artifacts/`:

  - `stem` Python package
  - `stemns/stemns.py` from StemNS

Build flags:

  - `make NCDNS_64BIT=1` — make a 64-bit build.
  - `make NCDNS_PRODVER=0.0.0.1` — set ncdns product version.
  - `make NO_NAMECOIN_CORE=1` — do not bundle Namecoin Core.
  - `make NO_ELECTRUM_NMC=1` — do not bundle Electrum-NMC.
  - `make NO_DNSSEC_TRIGGER=1` — do not bundle DNSSEC-Trigger.
  - `make NCDNS_LOGGING=1` — write install logs to `$INSTDIR\install.log`.  Requires NSIS to be built with `NSIS_CONFIG_LOG=yes`; this is supported by default on Fedora but not on Debian.

Install-time flags:

  - [All standard NSIS flags.](https://nsis.sourceforge.io/Docs/Chapter3.html#installerusage)
  - `/ETLD=org` — set up the TLS name constraints exclusion with a different eTLD from the default `bit`.  Only useful for debugging.

## Licence

ncdns-nsis is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ncdns-nsis is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ncdns-nsis.  If not, see [https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).
