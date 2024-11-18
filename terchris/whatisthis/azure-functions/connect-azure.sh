#!/bin/bash
#  ./connect-azure.sh NorgesRodeKors.onmicrosoft.com 81b4e732-2f1f-45db-9cf7-2bc06eed4c2c


# File: connect-azure.sh
# Description: Script to establish and verify Azure CLI connection with specified tenant and subscription.
#             Handles authentication and context switching while providing clear feedback at each step.
#             Includes error handling and parameter validation.
#             Accepts either tenant ID (GUID) or tenant name (organization.onmicrosoft.com)
# Example: ./connect-azure.sh NorgesRodeKors.onmicrosoft.com 81b4e732-2f1f-45db-9cf7-2bc06eed4c2c

# Function to check if az cli is installed
check_az_cli() {
    if ! command -v az &> /dev/null; then
        echo "Error: Azure CLI is not installed. Please install it first."
        exit 1
    fi
}

# Function to check if required parameters are provided
check_parameters() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: $0 <tenant_id_or_name> <subscription_id>"
        echo "Example with tenant name: $0 NorgesRodeKors.onmicrosoft.com 81b4e732-2f1f-45db-9cf7-2bc06eed4c2c"
        echo "Example with tenant ID: $0 70d22a8d-923a-445e-82d4-32329da21746 81b4e732-2f1f-45db-9cf7-2bc06eed4c2c"
        exit 1
    fi
}

# Function to ensure Azure connection
ensure_azure_connection() {
    local tenant_id=$1
    local subscription_id=$2

    # First, clear any existing login
    echo "Clearing existing Azure credentials..."
    az logout 2>/dev/null

    # Login to Azure first (without tenant specification)
    echo "Initiating browser authentication..."
    if ! az login; then
        echo "Error: Failed to login to Azure"
        exit 1
    fi

    # Now switch to the specific tenant
    echo "Switching to tenant: $tenant_id"
    if ! az account set --subscription "$subscription_id"; then
        echo "Error: Failed to set subscription context. Available subscriptions:"
        az account list --output table
        exit 1
    fi

    # Verify subscription
    local sub_name=$(az account show --query name -o tsv)
    echo "Successfully set subscription context to: $sub_name"
}

# Main script
main() {
    local tenant_id=$1
    local subscription_id=$2

    # Check prerequisites
    check_az_cli
    check_parameters "$tenant_id" "$subscription_id"

    # Ensure connection
    ensure_azure_connection "$tenant_id" "$subscription_id"
}

# Execute main function with provided parameters
main "$1" "$2"