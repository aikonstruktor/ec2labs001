terraform init
terraform validate
terraform apply -auto-approve

# terraform apply \
#   -var ami_id=ami-xxxxxxxx \
#   -var laptop_ip=YOUR.IP.ADDRESS/32 \
#   -auto-approve
