# Create VPC with CLI command

echo "Creating VPC..."
aws ec2 create-vpc --cidr-block 10.0.0.0/16
