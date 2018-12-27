# Big ol comment
locals {
  instance_tags = {
    env          = "${var.vpc_name}"
    resourceType = "airship"
  }
}

data "aws_vpc" "vpc" {
  tags {
    Name = "${var.vpc_name}"
  }
}

data "aws_ami" "docker" {
  filter {
    name   = "name"
    values = ["${var.ami_string}*"]
  }

  most_recent = true
}

data "aws_route53_zone" "local" {
  name         = "${var.vpc_name}.local."
  private_zone = true
  vpc_id       = "${data.aws_vpc.vpc.id}"
}

data "aws_subnet_ids" "private" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  tags {
    subnet_type = "private"
  }
}

data "aws_security_group" "common" {
  name   = "common"
  vpc_id = "${data.aws_vpc.vpc.id}"
}

data "template_file" "userdata" {
  template = "${file("${path.module}/templates/userdata.tpl")}"

  vars {
    vpc_name = "${var.vpc_name}"
    region   = "${var.aws_region}"
    airship_version = "${var.airship_version}"
  }
}

module "sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "2.5.0"

  name        = "airship"
  description = "Security group for "
  vpc_id      = "${data.aws_vpc.vpc.id}"

  ingress_with_cidr_blocks = [
    {
      from_port   = "5000"
      to_port     = "5000"
      protocol    = "tcp"
      cidr_blocks = "172.31.0.0/16"
    },
  ]
}

module "instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name           = "${var.vpc_name}_airship"
  instance_count = 1

  ami           = "${data.aws_ami.docker.image_id}"
  instance_type = "${var.instance_type}"

  vpc_security_group_ids = [
    "${module.sg.this_security_group_id}",
    "${data.aws_security_group.common.id}",
  ]

  user_data            = "${data.template_file.userdata.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.airship.name}"

  subnet_id = "${element(data.aws_subnet_ids.private.ids, 0)}"

  tags = "${merge(var.tags,local.instance_tags)}"
}

resource "aws_route53_record" "airship" {
  zone_id = "${data.aws_route53_zone.local.zone_id}"
  name    = "airship.${data.aws_route53_zone.local.name}"
  type    = "A"
  ttl     = "300"
  records = ["${module.instance.private_ip}"]
}
