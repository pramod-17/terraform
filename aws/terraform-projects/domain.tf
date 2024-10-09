# Ensure you have an existing Route 53 hosted zone for your domain
resource "aws_route53_zone" "domainxyz" {
  name = "devops-pramod.xyz" # Change this to your domain name
}

# Add an A record to Route 53 that points to the ALB
resource "aws_route53_record" "my_alb_record" {
  zone_id = aws_route53_zone.domainxyz.id # Hosted Zone ID for the domain
  name    = "www.devops-pramod.xyz"       # Subdomain you want to use, change accordingly
  type    = "A"                           # A record for ALB
  alias {
    name                   = aws_lb.mylb.dns_name # ALB DNS name
    zone_id                = aws_lb.mylb.zone_id  # ALB zone ID
    evaluate_target_health = false
  }
}

# If you want a record for the root domain, you can also add an A record for devops-pramod.xyz
resource "aws_route53_record" "root_record" {
  zone_id = aws_route53_zone.domainxyz.id  # Hosted Zone ID for the domain
  name    = "devops-pramod.xyz"             # Root domain
  type    = "A"                             # A record for ALB
  alias {
    name                   = aws_lb.mylb.dns_name # ALB DNS name
    zone_id                = aws_lb.mylb.zone_id  # ALB zone ID
    evaluate_target_health = false
  }
}

