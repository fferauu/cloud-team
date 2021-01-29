variable "project_id" {
  type        = string
  description = "Project ID"
  default     = null
}

variable "region_default" {
  type        = string
  description = "Default region to deploy resources"
  default     = null
}

variable "zone_default" {
  type        = string
  description = "value"
  default     = null
}

variable "vpc_name" {
  type        = string
  description = "Name of VPC"
  default     = null
}

variable "pub_ip" {
  type        = string
  description = "Public IP allowed to make ssh connetions to jh"
  default     = null
}