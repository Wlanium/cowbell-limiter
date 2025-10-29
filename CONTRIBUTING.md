# Contributing to Cowbell Limiter

First off, thanks for taking the time to contribute! 🎉🔔

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples**
- **Describe the behavior you observed and what you expected**
- **Include logs and error messages**
- **Specify your environment:**
  - Mailcow version
  - Docker/docker-compose version
  - OS and version
  - Bash version (`bash --version`)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description of the proposed enhancement**
- **Explain why this enhancement would be useful**
- **List potential implementation approaches**

### Pull Requests

- Fork the repo and create your branch from `main`
- Test your changes thoroughly
- Update documentation if needed
- Follow the existing code style
- Write clear commit messages
- Include examples if adding new features

## Development Guidelines

### Code Style

- Use 3-space indentation (to match existing code)
- Keep lines under 120 characters where reasonable
- Use descriptive variable names
- Add comments for complex logic
- Use consistent error handling

### Testing

Before submitting a PR, test your changes:

1. **With `--dry-run`**: Ensure no unintended changes
2. **On a test Mailcow instance**: Verify actual functionality
3. **Different installation paths**: Test auto-detection
4. **Edge cases**: Missing files, invalid input, etc.

### Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit first line to 72 characters
- Reference issues and pull requests when relevant

Example:
```
Add support for custom SMTP ports

- Detect non-standard Postfix ports
- Update port 588 detection logic
- Add tests for custom port configurations

Fixes #123
```

## Project Structure

```
cowbell-limiter/
├── set_message_size.sh    # Main script
├── README.md              # Documentation
├── LICENSE                # MIT License
├── CHANGELOG.md           # Version history
├── CONTRIBUTING.md        # This file
└── .gitignore            # Git ignore rules
```

## Questions?

Feel free to open an issue for questions or join discussions!

## Code of Conduct

Be respectful, constructive, and professional. We're all here to make Mailcow administration easier!

---

**Thank you for contributing to Cowbell Limiter!** 🔔
