###################################################################################
#starting of the script
#Get a STACK name to delete a stack
###################################################################################
echo "Please Enter a Name for the stack you want to delete"
read stack_name

###################################################################################
#execute command to delete cloudformation stack
###################################################################################
echo "Deleting Stack: $stack_name"
aws cloudformation delete-stack --stack-name ${stack_name} 

###################################################################################
#End of the script
#wait until cloudFormation is deleted...
###################################################################################
aws cloudformation wait stack-delete-complete --stack-name ${stack_name}
echo "Stack successfully deleted...!"

