/testing/guestbin/swan-prep --x509
ipsec setup start
/testing/pluto/bin/wait-until-pluto-started
ipsec auto --add road-eastnet-ikev1
echo "initdone"
