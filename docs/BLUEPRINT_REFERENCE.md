# EKS Platform Blueprints — Complete Reference

## Tier 1: Platform Foundation

| | Details |
|---|---|
| **Blueprint** | `EKSPlatformFoundation` |
| **Path** | `platform/foundation/` |
| **Required Inputs** | `clusterName`, `region`, `accountID` |
| **Optional Inputs** | `profile`, module toggles (observability, dns, compute, metrics, secrets, logging), AMP workspace config, Route53 config, Karpenter config, logging config |
| **What It Unlocks** | Complete cluster infrastructure in one declaration — observability, DNS automation, compute optimization, metrics, secrets management, centralized logging |
| **Resources Created** | 9 child ResourceGraphs: ObservabilityCluster, ExternalDNSCluster, KarpenterNodePool (×4 variants), MetricsServer, ExternalSecretsOperator, CentralizedLogging → each expands into 5-8 resources |
| **Prerequisites** | KRO, ACK (IAM, EKS, Prometheus), ADOT operator |
| **ACK Controllers** | `ack-iam`, `ack-eks`, `ack-prometheusservice` |

## Tier 2: Platform Security

| | Details |
|---|---|
| **Blueprint** | `EKSPlatformSecurity` |
| **Path** | `platform/security/` |
| **Required Inputs** | `clusterName` |
| **Optional Inputs** | `securityProfile` (permissive/standard/restricted), `policyEnforcement.mode` (deny/warn/dryrun), pod security level, image allowlist, required labels, network policy toggles, RBAC settings |
| **What It Unlocks** | Cluster-wide security governance — pod security standards, image registry control, resource limit enforcement, required labels for cost tracking, default-deny networking, RBAC audit |
| **Resources Created** | 5: ConfigMap (security policy, 10 keys), ClusterRole (platform-viewer), ClusterRole (platform-admin-audit), NetworkPolicy (default-deny-ingress), NetworkPolicy (default-deny-egress) |
| **Prerequisites** | KRO |
| **ACK Controllers** | None (native K8s resources only) |

## Tier 3: Team Services

### Team Namespace

| | Details |
|---|---|
| **Blueprint** | `TeamNamespace` |
| **Path** | `team-services/team-namespace/` |
| **Required Inputs** | `teamName`, `clusterName`, `region`, `accountID` |
| **Optional Inputs** | `environment`, `rbacProfile` (viewer/developer/admin), `adminUsers`, `developerUsers`, `viewerUsers`, `cpuQuota`, `memoryQuota`, `storageQuota`, `podQuota`, `enableNetworkPolicies`, `enableSecretsAccess`, `enableAWSAccess`, `awsServices` |
| **What It Unlocks** | Self-service team onboarding — isolated namespace with RBAC, quotas, network isolation, and governance labels in seconds |
| **Resources Created** | 10: Namespace (with labels), ResourceQuota, LimitRange, Role (developer), Role (admin), RoleBinding (developer), RoleBinding (admin), NetworkPolicy (deny-ingress), NetworkPolicy (allow-dns), ServiceAccount (team-workload) |
| **Prerequisites** | KRO |
| **ACK Controllers** | None (native K8s resources only) |

### Backup Strategy

| | Details |
|---|---|
| **Blueprint** | `BackupStrategy` |
| **Path** | `team-services/backup-strategy/` |
| **Required Inputs** | `clusterName`, `region`, `accountID`, `s3BucketName` |
| **Optional Inputs** | `backupNamespace`, `scheduleExpression`, `retentionDays`, `excludeNamespaces`, `snapshotVolumes` |
| **What It Unlocks** | Automated cluster backup with encrypted S3 storage, scheduled backups, and configurable retention |
| **Resources Created** | 7: Namespace (velero), S3 Bucket (ACK, encrypted), IAM Policy (S3 + EC2 snapshots), IAM Role (Pod Identity trust), PodIdentityAssociation, ServiceAccount, ConfigMap (backup config) |
| **Prerequisites** | KRO, ACK (IAM, EKS, S3), Velero operator |
| **ACK Controllers** | `ack-iam`, `ack-eks`, `ack-s3` |

### GitHub Runner

| | Details |
|---|---|
| **Blueprint** | `GitHubRunner` |
| **Path** | `team-services/github-runner/` |
| **Required Inputs** | `githubOrg`, `runnerScaleSetName`, `clusterName`, `region`, `accountID` |
| **Optional Inputs** | Runner labels, instance types, min/max replicas, resource limits |
| **What It Unlocks** | Self-hosted GitHub Actions runners on EKS with autoscaling, secrets integration, and network isolation |
| **Resources Created** | 11: Namespace, IAM Policy, IAM Role, PodIdentityAssociation, ServiceAccount, SecretProviderClass, ConfigMap, RunnerScaleSet, NetworkPolicy, ResourceQuota, PodDisruptionBudget |
| **Prerequisites** | KRO, ACK (IAM, EKS), GitHub Actions Runner Controller (`actions.github.com` CRD) |
| **ACK Controllers** | `ack-iam`, `ack-eks` |

## Tier 4: Data Services

### Database (Aurora)

| | Details |
|---|---|
| **Blueprint** | `TeamDatabase` |
| **Path** | `data-services/database/` |
| **Required Inputs** | `teamName`, `clusterName`, `region`, `accountID` |
| **Optional Inputs** | `engine` (aurora-postgresql/aurora-mysql), `engineVersion`, `instanceClass`, `databaseName`, `masterUsername`, `storageEncrypted`, `deletionProtection`, `backupRetentionPeriod` |
| **What It Unlocks** | Self-service database provisioning — team gets IAM-authenticated database access with Pod Identity, scoped to their namespace |
| **Resources Created** | 5: IAM Policy (rds-db:connect + secretsmanager:GetSecretValue), IAM Role (Pod Identity trust), PodIdentityAssociation, ServiceAccount, ConfigMap (connection config, 8 keys) |
| **Prerequisites** | KRO, ACK (IAM, EKS), team namespace must exist |
| **ACK Controllers** | `ack-iam`, `ack-eks` |

### Cache (ElastiCache)

| | Details |
|---|---|
| **Blueprint** | `TeamCache` |
| **Path** | `data-services/cache/` |
| **Required Inputs** | `teamName`, `clusterName`, `region`, `accountID` |
| **Optional Inputs** | `engine` (redis/memcached) |
| **What It Unlocks** | Self-service cache provisioning — team gets IAM-authenticated ElastiCache access with Pod Identity |
| **Resources Created** | 5: IAM Policy (elasticache:Connect), IAM Role (Pod Identity trust), PodIdentityAssociation, ServiceAccount, ConfigMap (cache config) |
| **Prerequisites** | KRO, ACK (IAM, EKS), team namespace must exist |
| **ACK Controllers** | `ack-iam`, `ack-eks` |

### Queue (SQS)

| | Details |
|---|---|
| **Blueprint** | `TeamQueue` |
| **Path** | `data-services/queue/` |
| **Required Inputs** | `teamName`, `clusterName`, `region`, `accountID`, `queueName` |
| **Optional Inputs** | `fifoQueue`, `visibilityTimeout`, `messageRetentionPeriod`, `enableEncryption` |
| **What It Unlocks** | Self-service message queue — SQS queue created via ACK with team-scoped IAM access |
| **Resources Created** | 5: SQS Queue (ACK, encrypted), IAM Policy (sqs:SendMessage/ReceiveMessage/DeleteMessage), IAM Role (Pod Identity trust), PodIdentityAssociation, ServiceAccount |
| **Prerequisites** | KRO, ACK (IAM, EKS, SQS), team namespace must exist |
| **ACK Controllers** | `ack-iam`, `ack-eks`, `ack-sqs` |

### Storage (S3)

| | Details |
|---|---|
| **Blueprint** | `TeamStorage` |
| **Path** | `data-services/storage/` |
| **Required Inputs** | `teamName`, `clusterName`, `region`, `accountID`, `bucketName` |
| **Optional Inputs** | `versioning`, `enableEncryption` |
| **What It Unlocks** | Self-service object storage — S3 bucket created via ACK with team-scoped IAM access |
| **Resources Created** | 5: S3 Bucket (ACK, tagged), IAM Policy (s3:GetObject/PutObject/DeleteObject/ListBucket), IAM Role (Pod Identity trust), PodIdentityAssociation, ServiceAccount |
| **Prerequisites** | KRO, ACK (IAM, EKS, S3), team namespace must exist |
| **ACK Controllers** | `ack-iam`, `ack-eks`, `ack-s3` |

## Tier 5: AI/ML

### GPU NodePool

| | Details |
|---|---|
| **Blueprint** | `GPUNodePool` |
| **Path** | `ai-ml/gpu-nodepool/` |
| **Required Inputs** | `clusterName` |
| **Optional Inputs** | `nodePoolName`, `acceleratorType` (nvidia-gpu/aws-neuron), `capacityType` (on-demand/spot), `cpuLimit`, `memoryLimit`, `gpuLimit` |
| **What It Unlocks** | GPU compute capacity for AI/ML workloads — Karpenter NodePool with GPU taints for workload isolation on EKS Auto Mode |
| **Resources Created** | 1: Karpenter NodePool (with nvidia.com/gpu taint, Auto Mode NodeClass reference, consolidation policy) |
| **Prerequisites** | KRO, EKS Auto Mode, NVIDIA device plugin (auto-managed by Auto Mode) |
| **ACK Controllers** | None (native Karpenter CRD) |

### Bedrock Access

| | Details |
|---|---|
| **Blueprint** | `BedrockAccess` |
| **Path** | `ai-ml/bedrock-access/` |
| **Required Inputs** | `teamName`, `clusterName`, `region`, `accountID` |
| **Optional Inputs** | `foundationModels` (model IDs or * for all), `enableGuardrails`, `guardrailName`, `monthlyBudgetUSD` |
| **What It Unlocks** | Self-service Bedrock model access — team pods can call Bedrock APIs (InvokeModel, guardrails) via Pod Identity without managing AWS credentials |
| **Resources Created** | 5: IAM Policy (bedrock:InvokeModel + guardrails), IAM Role (Pod Identity trust), PodIdentityAssociation, ServiceAccount, ConfigMap (model config, 5 keys) |
| **Prerequisites** | KRO, ACK (IAM, EKS), team namespace must exist, ACK controller role needs `bedrock:*` |
| **ACK Controllers** | `ack-iam`, `ack-eks` |

### Bedrock Agent

| | Details |
|---|---|
| **Blueprint** | `BedrockAgent` |
| **Path** | `ai-ml/bedrock-agent/` |
| **Required Inputs** | `teamName`, `region`, `accountID`, `agentName`, `instruction` |
| **Optional Inputs** | `foundationModel`, `description`, `idleSessionTTLInSeconds` |
| **What It Unlocks** | Managed AI agent creation — Bedrock Agent provisioned via ACK with proper IAM role for model invocation |
| **Resources Created** | 3: IAM Role (Bedrock service trust), IAM Policy (bedrock:InvokeModel), Bedrock Agent (ACK) |
| **Prerequisites** | KRO, ACK (IAM, Bedrock Agent), team namespace must exist, ACK controller role needs `bedrock:*` |
| **ACK Controllers** | `ack-iam`, `ack-bedrockagent` |

### SageMaker Notebook

| | Details |
|---|---|
| **Blueprint** | `SageMakerNotebook` |
| **Path** | `ai-ml/notebook/` |
| **Required Inputs** | `teamName`, `region`, `accountID`, `notebookName` |
| **Optional Inputs** | `instanceType` (default: ml.t3.medium), `volumeSizeInGB` (default: 20) |
| **What It Unlocks** | Self-service managed notebook — SageMaker NotebookInstance provisioned via ACK with S3, Bedrock, and CloudWatch access |
| **Resources Created** | 3: IAM Role (SageMaker service trust), IAM Policy (S3 + Bedrock + CloudWatch Logs), SageMaker NotebookInstance (ACK) |
| **Prerequisites** | KRO, ACK (IAM, SageMaker), team namespace must exist, ACK controller role needs `sagemaker:*` |
| **ACK Controllers** | `ack-iam`, `ack-sagemaker` |

### SageMaker Endpoint

| | Details |
|---|---|
| **Blueprint** | `SageMakerEndpoint` |
| **Path** | `ai-ml/sagemaker-endpoint/` |
| **Required Inputs** | `teamName`, `region`, `accountID`, `endpointName`, `modelData` (S3 URI), `containerImage` (ECR URI) |
| **Optional Inputs** | `instanceType` (default: ml.g5.xlarge), `instanceCount` (default: 1) |
| **What It Unlocks** | Self-service model serving — complete SageMaker inference pipeline (Model → EndpointConfig → Endpoint) from one declaration |
| **Resources Created** | 5: IAM Role (SageMaker service trust), IAM Policy (S3 + ECR + CloudWatch), SageMaker Model (ACK), SageMaker EndpointConfig (ACK), SageMaker Endpoint (ACK) |
| **Prerequisites** | KRO, ACK (IAM, SageMaker), team namespace must exist, model artifacts in S3, container image in ECR, ACK controller role needs `sagemaker:*` |
| **ACK Controllers** | `ack-iam`, `ack-sagemaker` |

### Training Job

| | Details |
|---|---|
| **Blueprint** | `TrainingJob` |
| **Path** | `ai-ml/training-job/` |
| **Required Inputs** | `teamName`, `region`, `accountID`, `jobName`, `trainingImage` (ECR URI), `trainingDataS3Uri`, `outputS3Uri` |
| **Optional Inputs** | `instanceType` (default: ml.g5.2xlarge), `instanceCount`, `volumeSizeInGB`, `maxRuntimeInSeconds`, `enableSpotTraining` |
| **What It Unlocks** | Self-service model training — SageMaker training job with managed spot support, S3 data access, and CloudWatch logging |
| **Resources Created** | 3: IAM Role (SageMaker service trust), IAM Policy (S3 + ECR + CloudWatch Logs), SageMaker TrainingJob (ACK) |
| **Prerequisites** | KRO, ACK (IAM, SageMaker), team namespace must exist, training data in S3, training image in ECR, ACK controller role needs `sagemaker:*` |
| **ACK Controllers** | `ack-iam`, `ack-sagemaker` |

---

## Summary

| Tier | Blueprint | Required Params | Resources | ACK Controllers |
|------|-----------|----------------|-----------|-----------------|
| 1 | EKSPlatformFoundation | 3 | 9 child RGs → 50+ | IAM, EKS, Prometheus |
| 2 | EKSPlatformSecurity | 1 | 5 | None |
| 3 | TeamNamespace | 4 | 10 | None |
| 3 | BackupStrategy | 4 | 7 | IAM, EKS, S3 |
| 3 | GitHubRunner | 5 | 11 | IAM, EKS |
| 4 | TeamDatabase | 4 | 5 | IAM, EKS |
| 4 | TeamCache | 4 | 5 | IAM, EKS |
| 4 | TeamQueue | 5 | 5 | IAM, EKS, SQS |
| 4 | TeamStorage | 5 | 5 | IAM, EKS, S3 |
| 5 | GPUNodePool | 1 | 1 | None |
| 5 | BedrockAccess | 4 | 5 | IAM, EKS |
| 5 | BedrockAgent | 5 | 3 | IAM, Bedrock Agent |
| 5 | SageMakerNotebook | 4 | 3 | IAM, SageMaker |
| 5 | SageMakerEndpoint | 6 | 5 | IAM, SageMaker |
| 5 | TrainingJob | 7 | 3 | IAM, SageMaker |
