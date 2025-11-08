# Contributing to SmartCRM Backend

## Commit Message Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automated versioning and changelog generation.

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: A new feature (triggers minor version bump)
- **fix**: A bug fix (triggers patch version bump)
- **docs**: Documentation only changes
- **style**: Changes that don't affect code meaning (formatting, etc.)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvement
- **test**: Adding or updating tests
- **build**: Changes to build system or dependencies
- **ci**: Changes to CI configuration
- **chore**: Other changes that don't modify src or test files
- **revert**: Reverts a previous commit

### Breaking Changes

Add `BREAKING CHANGE:` in the commit footer or add `!` after the type to trigger a major version bump:

```
feat!: remove deprecated API endpoint

BREAKING CHANGE: The /old-api endpoint has been removed. Use /new-api instead.
```

### Examples

#### Feature
```
feat(customers): add pagination support

- Implement limit and offset parameters
- Add total count in response
- Update API documentation
```

#### Bug Fix
```
fix(auth): correct JWT token validation

Fixes issue where expired tokens were not properly rejected
```

#### Documentation
```
docs: update API documentation with new endpoints
```

#### Breaking Change
```
feat(api)!: change customer response format

BREAKING CHANGE: Customer API now returns camelCase instead of snake_case
```

## Release Process

Releases are automated using semantic-release:

1. **Commit** your changes using conventional commit format
2. **Push** to `main` branch
3. **GitHub Actions** will:
   - Run tests
   - Build the project
   - Analyze commits
   - Determine version bump
   - Generate changelog
   - Create GitHub release
   - Update package.json version
   - Commit changes back to repo

### Version Bumps

- `fix:` → Patch (1.0.0 → 1.0.1)
- `feat:` → Minor (1.0.0 → 1.1.0)
- `BREAKING CHANGE:` → Major (1.0.0 → 2.0.0)

## Development Workflow

1. Create a feature branch: `git checkout -b feat/your-feature`
2. Make changes and commit using conventional commits
3. Push branch and create PR
4. After PR is merged to main, semantic-release will handle versioning

## Local Testing

To test semantic-release locally (dry-run):

```bash
npm run semantic-release -- --dry-run
```

This will show what version would be released without actually releasing.
