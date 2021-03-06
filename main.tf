
resource null_resource print_names {
  provisioner "local-exec" {
    command = "echo 'Resource group: ${var.resource_group_name}'"
  }
}

data "ibm_resource_group" "resource_group" {
  depends_on = [null_resource.print_names]

  name = var.resource_group_name
}

locals {
  name_prefix = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  name        = var.name != "" ? var.name : "${replace(local.name_prefix, "/[^a-zA-Z0-9_\\-\\.]/", "")}-tg-gateway"
  connection_name = "connection_instance-${random_string.random.result}"
}

resource "ibm_tg_gateway" "tg_gw_instance"{
  name           = local.name
  location       = var.region
  global         = true
  resource_group = data.ibm_resource_group.resource_group.id
  count = var.provision ? 1 : 0
}

data "ibm_tg_gateway" "instance" {
  depends_on = [ibm_tg_gateway.tg_gw_instance]
  
  name = local.name
}

resource "random_string" "random" {
  length           = 4
  special          = false
}

resource "ibm_tg_connection" "ibm_tg_connection_isntance"{
  count = length(var.connections)

  gateway = data.ibm_tg_gateway.instance.id
  network_type = "vpc"
  name= "${local.connection_name}-${count.index}"
  network_id = var.connections[count.index]
}



