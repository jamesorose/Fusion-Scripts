#!/bin/bash
#openvpngenconf.sh

#------------------------------------------------------------------------------
#
# "THE WAF LICENSE" (version 1)
# This is the Wife Acceptance Factor (WAF) License.
# jamesdotfsatstubbornrosesd0tcom  wrote this file.  As long as you retain this
# notice you can do whatever you want with it. If you appreciate the work,
# please consider purchasing something from my wife's wishlist. That pays
# bigger dividends to this coder than anything else I can think of ;).  It also
# keeps her happy while she's being ignored; so I can work on this stuff.
#   James Rose
#
# latest wishlist: http://www.stubbornroses.com/waf.html
#
# Credit: Based off of the BEER-WARE LICENSE (REVISION 42) by Poul-Henning Kamp
#
#------------------------------------------------------------------------------

BuildDir="/var/centralconfig/openvpn"
TmpDir="/tmp/buildvpn/$3"
DateStamp="$(date +%Y%m%d_%H%M%S_%s)"

revokecert() {

	#add checks for $2

	cd /usr/share/easy-rsa
	source ./vars
	./revoke-full $2

	echo "REVOKED $2"

	mkdir -p $BuildDir/keys/REVOKED/$2-$DateStamp
	mkdir -p $BuildDir/client/REVOKED

	cd $BuildDir/keys
	
	mkdir -p $BuildDir/keys/revoked/$2-$DateStamp/
	mkdir -p $BuildDir/client/REVOKED/$2-$DateStamp

	mv $2.crt $2.csr $2.key $BuildDir/keys/revoked/$2-$DateStamp/

	mv $BuildDir/client/$2 $BuildDir/client/REVOKED/$2-$DateStamp

	echo "OLD CERTS ARE STORKED AT: $BuildDir/keys/REVOKED/$2-$DateStamp/"
	echo "old build directory stored at $BuildDir/client/REVOKED/$2-$DateStamp/"


	echo "figure out telnet here to immediately revoke"
	
telnet localhost 7505 <<DELIM
kill $2
exit
DELIM



}

buildconf() {

	#add checks for $2 and $3

mkdir -p $TmpDir/keys


#see if the files exist first
if [ -e $BuildDir/keys/$3.crt ]; then
	echo
	echo "The keys for $3 already exist. Skipping key generation"
	echo "  If you want to rebuild the keys, then revoke the clinet $3 first"
	echo "  run: openvpngenconf.sh revoke $3"
	echo
	echo "now we will back up the existing configs"
	cd $BuildDir/client/$3
	tar -czvf $3-$DateStamp.tar.gz *.ovpn openvpn.tar vpn.cnf
	rm *.ovpn openvpn.tar vpn.cnf

else
	cd /usr/share/easy-rsa
	source ./vars
	#./build-key $3
	#./build-dh
	export EASY_RSA="${EASY_RSA:-.}"
	"$EASY_RSA/pkitool" --batch $3
fi

#cd $BuildDir
#mkdir -p client/$3/keys
#cp $BuildDir/keys/ca.crt $BuildDir/client/$3/keys/
cp $BuildDir/keys/ca.crt $TmpDir/keys/ca.crt
cp $BuildDir/keys/$3.crt $TmpDir/keys/client.crt
cp $BuildDir/keys/$3.key $TmpDir/keys/client.key

#cp $BuildDir/keys/$3.crt $BuildDir/client/$3/keys/client.crt

#cp $BuildDir/keys/$3.key $BuildDir/client/$3/keys/client.key



#cat > $BuildDir/client/$3/vpn.cnf <<DELIM
cat > $TmpDir/vpn.cnf <<DELIM
client
dev tun
dev-type tun
proto udp
remote $2 1194
setenv SERVER_Poll_TIMEOUT 4
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
comp-lzo
verb 3
DELIM


echo "cat done"
	
#build inline certificate	
		#cp $BuildDir/client/$3/vpn.cnf $TmpDir/"$2"-"$3".ovpn

mkdir -p $BuildDir/client/$3

cp $TmpDir/vpn.cnf $BuildDir/client/$3/"$2"-"$3".ovpn

echo "<ca>" >> $BuildDir/client/$3/"$2"-"$3".ovpn
cat $TmpDir/keys/ca.crt >> $BuildDir/client/$3/"$2"-"$3".ovpn
echo "</ca>" >> $BuildDir/client/$3/"$2"-"$3".ovpn

echo "<cert>" >> $BuildDir/client/$3/"$2"-"$3".ovpn
cat $TmpDir/keys/client.crt >> $BuildDir/client/$3/"$2"-"$3".ovpn
echo "</cert>" >> $BuildDir/client/$3/"$2"-"$3".ovpn

echo "<key>" >> $BuildDir/client/$3/"$2"-"$3".ovpn
cat $TmpDir/keys/client.key >> $BuildDir/client/$3/"$2"-"$3".ovpn
echo "</key>" >> $BuildDir/client/$3/"$2"-"$3".ovpn

todos $BuildDir/client/$3/"$2"-"$3".ovpn

echo "ovpn done"
		
		#echo "<ca>" >> $TmpDir/"$2"-"$3".ovpn
		#cat ./keys/ca.crt >> $TmpDir/"$2"-"$3".ovpn
		#echo "</ca>" >> $TmpDir/"$2"-"$3".ovpn
		
		#echo "<cert>" >> $TmpDir/"$2"-"$3".ovpn
		#cat ./keys/$3.crt >> $TmpDir/"$2"-"$3".ovpn
		#echo "</cert>" >> $TmpDir/"$2"-"$3".ovpn
		
		#echo "<key>" >> $TmpDir/"$2"-"$3".ovpn
		#cat ./keys/$3.key >> $TmpDir/"$2"-"$3".ovpn
		#echo "</key>" >> $TmpDir/"$2"-"$3".ovpn
		
		#todos $TmpDir/$2-$3.ovpn



#build yealink zip

	echo "ca /config/openvpn/keys/ca.crt" >> $TmpDir/vpn.cnf
	echo "cert /config/openvpn/keys/client.crt" >> $TmpDir/vpn.cnf
	echo "key /config/openvpn/keys/client.key" >> $TmpDir/vpn.cnf

	cd $TmpDir
	echo "creating the Yealink Tar File"
	tar -cvpf openvpn.tar *
	echo "--tar done"

	mv $TmpDir/vpn.cnf $BuildDir/client/$3/
	mv $TmpDir/openvpn.tar $BuildDir/client/$3/

	#mv $TmpDir/$2-$3.ovpn $BuildDir/client/$3/

	rm -r $TmpDir

	echo "DONE"
	echo " filename is: $BuildDir/client/$3/$2-$3.ovpn"
	echo "              $BuildDir/client/$3/openvpn.tar"
	
}

echo $1
echo $2
echo $3
case $1 in 
	build)
		buildconf $1 $2 $3
	;;

	revoke)
		revokecert $1 $2
	;;

	*)
		echo; echo
		echo "     USAGE: openvpngenconf.sh build|revoke OPTIONS"
		echo "     ---------------------------------------------"
		echo
	        echo "          build options:"
		echo "          	vpn_server_address client-name"
		echo "                  it's recommended to set client-name = phone_mac_address"
		echo "             Build Example:"
		echo "                  openvpngenconf.sh build vpn.example.com 805ab09d345f"
		echo "                     yields a config file for yealink named $BuildDir/client/805ab09d345f/openvpn.tar"
		echo "                        AND"
		echo "                     yields a config file with certs inline named $BuildDir/client/805ab09d345f/vpn.example.com-805ab09d345f.ovpn"
		echo; echo
		echo "         revoke options:"
		echo "                  client-name"
		echo "              Revoke Example:"
		echo "                   openvpngenconf.sh revoke Client1"
		echo "                      This will update the csr.pem file for the server and block the client from connecting."
		echo "                      The old certificates will be moved out of the way so that you can re-generate them"
		echo "                      if you need to. Have a look in $BuildDir/keys/revoked/"
		echo; echo
	;;
esac
