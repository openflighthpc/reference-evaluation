Flight silo has a type and repo

  $ flight silo repo list | grep " " | sed 's/│//g' | sed -e 's/\x1b\[[0-9;]*m//g'
   Name        Description                        Platform  Public? 
   openflight  Openflight software and resources  aws       true    

  $ flight silo type avail | grep " " | sed 's/│//g' | sed -e 's/\x1b\[[0-9;]*m//g'
   Name  Description                    Prepared 
   aws   Amazon Simple Storage Service  true     

