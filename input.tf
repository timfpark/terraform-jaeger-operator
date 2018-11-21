variable "name" {
  default = "jaeger"
}

variable "namespace" {
  default = "default"
}

variable "elasticsearch_client_endpoint" {
  type = "string"
}
