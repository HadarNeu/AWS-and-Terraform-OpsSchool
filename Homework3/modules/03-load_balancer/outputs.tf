output "name" {
  description = "The name of the VPC specified as argument to this module"
  value       = aws_vpc.vpc.name
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = try(aws_vpc.vpc.id)
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = try(aws_vpc.vpc.cidr_block, "")
}

output "public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = compact(aws_subnet.public[*].cidr_block)
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = compact(aws_subnet.private[*].cidr_block)
}

output "public_subnets_azs" {
  description = "List of availability zones of public subnets"
  value       = compact(aws_subnet.public[*].availability_zone)
}

output "private_subnets_azs" {
  description = "List of availability zones of private subnets "
  value       = compact(aws_subnet.private[*].availability_zone)
}