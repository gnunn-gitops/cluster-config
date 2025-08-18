# Llamastack

To run llamastack on OpenShift, we can utlize the kubernetes svc address along with providing a configmap for the unique values we want to test.


## Building Llamastack

If you need to use a specific branch or even the main branch of the upstream Llamastack repository in your container image, you can run the following steps:

```
git clone git@github.com:meta-llama/llama-stack.git
cd llama-stack

# Create the venv to install llamastack locally
python -m venv venv
source venv/bin/activate
pip install -U .

export CONTAINER_BINARY = podman
USE_COPY_NOT_MOUNT=true LLAMA_STACK_DIR=. llama stack build --template remote-vllm --image-type container

# tag the local container image and push to quay
podman tag localhost/distribution-remote-vllm:dev quay.io/<YOUR QUAY.IO USERNAME OR ORG>/<IMAGE NAME>
podman push quay.io/<YOUR QUAY.IO USERNAME OR ORG>/<IMAGE NAME>
```

## Building Llamastack with Milvus (in-line)

If you need to build Llamastack to use Milvus as the default in-line vector db provider in your container image, you can run the following steps:

```
git clone git@github.com:meta-llama/llama-stack.git
cd llama-stack

# Create the venv to install llamastack locally
python -m venv venv
source venv/bin/activate
pip install -U .
```

Edit the `build.yaml` in the `llama_stack/template/remote-vllm/build.yaml` to update the `vector_io` provider field and `image_type` field as shown below:

```
  providers:
    vector_io:
    - inline::milvus
image_type: container
```

Now, we can build the container.

```
export CONTAINER_BINARY = podman
USE_COPY_NOT_MOUNT=true LLAMA_STACK_DIR=. llama stack build --config llama_stack/templates/remote-vllm/build.yaml --image-type container --image-name remote-vllm-milvus
```

Once the image is built successfully you can push it to quay:

```
podman tag localhost/remote-vllm-milvus:<version tag> quay.io/<YOUR QUAY.IO USERNAME OR ORG>/<IMAGE NAME>
podman push quay.io/<YOUR QUAY.IO USERNAME OR ORG/<IMAGE NAME>
```

Update the [`deployment.yaml`](https://github.com/opendatahub-io/llama-stack-demos/blob/main/kubernetes/llama-stack/deployment.yaml#L71) file using the image generated above.


## Deployment

To create the Llamastack deployment:

```
oc create --kustomize llama-stack
```

## Telemetry (distributed trace collection)

To collect Llama Stack distributed traces, follow the [observability guide](../observability/README.md)

## Access

This deployment isn't exposed so depending on where you need to access it from outside the cluster, expose it accordingly.

If you want to deploy a chat server that points to the llamastack deployment then run the following:

```
oc expose deployment/llamastack-deployment
```

If you want to access the llama-stack externally from the cluster then you must expose the svc which will create a route:

```
oc expose svc/llamastack-deployment
```

The above will generate a route with a URL unique to your cluster.

## Using the endpoints

Now that everything is available in the OpenShift cluster, you can utilize the vLLM instance and the Llamastack server by ensuring that you set the following before running your tests/experiments:

```
export INFERENCE_MODEL="meta-llama/Llama-3.2-3B-Instruct"
export LLAMA_STACK_PORT=80
export INFERENCE_ADDR=<YOUR VLLM MODEL SERVING ENDPOINT>
```

(_**NOTE:**_ The INFERENCE_ADDR will be unique to your OpenShift environment. The INFERENCE_MODEL will be the model you have chosen to deploy via vLLM)

## Testing the endpoints

To test the Llamstack server, you can run any of the examples from [here](https://github.com/opendatahub-io/llama-stack-demos/tree/main/demos/rag_agentic/src). Make sure to set the following env vars in your `.env` file before executing the scripts:

```
LLAMA_STACK_PORT=80
INFERENCE_MODEL="meta-llama/Llama-3.2-3B-Instruct"
REMOTE_BASE_URL="<YOUR LLAMASTACK ENDPOINT URL>"
# if you want to run examples that interact with an MCP server, you will need to provide the MCP server URL
REMOTE_MCP_URL="<YOUR MCP SERVER ENDPOINT URL>"
```

Once you have the env vars, defined you should be able to run the example scripts.
You can simply run a script like so:

```
python 0_simple_agent.py
```
