# 🛍️ EasyShop — DevOps Deployment Platform for a Next.js E-Commerce Application

A production-grade, full-stack e-commerce application deployed on AWS EKS using modern DevOps practices — Infrastructure as Code, CI/CD pipelines, GitOps, and real-time monitoring.
---
## Architecture Diagram
<img width="1120" height="742" alt="Screenshot from 2026-07-04 11-48-43" src="https://github.com/user-attachments/assets/e3c80645-401e-449b-9497-410be3d2f8b5" />


## 📖 Table of Contents
- About the Project
- Architecture
- Tech Stack
- Project Structure
- Prerequisites
- Step 1 — Provision Infrastructure with Terraform
- Step 2 — Configure Jenkins (CI)
- Step 3 — Set Up ArgoCD (CD / GitOps)
- Step 4 — Configure NGINX Ingress & HTTPS
- Step 5 — Set Up Monitoring (Prometheus + Grafana)
- Verifying the Deployment
---

## 📌 About the Project

EasyShop is a full-stack Next.js e-commerce application that I containerized and deployed on AWS EKS using modern DevOps practices. The focus of this project is designing and automating the cloud infrastructure, CI/CD pipeline, GitOps workflow, and monitoring stack rather than developing the application itself.

Every piece of AWS infrastructure is written as code (Terraform), the application is automatically built and pushed to Docker Hub whenever code changes (Jenkins CI), and it's automatically deployed to Kubernetes whenever the manifests change (ArgoCD GitOps). On top of that, the entire cluster is monitored with Prometheus and Grafana.

> **Note**
>
> The application itself is an existing Next.js e-commerce application.
> The primary focus of this project is designing and implementing the DevOps platform around it, including infrastructure provisioning with Terraform, containerization, CI/CD with Jenkins, GitOps using ArgoCD, Kubernetes deployment, ingress, persistent storage, and monitoring.

### Application Tiers

**Presentation Tier**
- Next.js Frontend

**Application Tier**
- Next.js API

**Data Tier**
- MongoDB StatefulSet with persistent EBS storage

---

## 🛠️ Tech Stack

### Application

| Layer | Technology |
|-------|------------|
| **Frontend** | Next.js 14, TypeScript, Tailwind CSS |
| **State Management** | Redux Toolkit |
| **Database** | MongoDB 8.0 |
| **Authentication** | JWT, NextAuth.js |
| **Containerization** | Docker |

### DevOps & Infrastructure

| Tool | Purpose |
|------|---------|
| **Terraform** | Infrastructure as Code — provisions all AWS resources |
| **Jenkins** | CI — builds Docker images and pushes to Docker Hub |
| **ArgoCD** | CD — GitOps-based deployment to Kubernetes |
| **AWS EKS** | Managed Kubernetes cluster |
| **AWS EBS** | Persistent storage for MongoDB (gp3) |
| **Nginx Ingress** | Routes external traffic into the cluster |
| **Helm** | Kubernetes package manager |
| **Prometheus** | Metrics collection and alerting |
| **Grafana** | Metrics visualization and dashboards |
| **Docker Hub** | Container image registry |

---
## ✅ Prerequisites

> [!IMPORTANT]
> Make sure all of these are ready **before** you start. Skipping any one of them will cause failures later.

You need the following tools installed on your **local machine**:

| Tool | Purpose | Install Guide |
|------|---------|---------------|
| **AWS CLI** | Talk to AWS from your terminal | [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| **Terraform** | Provision AWS infrastructure | [Install Terraform](https://developer.hashicorp.com/terraform/install) |
| **kubectl** | Manage your Kubernetes cluster | [Install kubectl](https://kubernetes.io/docs/tasks/tools/) |
| **Helm** | Install Kubernetes packages (Prometheus, Grafana, etc.) | [Install Helm](https://helm.sh/docs/intro/install/) |
| **Git** | Clone this repository | [Install Git](https://git-scm.com/downloads) |

You also need:

- An AWS account with an IAM user that has admin/sufficient permissions
- A Docker Hub account (free at hub.docker.com)
- A GitHub account
- A domain name (this project uses kumarharish.in)

# 🔐 Security Considerations

- Sensitive Kubernetes Secrets are intentionally excluded from version control.
- The repository provides a `secret.example.yml` template instead of real secrets.
- Before deploying the application, create the Kubernetes Secret using your own values.
- Container images are scanned using Trivy before deployment.
- Jenkins credentials are securely stored using the Jenkins Credentials Manager.

---
# 🚀 Step 1 – Provision Infrastructure with Terraform

**What this does:** Terraform reads your `.tf` files and creates all the AWS resources for you. the VPC (your private network), EKS cluster (Kubernetes), and EC2 instance (Jenkins server)  automatically.

---

## 1.1 Install and Configure AWS CLI

First, install the AWS CLI so Terraform can talk to your AWS account.

### 📥 Download and Install

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install
```

### ✅ Verify Installation

```bash
aws --version
```
<img width="1169" height="154" alt="image" src="https://github.com/user-attachments/assets/558e6e96-752e-4023-9eb5-bd4e2184be42" />


### Configure AWS Credentials

```bash
aws configure
```

You'll be asked for four values:

| Setting | Value |
|---------|-------|
| AWS Access Key ID | Paste your IAM user's access key |
| AWS Secret Access Key | Paste your IAM user's secret key |
| Default region | `eu-west-1` |
| Default output format | `json` |

<img width="1346" height="207" alt="image" src="https://github.com/user-attachments/assets/e8f5dbac-9556-4aa0-bf99-60ed8b1ea0fd" />


> [!NOTE]
> To generate an Access Key:
>
> **AWS Console → IAM → Users → Your User → Security Credentials → Create Access Key**
<img width="1761" height="832" alt="image" src="https://github.com/user-attachments/assets/947b02cc-96dd-43cb-9385-af3785cf68bc" />

---

## 1.2 Install Terraform

### Add the HashiCorp Repository

```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

sudo apt-add-repository \
"deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

sudo apt-get update
sudo apt-get install terraform -y
```

### Verify Installation

```bash
terraform -v
```

---

## 1.3 Set Up Remote State Storage (Manual, One-Time Step)

### Why?

Terraform stores its **state** (a record of everything it created) in a file. We store this in **S3** so it's safe and shared.

We also use a **DynamoDB table** for state locking so multiple people can't run Terraform at the same time.

### Go to AWS Console and Create:

#### S3 Bucket

- Go to **S3 → Create Bucket**
- **Bucket name:** `{your-bucket-name}` *(must be globally unique also update in terraform.tf)*
- **Region:** `eu-west-1`
- Keep everything else at the default settings
- Click **Create Bucket**

<img width="1386" height="742" alt="image" src="https://github.com/user-attachments/assets/9d6a3df4-af1a-460d-a59b-664073158410" />

#### DynamoDB Table

- Go to **DynamoDB → Create Table**
- **Table name:** `terraform-locks`
- **Partition key:** `LockID` *(Type: String)*
- **Billing mode:** On-demand
- Click **Create Table**
<img width="1395" height="525" alt="image" src="https://github.com/user-attachments/assets/f5bd6d48-77b5-46fb-b67b-a07bf278bea1" />

> [!IMPORTANT]
> This is a one-time setup. These two resources stay forever and are never managed by Terraform itself.

---

## 1.4 Clone This Repository

```bash
git clone https://github.com/<your-username>/easyshop.git

cd easyshop
```

---

## 1.5 Generate an SSH Key Pair

This key lets you SSH into your Jenkins EC2 instance.

```bash
ssh-keygen -f terra-key
```

This creates two files:

- `terra-key` → Your **private key** (never share this)
- `terra-key.pub` → Your **public key** (Terraform uploads this to AWS)

Fix the permissions:

```bash
chmod 400 easyshop-key
```

---

## 1.6 Provision the Infrastructure

```bash
cd terraform/
```

### Download Required Providers

```bash
terraform init
```

### Preview the Changes

Always review the execution plan before applying.

```bash
terraform plan
```

### Create the Infrastructure

```bash
terraform apply
```

Type **yes** when prompted.

This process usually takes **10–15 minutes** (EKS clusters take the longest).

Once finished, note the outputs:

```text
Outputs:

ec2_public_ip = "13.234.x.x"

eks_command = "aws eks update-kubeconfig ..."
```

---

# 🚀 Step 2 – Configure Jenkins (CI)

What Jenkins does:

Every time you push code to GitHub, Jenkins automatically builds a Docker image of your application and pushes it to Docker Hub.

---

## 2.1 SSH into Your Jenkins Server

Use the public IP created by Terraform.

```bash
ssh -i easyshop-key ubuntu@<ec2_public_ip>
```

---

## 2.2 Connect Jenkins to Your EKS Cluster

> [!NOTE]
> Run this on the **Jenkins server**, not your local machine, because Jenkins needs direct access to deploy applications.

Configure AWS CLI:

```bash
aws configure
```

Enter:

- Access Key
- Secret Key
- Region (`eu-west-1`)
- Output (`json`)

Connect Jenkins to the Kubernetes cluster:

```bash
aws eks update-kubeconfig \
  --name easyshop-cluster
```

Verify it worked:

```bash
kubectl get nodes
```

Expected output:

```text
NAME                              STATUS   ROLES    AGE
ip-10-0-2-xx...compute.internal   Ready    <none>   10m
ip-10-0-4-xx...compute.internal   Ready    <none>   10m
```

---

## 2.3 Verify Jenkins Is Running

```bash
sudo systemctl status jenkins
```

If it isn't running:

```bash
sudo systemctl enable jenkins

sudo systemctl start jenkins
```

---

## 2.4 Open Jenkins in Your Browser

Go to:

```text
http://<ec2_public_ip>:8080
```
<img width="1281" height="913" alt="image" src="https://github.com/user-attachments/assets/5de47e44-873a-45c4-a8e0-e5e9e7a5054c" />


Retrieve the initial admin password:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
### Paste this into Jenkins, then click **Install Suggested Plugins** and create your admin user.
<img width="1023" height="598" alt="image" src="https://github.com/user-attachments/assets/12eba8fb-4629-4307-85c7-69e02230804b" />

---

## 2.5 Install Required Plugins

Go to:

**Manage Jenkins → Plugins → Available Plugins**

Search and install:

- ✅ Docker Pipeline → Lets Jenkins build and push Docker images
- ✅ Pipeline View → Better UI for viewing pipeline stages

<img width="1376" height="745" alt="image" src="https://github.com/user-attachments/assets/be5b2e02-1daa-40b5-b38a-7576827b261b" />


---

## 2.6 Add Credentials to Jenkins

Jenkins needs secure access to **GitHub** and **Docker Hub**.

Go to:

**Manage Jenkins → Credentials → (global) → Add Credentials**

### GitHub Credentials

| Field | Value |
|-------|-------|
| **Kind** | Username with password |
| **Username** | Your GitHub username |
| **Password** | GitHub Personal Access Token |
| **ID** | `github-credentials` |
| **Description** | GitHub access |

### Docker Hub Credentials

| Field | Value |
|-------|-------|
| **Kind** | Username with password |
| **Username** | Your Docker Hub username |
| **Password** | Docker Hub Personal Access Token |
| **ID** | `dockerhub-credentials` |
| **Description** | Docker Hub access |

> [!NOTE]
> These credential IDs must exactly match the IDs referenced in your Jenkins pipeline.
<img width="1818" height="393" alt="image" src="https://github.com/user-attachments/assets/129c92d6-cfe8-4a16-9fd8-07fbb4939ee1" />

---

## 2.7 Configure Email Notifications

Jenkins can automatically send an email whenever a pipeline succeeds or fails.

### Install the Plugin

Go to:

**Manage Jenkins → Plugins → Available Plugins**

Install:

- **Email Extension Plugin (Email Extension)**

Restart Jenkins if prompted.

---

### Configure SMTP

Go to:

**Manage Jenkins → System**

Scroll down to:

**Extended E-mail Notification**

Configure the following values.

| Field | Value |
|--------|-------|
| SMTP Server | `smtp.gmail.com` |
| SMTP Port | `465` |
| Use SSL | ✅ Enabled |
| SMTP Authentication | ✅ Enabled |
| Username | Your Gmail address |
| Password | Gmail App Password |

> [!IMPORTANT]
> Do **not** use your normal Gmail password.
> Generate a **Google App Password** from your Google Account and use it instead.

---

### Generate a Gmail App Password

1. Open your Google Account.
2. Go to **Security**.
3. Enable **2-Step Verification**.
4. Search for **App Passwords**.
5. Create a new App Password for **Mail**.
6. Copy the generated 16-character password.

---

### Test the Configuration

After saving the SMTP settings:

Go to:

**Manage Jenkins → System**

Click:

**Test configuration by sending test e-mail**

If the configuration is correct, Jenkins will send a test email successfully.

---

### Pipeline Integration

Once configured, the pipeline automatically sends:

- ✅ Success notification when the pipeline completes successfully.
- ❌ Failure notification when any stage fails.

## 2.8 Create the Jenkins Pipeline

1. Click **New Item**
2. Name it **EasyShop**
3. Select **Pipeline**
4. Click **OK**

### General

- ✅ Check **GitHub project**

**Project URL**

```text
https://github.com/<your-username>/easyshop
```

### Triggers

- ✅ Check **GitHub hook trigger for GITScm polling**

### Pipeline

- **Definition:** Pipeline script from SCM
- **SCM:** Git
- **Repository URL:** `https://github.com/<your-username>/easyshop`
- **Credentials:** `github-credentials`
- **Branch:** `main`
- **Script Path:** `Jenkinsfile`

Click **Save**.

---

## 2.9 Set Up GitHub Webhook

Go to your GitHub repository:

**Settings → Webhooks → Add webhook**

| Field | Value |
|-------|-------|
| **Payload URL** | `http://<jenkins-ip>:8080/github-webhook/` |
| **Content type** | `application/json` |
| **Events** | Just the push event |

Click **Add webhook**.

You'll see a green tick if the webhook is configured correctly.

---

## 2.10 Test the Pipeline

1. Open your Jenkins job.
2. Click **Build Now**.

The pipeline should execute:

```text
Checkout Repository
↓
Build Docker Images
↓
Trivy Image Scan
↓
Push Images to DockerHub
↓
Update Kubernetes Manifests
↓
Email Notification

```
<img width="1471" height="902" alt="Screenshot from 2026-06-21 23-43-56" src="https://github.com/user-attachments/assets/152d41a2-3dee-4d96-bd92-0c7776d66002" />

Verify your images appear on Docker Hub.

```
https://hub.docker.com/repositories/<your-username>
```

---

# 🚀 Step 3 — Install ArgoCD (CD / GitOps)

Jenkins updates the Kubernetes manifests stored in the GitOps repository.

ArgoCD continuously watches that repository and synchronizes those changes to the cluster.

---

## 3.1 Install ArgoCD

Create the namespace:

```bash
kubectl create namespace argocd
```

Install ArgoCD:

```bash
kubectl apply -n argocd \
-f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Watch the pods until they're running:

```bash
kubectl get pods -n argocd -w
```

Verify everything is healthy:

```bash
kubectl get pods -n argocd
```

Expected output:

```text
All pods should show 1/1 Running ✅
```

---

## 3.2 Expose ArgoCD

Change the service type to **NodePort**:

```bash
kubectl patch svc argocd-server \
-n argocd \
-p '{"spec":{"type":"NodePort"}}'
```

Find the NodePort:

```bash
kubectl get svc \
-n argocd argocd-server
```

Expected output:

```text
PORT(S)

80:30943
443:30463
```

Open ArgoCD:

```text
https://<ec2_public_ip>:30463
```

Your browser may display a certificate warning.

Click:

**Advanced → Proceed**

This is expected because ArgoCD uses a self-signed certificate.

---

## 3.3 Log In to ArgoCD

Retrieve the initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" \
| base64 -d && echo
```

Login credentials:

- **Username:** `admin`
- **Password:** *(command output above)*

> [!IMPORTANT]
> Change the password immediately after your first login.

---

## 3.4 Create Kubernetes Secrets

The application requires Kubernetes Secrets for authentication.

For security reasons, real secrets are **not stored in this repository**. Instead, a `kubernetes/secrets.example.yml` template is provided.

Create your own Kubernetes Secret before deploying the application.

### Create using kubectl

```bash
kubectl create secret generic easyshop-secrets \
  --from-literal=NEXTAUTH_SECRET="<YOUR_NEXTAUTH_SECRET>" \
  --from-literal=JWT_SECRET="<YOUR_JWT_SECRET>" \
  -n easyshop
```

### Verify

```bash
kubectl get secrets -n easyshop
```

Expected output:

```text
easyshop-secrets
```

> [!NOTE]
> The application deployment references this Secret. If it doesn't exist, the application pods will fail to start.

---

## 3.5 Deploy EasyShop via ArgoCD

Click **New App** and configure your GitOps repository to begin continuous deployment.

### Application Name

- **Application Name:** `easyshop`
- **Project:** `default`
- **Sync Policy:** `Automatic`

### Source

| Field | Value |
|-------|-------|
| **Repo URL** | `https://github.com/<your-username>/easyshop` |
| **Revision** | `main` |
| **Path** | `kubernetes` |

### Destination

| Field | Value |
|-------|-------|
| **Cluster URL** | `https://kubernetes.default.svc` |
| **Namespace** | `easyshop` |

Click **Create**.

ArgoCD will start syncing immediately.
<img width="1840" height="954" alt="argo_easyshop" src="https://github.com/user-attachments/assets/0569dc5a-61c1-42f2-99b9-7cc1102ebb66" />


---

## 3.5 Verify the Deployment

```bash
kubectl get pods -n easyshop
```

Expected output:

```text
NAME                    READY   STATUS
easyshop-deployment...  1/1     Running ✅
mongodb-0               1/1     Running ✅
db-migration-xxxxx      1/1     Completed ✅
```

Also verify the MongoDB volume is mounted:

```bash
kubectl get pvc -n easyshop
```

Expected output:

```text
STATUS should be Bound

STORAGECLASS should show gp3 ✅
```

---

# 🌐 Step 4 — Configure NGINX Ingress & HTTPS

### What This Step Does

This step exposes the EasyShop application to the internet using the NGINX Ingress Controller.

An AWS Load Balancer is automatically provisioned to receive external traffic, while the Ingress Controller routes requests to the correct Kubernetes Service inside the cluster.

To secure communication, cert-manager automatically requests and renews TLS certificates from Let's Encrypt, allowing the application to be accessed securely over HTTPS.

---

## 4.1 Install via Helm

Add the Helm repository:

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm repo update
```

Install the controller (this automatically creates an AWS Load Balancer):

```bash
helm install nginx-ingress ingress-nginx/ingress-nginx \
--namespace ingress-nginx \
--create-namespace \
--set controller.service.type=LoadBalancer
```

Verify the installation:

```bash
kubectl get pods -n ingress-nginx
```

Expected output:

```text
All pods should show Running ✅
```

---

## 4.2 Install cert-manager

cert-manager automates the process of requesting, issuing, and renewing TLS certificates for Kubernetes applications.

### Add the Helm Repository

```bash
helm repo add jetstack https://charts.jetstack.io

helm repo update
```

### Install cert-manager

```bash
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true
```

### Verify Installation

```bash
kubectl get pods -n cert-manager
```

Expected output:

```text
All pods should show Running ✅
```
---

## 4.3 Configure Let's Encrypt

A ClusterIssuer defines how cert-manager obtains certificates from Let's Encrypt. It is a cluster-wide resource that can be reused by multiple applications.

Create the ClusterIssuer that cert-manager will use to request TLS certificates from Let's Encrypt.

```bash
kubectl apply -f kubernetes/cluster-issuer.yml
```

Verify the ClusterIssuer:

```bash
kubectl get clusterissuer
```

Expected output:

```text
NAME                READY
letsencrypt-prod    True
```

---


## 4.4 Get the Load Balancer Address

```bash
kubectl get svc -n ingress-nginx
```

Example output:

```text
NAME                                 TYPE           EXTERNAL-IP
ingress-nginx-controller             LoadBalancer   ab12cd34.us-east-1.elb.amazonaws.com
```

Copy the **EXTERNAL-IP**.

---

## 4.5 Configure DNS

Log in to your domain registrar and create the following DNS record:

| Type | Value |
|------|-------|
| **Type** | CNAME |
| **Value** | `ab12cd34.us-east-1.elb.amazonaws.com` *(your EXTERNAL-IP)* |
| **TTL** | 300 |

<img width="1260" height="444" alt="image" src="https://github.com/user-attachments/assets/89c3b57c-b5aa-4cdc-8035-9393c850cd31" />


DNS propagation usually takes **2–10 minutes**.

Verify DNS:

```bash
nslookup kumarharish.in
```

Expected output:

```text
Should resolve to an AWS IP ✅
```

---

## 4.6 Enable HTTPS

Apply the Ingress manifest.

```bash
kubectl apply -f kubernetes/ingress.yml
```

The Ingress references the `letsencrypt-prod` ClusterIssuer created earlier.

cert-manager will automatically:

- Request a TLS certificate from Let's Encrypt.
- Store the certificate as the `easyshop-tls` Kubernetes Secret.
- Configure the NGINX Ingress Controller to terminate HTTPS traffic.

### 4.7 Verify the Certificate

Check that the certificate has been issued successfully.

```bash
kubectl get certificate -n easyshop
```

Expected output:

```text
READY   True
```

Verify that the TLS Secret has been created.

```bash
kubectl get secret easyshop-tls -n easyshop
```

Finally, open your application:

```text
https://kumarharish.in
```

Your browser should display a secure HTTPS connection.

> [!NOTE]
> The NGINX Ingress Controller and cert-manager are installed once as cluster-level components. After the platform is configured, ArgoCD manages the EasyShop application resources automatically through GitOps.

---

# 📊 Step 5 — Set Up Monitoring (Prometheus + Grafana)

### What Monitoring Does

What happens if your application starts consuming too much CPU or memory?

As pods crash, Prometheus collects metrics from your cluster automatically, and Grafana visualizes them in dashboards.

---

## 5.1 Install kube-prometheus-stack

This Helm chart installs **Prometheus**, **Grafana**, and **pre-built Kubernetes dashboards**.

Add the Helm repository:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm repo update
```

Create a namespace:

```bash
kubectl create namespace monitoring
```

Install the monitoring stack:

```bash
helm install monitoring prometheus-community/kube-prometheus-stack \
--namespace monitoring \
--set grafana.adminPassword=super-secure-password
```

Verify all pods are running:

```bash
kubectl get pods -n monitoring
```

Expected output:

```text
All pods should become Running within 2–3 minutes ✅
```

---

## 5.2 Access Grafana

Continue by exposing the Grafana service (NodePort, LoadBalancer, or Ingress) depending on your preferred deployment method.

```bash
kubectl port-forward \
--address 0.0.0.0 \
svc/monitoring-grafana \
3000:80 \
-n monitoring
```

Open:

```text
http://<EC2_PUBLIC_IP>:3000
```
<img width="1419" height="768" alt="brave_screenshot (2)" src="https://github.com/user-attachments/assets/a0c8c4d2-06a4-4cd7-a623-57995642f9c0" />


### Login Credentials

| Username | Password |
|----------|----------|
| `admin` | The password you set during Helm installation |

> [!TIP]
> Make sure **port 3000** is open in your EC2 Security Group, otherwise Grafana won't be reachable from your browser.

---

## 5.3 Explore the Pre-Built Dashboards

Grafana comes with Kubernetes dashboards already installed.

Navigate to:

**Dashboards → Browse**

| Dashboard | What You'll See |
|-----------|-----------------|
| Kubernetes / Cluster | Overall CPU, memory, and disk usage |
| Kubernetes / Pods | Per-pod resource usage and restart counts |
| Kubernetes / Nodes | Node-level CPU and memory metrics |
| Node Exporter | Detailed OS-level metrics |

<img width="1825" height="960" alt="brave_screenshot (3)" src="https://github.com/user-attachments/assets/2a2ea198-4487-4313-b1ad-92844af1bbfd" />


---

## 5.4 Import a Custom Dashboard

Grafana has thousands of community dashboards.

To import one:

1. In Grafana, go to **Dashboards → Import**
2. Enter the dashboard ID
3. Click **Load**
4. Select your **Prometheus** data source
5. Click **Import**

Useful dashboards:

| ID | Dashboard | Description |
|----|-----------|-------------|
| **315** | Kubernetes Cluster Monitoring | Cluster overview (CPU, memory, pods, nodes) |
| **6417** | Kubernetes Pods | Detailed pod metrics |
| **1860** | Node Exporter Full | Complete Linux server metrics |
| **15760** | Kubernetes All-in-One | Single dashboard for everything |

### Example — Import Dashboard 315

1. Open **Dashboards → Import**
2. Enter **1680**
3. Click **Load**
4. Select **Prometheus**
5. Click **Import**

You'll immediately see live CPU, memory, and pod metrics from your EKS cluster.

<img width="1849" height="960" alt="easyshop-dashboard" src="https://github.com/user-attachments/assets/226c880f-187a-4870-9beb-ee38e0e3ff58" />


---

# 🔄 How the Full CI/CD Flow Works

Here's what happens from end to end every time you push code:

1. You push code to the `main` branch.
2. GitHub sends a webhook to Jenkins.
3. Jenkins:
   - Checks out the latest code.
   - Builds the Docker image.
   - Tags the image with the Git commit SHA.
   - Pushes the image to Docker Hub.
   - Updates the Kubernetes deployment manifest with the new image tag.
   - Pushes the updated manifest to the GitOps repository.
4. ArgoCD detects the GitOps repository change.
5. ArgoCD syncs the new manifests to your EKS cluster.
6. Kubernetes performs a rolling update:
   - Starts new pods with the new image.
   - Waits for them to become healthy.
   - Terminates the old pods after the new ones are ready.
7. Users begin accessing the new version with **zero downtime**. ✅

---

# 🛠️ Troubleshooting

## MongoDB Pod Is Pending

This usually means the EBS CSI driver couldn't create the persistent volume.

Check if the CSI driver pods are healthy:

```bash
kubectl get pods -n kube-system | grep ebs-csi
```

Check why the PVC is pending:

```bash
kubectl describe pvc mongodb-storage-mongodb-0 -n easyshop
```

Check CSI driver logs:

```bash
kubectl logs -n kube-system deployment/ebs-csi-controller -c ebs-plugin --tail=20
```

> [!NOTE]
> If you see **"no EC2 IMDS role found"**, your EKS worker nodes may not have the required IAM role attached. Revisit your Terraform configuration and ensure the EBS CSI add-on is installed.

---

## ArgoCD App Is Stuck in "Progressing" or "Degraded"

Check recent events:

```bash
kubectl get events -n easyshop --sort-by='.lastTimestamp'
```

Check deployment logs:

```bash
kubectl logs -n easyshop deployment/easyshop-deployment --tail=30
```

---

## Domain Isn't Loading

Verify the Ingress exists:

```bash
kubectl get ingress -n easyshop
```

Verify the NGINX Ingress Controller is running:

```bash
kubectl get pods -n ingress-nginx
```

Check the controller logs:

```bash
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail=20
```

> [!TIP]
> Make sure your DNS **CNAME** record points to the correct AWS Load Balancer hostname and that DNS propagation has completed.

---

## Jenkins pipeline fails at Docker push
1. Check the credential ID in Jenkins is exactly: docker-hub-credentials
2. View the error: Build → Console Output
3. Make sure your Docker Hub username in Jenkinsfile matches your actual account

## 👋 Conclusion
This project was a deep dive into what real-world cloud deployments actually look like. From provisioning infrastructure with Terraform, to automating builds with Jenkins, to declarative deployments with ArgoCD, and finally getting visibility with Prometheus and Grafana, every piece connects to tell a complete story.

As someone just starting out in DevOps, deploying a production-grade Kubernetes setup like this with persistent storage, GitOps, monitoring, and a live domain was not easy for me. The bugs are frustrating, the debugging takes time, but that's exactly where the learning happens.

If you're reading this and following along just stick with it. Every error message is just a step closer to understanding how the whole thing actually works.

Deployed by Harish Kumar

DevOps Engineer · AWS · Kubernetes · Infrastructure