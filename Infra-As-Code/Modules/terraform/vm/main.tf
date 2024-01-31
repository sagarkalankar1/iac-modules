# Virtual Machine module
# Module source: https://registry.terraform.io/modules/Azure/virtual-machine/azurerm/1.0.0

module "virtual_machine" {
  source  = "Azure/virtual-machine/azurerm"
  version = "1.0.0"

  # Module Input Variables
  name                       = var.virtual_machine_name
  image_os                   = var.virtual_machine_image_os
  subnet_id                  = var.virtual_machine_subnet_id
  location                   = var.virtual_machine_location
  resource_group_name        = var.virtual_machine_resource_group_name
  size                       = var.virtual_machine_size
  zone                       = var.zone
  allow_extension_operations = var.allow_extension_operations

  # OS Disk Configuration
  os_disk = {
    name                 = var.virtual_machine_os_disk.name
    caching              = var.virtual_machine_os_disk.caching
    storage_account_type = var.virtual_machine_os_disk.storage_account_type
  }

  # Source Image Reference
  source_image_reference = {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  # Authentication Configuration
  admin_username                  = var.virtual_machine_admin_username
  admin_password                  = var.virtual_machine_admin_password
  disable_password_authentication = var.virtual_machine_disable_password_authentication

  new_network_interface = {
    name                          = var.new_network_interface.name
    ip_configurations             = [
        for ip_config in var.new_network_interface.ip_configurations : {
            name                                               = ip_config.name
            private_ip_address                                 = ip_config.private_ip_address
            private_ip_address_version                         = ip_config.private_ip_address_version
            private_ip_address_allocation                      = ip_config.private_ip_address_allocation
            public_ip_address_id                               = ip_config.public_ip_address_id
            primary                                            = ip_config.primary
            gateway_load_balancer_frontend_ip_configuration_id = ip_config.gateway_load_balancer_frontend_ip_configuration_id
        }
    ]
    dns_servers                    = var.new_network_interface.dns_servers
    edge_zone                      = var.new_network_interface.edge_zone
    accelerated_networking_enabled = var.new_network_interface.accelerated_networking_enabled
    ip_forwarding_enabled          = var.new_network_interface.ip_forwarding_enabled
    internal_dns_name_label        = var.new_network_interface.internal_dns_name_label
}
  
  extensions = [
    for ext in var.extensions : {
      name                        = ext.name
      publisher                   = ext.publisher
      type                        = ext.type
      type_handler_version        = ext.type_handler_version
      auto_upgrade_minor_version  = ext.auto_upgrade_minor_version
      automatic_upgrade_enabled   = ext.automatic_upgrade_enabled
      failure_suppression_enabled = ext.failure_suppression_enabled
      settings                    = ext.settings
      protected_settings          = ext.protected_settings
      protected_settings_from_key_vault = ext.protected_settings_from_key_vault
    }
  ]

  tags = var.tags
}
  

