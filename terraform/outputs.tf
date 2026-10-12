output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "app_sg_id" {
  value = aws_security_group.app.id
}

output "ci_sg_id" {
  value = aws_security_group.ci.id
}

output "key_pair_name" {
  value = aws_key_pair.main.key_name
}

output "ci_public_ip" {
  value = aws_instance.ci.public_ip
}

output "app_public_ip" {
  value = aws_instance.app.public_ip
}
