# A tunnel should have established with non-zero byte counters
ping -n -c 4 192.1.2.23
# jacob two two for east?
hostname | grep nic > /dev/null || ipsec whack --trafficstatus
hostname | grep nic > /dev/null || ipsec whack --trafficstatus
../../pluto/bin/ipsec-look.sh | sed "s/\(.\)port [0-9][0-9][0-9][0-9] /\1port XXXX /g"
# you should see both RSA and NULL
grep -e IKEv2_AUTH_ -e ': Authenticated using ' /tmp/pluto.log 
: ==== cut ====
ipsec auto --status
: ==== tuc ====
../bin/check-for-core.sh
if [ -f /sbin/ausearch ]; then ausearch -r -m avc -ts recent ; fi
: ==== end ====
