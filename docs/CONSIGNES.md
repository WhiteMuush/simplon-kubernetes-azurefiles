# Brief

## Summary

Set up persistent storage on AKS by connecting **Azure Files** to the cluster
through a **StorageClass**, so that the data of a **MongoDB** database survives
the pods that use it.

Volumes are provisioned by the native AKS CSI driver (`file.csi.azure.com`) in
**NFS** mode. The Azure storage account and the networking part (private
endpoint) are set up by hand or with an IaC tool such as Terraform.

The MongoDB application is provided (a git repository to fork): everything else
is up to you.

Every step must be documented: the documentation is part of the final
deliverable, alongside the repository. Grant access to the repository if it is
private.

## Steps

1. **Context and basics** (30min): storage on Kubernetes, the available
   backends, static versus dynamic provisioning
2. **Get hold of the AKS cluster** (30min): create a cluster, then check the
   access and the presence of the Azure Files CSI driver
   (`kubectl get pods -n kube-system | grep csi-azurefile`)
3. **Create the storage account and the Azure Files share** (1h): a Premium
   account (`FileStorage`, `Premium_LRS`) with NFS v3 enabled. This is the
   equivalent of an NFS share managed by Azure
4. **Connect the storage to the cluster** (1h30): NFS has no public endpoint,
   so create a private endpoint on the subnet of the AKS nodes, plus the
   private DNS, so that the cluster can reach the account
5. **Write the NFS StorageClass and test dynamic provisioning** (2h): write the
   StorageClass, then a 10 GB test PVC
6. **Deploy MongoDB on the PVC** (2h): apply the provided manifests, check the
   NFS mount inside the pod (`df -h /data/db`), then prove persistence: insert a
   document, delete the pod, observe that the document is still there. The
   MongoDB data can also be seen from the Azure portal

## Key notions

- StorageClass
- PersistentVolume (PV)
- PersistentVolumeClaim (PVC)

## Bonus

- The storage account is reachable only from the AKS cluster, not from the
  Internet
- Resize a volume while it is in use (the StorageClass needs
  `allowVolumeExpansion`) and observe the new size on the Azure side
- Take a snapshot of the NFS share
- Create a second StorageClass backed by **Azure Disks** (the VM disks) and
  redeploy on it
