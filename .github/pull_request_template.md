## Description
Describe what this PR does and why.

### Breaking changes / Migrations
- Does this introduce breaking API changes? If yes, describe migration steps.
- DB or config migrations required? Provide commands.

### Security considerations
- Any impact to authentication, authorization, secrets, or PII?

### Deployment notes
- Any changes to CI/CD, environment variables, or required GitHub secrets?

## Type of change
- [ ] Bug fix
- [ ] Feature
- [ ] Documentation
- [ ] CI/CD
- [ ] Refactor/Chore

## Related issues
Closes #

## How to test
- [ ] `make up`
- [ ] `make smoke`
- [ ] `make e2e`
- [ ] Manual checks (list steps)
 - [ ] Gateway config validated: `make gw-config-test`
 - [ ] OpenAPI updated: `make export-openapi` (and committed)
 - [ ] Diagrams updated if architecture/flows changed: `make render-diagrams`

## Screenshots / Logs (optional)

## Checklist
- [ ] Tests pass locally (`make smoke`, `make e2e`)
- [ ] Docs updated (README/CONTRIBUTING/OpenAPI/Postman)
 - [ ] Gateway routing/limits updated if needed and validated
 - [ ] Communication/architecture diagrams updated if needed
 - [ ] Noted any deployment or secret changes
- [ ] Conventional commits format (`type(scope): message`)
- [ ] No secrets or sensitive info in code/logs
- [ ] Backwards compatibility considered (API/versioning)

## Notes for reviewers
Anything that needs special attention.
