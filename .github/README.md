# CI/CD Pipeline Configuration

This repository includes GitHub Actions workflows for automated building, testing, and deployment of the Todo List Node.js application to private Docker registries.

## Workflows

### 1. `docker-build-push.yml` - Simple Docker Build & Push
Basic workflow that builds and pushes Docker images to a private registry on every push to main branches.

### 2. `ci-cd.yml` - Comprehensive CI/CD Pipeline
Full pipeline with testing, multi-registry support, security scanning, and environment deployments.

### 3. `private-registry.yml` - Private Registry Deployment
Specialized workflow for private registry deployment with advanced security features.

## Setup Instructions

### 1. Repository Secrets
Configure these secrets in your GitHub repository (Settings → Secrets and variables → Actions):

**For Private Registry:**
- `PRIVATE_REGISTRY_USERNAME` - Your private registry username
- `PRIVATE_REGISTRY_PASSWORD` - Your private registry password/token

**For Docker Hub (optional):**
- `DOCKERHUB_USERNAME` - Your Docker Hub username
- `DOCKERHUB_TOKEN` - Your Docker Hub access token

### 2. Repository Variables
Configure these variables in your GitHub repository (Settings → Secrets and variables → Actions):

- `PRIVATE_REGISTRY_URL` - Your private registry URL (e.g., `registry.company.com`)

### 3. Environment Configuration
Create environments in your repository settings:
- `staging` - For development/staging deployments
- `production` - For production deployments

## Registry Options Supported

1. **Private Docker Registry** - Your own registry
2. **Docker Hub** - Public Docker registry
3. **GitHub Container Registry (GHCR)** - Built-in GitHub registry
4. **AWS ECR, Azure ACR, GCP Artifact Registry** - Cloud provider registries

## Security Features

- **Vulnerability Scanning** with Trivy
- **SBOM Generation** for supply chain security
- **Image Signing** capabilities (cosign ready)
- **Multi-platform builds** (AMD64 + ARM64)
- **Layer caching** for faster builds

## Usage Examples

### Trigger Builds
- Push to `main`/`master` → Builds and deploys to production
- Push to `develop` → Builds and deploys to staging
- Create tag `v1.0.0` → Builds versioned release
- Manual workflow dispatch → Deploy to chosen environment

### Image Tags Generated
- `latest` - Latest main branch build
- `develop` - Development branch builds
- `v1.0.0` - Release version tags
- `main-abc1234-1640995200` - Branch + commit SHA + timestamp

## Customization

### Private Registry URL
Update the registry URL in the workflow files or set the `PRIVATE_REGISTRY_URL` repository variable.

### Deployment Commands
Replace the placeholder deployment commands in the workflows with your actual deployment logic:
- Kubernetes: `kubectl` commands
- Docker Swarm: `docker service update`
- Helm: `helm upgrade`
- Custom scripts: Your deployment automation

### Build Arguments
Modify the Docker build arguments in the workflows as needed for your application.

## Monitoring

The workflows provide:
- Build status notifications
- Security scan results in GitHub Security tab
- Deployment environment tracking
- SBOM artifacts for compliance

## Troubleshooting

### Common Issues

1. **Registry Authentication Failed**
   - Verify secrets are correctly set
   - Check registry URL format
   - Ensure credentials have push permissions

2. **Build Failures**
   - Check Dockerfile syntax
   - Verify all dependencies are available
   - Review build logs in Actions tab

3. **Deployment Issues**
   - Verify environment configurations
   - Check deployment scripts/commands
   - Ensure target infrastructure is accessible