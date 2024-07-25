# Create a custom Lambda Layer with Azure Python Modules using CloudShell

These steps provide a guide on how to create an AWS Lambda Layer populated with Azure Python Modules.  This Lambda Layer can be use to run scripts that interact with an Azure Subscription through the Azure Resource Manager APIs.  

This Lambda Layer will contain the following Modules;

* **azure-identity** - Required to authenticate with **Microsft Entra ID** and access to an Azure Subscription.
* **azure-mgmt-compute** - Required to manage Azure compute resources.
* **azure-core** - Provides shared exceptions and modules for Python SDK client libraries.

AWS Lambda uses an **Amazon Linux** environment in the backend.  We will package our Azure Python Modules into a Lambda Layer using an **Amazon Linux 2023** docker image pre-built with **`Python3.12`** runtime. Refer to [Deploy Python Lambda functions with container images](https://docs.aws.amazon.com/lambda/latest/dg/python-image.html#python-image-base) for more information.

For ease of use, we will be using **AWS CloudShell**, which comes pre-configured with Docker, to build our image and run the container which will create our Lambda Layer.

## Docker container preparation

1. Open AWS CloudShell console at <https://console.aws.amazon.com/cloudshell/home>.

2. Create a folder for project

    ```bash
    mkdir dockerimages
    cd dockerimages
    ```

3. Create a file named `dockerfile` (without any extensions) using nano

    ```bash
    nano dockerfile
    ```

4. Copy and paste the content below into the `dockerfile`. Here, we are using image for `Python3.12` runtime. For the URIs of other runtime, please see [Amazon ECR Public Gallery](https://gallery.ecr.aws/lambda/python/)

    ```text
    FROM public.ecr.aws/lambda/python:3.12

    # Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
    CMD [ "lambda_function.handler" ]
    ```

5. Save (ctrl+s) and exit Nano (ctrl+x)
6. Build docker image with docker build command

    ```bash
    docker build --platform linux/amd64 -t azure-python-lambda-layer:3.12 .
    ```

    **Note**:- If your lambda function is configured to run on arm64 environment, please change the **--platform** parameter to `linux/arm64`

7. Run a container from above image using the docker run command

    ```bash
    docker run --rm --name "azure-python" -d azure-python-lambda-layer:3.12
    ```

## Azure Python module packaging

### Connect to the Docker Container

1. To access the shell of the docker container, run the docker exec command

    ```bash
    docker exec -it "azure-python" sh
    ```

2. Install `zip` and `nano` packages

    ```bash
    dnf install nano zip -y
    ```

### Create Directory structure for the Azure Python packaging

Directory Structure to be created

```text
├── requirements.txt
└── python/
    └── lib/
        ├── python3.12/
        │   └── site-packages/
```

1. Create a Parent folder for Layers and Requirements file

    ```bash
    mkdir azure-python-lambda-layer && cd azure-python-lambda-layer
    ```

2. Create Layers folder with packaging structure allowed by lambda layers

    ```bash
    mkdir -p layer/python/lib/python3.12/site-packages
    ```

### Install your custom Python modules.

1. Create a `requirements.txt` file to install all the required Azure Python modules

    ```bash
    nano requirements.txt
    ```

2. Copy and paste content below into the `requirements.txt` file, then Save (ctrl+s) and exit Nano (ctrl+x)

    ```bash
    azure-identity
    azure-mgmt-compute
    azure-core
    ```

    This will install the latest version of each module. For specific module versions, please enter **module-name==version-number**(Example -> `azure-identity==1.15.0`)

3. Run below command to install all modules specified in the `requirements.txt` file

    ```bash
    pip3.12 install -r requirements.txt -t layer/python/lib/python3.12/site-packages
    ```

4. Zip up the Azure Python Modules into a package

    ```bash
    cd layer
    zip -r python3-azure-modules.zip *
    ```

## Export the package from the Container and download from CloudShell to your local machine

### Export the python3-azure-modules.zip from the container image

1. Exit the shell of the container **(ctrl+d)**
2. Export the zip file from the container into the home directory of the **cloudshell-user** in CloudShell

    ```bash
    docker cp azure-python:/var/task/azure-python-lambda-layer/layer/python3-azure-modules.zip /home/cloudshell-user/dockerimages
    ```

### Download the python3-azure-modules.zip from CloudShell to your Local Machine

1. From the **Actions** dropdown menu of your CloudShell session, choose **Download** file
2. Enter `/home/cloudshell-user/dockerimages/python3-azure-modules.zip` and choose **Download**

The **python3-azure-modules.zip** will now be in your downloads folder and ready for importing into a Lambda Layer. Refer to [Creating and deleting layers in Lambda](https://docs.aws.amazon.com/lambda/latest/dg/creating-deleting-layers.html) for detailed steps on creating a lambda layer with the above zip file.
