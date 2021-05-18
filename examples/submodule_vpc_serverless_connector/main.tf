/**
 * Copyright 2021 Google LLC
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

provider "google" {
  version = "~> 3.62"
}

provider "google-beta" {
  version = "~> 3.62"
}

module "test-vpc-module" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 3.2.0"
  project_id   = var.project_id # Replace this with your project ID in quotes
  network_name = "my-serverless-network"
  mtu          = 1460

  subnets = [
    {
      subnet_name   = "serverless-subnet"
      subnet_ip     = "10.10.10.0/28"
      subnet_region = "us-central1"
    }
  ]
}

module "serverless-connector" {
  source     = "../../modules/vpc-serverless-connector-beta"
  project_id = var.project_id
  vpc_connectors = [{
    name   = "central-serverless"
    region = "us-central1"
    # Uncomment network & ip_cidr_range then set subnet_name = null to leverage ip_cidr_range
    # network       = module.test-vpc-module.network_name
    # ip_cidr_range = "10.10.11.0/28"
    subnet_name = module.test-vpc-module.subnets["us-central1/serverless-subnet"].name
    # host_project_id = var.host_project_id # Leverage host_project_id if using a shared VPC
    machine_type  = "e2-standard-4"
    min_instances = 2
    max_instances = 7
  }]
}
