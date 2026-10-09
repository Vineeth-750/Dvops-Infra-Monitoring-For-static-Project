
# AWS Static Website DevOps Project

Terraform provisions AWS networking, two Red Hat Enterprise Linux EC2 instances, security groups, and an S3 bucket for deployment artifacts/logs. Ansible configures the web and monitoring hosts. GitHub Actions tests and builds a Docker image, then pushes it to Docker Hub.

## Architecture

- **Web EC2 (RHEL)**: Docker Engine + a dedicated `deploy` user; runs the static site in an Nginx container.
- **Monitoring EC2 (RHEL)**: Prometheus + Grafana.
- **Node Exporter**: installed on both EC2 instances; Prometheus scrapes both.
- **S3**: private bucket for optional deployment artifacts/logs. Docker images are stored in Docker Hub, not S3.
- **Terraform**: VPC, public subnet, internet gateway, route table, EC2, IAM instance role, security groups, S3.
- **Ansible**: host setup and monitoring configuration.
- **GitHub Actions**: checks the site, builds the image, and pushes it to Docker Hub.

> Cost warning: EC2, EBS, public IPv4 addresses, and data transfer can incur charges. Run `terraform destroy` when finished. This starter puts both instances in a public subnet for simplicity; restrict SSH to your own IP and consider private subnets + SSM/NAT for production.

## Repository layout

```text
.
├── terraform/
├── ansible/
├── website/
├── Dockerfile
└── .github/workflows/
```

## 1. Prerequisites

- Terraform, Ansible, AWS CLI, Git, Docker
- AWS credentials configured locally (`aws configure` or environment variables)
- Docker Hub account
- SSH key pair created in AWS EC2, with the private key available locally

## 2. Provision AWS

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: AWS region, EC2 key pair name, your public IPv4/CIDR, and instance type.
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Terraform outputs the web and monitoring public IPs and the S3 bucket name.

## 3. Configure Ansible

From `ansible/`, copy the example inventory and fill in the IPs and private-key path:

```bash
cp inventory.ini.example inventory.ini
cp group_vars/all.yml.example group_vars/all.yml
```

Update `inventory.ini` and `group_vars/all.yml`. Then run:

```bash
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i inventory.ini site.yml
```

Prometheus is configured to scrape both node-exporter endpoints. Grafana is available on port 3000; change the initial admin password immediately. Prometheus is exposed on port 9090 in this demo; lock it down to your IP in the security group before use.

## 4. Build and run locally

```bash
docker build -t static-site:local .
docker run --rm -p 8080:80 static-site:local
```

Open http://localhost:8080.

## 5. GitHub Actions → Docker Hub

In your GitHub repository, add these **Actions secrets**:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN` (Docker Hub access token; do not use your account password)

The workflow runs on pushes and pull requests. On pushes to `main`, it builds and pushes `DOCKERHUB_USERNAME/static-site:latest` and a commit-SHA tag.

To download the image on any Docker host:

```bash
docker login
docker pull YOUR_DOCKERHUB_USERNAME/static-site:latest
docker run -d --name static-site -p 80:80 --restart unless-stopped \
  YOUR_DOCKERHUB_USERNAME/static-site:latest
```

## 6. Deploy the image to the web EC2

After the workflow has pushed the image, connect to the web host and run the commands in the previous section, replacing the image name. For a repeatable deployment, extend the Ansible web play to log in to Docker Hub (if the image is private), pull the SHA tag, and recreate the container.

## Security notes

- Never commit `terraform.tfvars`, private keys, AWS credentials, Docker Hub tokens, or Ansible vault passwords.
- Use a narrow SSH CIDR such as `203.0.113.10/32`, not `0.0.0.0/0`.
- Use a private Docker Hub repository or image pull secret if the image should not be public.
- Rotate Grafana credentials and restrict Grafana/Prometheus ingress.
- For production, use private subnets, SSM Session Manager, TLS, a domain name, secrets management, and pinned provider/module versions.
