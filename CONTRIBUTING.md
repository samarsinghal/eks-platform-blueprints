# Contributing to EKS Platform Blueprints

Thank you for your interest in contributing! This document provides guidelines for contributing to the EKS Platform Blueprints project.

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs or request features
- Provide clear reproduction steps
- Include relevant logs and configurations

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit with clear messages (`git commit -m 'Add amazing feature'`)
6. Push to your fork (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Blueprint Development Guidelines

### Creating a New Blueprint

1. **Directory Structure**:
   ```
   blueprint-name/
   ├── kro-resourcegroups/
   │   └── blueprint-name.yaml
   ├── examples/
   │   └── example-instance.yaml
   └── README.md
   ```

2. **ResourceGraphDefinition Standards**:
   - Use clear, descriptive names
   - Group API: `<category>.company.com`
   - Version: `v1alpha1`
   - 3-15 parameters (keep it simple)
   - Include descriptions for all parameters

3. **Example Files**:
   - Provide production-ready examples
   - Include comments explaining key parameters
   - Use realistic values

4. **Documentation**:
   - Clear README with overview
   - "What you get" section
   - Quick start guide
   - Parameter reference

### API Group Naming

Use consistent API group naming:
- `observability.company.com` - Monitoring and metrics
- `security.company.com` - Security policies
- `namespace.company.com` - Multi-tenancy
- `platform.company.com` - Platform orchestration

### Adding New API Groups

When adding a new custom API group:

1. Add to `kro-setup/rbac.yaml`:
   ```yaml
   - apiGroups:
     - yournew.company.com
     resources:
     - '*'
     verbs:
     - '*'
   ```

2. Update `bootstrap/deploy-blueprints.sh` if needed

3. Document in blueprint README

## Testing

### Local Testing

```bash
# 1. Deploy blueprint template
kubectl apply -f <blueprint>/kro-resourcegroups/

# 2. Create test instance
kubectl apply -f <blueprint>/examples/

# 3. Verify resources created
kubectl get <resource-type> -o wide

# 4. Clean up
kubectl delete -f <blueprint>/examples/
```

### Integration Testing

- Test with fresh EKS cluster
- Verify GitOps deployment
- Test multi-cluster scenarios
- Validate RBAC permissions

## Documentation Standards

### README Structure

```markdown
# Blueprint Name

Brief description (1-2 sentences)

## Overview

Detailed explanation of what the blueprint does

## What You Get

- Bullet list of resources created
- Key features
- Benefits

## Quick Start

Step-by-step deployment instructions

## Parameters

Table of all parameters with descriptions

## Examples

Links to example files with explanations

## Architecture

Diagrams or explanations of how it works

## Troubleshooting

Common issues and solutions
```

### Code Comments

- Explain **why**, not **what**
- Document non-obvious decisions
- Include links to relevant documentation

## Pull Request Guidelines

### PR Title Format

- `feat: Add new blueprint for X`
- `fix: Correct RBAC permissions for Y`
- `docs: Update README for Z`
- `refactor: Simplify W blueprint`

### PR Description

Include:
- **What**: What does this PR do?
- **Why**: Why is this change needed?
- **How**: How does it work?
- **Testing**: How was it tested?

### Checklist

- [ ] Code follows project conventions
- [ ] Documentation updated
- [ ] Examples provided
- [ ] Tested locally
- [ ] RBAC permissions added (if new API group)
- [ ] Bootstrap script updated (if needed)

## Review Process

1. Automated checks run
2. Maintainer review
3. Address feedback
4. Approval and merge

## Questions?

- Open a GitHub Issue
- Check existing documentation
- Review similar blueprints

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.
