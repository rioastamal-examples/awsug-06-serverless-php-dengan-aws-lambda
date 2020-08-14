locals {
  private_key = trimsuffix(var.demo.ssh_pub_key, ".pub")
}

output "demo" {
  value = {
    mailhog = {
      ec2_ip = aws_instance.mailhog_demo.public_ip
      url = "https://${var.demo.domain}"
      mailhog_auth = "user = teknocerdas | password = orang.cerdas"
      ssh_access = "ssh -i ${local.private_key} -o LogLevel=quiet -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${aws_instance.mailhog_demo.public_ip}"
    }

    s3_bucket = {
      butcket_name = aws_s3_bucket.s3_new_file.bucket
      create_example = "aws s3 cp ./YOUR_FILE.ext s3://${aws_s3_bucket.s3_new_file.bucket}/"
    }
  }
}