# Prompt the user for confirmation
read -p "Are you sure you want to continue? (y/n) " -n 1 -r

# Move to a new line for better readability after the input
echo

# Check the user input
if [[ "$REPLY" =~ ^[Yy]$ ]]
then
    echo "Continuing with the script..."
    # Place the rest of your script here
else
    echo "Operation canceled. Exiting."
    exit 1
fi

rm -fr .terraform/ .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup 
