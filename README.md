# Application provisioning on an Amazon EKS cluster with ingress and monitoring capabilities using Terraform and Helm

## Technologies used

| Name | Version
| :--- | :--- 
| [terraform](https://www.terraform.io/) | ~> 1.2.2 
| [eks](https://aws.amazon.com/eks/)  | 1.22
| [kubectl](https://kubernetes.io/docs/reference/kubectl/kubectl/)  | v1.24.2
| [aws-cli](https://aws.amazon.com/cli/)  | 2.7.10
| [ingress-nginx helm chart](https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx) | 4.1.4 
| [kube-prometheus-stack helm chart](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) | 36.6.1
| [kind node image](https://kind.sigs.k8s.io/docs/design/node-image/) | kindest/node:v1.22.9
| [go](https://go.dev/) | 1.18

## Go Application
The application that will be deployed, which resides in the <code>/app</code> directory, is a simple Go web application that scrapes the Kubernetes API server and shows a dashboard with information about all running pods in its namespace.

## Amazon EKS
To provision infrastructure in the AWS cloud, the [aws-cli](https://aws.amazon.com/cli/) tool is needed, in order to configure your account's credentials. Alternatively, store them in two terraform variables named <code>AWS_ACCESS_KEY_ID</code> and <code>AWS_SECRET_ACCESS_KEY</code> and use them in all terraform directories to configure the aws provider. It is important that the latest version <code>AWS CLI version 2</code> is used, otherwise in following steps, the kubeconfig file comes with an error - it uses the invalid `apiVersion: client.authentication.k8s.io/v1alpha1` instead of the correct `apiVersion: client.authentication.k8s.io/v1beta1`.

For extra safety and isolation, the EKS cluster, the <code>ingress-nginx</code> controller and the <code>kube-prometheus-stack</code> are all managed by different directories. To further experiment and explore the terraform EKS provisioning procedure, the official EKS module was not used - instead, the EKS cluster was build with simple terraform resources (e.g. <code>aws_eks_cluster</code>, <code>aws_eks_node_group</code>, etc.).

Firstly, navigate to the <code>/eks</code> directory and deploy the eks cluster. Upon completion, the eks service will be deployed, as well as two node groups, the <code>monitoring</code> and the <code>application</code> groups. Both have a <code>group</code> label, but the first one has a <code>group=monitoring:NoSchedule</code> taint as well, so just the pods created by the <code>kube-prometheus-stack</code> helm chart will be scheduled only on these nodes. The cluster configuration will be included in the <code>${HOME}/.kube/config</code> file and will be updated every time the eks cluster changes.

To verify the correct cluster status, run for example:
```shell
kubectl get nodes --show-labels
```

Then, in the <code>/ingress-nginx</code> directory, deploy the ingress-nginx controller using Helm, specifying just two chart values regarding the controller update strategy.

After making sure that the ingress controller is in a stable state (for example, to avoid a `failed calling webhook "validate.nginx.ingress.kubernetes.io"` error), deploy the kube-prometheus-stack from the <code>/monitoring</code> directory, again using Helm. The file <code>/monitoring/values.yaml</code> contains values that create ingresses for the prometheus, grafana and alertmanager components and supply them with the node affinity rules and tolerations needed for the monitoring node group.

Lastly, the <code>/app-manifests</code> directory is responsible for the application deployment. Along with the usual configuration, an ingress resource is created in order for the app to be accessible from the <code>/app</code> route, as well as a <code>ServiceMonitor</code> resource for the app to be visible and monitored by the monitoring stack.

To find the hostname of the AWS ELB provisioned by the ingress controller, use the [kubectl](https://kubernetes.io/docs/reference/kubectl/kubectl/) tool and execute the following command:
```shell
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'
```
Alternatively, this hostname can also be found in the AWS Console in the EC2 Load balancers section.

After applying all of the above steps, the following routes are exposed:

| Name | Type
| :--- | :---
| /app | Prefix
| /monitor/prometheus | Prefix
| /monitor/grafana | Prefix
| /monitor/alertmanager | Prefix


## Local deployment with kind
To setup a local K8S cluster that mimics the one that would be deployed on AWS, navigate to the <code>/kind</code> directory
and use the configuration to deploy a [kind](https://kind.sigs.k8s.io/) cluster. For all the other directories, the only change needed is to set the variable <code>env</code> equal to <code>kind</code> (instead of the default <code>aws</code>). Everything else stays the same and all routes will ultimately be hosted at <code>localhost</code>.

---

## License
Copyright &copy; 2022 Kyriakos Tsaliagkos

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.