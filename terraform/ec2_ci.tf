data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

resource "aws_instance" "ci" {
  ami                    = data.aws_ssm_parameter.ubuntu.value
  instance_type          = var.ci_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ci.id]
  key_name               = aws_key_pair.main.key_name
  user_data              = file("${path.module}/userdata-ci.sh")

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = { Name = "${var.project}-ci" }
}
