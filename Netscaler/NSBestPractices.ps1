#Netscaler Information
$script:username = "nsroot"
$script:password = "nsroot"
$script:nsip = "192.168.1.50"

##PowerShell 5 PSGallery modules needed
#find-module netscaler
#install-module netscaler

#Connect to the Netscaler and create session variable
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($Username,$SecurePassword)
$script:Session = Connect-NetScaler -Hostname $nsip -Passthru -Credential $Credential

#Global HTTP Settings (CTX121149)
$payload = ConvertTo-Json @{
	"nshttpparam" = @{
		"dropinvalreqs" = "on";
	}
}
Invoke-RestMethod -Uri ("$($session.Uri)/config/nshttpparam") -Method Put -WebSession $session.WebSession -ContentType "application/json" -Body $payload

$payload = ConvertTo-Json @{
	"nsparam" = @{
		"cookieversion" = "1";
	}
}
Invoke-RestMethod -Uri ("$($session.Uri)/config/nsparam") -Method Put -WebSession $session.WebSession -ContentType "application/json" -Body $payload

#MODES (CTX121149)
#Modes to enable
@("fr","usnip","l3","pmtud") | ForEach-Object {
	Invoke-RestMethod -Uri ("$($session.Uri)/config/nsmode?action=enable") -Method POST -WebSession $session.WebSession -ContentType "application/json" -Body (ConvertTo-Json @{
			"nsmode" = @{
				"mode" = $_;
			}
		})
}

#Modes to disable
@("l2","usip","cka","tcpb","sradv","dradv","iradv","sradv6","dradv6","bridgebpdus") | ForEach-Object {
	Invoke-RestMethod -Uri ("$($session.Uri)/config/nsmode?action=disable") -Method POST -WebSession $session.WebSession -ContentType "application/json" -Body (ConvertTo-Json @{
			"nsmode" = @{
				"mode" = $_;
			}
		})
}


#TCPProfile CTX232321
$payload = ConvertTo-Json @{
	"nstcpprofile" = @{
		"name" = "nstcp_default_profile";
		"nagle" = "ENABLED";
		"flavor" = "BIC";
		"sack" = "ENABLED";
		"ws" = "ENABLED";
		"wsval" = "8";
		"minrto" = "600";
		"buffersize" = "600000";
		"sendbuffsize" = "600000";
	}
}
Invoke-RestMethod -Uri ("$($session.Uri)/config/nstcpprofile") -Method Put -WebSession $session.WebSession -ContentType "application/json" -Body $payload

#Disable External Authentication for NSROOT
$payload = ConvertTo-Json @{
	"systemuser" = @{
		"username" = "nsroot";
		"externalauth" = "DISABLED";
	}
}
Invoke-RestMethod -Uri ("$($session.Uri)/config/systemuser") -Method Put -WebSession $session.WebSession -ContentType "application/json" -Body $payload


#Save and logoff
Save-NSConfig -Session $session
Disconnect-NetScaler -Session $session

