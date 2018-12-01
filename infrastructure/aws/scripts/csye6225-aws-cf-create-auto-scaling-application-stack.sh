## New test
###################################################################################
###################################################################################
appname="csye6225CodeDeployApplication"
echo $appname

depname="csye6225CodeDeployApplication-depgroup"
echo $depname

accid=$(aws sts get-caller-identity --output text --query 'Account')
echo "AccountId: $accid"

domain=$(aws route53 list-hosted-zones --query HostedZones[0].Name --output text)
trimdomain=${domain::-1}
bucket_name="$trimdomain.tld.csye6225.com"
senderEmail="noreply@$trimdomain"
echo "S3 Domain: $bucket_name"

dbidentifier="csye6225-fall2018-1"
dBsubnetGroup_name="dbSubnetGrp-1"

echo "Please Enter a new name for the stack: "
read stack_name

echo "Retrieving VPC:"
echo "Please enter the Stack name where VPC belongs to: "
read nw_stack_name

echo "Enter the DynamoDB table name"
read dynamoDB_table

vpc_id=$(aws ec2 describe-vpcs --query "Vpcs[?Tags[?Key=='aws:cloudformation:stack-name']|[?Value=='$nw_stack_name']].VpcId" --output text)
echo "VPC ID: " $vpc_id

SSLArn=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='$trimdomain'].CertificateArn" --output text)
echo "SSLArn: $SSLArn"

hostedZoneId=$(aws route53 list-hosted-zones --query 'HostedZones[*].{Id:Id}'  --output text |cut -d"/" -f3 )
echo $hostedZoneId

#hostedZoneName=$(aws route53 list-hosted-zones-by-name --query 'HostedZones[*].{Name:Name}'  --output text |cut -d"." -f1-2)
#echo $hostedZoneName

subnet_id_pub=$(aws ec2 describe-route-tables --query "RouteTables[?Tags[?Key=='Name']|[?Value=='$nw_stack_name-csye6225-public-route-table']].Associations[].SubnetId")
echo "Subnet ID: " $subnet_id_pub

pvt=$( aws ec2 describe-route-tables --query "RouteTables[?Tags[?Key=='Name']|[?Value=='$nw_stack_name-csye6225-private-route-table']].Associations[].SubnetId")
echo 'PVT: ' $pvt

count=0
for i in $pvt
do
    if [ "$i" = "[" ] || [ "$i" = "]" ]; then
    echo "...."
  else
    #subnets+=$i
    #subnet=`echo $i  | sed "s/\"//g" | sed 's/,/ /g'`
    subnet=`echo $i  | sed 's/,/ /g'`
    echo $subnet
    jq '.Resources.DBsubnetGroup.Properties.SubnetIds['$count'] =  '"$subnet"'' ../cloudformation/csye6225-cf-auto-scaling-application.json > tmp.$$.json && mv tmp.$$.json ../cloudformation/csye6225-cf-auto-scaling-application.json
    ((count++))
    echo $count
  fi;
done

pub_sub=$( aws ec2 describe-route-tables --query "RouteTables[?Tags[?Key=='Name']|[?Value=='$nw_stack_name-csye6225-public-route-table']].Associations[].SubnetId")
echo 'Pub Subs: ' $pub_sub

count=0
for i in $pub_sub
do
    if [ "$i" = "[" ] || [ "$i" = "]" ]; then
    echo "...."
  else
    #subnets+=$i
    #subnet=`echo $i  | sed "s/\"//g" | sed 's/,/ /g'`
    subnet=`echo $i  | sed 's/,/ /g'`
    echo $subnet
    jq '.Resources.MyLoadBalancer.Properties.Subnets['$count'] =  '"$subnet"'' ../cloudformation/csye6225-cf-auto-scaling-application.json > tmp.$$.json && mv tmp.$$.json ../cloudformation/csye6225-cf-auto-scaling-application.json
    
    jq '.Resources.WebServerGroup.Properties.VPCZoneIdentifier['$count'] =  '"$subnet"'' ../cloudformation/csye6225-cf-auto-scaling-application.json > tmp.$$.json && mv tmp.$$.json ../cloudformation/csye6225-cf-auto-scaling-application.json
    ((count++))
    echo $count
  fi;
done

subnet_id=$(aws ec2 describe-subnets --query "Subnets[?Tags[?contains(Value, 'private')]] | [0].SubnetId " --output text)
echo "Subnet ID: " $subnet_id

echo "Executing Create Stack....."

aws cloudformation create-stack --stack-name ${stack_name} --template-body file://../cloudformation/csye6225-cf-auto-scaling-application.json --capabilities=CAPABILITY_NAMED_IAM --parameters ParameterKey=SSLArn,ParameterValue=$SSLArn ParameterKey=VpcId,ParameterValue=$vpc_id ParameterKey=senderEmail,ParameterValue=$senderEmail ParameterKey=dynamoDB,ParameterValue=$dynamoDB_table ParameterKey=s3domain,ParameterValue=$bucket_name ParameterKey=myAccountId,ParameterValue=$accid ParameterKey=DBSubnetGroupName,ParameterValue=$dBsubnetGroup_name ParameterKey=DBInstanceIdentifier,ParameterValue=$dbidentifier ParameterKey=HostedZoneName,ParameterValue=$domain ParameterKey=appname,ParameterValue=$appname ParameterKey=depname,ParameterValue=$depname ParameterKey=hostedZoneId,ParameterValue=$hostedZoneId

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


val='
{
	"logs": {
		"logs_collected": {
			"files": {
				"collect_list": [
					{
						"file_path": "/var/log/messages",
						"log_group_name": "Log2"
					}
				]
			}
		}
	},
	"metrics": {
		"metrics_collected": {
			"collectd": {
				"metrics_aggregation_interval": 60
			},
			"statsd": {
				"metrics_aggregation_interval": 60,
				"metrics_collection_interval": 10,
				"service_address": ":8125"
			}
		}
	}
}
'

echo $val
parameter_name="WebApp"
aws ssm put-parameter --name "$parameter_name" --type "String" --value "$val"

