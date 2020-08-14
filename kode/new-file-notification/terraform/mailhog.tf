variable "demo" {
  type = map
  default = {
    # Change this based on your needs using terraform.tfvars
    ec2_type = "t2.micro"
    ssh_pub_key = "~/.ssh/teknocerdas.key.pub"
    domain = "mailhog.teknocerdas.com"

    # CloudFlare
    cf_email = null
    cf_api_key = null
    cf_zone_id = null
  }
}

provider "cloudflare" {
  email = var.demo.cf_email
  api_key = var.demo.cf_api_key
}

data "aws_vpc" "mailhog_demo" {
  default = true
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Setup SSH key
resource "aws_key_pair" "ssh_key" {
  key_name = "awsug-key"
  public_key = chomp(file(var.demo.ssh_pub_key))
}

resource "aws_security_group" "mailhog_demo" {
  name = "awsug-mailhog-demo"
  name_prefix = null
  description = "Firewall for MailHog demo"

  ingress {
    description = "SSH for MailHog"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP for MailHog"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SMTP for MailHog"
    from_port   = 1025
    to_port     = 1025
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Output rule for MailHog"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = data.aws_vpc.mailhog_demo.id
  tags = var.default_tags
}

resource "aws_instance" "mailhog_demo" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.demo.ec2_type
  key_name = "awsug-key"
  availability_zone = "ap-southeast-1a"

  tags = var.default_tags
  volume_tags = var.default_tags

  vpc_security_group_ids = [aws_security_group.mailhog_demo.id]

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
    delete_on_termination = true
    encrypted = false
  }
}

resource "cloudflare_record" "mailhog_demo" {
  zone_id = var.demo.cf_zone_id
  name = var.demo.domain
  type = "A"
  value = aws_instance.mailhog_demo.public_ip
  proxied = true
}