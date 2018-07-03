job("full-recreate-subnet") {
    authorization {
        permissions('admin', [
            'hudson.model.Item.Build',
            'hudson.model.Item.Cancel',
            'hudson.model.Item.Configure',
            'hudson.model.Item.Delete',
            'hudson.model.Item.Discover',
            'hudson.model.Item.Read',
            'hudson.model.Item.Workspace',
            'hudson.model.Run.Delete',
            'hudson.model.Run.Update',
            'hudson.scm.SCM.Tag'
        ])

    }

    scm {
        cloneWorkspace("cloneSources", "Any")
    }

    steps {
        shell '''export VAULT_PASSWORD=${VAULT_PASSWORD} 
ansible-playbook tasks/generate_current_subnet_state_inventory.yml --vault-password-file ./vault_pass.py -i inventory --extra-vars "state=current force_variable_check=True" --extra-vars "@inventory/enforce_value_vars.yml" ansible-playbook tasks/manage_subnet_machines.yml --vault-password-file ./vault_pass.py -i inventory --extra-vars "state=stopped host=CurrentSubnetHostsLocalhost proxmox_node=CurrentSubnetHosts force_variable_check=True" --extra-vars "@inventory/enforce_value_vars.yml"
ansible-playbook tasks/manage_subnet_machines.yml --vault-password-file ./vault_pass.py -i inventory --extra-vars "state=absent  host=CurrentSubnetHostsLocalhost proxmox_node=CurrentSubnetHosts force_variable_check=True" --extra-vars "@inventory/enforce_value_vars.yml"
ansible-playbook tasks/recreate_subnet_vms.yml --vault-password-file ./vault_pass.py -i inventory --extra-vars "force_variable_check=True" --extra-vars "@inventory/enforce_value_vars.yml"
        '''
    }
}

job("guest-build-inventory") {
    authorization {
        permissions('admin', [
            'hudson.model.Item.Build',
            'hudson.model.Item.Cancel',
            'hudson.model.Item.Configure',
            'hudson.model.Item.Delete',
            'hudson.model.Item.Discover',
            'hudson.model.Item.Read',
            'hudson.model.Item.Workspace',
            'hudson.model.Run.Delete',
            'hudson.model.Run.Update',
            'hudson.scm.SCM.Tag'
        ])

        permissions('anonymous', [
            'hudson.model.Item.Build',
            'hudson.model.Item.Cancel',
            'hudson.model.Item.Read'
        ])
    }

    steps {
        shell '''# "-------------------------Please put/copy your inventory definition inside the double brackets ------------------------------"

INVENTORY_VALUE="

[InternalUserVMsGroup:children]

ActiveChestFlowerViolenceVM
StupidRejoiceClassDressVM

[ActiveChestFlowerViolenceVM]
activeChestFlowerViolenceVM
[ActiveChestFlowerViolenceVM:vars]
vmid=6004
new_machine_name=VM1
template_vmid=6011
ansible_host=10.5.202.19
full_clone=no

[StupidRejoiceClassDressVM]
stupidRejoiceClassDressVM
[StupidRejoiceClassDressVM:vars]
vmid=6005
new_machine_name=VM6
template_vmid=6011
ansible_host=10.5.202.20
full_clone=no"

# "-------------------------Please put/copy your inventory definition above------------------------------"
echo "$INVENTORY_VALUE" > /var/lib/jenkins/infrastructure-github/inventory/user_subnet_vms
'''
    }
}

job("manage-all-subnet-machines") {
    parameters {
        activeChoiceParam('vm_state') {
            choiceType('SINGLE_SELECT')
            groovyScript {
                script("return ['started', 'absent', 'stopped', 'restarted', 'current']")
            }
        }
    }
  
    authorization {
        permissions('admin', [
            'hudson.model.Item.Build',
            'hudson.model.Item.Cancel',
            'hudson.model.Item.Configure',
            'hudson.model.Item.Delete',
            'hudson.model.Item.Discover',
            'hudson.model.Item.Read',
            'hudson.model.Item.Workspace',
            'hudson.model.Run.Delete',
            'hudson.model.Run.Update',
            'hudson.scm.SCM.Tag'
        ])

        permissions('anonymous', [
            'hudson.model.Item.Build',
            'hudson.model.Item.Cancel',
            'hudson.model.Item.Read'
        ])
    }

    scm {
        cloneWorkspace('cloneSources', criteria = 'Any')
    }
  
    steps {
        shell '''export VAULT_PASSWORD=${VAULT_PASSWORD}
ansible-playbook tasks/generate_current_subnet_state_inventory.yml --vault-password-file ./vault_pass.py -i inventory --extra-vars "state=current force_variable_check=True" --extra-vars "@inventory/enforce_value_vars.yml"
ansible-playbook tasks/manage_subnet_machines.yml --vault-password-file ./vault_pass.py -i inventory --extra-vars "state=stopped host=CurrentSubnetHostsLocalhost proxmox_node=CurrentSubnetHosts force_variable_check=True" --extra-vars "@inventory/enforce_value_vars.yml"
ansible-playbook tasks/manage_subnet_machines.yml --vault-password-file ./vault_pass.py -i inventory --extra-vars "state=absent  host=CurrentSubnetHostsLocalhost proxmox_node=CurrentSubnetHosts force_variable_check=True" --extra-vars "@inventory/enforce_value_vars.yml"
ansible-playbook tasks/recreate_subnet_vms.yml --vault-password-file ./vault_pass.py -i inventory --extra-vars "force_variable_check=True" --extra-vars "@inventory/enforce_value_vars.yml"
        '''
    }
}

job("manage-single-subnet-machine") {
    authorization {
        permissions('admin', [
            'hudson.model.Item.Build',
            'hudson.model.Item.Cancel',
            'hudson.model.Item.Configure',
            'hudson.model.Item.Delete',
            'hudson.model.Item.Discover',
            'hudson.model.Item.Read',
            'hudson.model.Item.Workspace',
            'hudson.model.Run.Delete',
            'hudson.model.Run.Update',
            'hudson.scm.SCM.Tag'
        ])

        permissions('anonymous', [
            'hudson.model.Item.Build',
            'hudson.model.Item.Cancel',
            'hudson.model.Item.Read'
        ])
    }

    scm {
        cloneWorkspace('cloneSources', criteria = 'Any')
    }

    parameters {
        activeChoiceParam('vm_state') {
            choiceType('SINGLE_SELECT')
            groovyScript {
                script("return ['started', 'absent', 'stopped', 'restarted', 'current']")
            }
        }
        stringParam ('vmid', '', 'the vmid of the machine you want to put in specific state')
    }      
    
    steps {
        shell '''export VAULT_PASSWORD=${VAULT_PASSWORD}
ansible-playbook tasks/manage_subnet_machines.yml --vault-password-file ./vault_pass.py -i inventory -vvv --extra-vars "@inventory/enforce_value_vars.yml" --extra-vars "host=localhostInternalSubnet proxmox_node=proxmoxNodeInternalPrivileges state=${vm_state} vmid=${vmid} force_variable_check=True"
        '''
    }
}
