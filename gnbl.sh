#!/bin/bash
# GTAXLnet DNSBL Script
# Utilizes DNSimple's API to add and remove IPs from a DNSBL.
# Dependency: jq, curl
# gnbl.sh
# Victor Coss gtaxl@gtaxl.net
# Version: 1.00 AUG/19/2020

regIP=$2.
revIP=$(printf %s "$regIP" | tac -s. | sed 's/\.$//')

TOKEN=""                # The API v2 OAuth token
ACCOUNT_ID=""           # Replace with your account ID
ZONE_ID="bl.gtaxl.net"  # The zone ID is the name of the zone (or domain)
DNSSERVER=162.159.24.4  # It is recommended to keep this to an authorative nameserver of the DNSBL to avoid caching, etc.
TTL=1800				# Default TTL in seconds to set on new records, we recommend 1800 aka 30 minutes, use lower such as 60 when debugging/sandbox

case "$1" in
	add)
		check=$(host $revIP.$ZONE_ID $DNSSERVER | grep "NXDOMAIN")
		if [ -z "$check" ]
		then
			echo -e "[0;31mThat IP is already listed or there was a problem looking it up.[0m"
		else
			echo -e "[0;33mNot listed. Adding record $revIP.$ZONE_ID to the database...[0m"
			result=$(curl -s -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "Accept: application/json" -X "POST" -i "https://api.dnsimple.com/v2/$ACCOUNT_ID/zones/$ZONE_ID/records" -d "{\"name\":\"$revIP\",\"type\":\"A\",\"content\":\"127.0.0.2\",\"ttl\":$TTL}" | grep "HTTP/2 201")
			if [ -z "$result" ]
			then
				echo -e "[0;31mFailed to add IP to database![0m"
			else
				if [ -z "$3" ]
				then
					echo -e "[0;32mSuccessfully added IP to the database.[0m"
				else
					reason=${@:3}
					echo -e "[0;32mSuccessfully added the IP to the database.[0m"
					result2=$(curl -s -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "Accept: application/json" -X "POST" -i "https://api.dnsimple.com/v2/$ACCOUNT_ID/zones/$ZONE_ID/records" -d "{\"name\":\"$revIP\",\"type\":\"TXT\",\"content\":\"$reason\",\"ttl\":$TTL}" | grep "HTTP/2 201")
					if [ -z "$result2" ]
					then
						echo -e "[0;31mFailed to add the reason to database![0m"
					else
						echo -e "[0;32mSuccessfully added the reason to the database.[0m"
					fi
				fi
			fi
		fi
        ;;
         
    del|delete|remove)
        check=$(host $revIP.$ZONE_ID $DNSSERVER | grep "NXDOMAIN")
		if [ -z "$check" ]
		then
			checka=$(curl -s -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" "https://api.dnsimple.com/v2/$ACCOUNT_ID/zones/$ZONE_ID/records?name=$revIP&type=A")
			respa=$(echo $checka | grep "zone_id")
			if [ -z "$respa" ]
			then
				echo -e "[0;31mFailed to fetch the record id from the API. Double check the IP is listed or try again later.[0m"
			else
				fetchid=$(echo $checka | jq -r '{"data"}[] | .[0] | .id')
				result=$(curl -s -i -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" -H "Content-Type: application/json" -X DELETE https://api.dnsimple.com/v2/$ACCOUNT_ID/zones/$ZONE_ID/records/$fetchid | grep "HTTP/2 204")
				if [ -z "$result" ]
				then
					echo -e "[0;31mFailed to remove the IP from the database.[0m"
				else
					echo -e "[0;32mSuccessfully removed the IP from the database.[0m"
					checktxt=$(curl -s -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" "https://api.dnsimple.com/v2/$ACCOUNT_ID/zones/$ZONE_ID/records?name=$revIP&type=TXT")
					resptxt=$(echo $checktxt | grep "zone_id")
					if [ -z "$resptxt" ]
					then
						exit
					else
						fetchid2=$(echo $checktxt | jq -r '{"data"}[] | .[0] | .id')
						result2=$(curl -s -i -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" -H "Content-Type: application/json" -X DELETE https://api.dnsimple.com/v2/$ACCOUNT_ID/zones/$ZONE_ID/records/$fetchid2 | grep "HTTP/2 204")
						if [ -z "$result2" ]
						then
							echo -e "[0;31mFailed to remove the reason from the database.[0m"
						else
							echo -e "[0;32mSuccessfully removed the reason from the database.[0m"
						fi
					fi
				fi
			fi
		else
			echo -e "[0;31mThat IP address is not in the database or failed to look up. $revIP.$ZONE_ID[0m"
		fi
        ;;
         
    chk|check)
        check=$(host $revIP.$ZONE_ID $DNSSERVER | grep "127.0.0.2")
		if [ -z "$check" ]
		then
			echo -e "[0;31mNot listed or failed to lookup![0m"
		else
			echo -e "[0;35mListed in DNS: [0;32mYES[0m"
			checka=$(curl -s -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" "https://api.dnsimple.com/v2/$ACCOUNT_ID/zones/$ZONE_ID/records?name=$revIP&type=A")
			respa=$(echo $checka | grep "zone_id")
			if [ -z "$respa" ]
			then
				echo -e "[0;35mListed in API: [0;31mNO[0m"
			else
				fetchid=$(echo $checka | jq -r '{"data"}[] | .[0] | .id')
				fetchttl=$(echo $checka | jq -r '{"data"}[] | .[0] | .ttl')
				fetchdate=$(echo $checka | jq -r '{"data"}[] | .[0] | .created_at')
				echo -e "[0;35mListed in API: [0;32mYES, TTL: $fetchttl ID: $fetchid[0m"
				echo -e "[0;35mDate Listed: [0;32m$fetchdate[0m"
				checktxt=$(curl -s -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" "https://api.dnsimple.com/v2/$ACCOUNT_ID/zones/$ZONE_ID/records?name=$revIP&type=TXT")
				resptxt=$(echo $checktxt | grep "zone_id")
				if [ -z "$resptxt" ]
				then
					echo -e "[0;35mReason: [0;31mNo reason in the system.[0m"
				else
					fetchid2=$(echo $checktxt | jq -r '{"data"}[] | .[0] | .id')
					fetchreason=$(echo $checktxt | jq -r '{"data"}[] | .[0] | .content')
					fetchttl2=$(echo $checktxt | jq -r '{"data"}[] | .[0] | .ttl')
					echo -e "[0;35mReason: [0;32m$fetchreason, TTL: $fetchttl2 ID: $fetchid2[0m"
				fi
			fi
		fi
        ;;

    *)
        echo "  ---Syntax--- "
		echo "./gnbl.sh add IP reason"
		echo "./gnbl.sh del IP"
		echo "./gnbl.sh chk IP"
        exit 1
 
esac
