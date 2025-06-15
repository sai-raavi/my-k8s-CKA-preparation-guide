# Cluster Architecture Overview

A Kubernetes cluster is composed of a set of machines, called nodes. These nodes host the applications, and the control plane manages these applications.

## Control Plane (Master Node)

The Control Plane components make global decisions about the cluster (e.g., scheduling), and detect and respond to cluster events (e.g., starting up new pods when a deployment's `replicas` field is unsatisfied).

## Worker Nodes

Worker nodes run the actual containerized applications (Pods).