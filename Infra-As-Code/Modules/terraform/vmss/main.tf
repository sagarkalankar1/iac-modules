locals {
  is_linux   = var.os_flavor == "linux"
  is_windows = var.os_flavor == "windows"
}

# Null Resource
# This is utilized to generalize a Virtual Machine, enabling the generation of an image from it.
resource "null_resource" "generalize_vm" {
  count = var.source_image_id == null ? 1 : 0
  
  triggers = {
    vm_id = var.virtual_machine_id
  }
  provisioner "local-exec" {
    command = "az vm deallocate --resource-group ${var.vm_resource_group_name} --name ${var.virtual_machine_name}"
  }
  provisioner "local-exec" {
    command = "az vm generalize --resource-group ${var.vm_resource_group_name} --name ${var.virtual_machine_name}"
  }
}

# Virtual Machine Image
# https://registry.terraform.io/providers/hashicorp/azurerm/3.78.0/docs/resources/image
resource "azurerm_image" "vm_image" {
  count = var.source_image_id == null ? 1 : 0

  name                      = var.vm_image_name
  location                  = var.vm_image_location
  resource_group_name       = var.vm_image_resource_group_name
  source_virtual_machine_id = var.vm_image_source_virtual_machine_id

  # Dynamic "os_disk" block
  dynamic "os_disk" {
    for_each = var.vm_image_os_disk != null ? [1] : []
    content {
      os_type                = var.vm_image_os_disk.os_type
      os_state               = var.vm_image_os_disk.os_state
      managed_disk_id        = var.vm_image_os_disk.managed_disk_id
      blob_uri               = var.vm_image_os_disk.blob_uri
      caching                = var.vm_image_os_disk.caching
      size_gb                = var.vm_image_os_disk.size_gb
      disk_encryption_set_id = var.vm_image_os_disk.disk_encryption_set_id
    }
  }

  # Dynamic "data_disk" block
  dynamic "data_disk" {
    for_each = var.vm_image_data_disk != null ? [1] : []
    content {
      lun             = var.vm_image_data_disk.lun
      managed_disk_id = var.vm_image_data_disk.managed_disk_id
      blob_uri        = var.vm_image_data_disk.blob_uri
      caching         = var.vm_image_data_disk.caching
      size_gb         = var.vm_image_data_disk.size_gb
    }
  }

  tags               = var.vm_image_tags
  zone_resilient     = var.vm_image_zone_resilient
  hyper_v_generation = var.vm_image_hyper_v_generation

  depends_on = [null_resource.generalize_vm]
}

# Linux Virual-Machine Scale Set
# https://registry.terraform.io/providers/hashicorp/azurerm/3.78.0/docs/resources/linux_virtual_machine_scale_set

resource "azurerm_linux_virtual_machine_scale_set" "linux_virtual_machine_scale_set_basic" {
  count = local.is_linux ? 1 : 0

  name                = var.virtual_machine_scale_set_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.vm_sku
  admin_username      = var.admin_username
  instances           = var.instance_count
  admin_password      = var.admin_password
  source_image_id     = var.source_image_id != null ? var.source_image_id : azurerm_image.vm_image[0].id

  # Dynamic "source_image_reference" block
  dynamic "source_image_reference" {
    for_each = var.source_image_reference != null ? [1] : []
    content {
      publisher = var.source_image_reference.publisher
      offer     = var.source_image_reference.offer
      sku       = var.source_image_reference.sku
      version   = var.source_image_reference.version
    }
  }

  # Dynamic "network_interface" block
  dynamic "network_interface" {
    for_each = var.network_interface != null ? [1] : []
    content {
      name    = var.network_interface.name
      primary = var.network_interface.primary
      ip_configuration {
        name                                         = var.network_interface.ip_configuration.name
        application_gateway_backend_address_pool_ids = var.network_interface.ip_configuration.application_gateway_backend_address_pool_ids
        application_security_group_ids               = var.network_interface.ip_configuration.application_security_group_ids
        load_balancer_backend_address_pool_ids       = var.network_interface.ip_configuration.load_balancer_backend_address_pool_ids
        load_balancer_inbound_nat_rules_ids          = var.network_interface.ip_configuration.load_balancer_inbound_nat_rules_ids
        primary                                      = var.network_interface.ip_configuration.primary
        dynamic "public_ip_address" {
          for_each = var.network_interface.ip_configuration.public_ip_address != null ? [1] : []
          content {
            name                    = var.network_interface.ip_configuration.public_ip_address.name
            domain_name_label       = var.network_interface.ip_configuration.public_ip_address.domain_name_label
            idle_timeout_in_minutes = var.network_interface.ip_configuration.public_ip_address.idle_timeout_in_minutes
            dynamic "ip_tag" {
              for_each = var.network_interface.ip_configuration.public_ip_address.ip_tag != null ? [1] : []
              content {
                tag  = var.network_interface.ip_configuration.public_ip_address.ip_tag.tag
                type = var.network_interface.ip_configuration.public_ip_address.ip_tag.type
              }
            }
            public_ip_prefix_id = var.network_interface.ip_configuration.public_ip_address.public_ip_prefix_id
            version             = var.network_interface.ip_configuration.public_ip_address.version
          }
        }
        subnet_id = var.network_interface.ip_configuration.subnet_id
        version   = var.network_interface.ip_configuration.version
      }
      dns_servers                   = var.network_interface.dns_servers
      enable_accelerated_networking = var.network_interface.enable_accelerated_networking
      enable_ip_forwarding          = var.network_interface.enable_ip_forwarding
      network_security_group_id     = var.network_interface.network_security_group_id
    }
  }

  # "os_disk" block
  os_disk {
    storage_account_type = var.os_disk.storage_account_type
    caching              = var.os_disk.caching
    dynamic "diff_disk_settings" {
      for_each = var.os_disk.diff_disk_settings != null ? [1] : []
      content {
        option    = var.os_disk.diff_disk_settings.option
        placement = var.os_disk.diff_disk_settings.placement
      }
    }
    disk_encryption_set_id           = var.os_disk.disk_encryption_set_id
    disk_size_gb                     = var.os_disk.disk_size_gb
    secure_vm_disk_encryption_set_id = var.os_disk.secure_vm_disk_encryption_set_id
    security_encryption_type         = var.os_disk.security_encryption_type
    write_accelerator_enabled        = var.os_disk.write_accelerator_enabled
  }

  # Dynamic "additional_capabilities" block
  dynamic "additional_capabilities" {
    for_each = var.additional_capabilities != null ? [1] : []
    content {
      ultra_ssd_enabled = var.additional_capabilities.ultra_ssd_enabled
    }
  }

  # Dynamic "automatic_os_upgrade_policy" block
  dynamic "automatic_os_upgrade_policy" {
    for_each = var.automatic_os_upgrade_policy != null ? [1] : []
    content {
      disable_automatic_rollback  = var.automatic_os_upgrade_policy.disable_automatic_rollback
      enable_automatic_os_upgrade = var.automatic_os_upgrade_policy.enable_automatic_os_upgrade
    }
  }

  # Dynamic "boot_diagnostics" block
  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics != null ? [1] : []
    content {
      storage_account_uri = var.boot_diagnostics.storage_account_uri
    }
  }

  capacity_reservation_group_id = var.capacity_reservation_group_id
  computer_name_prefix          = var.computer_name_prefix
  custom_data                   = var.custom_data

  # Dynamic "data_disk" block
  dynamic "data_disk" {
    for_each = var.data_disk != null ? [1] : []
    content {
      name                           = var.data_disk.name
      caching                        = var.data_disk.caching
      create_option                  = var.data_disk.create_option
      disk_size_gb                   = var.data_disk.disk_size_gb
      lun                            = var.data_disk.lun
      storage_account_type           = var.data_disk.storage_account_type
      disk_encryption_set_id         = var.data_disk.disk_encryption_set_id
      ultra_ssd_disk_iops_read_write = var.data_disk.ultra_ssd_disk_iops_read_write
      ultra_ssd_disk_mbps_read_write = var.data_disk.ultra_ssd_disk_mbps_read_write
      write_accelerator_enabled      = var.data_disk.write_accelerator_enabled
    }
  }

  disable_password_authentication                   = var.disable_password_authentication
  do_not_run_extensions_on_overprovisioned_machines = var.do_not_run_extensions_on_overprovisioned_machines
  edge_zone                                         = var.edge_zone
  encryption_at_host_enabled                        = var.encryption_at_host_enabled

  # Dynamic "extension" block
  dynamic "extension" {
    for_each = var.extension != null ? var.extension : []

    content {
      name                       = try(extension.value.name, null)
      publisher                  = try(extension.value.publisher, null)
      type                       = try(extension.value.type, null)
      type_handler_version       = try(extension.value.type_handler_version, null)
      auto_upgrade_minor_version = try(extension.value.auto_upgrade_minor_version, null)
      automatic_upgrade_enabled  = try(extension.value.automatic_upgrade_enabled, null)
      force_update_tag           = try(extension.value.force_update_tag, null)
      protected_settings         = can(extension.value.protected_settings) ? extension.value.protected_settings : null
      dynamic "protected_settings_from_key_vault" {
        for_each = extension.value.protected_settings_from_key_vault != null ? [1] : []
        content {
          secret_url      = try(extension.value.protected_settings_from_key_vault.secret_url, null)
          source_vault_id = try(extension.value.protected_settings_from_key_vault.source_vault_id, null)
        }
      }
      provision_after_extensions = can(extension.value.provision_after_extensions) ? extension.value.provision_after_extensions : null
      settings                   = can(extension.value.settings) ? extension.value.settings : null
    }
  }

  extension_operations_enabled = var.extension_operations_enabled
  extensions_time_budget       = var.extensions_time_budget
  eviction_policy              = var.eviction_policy

  # Dynamic "gallery_application" block
  dynamic "gallery_application" {
    for_each = var.gallery_application != null ? [1] : []
    content {
      version_id             = var.gallery_application.version_id
      configuration_blob_uri = var.gallery_application.configuration_blob_uri
      order                  = var.gallery_application.order
      tag                    = var.gallery_application.tag
    }
  }

  health_probe_id = var.health_probe_id
  host_group_id   = var.host_group_id

  # Dynamic "identity" block
  dynamic "identity" {
    for_each = var.identity != null ? [1] : []
    content {
      type         = var.identity.type
      identity_ids = var.identity.identity_ids
    }
  }

  max_bid_price = var.max_bid_price
  overprovision = var.overprovision

  # Dynamic "plan" block
  dynamic "plan" {
    for_each = var.plan != null ? [1] : []
    content {
      name      = var.plan.name
      publisher = var.plan.publisher
      product   = var.plan.product
    }
  }

  platform_fault_domain_count  = var.platform_fault_domain_count
  priority                     = var.priority
  provision_vm_agent           = var.provision_vm_agent
  proximity_placement_group_id = var.proximity_placement_group_id

  # Dynamic "rolling_upgrade_policy" block
  dynamic "rolling_upgrade_policy" {
    for_each = var.rolling_upgrade_policy != null ? [1] : []
    content {
      cross_zone_upgrades_enabled             = var.rolling_upgrade_policy.cross_zone_upgrades_enabled
      max_batch_instance_percent              = var.rolling_upgrade_policy.max_batch_instance_percent
      max_unhealthy_instance_percent          = var.rolling_upgrade_policy.max_unhealthy_instance_percent
      max_unhealthy_upgraded_instance_percent = var.rolling_upgrade_policy.max_unhealthy_upgraded_instance_percent
      pause_time_between_batches              = var.rolling_upgrade_policy.pause_time_between_batches
      prioritize_unhealthy_instances_enabled  = var.rolling_upgrade_policy.prioritize_unhealthy_instances_enabled
    }
  }

  # Dynamic "scale_in" block
  dynamic "scale_in" {
    for_each = var.scale_in != null ? [1] : []
    content {
      rule                   = var.scale_in.rule
      force_deletion_enabled = var.scale_in.force_deletion_enabled
    }
  }

  # Dynamic "secret" block
  dynamic "secret" {
    for_each = var.secret != null ? [1] : []
    content {
      certificate {
        url = var.secret.certificate.url
      }
      key_vault_id = var.secret.key_vault_id
    }
  }

  secure_boot_enabled    = var.secure_boot_enabled
  single_placement_group = var.single_placement_group

  # Dynamic "spot_restore" block
  dynamic "spot_restore" {
    for_each = var.spot_restore != null ? [1] : []
    content {
      enabled = var.spot_restore.enabled
      timeout = var.spot_restore.timeout
    }
  }

  tags = var.tags

  # Dynamic "terminate_notification" block
  dynamic "terminate_notification" {
    for_each = var.terminate_notification != null ? [1] : []
    content {
      enabled = var.terminate_notification.enabled
      timeout = var.terminate_notification.timeout
    }
  }

  upgrade_mode = var.upgrade_mode
  user_data    = var.user_data
  vtpm_enabled = var.vtpm_enabled
  zone_balance = var.zone_balance
  zones        = var.zones

  depends_on = [azurerm_image.vm_image]
}

# Windows Virual-Machine Scale Set
# https://registry.terraform.io/providers/hashicorp/azurerm/3.78.0/docs/resources/windows_virtual_machine_scale_set
resource "azurerm_windows_virtual_machine_scale_set" "windows_virtual_machine_scale_set_basic" {
  count = local.is_windows ? 1 : 0

  name                = var.virtual_machine_scale_set_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.vm_sku
  admin_username      = var.admin_username
  instances           = var.instance_count
  admin_password      = var.admin_password
  source_image_id     = var.source_image_id != null ? var.source_image_id : azurerm_image.vm_image[0].id

  # Dynamic "source_image_reference" block
  dynamic "source_image_reference" {
    for_each = var.source_image_reference.publisher != null ? [1] : []
    content {
      publisher = var.source_image_reference.publisher
      offer     = var.source_image_reference.offer
      sku       = var.source_image_reference.sku
      version   = var.source_image_reference.version
    }
  }

  # Dynamic "network_interface" block
  dynamic "network_interface" {
    for_each = var.network_interface != null ? [1] : []
    content {
      name    = var.network_interface.name
      primary = var.network_interface.primary
      ip_configuration {
        name                                         = var.network_interface.ip_configuration.name
        application_gateway_backend_address_pool_ids = var.network_interface.ip_configuration.application_gateway_backend_address_pool_ids
        application_security_group_ids               = var.network_interface.ip_configuration.application_security_group_ids
        load_balancer_backend_address_pool_ids       = var.network_interface.ip_configuration.load_balancer_backend_address_pool_ids
        load_balancer_inbound_nat_rules_ids          = var.network_interface.ip_configuration.load_balancer_inbound_nat_rules_ids
        primary                                      = var.network_interface.ip_configuration.primary
        dynamic "public_ip_address" {
          for_each = var.network_interface.ip_configuration.public_ip_address != null ? [1] : []
          content {
            name                    = var.network_interface.ip_configuration.public_ip_address.name
            domain_name_label       = var.network_interface.ip_configuration.public_ip_address.domain_name_label
            idle_timeout_in_minutes = var.network_interface.ip_configuration.public_ip_address.idle_timeout_in_minutes
            dynamic "ip_tag" {
              for_each = var.network_interface.ip_configuration.public_ip_address.ip_tag != null ? [1] : []
              content {
                tag  = var.network_interface.ip_configuration.public_ip_address.ip_tag.tag
                type = var.network_interface.ip_configuration.public_ip_address.ip_tag.type
              }
            }
            public_ip_prefix_id = var.network_interface.ip_configuration.public_ip_address.public_ip_prefix_id
            version             = var.network_interface.ip_configuration.public_ip_address.version
          }
        }
        subnet_id = var.network_interface.ip_configuration.subnet_id
        version   = var.network_interface.ip_configuration.version
      }
      dns_servers                   = var.network_interface.dns_servers
      enable_accelerated_networking = var.network_interface.enable_accelerated_networking
      enable_ip_forwarding          = var.network_interface.enable_ip_forwarding
      network_security_group_id     = var.network_interface.network_security_group_id
    }
  }

  # "os_disk" block
  os_disk {
    storage_account_type = var.os_disk.storage_account_type
    caching              = var.os_disk.caching
    dynamic "diff_disk_settings" {
      for_each = var.os_disk.diff_disk_settings != null ? [1] : []
      content {
        option    = var.os_disk.diff_disk_settings.option
        placement = var.os_disk.diff_disk_settings.placement
      }
    }
    disk_encryption_set_id           = var.os_disk.disk_encryption_set_id
    disk_size_gb                     = var.os_disk.disk_size_gb
    secure_vm_disk_encryption_set_id = var.os_disk.secure_vm_disk_encryption_set_id
    security_encryption_type         = var.os_disk.security_encryption_type
    write_accelerator_enabled        = var.os_disk.write_accelerator_enabled
  }

  # Dynamic "additional_capabilities" block
  dynamic "additional_capabilities" {
    for_each = var.additional_capabilities != null ? [1] : []
    content {
      ultra_ssd_enabled = var.additional_capabilities.ultra_ssd_enabled
    }
  }

  # Dynamic "automatic_os_upgrade_policy" block
  dynamic "automatic_os_upgrade_policy" {
    for_each = var.automatic_os_upgrade_policy != null ? [1] : []
    content {
      disable_automatic_rollback  = var.automatic_os_upgrade_policy.disable_automatic_rollback
      enable_automatic_os_upgrade = var.automatic_os_upgrade_policy.enable_automatic_os_upgrade
    }
  }

  # Dynamic "boot_diagnostics" block
  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics != null ? [1] : []
    content {
      storage_account_uri = var.boot_diagnostics.storage_account_uri
    }
  }

  capacity_reservation_group_id = var.capacity_reservation_group_id
  computer_name_prefix          = var.computer_name_prefix
  custom_data                   = var.custom_data

  # Dynamic "data_disk" block
  dynamic "data_disk" {
    for_each = var.data_disk != null ? [1] : []
    content {
      name                           = var.data_disk.name
      caching                        = var.data_disk.caching
      create_option                  = var.data_disk.create_option
      disk_size_gb                   = var.data_disk.disk_size_gb
      lun                            = var.data_disk.lun
      storage_account_type           = var.data_disk.storage_account_type
      disk_encryption_set_id         = var.data_disk.disk_encryption_set_id
      ultra_ssd_disk_iops_read_write = var.data_disk.ultra_ssd_disk_iops_read_write
      ultra_ssd_disk_mbps_read_write = var.data_disk.ultra_ssd_disk_mbps_read_write
      write_accelerator_enabled      = var.data_disk.write_accelerator_enabled
    }
  }

  do_not_run_extensions_on_overprovisioned_machines = var.do_not_run_extensions_on_overprovisioned_machines
  edge_zone                                         = var.edge_zone
  encryption_at_host_enabled                        = var.encryption_at_host_enabled

  # Dynamic "extension" block
  dynamic "extension" {
    for_each = var.extension != null ? var.extension : []
    content {
      name                       = try(extension.value.name, null)
      publisher                  = try(extension.value.publisher, null)
      type                       = try(extension.value.type, null)
      type_handler_version       = try(extension.value.type_handler_version, null)
      auto_upgrade_minor_version = try(extension.value.auto_upgrade_minor_version, null)
      automatic_upgrade_enabled  = try(extension.value.automatic_upgrade_enabled, null)
      force_update_tag           = try(extension.value.force_update_tag, null)
      protected_settings         = can(extension.value.protected_settings) ? extension.value.protected_settings : null
      dynamic "protected_settings_from_key_vault" {
        for_each = extension.value.protected_settings_from_key_vault != null ? [1] : []
        content {
          secret_url      = try(extension.value.protected_settings_from_key_vault.secret_url, null)
          source_vault_id = try(extension.value.protected_settings_from_key_vault.source_vault_id, null)
        }
      }
      provision_after_extensions = can(extension.value.provision_after_extensions) ? extension.value.provision_after_extensions : null
      settings                   = can(extension.value.settings) ? extension.value.settings : null
    }
  }

  extension_operations_enabled = var.extension_operations_enabled
  extensions_time_budget       = var.extensions_time_budget
  eviction_policy              = var.eviction_policy

  # Dynamic "gallery_application" block
  dynamic "gallery_application" {
    for_each = var.gallery_application != null ? [1] : []
    content {
      version_id             = var.gallery_application.version_id
      configuration_blob_uri = var.gallery_application.configuration_blob_uri
      order                  = var.gallery_application.order
      tag                    = var.gallery_application.tag
    }
  }

  health_probe_id = var.health_probe_id
  host_group_id   = var.host_group_id

  # Dynamic "identity" block
  dynamic "identity" {
    for_each = var.identity != null ? [1] : []
    content {
      type         = var.identity.type
      identity_ids = var.identity.identity_ids
    }
  }

  max_bid_price = var.max_bid_price
  overprovision = var.overprovision

  # Dynamic "plan" block
  dynamic "plan" {
    for_each = var.plan != null ? [1] : []
    content {
      name      = var.plan.name
      publisher = var.plan.publisher
      product   = var.plan.product
    }
  }

  platform_fault_domain_count  = var.platform_fault_domain_count
  priority                     = var.priority
  provision_vm_agent           = var.provision_vm_agent
  proximity_placement_group_id = var.proximity_placement_group_id

  # Dynamic "rolling_upgrade_policy" block
  dynamic "rolling_upgrade_policy" {
    for_each = var.rolling_upgrade_policy != null ? [1] : []
    content {
      cross_zone_upgrades_enabled             = var.rolling_upgrade_policy.cross_zone_upgrades_enabled
      max_batch_instance_percent              = var.rolling_upgrade_policy.max_batch_instance_percent
      max_unhealthy_instance_percent          = var.rolling_upgrade_policy.max_unhealthy_instance_percent
      max_unhealthy_upgraded_instance_percent = var.rolling_upgrade_policy.max_unhealthy_upgraded_instance_percent
      pause_time_between_batches              = var.rolling_upgrade_policy.pause_time_between_batches
      prioritize_unhealthy_instances_enabled  = var.rolling_upgrade_policy.prioritize_unhealthy_instances_enabled
    }
  }

  # Dynamic "scale_in" block
  dynamic "scale_in" {
    for_each = var.scale_in != null ? [1] : []
    content {
      rule                   = var.scale_in.rule
      force_deletion_enabled = var.scale_in.force_deletion_enabled
    }
  }

  # Dynamic "secret" block
  dynamic "secret" {
    for_each = var.secret != null ? [1] : []
    content {
      certificate {
        url   = var.secret.certificate.url
        store = var.secret.certificate.store
      }
      key_vault_id = var.secret.key_vault_id
    }
  }

  secure_boot_enabled    = var.secure_boot_enabled
  single_placement_group = var.single_placement_group

  # Dynamic "spot_restore" block
  dynamic "spot_restore" {
    for_each = var.spot_restore != null ? [1] : []
    content {
      enabled = var.spot_restore.enabled
      timeout = var.spot_restore.timeout
    }
  }

  tags = var.tags

  # Dynamic "terminate_notification" block
  dynamic "terminate_notification" {
    for_each = var.terminate_notification != null ? [1] : []
    content {
      enabled = var.terminate_notification.enabled
      timeout = var.terminate_notification.timeout
    }
  }

  dynamic "additional_unattend_content" {
    for_each = var.additional_unattend_content != null ? [1] : []
    content {
      content = var.additional_unattend_content.content
      setting = var.additional_unattend_content.setting
    }
  }

  dynamic "automatic_instance_repair" {
    for_each = var.automatic_instance_repair != null ? [1] : []
    content {
      enabled      = var.automatic_instance_repair.enabled
      grace_period = var.automatic_instance_repair.grace_period
    }
  }

  dynamic "winrm_listener" {
    for_each = var.winrm_listener != null ? [1] : []
    content {
      certificate_url = var.winrm_listener.certificate_url
      protocol        = var.winrm_listener.protocol
    }
  }

  timezone                 = var.timezone
  enable_automatic_updates = var.enable_automatic_updates
  license_type             = var.license_type
  upgrade_mode             = var.upgrade_mode
  user_data                = var.user_data
  vtpm_enabled             = var.vtpm_enabled
  zone_balance             = var.zone_balance
  zones                    = var.zones

  depends_on = [azurerm_image.vm_image]
}