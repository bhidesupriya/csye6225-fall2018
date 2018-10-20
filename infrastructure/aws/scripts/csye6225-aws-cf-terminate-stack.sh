###################################################################################
#starting of script
#Get a STACK name to delete it.
###################################################################################
echo "Please Enter a Name for the stack you want to delete"
read stack_name

###################################################################################
#run command to delete a cloudFormation stack...
###################################################################################
echo "Deleting Stack: $stack_name"
aws cloudformation delete-stack --stack-name ${stack_name} 

###################################################################################
# waiting until cloudFormation is deleted...
# End of the script...
###################################################################################
aws cloudformation wait stack-delete-complete --stack-name ${stack_name}
echo "Stack successfully deleted...!"

