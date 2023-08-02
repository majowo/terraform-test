/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  subnets = {
    for x in var.subnets :
    "${x.subnet_region}/${x.subnet_name}" => x
  }
}


/******************************************
	Subnet configuration
 *****************************************/
resource "google_compute_subnetwork" "subnetwork" {
  provider                 = google-beta
  for_each                 = local.subnets
  name                     = each.value.subnet_name
  ip_cidr_range            = each.value.subnet_ip
  region                   = each.value.subnet_region
  private_ip_google_access = each.value.subnet_private_access
  dynamic "log_config" {
    for_each = coalesce(each.value.subnet_flow_logs, false) ? [{
      aggregation_interval = each.value.subnet_flow_logs_interval
      flow_sampling        = each.value.subnet_flow_logs_sampling
      metadata             = each.value.subnet_flow_logs_metadata
      filter_expr          = each.value.subnet_flow_logs_filter
      metadata_fields      = each.value.subnet_flow_logs_metadata_fields
    }] : []
    content {
      aggregation_interval = log_config.value.aggregation_interval
      flow_sampling        = log_config.value.flow_sampling
      metadata             = log_config.value.metadata
      filter_expr          = log_config.value.filter_expr
      metadata_fields      = log_config.value.metadata_fields
    }
  }
  network     = var.network_name
  project     = var.project_id
  description = each.value.description
  secondary_ip_range = [
    for i in range(
      length(
        contains(
        keys(var.secondary_ranges), each.value.subnet_name) == true
        ? var.secondary_ranges[each.value.subnet_name]
        : []
    )) :
    var.secondary_ranges[each.value.subnet_name][i]
  ]

  purpose          = each.value.purpose
  role             = each.value.role
  stack_type       = each.value.stack
  ipv6_access_type = each.value.ipv6_type

  depends_on = [var.module_depends_on]
}
