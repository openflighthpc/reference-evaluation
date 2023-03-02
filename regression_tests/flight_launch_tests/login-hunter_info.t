Check that hunter buffer holds info on all the nodes we want to find

  > for ip in "${nodeips[@]}" 
  > do echo "$ip"
  > flight hunter list | grep "$ip"
  > done
