/testing/guestbin/swan-prep --x509
ipsec start
/testing/pluto/bin/wait-until-pluto-started
ipsec whack --debug-all --impair-retransmits
echo "initdone"
