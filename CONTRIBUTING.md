# Contributing to Fangorn Sentinel

Thank you for your interest in contributing to Fangorn Sentinel! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Test-Driven Development](#test-driven-development)
- [Code Style](#code-style)
- [Submitting Changes](#submitting-changes)
- [Release Process](#release-process)

## Code of Conduct

By participating in this project, you agree to:
- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive feedback
- Assume good intentions

## Getting Started

### Prerequisites

**Backend Development**:
- Elixir 1.17.3+
- Erlang/OTP 27+
- PostgreSQL 14+
- Docker & Docker Compose

**iOS Development**:
- macOS with Xcode 15+
- Swift 5.9+
- CocoaPods

**Android Development**:
- Android Studio
- JDK 17+
- Android SDK 34+

### Local Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/notifd/fangorn_sentinel.git
   cd fangorn_sentinel
   ```

2. **Backend setup**:
   ```bash
   # Start Docker services
   docker-compose up -d

   # Install dependencies
   cd backend
   mix deps.get

   # Create and migrate database
   mix ecto.setup

   # Run tests
   mix test

   # Start server
   mix phx.server
   ```

3. **iOS setup**:
   ```bash
   cd mobile/ios/Sentinel
   pod install
   open Sentinel.xcworkspace
   ```

4. **Android setup**:
   ```bash
   cd mobile/android
   ./gradlew assembleDebug
   ```

## Development Workflow

### Finding Work

1. Check [open issues](https://github.com/notifd/fangorn_sentinel/issues)
2. Look for issues labeled `good first issue` or `help wanted`
3. Review the [project milestones](https://github.com/notifd/fangorn_sentinel/milestones)
4. Comment on the issue to let others know you're working on it

### Branch Naming

- `feature/issue-{number}-{short-description}` - New features
- `fix/issue-{number}-{short-description}` - Bug fixes
- `docs/issue-{number}-{short-description}` - Documentation
- `refactor/issue-{number}-{short-description}` - Code refactoring

Examples:
- `feature/issue-42-add-slack-notifications`
- `fix/issue-123-alert-deduplication-bug`

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat(alerts): add Grafana webhook support

Implements webhook endpoint to receive alerts from Grafana AlertManager.
Includes payload parsing, validation, and alert creation.

Closes #42
```

## Test-Driven Development

**TDD IS MANDATORY** for all code changes. No exceptions.

### The TDD Cycle

1. **🔴 RED**: Write a failing test
   ```elixir
   test "creates alert from Grafana payload" do
     payload = %{...}
     assert {:ok, alert} = Alerts.create_from_grafana(payload)
     assert alert.title == "High CPU Usage"
   end
   ```

2. **🟢 GREEN**: Write minimal code to make it pass
   ```elixir
   def create_from_grafana(payload) do
     # Minimal implementation
     attrs = %{title: payload["alertname"]}
     create_alert(attrs)
   end
   ```

3. **♻️ REFACTOR**: Clean up while keeping tests green
   ```elixir
   def create_from_grafana(payload) do
     attrs = parse_grafana_payload(payload)
     create_alert(attrs)
   end

   defp parse_grafana_payload(payload) do
     # Extracted and cleaned up
   end
   ```

### Test Coverage

- Minimum **80% test coverage** required
- All new features must include tests
- All bug fixes must include regression tests

### Running Tests

**Backend**:
```bash
cd backend
mix test                    # Run all tests
mix test --cover           # With coverage report
mix test path/to/test.exs  # Run specific test file
```

**iOS**:
```bash
cd mobile/ios/Sentinel
xcodebuild test -scheme Sentinel -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Android**:
```bash
cd mobile/android
./gradlew test
./gradlew connectedAndroidTest  # UI tests
```

## Code Style

### Elixir/Phoenix

- Follow the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- Use `mix format` before committing
- Run `mix credo --strict` for linting
- Maximum line length: 120 characters

### Swift

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftLint
- Use SwiftFormat for automatic formatting

### Kotlin

- Follow [Kotlin Coding Conventions](https://kotlinlang.org/docs/coding-conventions.html)
- Use Android Studio's built-in formatter
- Maximum line length: 120 characters

### Documentation

- Add module documentation for all public modules
- Add function documentation for all public functions
- Include examples in documentation when helpful
- Keep README and docs up to date

## Submitting Changes

### Before Submitting

- [ ] All tests passing
- [ ] Code formatted correctly
- [ ] No linting errors
- [ ] Test coverage maintained (>80%)
- [ ] Documentation updated
- [ ] JOURNAL.md updated (for significant changes)

### Pull Request Process

1. **Create a pull request**:
   - Link to the related issue (e.g., "Closes #42")
   - Fill out the PR template completely
   - Add screenshots for UI changes
   - Describe testing performed

2. **Code Review**:
   - At least one approval required
   - Address all review comments
   - Keep discussions focused and respectful

3. **CI Checks**:
   - All GitHub Actions must pass
   - No merge conflicts
   - Branch up to date with main

4. **Merge**:
   - Squash and merge preferred
   - Delete branch after merge

### PR Checklist

- [ ] **RED-GREEN-REFACTOR**: TDD cycle followed
- [ ] Tests added/updated
- [ ] All tests passing
- [ ] Code formatted
- [ ] No linting errors
- [ ] Documentation updated
- [ ] PR template filled out
- [ ] Linked to issue
- [ ] Screenshots added (if UI change)

## Release Process

### Versioning

We use [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes (backwards compatible)

### Release Checklist

1. Update version in `mix.exs`, `package.json`, etc.
2. Update CHANGELOG.md
3. Run full test suite
4. Create release tag
5. Build and publish artifacts
6. Update documentation

## Getting Help

- **Slack**: Join our [Slack workspace](#) (TBD)
- **Issues**: [GitHub Issues](https://github.com/notifd/fangorn_sentinel/issues)
- **Discussions**: [GitHub Discussions](https://github.com/notifd/fangorn_sentinel/discussions)
- **Email**: chaos@notifd.io

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Given credit in documentation

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to Fangorn Sentinel!** 🚀

Your contributions help make on-call management better for everyone.
