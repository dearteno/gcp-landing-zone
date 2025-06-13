include {
  path = find_in_parent_folders("terragrunt.hcl")
}

dependency "networking" {
  config_path = "../networking"
}

inputs = {
  security_policy = "dev-security-policy"
  enable_logging  = true
}