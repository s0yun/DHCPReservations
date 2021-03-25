function NewDHCPReservation {
#Collect Scope, IP address and Mac Address. 
$scopeid = Read-Host -Prompt 'Please enter the scope name you wish to add a reservation to.'
$reservationIP = Read-Host -Prompt 'Please enter the IP Address you wish to assign.'
$clientmac = Read-Host -Prompt 'Please enter the Mac Address of Client.'
$description = Read-Host -Prompt 'Please give a brief discription of the reservation'
#Change the format to something that windows likes
$clientmac = $clientmac -replace ":", "-"
#Add to the reservation scope
Add-DhcpServerv4Reservation -ScopeId $scopeid -IPAddress $reservationIP -ClientId $clientmac -Description $description
}
