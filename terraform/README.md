# Terraform Modules

## modules/network
VPC + Private Subnet với fixed CIDR cho static IP convention

## modules/security
Security groups cho SSH + PostgreSQL

## modules/db-node
EC2 instance với EBS volumes + static private IP

## topologies/single-node
Phase 1: c8g.4xlarge với static IP 10.0.1.10
