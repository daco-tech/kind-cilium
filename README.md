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

To open hubble dashboard run:
 
```bash
kubectl port-forward -n kube-system svc/hubble-ui --address 0.0.0.0 --address :: 12000:80
```

Then open the dashboard at: http://localhost:12000/


# Credits:

Kind Setup: https://kind.sigs.k8s.io/docs/user/quick-start/

Cilium install on kind: https://docs.cilium.io/en/v1.13/installation/kind/
