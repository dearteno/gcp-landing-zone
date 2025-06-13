include {
  path = find_in_parent_folders("terragrunt.hcl")
}

dependency "networking" {
  config_path = "../networking"
}

dependency "security" {
  config_path = "../security"
}

dependency "compute" {
  config_path = "../compute"
}

inputs = {
  environment = "staging"
}