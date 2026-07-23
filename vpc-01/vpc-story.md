রোহিত শর্মার Terraform রাজ্য – ফাইনাল এডিশন

এক ছিলো রোহিত শর্মা। সে শুধু DevOps ইঞ্জিনিয়ার নয়, বরং Terraform যাদুকর। একদিন সে ঠিক করলো, সে একটা VPC rajya বানাবে, যা হবে Multi-AZ, Highly Available এবং Fully Tagged।

🏰 রাজ্যের ভিত্তি – VPC

রোহিত রাজ্যের নাম দিলো aws_vpc।

রাজ্যের চারপাশে বিশাল CIDR Block দিয়ে দেয়াল তৈরি হলো।
রাজ্য ছিলো DNS Support + DNS Hostnames সহ এবং Dedicated Instance Tenancy।
সবকিছুর উপরে উজ্জ্বল ট্যাগ ঝলমল করছিলো:

Name = "rohit-vpc"


রাজ্যটা যেনো AWS-এর সব দিক থেকে নিরাপদ ও সুগঠিত।

🏘️ পাড়া গুলো – Public & Private Subnets

রাজ্যের ভেতরে দুটি ধরনের পাড়া:

Public Subnets – উন্মুক্ত বাজার

ap-south-1a → Public Subnet A

ap-south-1b → Public Subnet B

প্রতিটা পাড়ার ভিতরে আছে:

cidr_block
vpc_id
availability_zone
tags

Private Subnets – গোপন এলাকা

ap-south-1a → Private Subnet A

ap-south-1b → Private Subnet B

এই গোপন এলাকাগুলোও সম্পূর্ণ সজ্জিত, tags সহ।

🌉 NAT Gateway – গোপন সেতু

রোহিত রাজ্যের নিরাপত্তার জন্য বানালো NAT Gateways:

Public Subnet A → NAT GW A (Elastic IP A সহ)

Public Subnet B → NAT GW B (Elastic IP B সহ)

প্রতিটা NAT GW-এর ভেতরে আছে:

vpc_id + tags


এরা নিরাপদে private subnet থেকে internet access নিশ্চিত করছে।

🛣️ রাস্তা তৈরি – Route Tables & Routes
Public Routes – সবাই যেতে পারবে

প্রতিটা Public Subnet-এর জন্য বানানো হলো:

vpc_id
cidr_block = "0.0.0.0/0"
gateway_id = Internet Gateway

Route Tables – রাজ্যের মানচিত্র

Public Route Table A & B

Private Route Table A & B

প্রতিটা Subnet-এর সাথে Association:

for_each loop
subnet_id
route_table_id


এভাবে সবাই ঠিকভাবে তাদের গন্তব্যে পৌঁছাচ্ছে।

🌐 Internet Gateway – রাজ্যের বিশ্ব দরজা

একটি দরজা খোলা হলো, নাম: aws_internet_gateway
ভেতরে আছে:

vpc_id
tags = "rohit-igw"


যেখানে রাজ্যের সকল open traffic যেতে পারবে।

📊 VPC Flow Logs – নজরদারি ব্যবস্থা

রোহিত রাজ্যে নজরদারি শুরু করলো aws_flow_log দিয়ে:

vpc_id
log_destination (CloudWatch / S3)
traffic_type = ALL
tags = "rohit-vpc-flow-log"


এখন রাজ্যটা একদম secure, traffic monitored এবং compliant।
```
🎉 সারাংশ – রাজ্যের সম্পূর্ণ Terraform Inventory
Resource	Attributes
aws_vpc	cidr_block, dns_support, tenancy, tags
aws_subnet	vpc_id, cidr_block, availability_zone, tags
aws_nat_gateway	vpc_id, elastic_ip, subnet_id, tags
aws_route	vpc_id, cidr_block, gateway_id
aws_route_table	vpc_id, tags
aws_route_table_association	for_each, subnet_id, route_table_id
aws_internet_gateway	vpc_id, tags
aws_flow_log	vpc_id, log_destination, traffic_type, tags
```
এভাবে রোহিত শর্মার Terraform রাজ্য হয়ে উঠলো Multi-AZ, Highly Available, Fully Tagged এবং Secure।

🎖️ শেষ কথা: এই রাজ্যের প্রতিটি subnet, NAT GW, route table, এবং flow log যেনো এক এক করে এক বাস্তব রাজ্যের দুর্গ, সেতু ও নজরদারি টাওয়ার।
