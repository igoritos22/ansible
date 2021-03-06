module "az_virtual_machines" {
    source             = "git@github.com:igoritos22/terraformlabs//modules/az_virtual_machine"
    tag_projeto        = "iac_expert"
    az_group           = "iac_expert"
    vm_name            = ["iacnode1", "iacnode2", "iacnode3"]
    ip_allocation      = "Dynamic"
    nic_name           = "niciacexpert"
    allocation_method  = "Static"
    vm_size            = "Standard_B2ms"
    storage_name       = "stgiacexpertlab"
    account_tier       = "Standard"
    replication_type   = "LRS"
    publisher          = "Canonical"
    offer              = "UbuntuServer"
    sku                = "18.04-LTS"
    version_image      = "latest"
    admin_password     = "1aC3xp3rt99"
}

output "ip_instances" {
    value = module.az_virtual_machines.ips_internos
}

##plus

resource "local_file" "inventory" {
    filename = "./host"
    content     = <<_EOF
    [k8s-master]
    ${module.az_virtual_machines.ips_internos[0]}

    [k8s-workers]
    ${module.az_virtual_machines.ips_internos[1]}
    ${module.az_virtual_machines.ips_internos[2]}

    [k8s-workers:vars]
    K8S_MASTER_NODE_IP=${module.az_virtual_machines.ips_internos[0]}
    K8S_API_SECURE_PORT=6443
    _EOF
}