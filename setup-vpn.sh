#!/bin/bash
# Ensure that you are already signed into AWS (i.e. CLI works) before running

cd ~
git clone https://github.com/OpenVPN/easy-rsa.git
cd easy-rsa/easyrsa3
./easyrsa init-pki
EASYRSA_BATCH=1 ./easyrsa build-ca nopass
./easyrsa build-server-full server nopass
./easyrsa build-client-full client1.domain.tld nopass
mkdir ~/eksvpn/
cp pki/ca.crt ~/eksvpn/
cp pki/issued/server.crt ~/eksvpn/
cp pki/private/server.key ~/eksvpn/
cp pki/issued/client1.domain.tld.crt ~/eksvpn
cp pki/private/client1.domain.tld.key ~/eksvpn/
cd ~/eksvpn/
echo "Server Certificate Import"
aws acm import-certificate --certificate fileb://server.crt --private-key fileb://server.key --certificate-chain fileb://ca.crt
echo "Client Certificate Import"
aws acm import-certificate --certificate fileb://client1.domain.tld.crt --private-key fileb://client1.domain.tld.key --certificate-chain fileb://ca.crt