variable "credentials" {
  default = {
    linode = {
      token = "<token>"
    }
  }
}

variable "settings" {
  default = {
    cluster = {
      namespace  = "<namespace>"
      identifier = "<identifier>"
    }
  }
}