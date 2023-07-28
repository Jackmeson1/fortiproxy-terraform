
output "FPXActiveMGMTPublicIP" {
  value = aws_eip.MGMTPublicIP.public_ip
}

output "FPXClusterPublicFQDN" {
  value = "${join("", tolist(["https://", "${aws_eip.ClusterPublicIP.public_dns}", ":", "${var.adminsport}"]))}"
}

output "FPXClusterPublicIP" {
  value = aws_eip.ClusterPublicIP.public_ip
}


output "FPXPassiveMGMTPublicIP" {
  value = aws_eip.PassiveMGMTPublicIP.public_ip
}

output "Username" {
  value = "admin"
}

output "Password" {
  value = aws_instance.fpxactive.id
}

