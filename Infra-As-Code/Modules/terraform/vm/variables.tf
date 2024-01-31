# variables.tf

variable "virtual_machine_name" {
  description = "Name for the virtual machine"
  type        = string
}

variable "virtual_machine_image_os" {
  description = "Operating system image for the virtual machine"
  type        = string
}

variable "virtual_machine_subnet_id" {
  description = "ID of the subnet where the virtual machine should be placed"
  type        = string
}

variable "virtual_machine_location" {
  description = "Location/region where the virtual machine should be created"
  type        = string
}

variable "virtual_machine_resource_group_name" {
  description = "Name of the resource group where the virtual machine should be created"
  type        = string
}

variable "virtual_machine_size" {
  description = "Size of the virtual machine"
  type        = string
}

variable "zone" {
  description = "Defines the zone where the virtual machine is to be placed"
  type        = number
  default     = null
}

variable "allow_extension_operations" {
  description = "(Optional) Should Extension Operations be allowed on this Virtual Machine? Defaults to `false`."
  type        = bool
  default     = false
}

variable "virtual_machine_os_disk" {
  description = "Configuration for the OS disk"
  type = object({
    name                 = string
    caching              = string
    storage_account_type = string
  })
}

variable "source_image_reference" {
  description = "Reference to the source image for the virtual machine"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

variable "virtual_machine_admin_username" {
  description = "Admin username for the virtual machine"
  type        = string
}

variable "virtual_machine_admin_password" {
  description = "Admin password for the virtual machine"
  type        = string
  default     = null
}

variable "virtual_machine_disable_password_authentication" {
  description = "Disable password authentication for the virtual machine"
  type        = bool
  default     = null
}

variable "new_network_interface" {
  description = <<-EOT
  New Network Interface that should be created and attached to this Virtual Machine. Cannot be used along with `network_interface_ids`.
  name = "(Optional) The name of the Network Interface. Omit this name would generate one. Changing this forces a new resource to be created."
  ip_configurations = list(object({
    name                                               = "(Optional) A name used for this IP Configuration. Omit this name would generate one. Changing this forces a new resource to be created."
    private_ip_address                                 = "(Optional) The Static IP Address which should be used. When `private_ip_address_allocation` is set to `Static` this field can be configured."
    private_ip_address_version                         = "(Optional) The IP Version to use. Possible values are `IPv4` or `IPv6`. Defaults to `IPv4`."
    private_ip_address_allocation                      = "(Required) The allocation method used for the Private IP Address. Possible values are `Dynamic` and `Static`. Defaults to `Dynamic`."
    public_ip_address_id                               = "(Optional) Reference to a Public IP Address to associate with this NIC"
    primary                                            = "(Optional) Is this the Primary IP Configuration? Must be `true` for the first `ip_configuration`. Defaults to `false`."
    gateway_load_balancer_frontend_ip_configuration_id = "(Optional) The Frontend IP Configuration ID of a Gateway SKU Load Balancer."
  }))
  dns_servers                    = "(Optional) A list of IP Addresses defining the DNS Servers which should be used for this Network Interface. Configuring DNS Servers on the Network Interface will override the DNS Servers defined on the Virtual Network."
  edge_zone                      = "(Optional) Specifies the Edge Zone within the Azure Region where this Network Interface should exist. Changing this forces a new Network Interface to be created."
  accelerated_networking_enabled = "(Optional) Should Accelerated Networking be enabled? Defaults to `false`. Only certain Virtual Machine sizes are supported for Accelerated Networking - [more information can be found in this document](https://docs.microsoft.com/azure/virtual-network/create-vm-accelerated-networking-cli). To use Accelerated Networking in an Availability Set, the Availability Set must be deployed onto an Accelerated Networking enabled cluster."
  ip_forwarding_enabled          = "(Optional) Should IP Forwarding be enabled? Defaults to `false`."
  internal_dns_name_label        = "(Optional) The (relative) DNS Name used for internal communications between Virtual Machines in the same Virtual Network."
  EOT
  type = object({
    name = optional(string)
    ip_configurations = list(object({
      name                                               = optional(string)
      private_ip_address                                 = optional(string)
      private_ip_address_version                         = optional(string, "IPv4")
      private_ip_address_allocation                      = optional(string, "Dynamic")
      public_ip_address_id                               = optional(string)
      primary                                            = optional(bool, false)
      gateway_load_balancer_frontend_ip_configuration_id = optional(string)
    }))
    dns_servers                    = optional(list(string))
    edge_zone                      = optional(string)
    accelerated_networking_enabled = optional(bool, false)
    ip_forwarding_enabled          = optional(bool, false)
    internal_dns_name_label        = optional(string)
  })
  default = {
    name = null
    ip_configurations = [
      {
        name                                               = null
        private_ip_address                                 = null
        private_ip_address_version                         = null
        public_ip_address_id                               = null
        private_ip_address_allocation                      = null
        primary                                            = true
        gateway_load_balancer_frontend_ip_configuration_id = null
      }
    ]
    dns_servers                    = null
    edge_zone                      = null
    accelerated_networking_enabled = null
    ip_forwarding_enabled          = null
    internal_dns_name_label        = null
  }
}

variable "extensions" {
  description = "Argument to create `azurerm_virtual_machine_extension` resource, the argument descriptions could be found at [the document](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension)."
  type = set(object({
    name                        = string
    publisher                   = string
    type                        = string
    type_handler_version        = string
    auto_upgrade_minor_version  = optional(bool)
    automatic_upgrade_enabled   = optional(bool)
    failure_suppression_enabled = optional(bool, false)
    settings                    = optional(string)
    protected_settings          = optional(string)
    protected_settings_from_key_vault = optional(object({
      secret_url      = string
      source_vault_id = string
    }))
  }))
  # tflint-ignore: terraform_sensitive_variable_no_default
  default     = []
}

variable "tags" {
  description = "A map of the tags to use on the resources that are deployed with this module."
  type        = map(string)
}

