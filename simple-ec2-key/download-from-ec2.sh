rsync -avz -e \
    "ssh -i ~/.ssh/id_rsa" \
    rocky@1.1.1.1:/home/ec2-user/ocsinstall/ \
    ./ocsinstall
