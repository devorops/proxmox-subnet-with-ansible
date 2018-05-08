## Setup environment/PW
* source setup_environment.sh

## Validates newly created from template inventory! Should be executed over every new inventory/every new subnet that we are about to create. The passed inventory will be the one that you have manually changed the necessary host/group variables to make the inventory right for the new subnet. Fail from this task means you have forgot to change/uncomment some necessary variables, so you need to go and do it. This is a good practive step in order to avoid mistakes!
* ansible-inventory -i inventory/Template --list 

## Ansible Commands Used
To call create_vm_from_template.yml on its own do: 
* ansible-playbook create_vm_from_template.yml --vault-password-file ./vault_pass.py -i inventory

To call on its own do:
* ansible-playbook  createSubnetUserAndSetPrivileges.yml --vault-password-file .././vault_pass.py -i SOME_INVENTORY_FILE(you need to create it)

To call main(parent) create_limited_access_subnet.yml do:
* ansible-playbook create_limited_access_subnet.yml --vault-password-file ./vault_pass.py -i inventory/Testnet 
