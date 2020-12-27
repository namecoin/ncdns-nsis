@echo off
rem Pull the latest AuthRoot.stl from Windows Update servers, and preload the
rem certs into the CryptoAPI cert store.  This is a prerequisite to applying
rem system-wide name constraints via certinject.

certutil -v -f -verifyCTL AuthRootWU
