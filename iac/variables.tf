variable "credentials" {
  default = {
    linode = {
      identifier = "<identifier>"
      token      = "<token>"
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