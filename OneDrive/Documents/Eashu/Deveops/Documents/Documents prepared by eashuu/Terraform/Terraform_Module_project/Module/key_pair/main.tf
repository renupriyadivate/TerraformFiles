resource "tls_private_key" "ssh_keys" {
   algorithm = "RSA"
   rsa_bits =  2048
}

resource "aws_key_pair" "public_key" {
  key_name = var.key_name
  public_key = tls_private_key.ssh_keys.public_key_openssh
}

resource "local_file" "private_key" {
  content = tls_private_key.ssh_keys.private_key_pem
  filename = var.filename
}