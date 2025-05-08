# Contributing to Jira-Bash

Thank you for considering contributing to Jira-Bash! This document outlines the process for contributing to the project.

## Code of Conduct

By participating in this project, you agree to abide by common open source conventions: be respectful of others, be constructive in your feedback, and focus on making the tool better for everyone.

## How Can I Contribute?

### Reporting Bugs

If you encounter a bug, please create an issue with the following information:
- Clear title and description of the bug
- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment (OS, Bash version, etc.)
- Any relevant logs or error messages

### Suggesting Enhancements

Have an idea for a new feature? Create an issue with:
- Clear title and description of your enhancement
- Use case (why this would be useful)
- Any implementation ideas you have

### Pull Requests

1. Fork the repository
2. Create a new branch for your changes
3. Make your changes
4. Test your changes thoroughly
5. Submit a pull request

## Development Guidelines

### Style Guide

- Use 4-space indentation
- Use `function name() {` style for function declarations
- Add descriptive comments for non-obvious code
- Use lowercase with underscores for variable and function names
- Use `[[ ]]` for conditional expressions
- Quote all variables that might contain spaces
- Follow existing patterns in the codebase

### Testing

Before submitting a pull request, test your changes with:

- Different Jira configurations
- Different operating systems if possible
- Edge cases and error conditions

### Documentation

Update documentation when you change functionality:

- Update README.md for user-facing changes
- Update in-script help information
- Add comments explaining complex parts of your code

## Release Process

The maintainer will:

1. Review contributions
2. Merge approved pull requests
3. Update version numbers following semantic versioning
4. Create releases with changelogs

Thank you for helping make Jira-Bash better!