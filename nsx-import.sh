#!/bin/bash

QT='"'
LIST=network.list

for LINE in `cat $LIST`

do

T1GW=`echo $LINE | cut -f1 -d","`
SEG=`echo $LINE | cut -f2 -d","`
DFGW=`echo $LINE | cut -f3 -d","`
MASK=`echo $LINE | cut -f4 -d","`

T1VAL=`ls | grep $T1GW.tf`

if [ -z $T1VAL ];

then

cat > $T1GW.tf << EOL
resource "nsxt_policy_tier1_gateway" $QT$T1GW$QT {
  display_name              = $QT$T1GW$QT
  description               = $QT Tier1 $T1GW provisioned by Terraform$QT
  edge_cluster_path         = data.nsxt_policy_edge_cluster.demo.path
  failover_mode             = "PREEMPTIVE"
  default_rule_logging      = "false"
  enable_firewall           = "true"
  enable_standby_relocation = "false"
  tier0_path                = data.nsxt_policy_tier0_gateway.t0_gateway.path
  route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]
}
EOL

fi

cat > $SEG.tf << EOL
resource "nsxt_policy_segment" $QT$SEG$QT {
  display_name        = $QT$SEG$QT
  description         = $QT Terraform provisioned $SEG $QT
  connectivity_path   = nsxt_policy_tier1_gateway.$T1GW.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path
  subnet {
    cidr        = $QT$DFGW/$MASK$QT
  }
}
EOL

done

terraform plan

echo "Do you want to proceed with the object import?"
echo ""
read -p "(Y/N)" -n 1 -r  CHOICE
echo ""
if [[ $CHOICE =~ ^[Yy]$ ]];

then

terraform apply -auto-approve

else

echo "Saving tf files for review no changes in the NSX configuration"

fi
