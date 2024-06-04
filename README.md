```markdown
# Azure Synapse Deployment with Terraform

This repository contains Terraform scripts to deploy a complete Azure Synapse Analytics cluster along with candidate accounts. These accounts can be shared with candidates who will connect to the Synapse workspace and use the provided datasets to solve exercises.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Connecting to Azure Synapse](#connecting-to-azure-synapse)
- [License](#license)

## Prerequisites

Before you begin, ensure you have met the following requirements:

- An Azure subscription
- [Terraform](https://www.terraform.io/downloads.html) installed on your local machine
- Azure CLI installed and configured ([Install and configure the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))

## Installation

1. Clone this repository to your local machine:

    ```sh
    git clone git@github.com:stumpyfr/de_pyspark_test.git
    cd de_pyspark_test
    ```

2. Initialize Terraform:

    ```sh
    terraform init
    ```

## Usage

### Configuration

Before deploying the infrastructure, you need to configure the variables. Create a `terraform.tfvars` file in the root directory and populate it with your Azure details and Synapse configuration:

    ```hcl
    env="" # the environment name, used to generate resource names
    location="" # the Azure region where the resources will be deployed
    owner_uuid="" # your Azure AD object ID
    tld="" # your domain name, used to generate candidate email addresses
    ```

### Deployment

To deploy the Azure Synapse cluster and candidate accounts, run the following command:

    ```sh
    terraform apply
    ```

Review the planned changes and confirm the deployment by typing `yes`.

## Connecting to Azure Synapse

Once the deployment is complete, candidate accounts will be created and their credentials will be available in the Terraform output. Candidates can connect to the Synapse workspace using these credentials to access the provided datasets and solve exercises.

### Instructions for Candidates

1. Connect to the Synapse workspace using the provided credentials.
2. Explore the available datasets and start working on the exercises (provided separately).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
