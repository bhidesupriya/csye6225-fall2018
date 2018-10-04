echo "Please Enter a new name for the stack: "
read stack_name

echo "Retrieving VPC:"
echo "Please enter the Stack name where VPC belongs to: "
read nw_stack_name

vpc_id=$(aws ec2 describe-vpcs --query "Vpcs[?Tags[?Key=='aws:cloudformation:stack-name']|[?Value=='$nw_stack_name']].VpcId" --output text)
#echo "VPC ID: " $vpc_id

subnet_id=$(aws ec2 describe-subnets --query "Subnets[?Tags[?contains(Value, 'public')]] | [0].SubnetId " --output text)
#echo "Subnet ID: " $subnet_id

jq '.Resources.csye6225Webapp.Properties.VpcId = "'$vpc_id'"' ../cloudformation/csye6225-cf-application.json > tmp.$$.json && mv tmp.$$.json ../cloudformation/csye6225-cf-application.json

jq '.Resources.csye6225RDS.Properties.VpcId = "'$vpc_id'"' ../cloudformation/csye6225-cf-application.json > tmp.$$.json && mv tmp.$$.json ../cloudformation/csye6225-cf-application.json

jq '.Resources.Ec2Instance.Properties.Tags[0].Value = "'$stack_name'-ec2"' ../cloudformation/csye6225-cf-application.json > tmp.$$.json && mv tmp.$$.json ../cloudformation/csye6225-cf-application.json

jq '.Resources.Ec2Instance.Properties.SubnetId = "'$subnet_id'"' ../cloudformation/csye6225-cf-application.json > tmp.$$.json && mv tmp.$$.json ../cloudformation/csye6225-cf-application.json

echo "Executing Create Stack....."

aws cloudformation create-stack --stack-name ${stack_name} --template-body file://../cloudformation/csye6225-cf-application.json --capabilities=CAPABILITY_NAMED_IAM

if [ $? -eq 0 ]; then
	echo "Waiting to create gets executed completely...!"
else
	echo "Error in Create Stack...Exiting..."
	exit 1
fi

aws cloudformation wait stack-create-complete --stack-name ${stack_name}

if [ $? -eq 0 ]; then
	echo "Create successfully executed...!"
else
	echo "Error in Create Stack...Exiting..."
	exit 1
fi

echo "Stack Create Execution Complete...!!!"
