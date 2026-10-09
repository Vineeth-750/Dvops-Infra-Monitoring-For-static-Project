output "web_public_ip" {
  value = aws_instance.web.public_ip
}

output "monitoring_public_ip" {
  value = aws_instance.monitoring.public_ip
}

output "s3_artifacts_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}

output "web_instance_id" {
  value = aws_instance.web.id
}

output "monitoring_instance_id" {
  value = aws_instance.monitoring.id
}
