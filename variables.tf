variable "jenkins_version" {
  type        = string
  nullable    = false
  default     = "lts-jdk17"
  description = "Version of Jenkins to deploy"
}

variable "memory" {
  type        = number
  default     = 256
  nullable    = false
  description = "Amount of memory to require"
}

variable "vcpu" {
  type        = number
  default     = 0.25
  nullable    = false
  description = "Amount of vCPU to allocate to the container"
}

variable "log_group" {
  type        = string
  nullable    = false
  default     = "services/jenkins"
  description = "CloudWatch log group name"
}

variable "efs_file_system_name" {
  type        = string
  description = "Name of EFS file system to use for Nexus storage"
}

variable "load_balancers" {
  type = list(object({
    name          = string
    short_name    = optional(string)
    dns_zone      = string
    dns_subdomain = string
    priority      = optional(number)
    vpc           = string
  }))
  nullable    = false
  default     = []
  description = "List of load balancer names to add Jenkins to"
}

variable "ecs_cluster" {
  type        = string
  nullable    = false
  description = "Name of the ECS cluster to deploy in"
}
