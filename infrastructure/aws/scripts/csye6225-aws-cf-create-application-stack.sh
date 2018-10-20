###################################################################################
#starting of script
#Get a STACK name to create new one.
###################################################################################
echo "Please Enter a new name for the stack: "
read stack_name

###################################################################################
#Retrive VPC using already created STACK Name
###################################################################################
echo "Retrieving VPC:"
echo "Please enter the Stack name where VPC belongs to: "
read nw_stack_name

###################################################################################
#retrieve VPC_Id from the existing created STACK
###################################################################################
vpc_id=$(aws ec2 describe-vpcs --query "Vpcs[?Tags[?Key=='aws:cloudformation:stack-name']|[?Value=='$nw_stack_name']].VpcId" --output text)
#echo "VPC ID: " $vpc_id

###################################################################################
#retrieve subnet_ids from the existing created vpc using vpc_id and stack name
###################################################################################
subnet_id=$(aws ec2 describe-subnets --query "Subnets[?Tags[?contains(Value, 'public')]] | [0].SubnetId " --output text)
#echo "Subnet ID: " $subnet_id

###################################################################################
# VPC_ID reference given to the csye6225-cf-application.json for dynamic creation
###################################################################################
jq '.Resources.csye6225Webapp.Properties.VpcId = "'$vpc_id'"' ../cloudformation/csye6225-cf-application.json > tmp.$$.json && mv tmp.$$.json ../cloudformation/csye6225-cf-application.json

###################################################################################
# VPC_ID reference given to the csye6225-cf-application.json for dynamic creation
###################################################################################
jq '.Resources.csye6225RDS.Properties.VpcId = "'$vpc_id'"' ../cloudformation/csye6225-cf-application.json > tmp.$$.json && mv tmp.$$.json ../cloudformation/csye6225-cf-application.json

###################################################################################
# stack name reference given to the csye6225-cf-application.json for dynamic creation
###################################################################################
jq '.Resources.Ec2Instance.Properties.Tags[0].Value = "'$stack_name'-ec2"' ../cloudformation/csye6225-cf-application.json > tmp.$$.json && mv tmp.$$.json ../cloudformation/csye6225-cf-application.json

###################################################################################
# subnet_id reference given to the csye6225-cf-application.json for dynamic creation
###################################################################################
jq '.Resources.Ec2Instance.Properties.SubnetId = "'$subnet_id'"' ../cloudformation/csye6225-cf-application.json > tmp.$$.json && mv tmp.$$.json ../cloudformation/csye6225-cf-application.json

###################################################################################
# Create a stack with cloudformation  using all required parameters in .json and execute it
###################################################################################
echo "Executing Create Stack....."

aws cloudformation create-stack --stack-name ${stack_name} --template-body file://../cloudformation/csye6225-cf-application.json --capabilities=CAPABILITY_NAMED_IAM

if [ $? -eq 0 ]; then
	echo "Waiting to create gets executed completely...!"
else
	echo "Error in Create Stack...Exiting..."
	exit 1
fi

###################################################################################
# wait unitl cloudformation is completed successfully...
###################################################################################
aws cloudformation wait stack-create-complete --stack-name ${stack_name}

if [ $? -eq 0 ]; then
	echo "Create successfully executed...!"
else
	echo "Error in Create Stack...Exiting..."
	exit 1
fi

###################################################################################
# END of the cloud formation creation...
###################################################################################
echo "Stack Create Execution Complete...!!!"

