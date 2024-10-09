output "aws_vpc_id" {
  value = aws_vpc.myvpc.id

}

output "aws_instance" {
  value = aws_instance.webserver1.public_ip

}

output "loadbalancerdns" {
  value = aws_lb.mylb.dns_name
}

output "pvtserverpvtip" {
  value       = aws_instance.webserver2.private_ip
  description = "private server private ip"

}

# Output the name servers (NS records) for the domain
output "ns_records" {
  value = aws_route53_zone.domainxyz.name_servers
}

output "awsalblistner" {
  value = aws_lb_listener.listner.arn
  
}