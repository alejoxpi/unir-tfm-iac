variable "resource_group_name" {
    type = string    
    default = ""
}

variable "location" {
    type = string
    default = ""
}

variable "default_tags" {    
    type = map(string)
    default = {}
}

variable "ai_name" { 
    type = string
    default = ""
}

variable "ai_application_type" { 
    type = string
    default = ""
}

variable "ai_retention_in_days" { 
    type = number
    default = 30
}