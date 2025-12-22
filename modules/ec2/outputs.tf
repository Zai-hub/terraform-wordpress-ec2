output "public_ip" {
  value = aws_instance.this.public_ip
}

output "public_dns" {
  value = aws_instance.this.public_dns
}

output "url" {
  value = "http://${aws_instance.this.public_dns}"
}
