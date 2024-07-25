#!/bin/bash

# Create a folder for the project
mkdir -p dockerimages
cd dockerimages

# Create the Dockerfile
cat << EOF > dockerfile
FROM public.ecr.aws/lambda/python:3.12

# Set the CMD to your handler
CMD [ "lambda_function.handler" ]
EOF

# Build the Docker image
docker build --platform linux/amd64 -t azure-python-lambda-layer:3.12 .

# Run the Docker container
docker run --rm --name "azure-python" -d azure-python-lambda-layer:3.12

# Connect to the Docker container
docker exec -it "azure-python" sh -c "
    # Install required packages inside the container
    dnf install nano zip -y

    # Create the directory structure for the Lambda Layer
    mkdir -p azure-python-lambda-layer/layer/python/lib/python3.12/site-packages
    cd azure-python-lambda-layer

    # Create the requirements.txt file
    cat << EOF > requirements.txt
azure-identity
azure-mgmt-compute
azure-core
EOF

    # Install the Azure Python modules
    pip3.12 install -r requirements.txt -t layer/python/lib/python3.12/site-packages

    # Zip the Python modules
    cd layer
    zip -r python3-azure-modules.zip *
"

# Export the zip file from the container
docker cp azure-python:/var/task/azure-python-lambda-layer/layer/python3-azure-modules.zip /home/cloudshell-user/dockerimages

# Download the zip file from CloudShell
echo "Please download the '/home/cloudshell-user/dockerimages/python3-azure-modules.zip' file from the CloudShell file browser."
