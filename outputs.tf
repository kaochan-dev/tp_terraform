
output "load_balancer_dns" {
  description = "Public DNS name of the Load Balancer"
  value       = aws_lb.sra_alb.dns_name
}
