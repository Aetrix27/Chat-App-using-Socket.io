# Chat-App-using-Socket.io
A simple chat app using socket.io
  
See it in action - [Kunal Chat App](https://kunal-chat-app.herokuapp.com)

# Instructions:

## Steps to run the project on an AWS account:
## Before running, please install: Terraform, PUTTY

1. Download the Github project in the top right
2. Check that you are in the us-east-1 region on your AWS account, may take a while to apply if it has been changed
3. Run terraform init, then terraform apply, and then enter your AWS access key and secret key when prompted
4. Go to AWS ec2 services, and generate a primary key, which the 2 instances will connect to
5. Make sure that you use ubuntu for SSH connection since the AMI key is specific to ubuntu
6. Download your private key and open and use PUTTYgen to convert the .pem file to a .ppk file, which can be used by PUTTY
7. Establish ssh connection using PUTTY through port 22 and connecting ubuntu@[IP] then selecting SSH->Auth and running the commands which can be found in main.tf EOF commands, or you can access the app and check by visiting http://[First-EC2-IP] and http://[Second-EC2-IP] in incognito mode, in my case: http://3.86.22.78 or http://44.199.115.150

Deployed Load Balancer: load-1-1927657474.us-east-1.elb.amazonaws.com
(Was not able to get node app, only the nginx page since I ran into ubuntu permission issues and ran short on time but I was able to quickly to learn these new technologies)