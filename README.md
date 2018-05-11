## Setup environment/PW
* source setup_environment.sh

## Validates newly created from template inventory! Failing in this task means you have forgot to change/uncomment some necessary variables. 
## This is a good practive step in order to avoid mistakes! 
* ansible-inventory -i inventory/Template --list 

## Ansible Commands Used
To call main(parent) create_limited_access_subnet.yml do:
* First do the Setup environment step. After that:
* ansible-playbook create_limited_access_subnet.yml --vault-password-file ./vault_pass.py -i inventory/Testnet/ -v
 
