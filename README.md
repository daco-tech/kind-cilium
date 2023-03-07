# CILIUM @KIND with Hubble

This repo contains a bash script to install kind, and deploy a k8s cluster using kind and Cilium

## Pre-checks:

Ensure you do not have a kind cluster deployed.
Ensure you have git and docker installed and properly configured/working on your machine.

# How to use:

To run the script just execute:

```bash
chmod +x ./setup-kind.sh
./setup-kind.sh
```

# Credits:

Kind Setup: https://kind.sigs.k8s.io/docs/user/quick-start/
Cilium install on kind: https://docs.cilium.io/en/v1.9/gettingstarted/kind/
