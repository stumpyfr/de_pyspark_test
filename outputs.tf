output "candidate_emails" {
  value = azuread_user.candidate_names[*].user_principal_name
}

output "password" {
  sensitive = true
  value     = random_password.password.result
}
