resource "aws_security_group" "ci" {
  name        = "${var.project}-ci-sg"
  description = "Jenkins and SonarQube server"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project}-ci-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "ci_ssh" {
  security_group_id = aws_security_group.ci.id
  description       = "SSH from my IP only"
  cidr_ipv4         = var.my_ip
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ci_jenkins" {
  security_group_id = aws_security_group.ci.id
  description       = "Jenkins UI from my IP only"
  cidr_ipv4         = var.my_ip
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ci_sonar" {
  security_group_id = aws_security_group.ci.id
  description       = "SonarQube UI from my IP only"
  cidr_ipv4         = var.my_ip
  from_port         = 9000
  to_port           = 9000
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ci_all_out" {
  security_group_id = aws_security_group.ci.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
