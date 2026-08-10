# cli-pomodoro

Planning artifacts:

- [Feature context](.scratch/menu-bar-pomodoro/FEATURES.md)
- [Ready-for-agent specification](.scratch/menu-bar-pomodoro/SPEC.md)
- [Domain glossary](CONTEXT.md)
- [Architecture decisions](docs/adr/)

## Package the Agent

Build a launch-at-login-compatible application bundle with:

```sh
Scripts/package-agent-app.sh release
```

The bundle is written to `.build/release/Pomo.app` by default and uses the
`com.nazakun.pomo` bundle identifier with ad-hoc Hardened Runtime signing.
