variable "virtual_machine_scale_set_name" {
  description = "The name of the Linux Virtual Machine Scale Set"
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "The name of the Azure resource group"
  type        = string
  default     = null
}

variable "location" {
  description = "The Azure region where the virtual machine scale set will be created"
  type        = string
  default     = null
}

variable "vm_sku" {
  description = "The SKU (size) of the virtual machines in the scale set"
  type        = string
  default     = null
}

variable "admin_username" {
  description = "The administrator username for the virtual machines"
  type        = string
  default     = null
}

variable "instance_count" {
  description = "The number of virtual machine instances in the scale set. Default to zero"
  type        = number
  default     = null
}

variable "admin_password" {
  description = "The administrator password for the virtual machines (optional)"
  type        = string
  sensitive   = true
  default     = null
}

variable "capacity_reservation_group_id" {
  description = "The ID of the capacity reservation group"
  type        = string
  default     = null
}

variable "computer_name_prefix" {
  description = "The prefix for the computer names of virtual machines"
  type        = string
  default     = null
}

variable "custom_data" {
  description = "Custom data for virtual machine."
  type        = string
  default     = null
}

variable "disable_password_authentication" {
  description = "Disable password authentication for VM instances"
  type        = bool
  default     = true
}

variable "do_not_run_extensions_on_overprovisioned_machines" {
  description = "Do not run extensions on overprovisioned machines"
  type        = bool
  default     = false
}

variable "edge_zone" {
  description = "The edge zone where the virtual machine scale set will be created"
  type        = string
  default     = null
}

variable "encryption_at_host_enabled" {
  description = "Enable encryption at host for VM instances"
  type        = bool
  default     = false
}

variable "source_image_reference" {
  description = "Configuration for the source_image_reference block in the Azure virtual machine"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default     = null
}

variable "network_interface" {
  description = "Configuration for the network_interface block in the Azure virtual machine"
  type = object({
    name    = string
    primary = optional(bool)
    ip_configuration = object({
      name                                         = string
      application_gateway_backend_address_pool_ids = optional(list(string))
      application_security_group_ids               = optional(list(string))
      load_balancer_backend_address_pool_ids       = optional(list(string))
      load_balancer_inbound_nat_rules_ids          = optional(list(string))
      primary                                      = optional(bool)
      public_ip_address = optional(object({
        name                    = optional(string)
        domain_name_label       = optional(string)
        idle_timeout_in_minutes = optional(number)
        ip_tag                  = optional(string)
        public_ip_prefix_id     = optional(string)
        version                 = optional(string)
      }))
      subnet_id = optional(string)
      version   = optional(string)
    })
    dns_servers                   = optional(list(string))
    enable_accelerated_networking = optional(bool)
    enable_ip_forwarding          = optional(bool)
    network_security_group_id     = optional(string)
  })
  default     = null
}

variable "os_disk" {
  description = "Configuration for the os_disk block in the Azure virtual machine"
  type = object({
    storage_account_type = string
    caching              = string
    diff_disk_settings = optional(object({
      option    = string
      placement = string
    }))
    disk_encryption_set_id           = optional(string)
    disk_size_gb                     = optional(number)
    secure_vm_disk_encryption_set_id = optional(string)
    security_encryption_type         = optional(string)
    write_accelerator_enabled        = optional(bool)
  })
  default     = null
}

variable "additional_capabilities" {
  description = "Configuration for the additional_capabilities block in the Azure virtual machine"
  type = object({
    ultra_ssd_enabled = optional(bool)
  })
  default     = null
}

variable "automatic_os_upgrade_policy" {
  description = "Configuration for the automatic_os_upgrade_policy block in the Azure virtual machine"
  type = object({
    disable_automatic_rollback  = bool
    enable_automatic_os_upgrade = bool
  })
  default     = null
}

variable "boot_diagnostics" {
  description = "Configuration for the boot_diagnostics block in the Azure virtual machine"
  type = object({
    storage_account_uri = optional(string)
  })
  default     = null
}

variable "data_disk" {
  description = "Configuration for the data_disk block in the Azure virtual machine"
  type = object({
    name                           = optional(string)
    caching                        = string
    create_option                  = optional(string)
    disk_size_gb                   = number
    lun                            = number
    storage_account_type           = string
    disk_encryption_set_id         = optional(string)
    ultra_ssd_disk_iops_read_write = optional(number)
    ultra_ssd_disk_mbps_read_write = optional(number)
    write_accelerator_enabled      = optional(bool)
  })
  default     = null
}

variable "extension" {
  description = "Configuration for the extension block in the Azure virtual machine"
  type = list(object({
    name                       = string
    publisher                  = string
    type                       = string
    type_handler_version       = string
    auto_upgrade_minor_version = bool
    automatic_upgrade_enabled  = optional(bool)
    force_update_tag           = optional(string)
    protected_settings         = optional(string)
    protected_settings_from_key_vault = optional(object({
      secret_url      = string
      source_vault_id = string
    }))
    provision_after_extensions = optional(list(string))
    settings                   = optional(string)
  }))
  default     = null
}

variable "identity" {
  description = "Configuration for the identity block in the Azure virtual machine"
  type = object({
    type         = string
    identity_ids = optional(list(string))
  })
  default     = null
}

variable "plan" {
  description = "Configuration for the plan block in the Azure virtual machine"
  type = object({
    name      = string
    publisher = string
    product   = string
  })
  default     = null
}

variable "scale_in" {
  description = "Configuration for the scale_in block in the Azure virtual machine"
  type = object({
    rule                   = optional(string)
    force_deletion_enabled = optional(bool)
  })
  default     = null
}

variable "secret" {
  description = "Configuration for the secret block in the Azure virtual machine"
  type = object({
    certificate = object({
      url   = string
      store = string
    })
    key_vault_id = string
  })
  default     = null
}

variable "extension_operations_enabled" {
  description = "Enable extension operations"
  type        = bool
  default     = true
}

variable "extensions_time_budget" {
  description = "The time budget for extensions"
  type        = string
  default     = null
}

variable "eviction_policy" {
  description = "The eviction policy for VM instances"
  type        = string
  default     = null
}

variable "gallery_application" {
  description = "Gallery application configuration"
  type = object({
    version_id             = string
    configuration_blob_uri = optional(string)
    order                  = optional(number)
    tag                    = optional(string)
  })
  default = null
}

variable "health_probe_id" {
  description = "The ID of the health probe"
  type        = string
  default     = null
}

variable "host_group_id" {
  description = "The ID of the host group"
  type        = string
  default     = null
}

variable "max_bid_price" {
  description = "The maximum bid price for spot instances"
  type        = number
  default     = null
}

variable "overprovision" {
  description = "Enable overprovisioning of VM instances"
  type        = bool
  default     = false
}

variable "platform_fault_domain_count" {
  description = "The number of fault domains for the virtual machine scale set"
  type        = number
  default     = null
}

variable "priority" {
  description = "The priority of the virtual machine scale set"
  type        = string
  default     = null
}

variable "provision_vm_agent" {
  description = "Provision the VM agent on VM instances"
  type        = bool
  default     = null
}

variable "proximity_placement_group_id" {
  description = "The ID of the proximity placement group"
  type        = string
  default     = null
}

variable "rolling_upgrade_policy" {
  description = "Rolling upgrade policy configuration"
  type = object({
    cross_zone_upgrades_enabled             = optional(bool)
    max_batch_instance_percent              = number
    max_unhealthy_instance_percent          = number
    max_unhealthy_upgraded_instance_percent = number
    pause_time_between_batches              = string
    prioritize_unhealthy_instances_enabled  = optional(bool)
  })
  default = null
}

variable "secure_boot_enabled" {
  description = "Enable secure boot for VM instances"
  type        = bool
  default     = false
}

variable "single_placement_group" {
  description = "Enable single placement group for VM instances"
  type        = bool
  default     = false
}

variable "source_image_id" {
  description = "The ID of the source image"
  type        = string
  default     = null
}

variable "spot_restore" {
  description = "Spot restore configuration"
  type = object({
    enabled = optional(bool)
    timeout = optional(string)
  })
  default = null
}

variable "terminate_notification" {
  description = "terminate_notification configuration"
  type = object({
    enabled = bool
    timeout = optional(string)
  })
  default = null
}

variable "tags" {
  description = "Tags to apply to the virtual machine scale set"
  type        = map(string)
  default     = null
}

variable "upgrade_mode" {
  description = "The upgrade mode for the virtual machine scale set"
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data for VM instances"
  type        = string
  default     = null
}

variable "vtpm_enabled" {
  description = "Enable virtual trusted platform module (vTPM) for VM instances"
  type        = bool
  default     = null
}

variable "zone_balance" {
  description = "Enable zone balancing for VM instances"
  default     = null
}

variable "zones" {
  description = "The availability zones for the virtual machine scale set"
  type        = list(string)
  default     = null
}

# Variable for OS flavor for VMSS
variable "os_flavor" {
  description = "Specify the flavour of the operating system image to deploy VMSS. Valid values are `windows` and `linux`"
  default     = ""
}

# Variables for VM Imgage
variable "vm_image_name" {
  description = "Name of the Azure VM image"
  type        = string
  default     = null
}

variable "vm_image_location" {
  description = "Location where the image will be created"
  type        = string
  default     = null
}

variable "vm_image_resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = null
}

variable "vm_image_source_virtual_machine_id" {
  description = "ID of the source virtual machine"
  type        = string
  default     = null
}

variable "vm_image_os_disk" {
  description = "Configuration for the OS disk"
  type = object({
    os_type                = optional(string)
    os_state               = optional(string)
    managed_disk_id        = optional(string)
    blob_uri               = optional(string)
    caching                = optional(string)
    size_gb                = optional(number)
    disk_encryption_set_id = optional(string)
  })
  default = null
}

variable "vm_image_data_disk" {
  description = "Configuration for data disks"
  type = object({
    lun             = optional(number)
    managed_disk_id = optional(string)
    blob_uri        = optional(string)
    caching         = optional(string)
    size_gb         = optional(number)
  })
  default = null
}

variable "vm_image_tags" {
  description = "Tags to associate with the VM image"
  type        = map(string)
  default     = null
}

variable "vm_image_zone_resilient" {
  description = "Is the VM image zone resilient?"
  type        = bool
  default     = null
}

variable "vm_image_hyper_v_generation" {
  description = "Hyper-V generation of the VM image"
  type        = string
  default     = null
}

# Null Resource Variables
variable "virtual_machine_id" {
  description = "The ID of the virtual machine to deallocate and generalize"
  type        = string
  default     = null
}

variable "vm_resource_group_name" {
  description = "Name of the resource group where the virtual machine is located"
  type        = string
  default     = null
}

variable "virtual_machine_name" {
  description = "Name of the virtual machine to deallocate and generalize"
  type        = string
  default     = null
}

variable "additional_unattend_content" {
  description = "Additional unattend content configuration"
  type = object({
    content = string
    setting = string
  })
  default = null
}

variable "automatic_instance_repair" {
  description = "Automatic instance repair configuration"
  type = object({
    enabled      = bool
    grace_period = optional(number)
  })
  default = null
}

variable "winrm_listener" {
  description = "WinRM listener configuration"
  type = object({
    certificate_url = optional(string)
    protocol        = string
  })
  default = null
}

variable "timezone" {
  description = "Timezone configuration"
  type        = string
  default     = null
}

variable "enable_automatic_updates" {
  description = "Enable automatic updates"
  type        = bool
  default     = null
}

variable "license_type" {
  description = "License type"
  type        = string
  default     = null
}
