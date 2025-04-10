#!/bin/bash

# Exit on any error
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if a command succeeded
check_status() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: $1 failed${NC}"
        exit 1
    fi
}

# Function to display usage
usage() {
    echo "Usage: $0 [-f <params_file>] [-r <storage_resource_group>] [-v <vnet_resource_group>] [-l <location>] [-s <storage_account_name>] [-n <vnet_name>] [-b <subnet_name>] [-p <private_endpoint_name>] [-k <sku>] [-t <performance_tier>] [-d <dns_subscription_id>] [-g <dns_resource_group>] [-z <dns_zone_name>] [-c <container_name>] [-i <point_in_time_restore>] [-j <point_in_time_restore_days>] [-o <soft_delete_blobs>] [-q <soft_delete_blobs_days>] [-u <soft_delete_containers>] [-e <soft_delete_containers_days>] [-a <soft_delete_file_shares>] [-y <soft_delete_file_shares_days>] [-m <versioning_blobs>] [-x <blob_change_feed>] [-w <blob_change_feed_days>]"
    echo "  -f: Path to parameters file (e.g., params_dev.json)"
    echo "  Required parameters: storageResourceGroup, vnetResourceGroup, location, storageAccountName, vnetName, subnetName, privateEndpointName, sku, performanceTier, dnsSubscriptionId, dnsResourceGroup, dnsZoneName, containerNames (array)"
    echo "  Optional parameters: pointInTimeRestore, pointInTimeRestoreDays, softDeleteBlobs, softDeleteBlobsDays, softDeleteContainers, softDeleteContainersDays, softDeleteFileShares, softDeleteFileSharesDays, versioningBlobs, blobChangeFeed, blobChangeFeedDays"
    echo "  performanceTier must be 'Standard' or 'Premium'"
    echo "  Example with file: $0 -f params_dev.json"
    echo "  Example with args: $0 -r storage-rg -v vnet-rg -l eastus -s mystorage123 -n my-vnet -b my-subnet -p mystorage123-pe -k Standard_LRS -t Standard -d <dns-sub-id> -g dns-rg -z privatelink.blob.core.windows.net -c tfstate -i true -j 7"
    exit 1
}

# Capture the original subscription ID at the start
ORIGINAL_SUBSCRIPTION=$(az account show --query id -o tsv)
check_status "Capturing original subscription"

# Parse command-line arguments
while getopts "f:r:v:l:s:n:b:p:k:t:d:g:z:c:i:j:o:q:u:e:a:y:m:x:w:h" opt; do
    case $opt in
        f) PARAMS_FILE="$OPTARG";;
        r) STORAGE_RESOURCE_GROUP="$OPTARG";;
        v) VNET_RESOURCE_GROUP="$OPTARG";;
        l) LOCATION="$OPTARG";;
        s) STORAGE_ACCOUNT_NAME="$OPTARG";;
        n) VNET_NAME="$OPTARG";;
        b) SUBNET_NAME="$OPTARG";;
        p) PRIVATE_ENDPOINT_NAME="$OPTARG";;
        k) SKU="$OPTARG";;
        t) PERFORMANCE_TIER="$OPTARG";;
        d) DNS_SUBSCRIPTION_ID="$OPTARG";;
        g) DNS_RESOURCE_GROUP="$OPTARG";;
        z) DNS_ZONE_NAME="$OPTARG";;
        c) CONTAINER_NAMES="$OPTARG";;
        i) POINT_IN_TIME_RESTORE="$OPTARG";;
        j) POINT_IN_TIME_RESTORE_DAYS="$OPTARG";;
        o) SOFT_DELETE_BLOBS="$OPTARG";;
        q) SOFT_DELETE_BLOBS_DAYS="$OPTARG";;
        u) SOFT_DELETE_CONTAINERS="$OPTARG";;
        e) SOFT_DELETE_CONTAINERS_DAYS="$OPTARG";;
        a) SOFT_DELETE_FILE_SHARES="$OPTARG";;
        y) SOFT_DELETE_FILE_SHARES_DAYS="$OPTARG";;
        m) VERSIONING_BLOBS="$OPTARG";;
        x) BLOB_CHANGE_FEED="$OPTARG";;
        w) BLOB_CHANGE_FEED_DAYS="$OPTARG";;
        h) usage;;
        ?) usage;;
    esac
done

# If a parameters file is provided, load values from it (JSON format)
if [ -n "$PARAMS_FILE" ]; then
    if [ ! -f "$PARAMS_FILE" ]; then
        echo -e "${RED}Error: Parameters file '$PARAMS_FILE' not found${NC}"
        exit 1
    fi
    # Use jq to parse JSON (requires jq installed)
    STORAGE_RESOURCE_GROUP=$(jq -r '.storageResourceGroup // empty' "$PARAMS_FILE")
    VNET_RESOURCE_GROUP=$(jq -r '.vnetResourceGroup // empty' "$PARAMS_FILE")
    LOCATION=$(jq -r '.location // empty' "$PARAMS_FILE")
    STORAGE_ACCOUNT_NAME=$(jq -r '.storageAccountName // empty' "$PARAMS_FILE")
    VNET_NAME=$(jq -r '.vnetName // empty' "$PARAMS_FILE")
    SUBNET_NAME=$(jq -r '.subnetName // empty' "$PARAMS_FILE")
    PRIVATE_ENDPOINT_NAME=$(jq -r '.privateEndpointName // empty' "$PARAMS_FILE")
    SKU=$(jq -r '.sku // empty' "$PARAMS_FILE")
    PERFORMANCE_TIER=$(jq -r '.performanceTier // empty' "$PARAMS_FILE")
    DNS_SUBSCRIPTION_ID=$(jq -r '.dnsSubscriptionId // empty' "$PARAMS_FILE")
    DNS_RESOURCE_GROUP=$(jq -r '.dnsResourceGroup // empty' "$PARAMS_FILE")
    DNS_ZONE_NAME=$(jq -r '.dnsZoneName // empty' "$PARAMS_FILE")
    # Parse containerNames as an array
    CONTAINER_NAMES=$(jq -r '.containerNames[]' "$PARAMS_FILE" | tr '\n' ' ')
    POINT_IN_TIME_RESTORE=$(jq -r '.pointInTimeRestore // empty' "$PARAMS_FILE")
    POINT_IN_TIME_RESTORE_DAYS=$(jq -r '.pointInTimeRestoreDays // empty' "$PARAMS_FILE")
    SOFT_DELETE_BLOBS=$(jq -r '.softDeleteBlobs // empty' "$PARAMS_FILE")
    SOFT_DELETE_BLOBS_DAYS=$(jq -r '.softDeleteBlobsDays // empty' "$PARAMS_FILE")
    SOFT_DELETE_CONTAINERS=$(jq -r '.softDeleteContainers // empty' "$PARAMS_FILE")
    SOFT_DELETE_CONTAINERS_DAYS=$(jq -r '.softDeleteContainersDays // empty' "$PARAMS_FILE")
    SOFT_DELETE_FILE_SHARES=$(jq -r '.softDeleteFileShares // empty' "$PARAMS_FILE")
    SOFT_DELETE_FILE_SHARES_DAYS=$(jq -r '.softDeleteFileSharesDays // empty' "$PARAMS_FILE")
    VERSIONING_BLOBS=$(jq -r '.versioningBlobs // empty' "$PARAMS_FILE")
    BLOB_CHANGE_FEED=$(jq -r '.blobChangeFeed // empty' "$PARAMS_FILE")
    BLOB_CHANGE_FEED_DAYS=$(jq -r '.blobChangeFeedDays // empty' "$PARAMS_FILE")
fi

# Validate all required parameters are set
for var in STORAGE_RESOURCE_GROUP VNET_RESOURCE_GROUP LOCATION STORAGE_ACCOUNT_NAME VNET_NAME SUBNET_NAME PRIVATE_ENDPOINT_NAME SKU PERFORMANCE_TIER DNS_SUBSCRIPTION_ID DNS_RESOURCE_GROUP DNS_ZONE_NAME CONTAINER_NAMES; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}Error: Missing required parameter: $var${NC}"
        usage
    fi
done

# Validate performanceTier is either Standard or Premium
if [ "$PERFORMANCE_TIER" != "Standard" ] && [ "$PERFORMANCE_TIER" != "Premium" ]; then
    echo -e "${RED}Error: performanceTier must be 'Standard' or 'Premium', got '$PERFORMANCE_TIER'${NC}"
    usage
fi

# Set defaults for optional boolean parameters if not provided
POINT_IN_TIME_RESTORE=${POINT_IN_TIME_RESTORE:-false}
SOFT_DELETE_BLOBS=${SOFT_DELETE_BLOBS:-false}
SOFT_DELETE_CONTAINERS=${SOFT_DELETE_CONTAINERS:-false}
SOFT_DELETE_FILE_SHARES=${SOFT_DELETE_FILE_SHARES:-false}
VERSIONING_BLOBS=${VERSIONING_BLOBS:-false}
BLOB_CHANGE_FEED=${BLOB_CHANGE_FEED:-false}

# Derived variables
DNS_RECORD_NAME="${STORAGE_ACCOUNT_NAME}"

echo -e "${GREEN}Starting deployment with the following settings:${NC}"
echo "Original Subscription: $ORIGINAL_SUBSCRIPTION"
echo "Storage Resource Group: $STORAGE_RESOURCE_GROUP"
echo "VNet Resource Group: $VNET_RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "VNet Name: $VNET_NAME"
echo "Subnet Name: $SUBNET_NAME"
echo "Private Endpoint: $PRIVATE_ENDPOINT_NAME"
echo "SKU: $SKU"
echo "Performance Tier: $PERFORMANCE_TIER"
echo "DNS Subscription: $DNS_SUBSCRIPTION_ID"
echo "DNS Resource Group: $DNS_RESOURCE_GROUP"
echo "DNS Zone: $DNS_ZONE_NAME"
echo "Containers: $CONTAINER_NAMES"
echo "Point-in-Time Restore: $POINT_IN_TIME_RESTORE (${POINT_IN_TIME_RESTORE_DAYS:-N/A} days)"
echo "Soft Delete Blobs: $SOFT_DELETE_BLOBS (${SOFT_DELETE_BLOBS_DAYS:-N/A} days)"
echo "Soft Delete Containers: $SOFT_DELETE_CONTAINERS (${SOFT_DELETE_CONTAINERS_DAYS:-N/A} days)"
echo "Soft Delete File Shares: $SOFT_DELETE_FILE_SHARES (${SOFT_DELETE_FILE_SHARES_DAYS:-N/A} days)"
echo "Versioning Blobs: $VERSIONING_BLOBS"
echo "Blob Change Feed: $BLOB_CHANGE_FEED (${BLOB_CHANGE_FEED_DAYS:-N/A} days)"

# Step 1: Deploy the storage account with private endpoint
echo "Creating storage account: $STORAGE_ACCOUNT_NAME in $STORAGE_RESOURCE_GROUP"
az storage account create \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$STORAGE_RESOURCE_GROUP" \
    --location "$LOCATION" \
    --kind "StorageV2" \
    --access-tier "Hot" \
    --min-tls-version "TLS1_2" \
    --require-infrastructure-encryption \
    --https-only true \
    --allow-blob-public-access false \
    --allow-shared-key-access true \
    --sku "$SKU" \
    --default-action "Deny" \
    --bypass "AzureServices" \
    --output none
check_status "Storage account creation"

# Configure blob service properties
echo "Configuring blob service properties"
az storage account blob-service-properties update \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$STORAGE_RESOURCE_GROUP" \
    --enable-restore-policy "$POINT_IN_TIME_RESTORE" \
    $( [ "$POINT_IN_TIME_RESTORE" = "true" ] && [ -n "$POINT_IN_TIME_RESTORE_DAYS" ] && echo "--restore-days $POINT_IN_TIME_RESTORE_DAYS" ) \
    --enable-delete-retention "$SOFT_DELETE_BLOBS" \
    $( [ "$SOFT_DELETE_BLOBS" = "true" ] && [ -n "$SOFT_DELETE_BLOBS_DAYS" ] && echo "--delete-retention-days $SOFT_DELETE_BLOBS_DAYS" ) \
    --enable-container-delete-retention "$SOFT_DELETE_CONTAINERS" \
    $( [ "$SOFT_DELETE_CONTAINERS" = "true" ] && [ -n "$SOFT_DELETE_CONTAINERS_DAYS" ] && echo "--container-delete-retention-days $SOFT_DELETE_CONTAINERS_DAYS" ) \
    --enable-versioning "$VERSIONING_BLOBS" \
    --enable-change-feed "$BLOB_CHANGE_FEED" \
    $( [ "$BLOB_CHANGE_FEED" = "true" ] && [ -n "$BLOB_CHANGE_FEED_DAYS" ] && echo "--change-feed-days $BLOB_CHANGE_FEED_DAYS" ) \
    --output none
check_status "Blob service properties update"

# Configure file service properties for file share soft delete
if [ "$SOFT_DELETE_FILE_SHARES" = "true" ] && [ -n "$SOFT_DELETE_FILE_SHARES_DAYS" ]; then
    echo "Configuring file service properties"
    az storage account file-service-properties update \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$STORAGE_RESOURCE_GROUP" \
        --enable-delete-retention "$SOFT_DELETE_FILE_SHARES" \
        --delete-retention-days "$SOFT_DELETE_FILE_SHARES_DAYS" \
        --output none
    check_status "File service properties update"
fi

echo "Creating private endpoint for storage account with VNet: $VNET_NAME, Subnet: $SUBNET_NAME in $VNET_RESOURCE_GROUP"
az network private-endpoint create \
    --name "$PRIVATE_ENDPOINT_NAME" \
    --resource-group "$VNET_RESOURCE_GROUP" \
    --vnet-name "$VNET_NAME" \
    --subnet "$SUBNET_NAME" \
    --private-connection-resource-id "$(az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$STORAGE_RESOURCE_GROUP" --query id -o tsv)" \
    --group-id "blob" \
    --connection-name "${STORAGE_ACCOUNT_NAME}-plink" \
    --location "$LOCATION" \
    --output none
check_status "Private endpoint creation"

echo "Retrieving private endpoint IP"
PRIVATE_ENDPOINT_IP=$(az network private-endpoint show \
    --name "$PRIVATE_ENDPOINT_NAME" \
    --resource-group "$VNET_RESOURCE_GROUP" \
    --query "customDnsConfigs[0].ipAddresses[0]" -o tsv)
check_status "Private endpoint IP retrieval"
echo "Private Endpoint IP: $PRIVATE_ENDPOINT_IP"

# Skip network rule addition since private endpoint handles access
echo "Skipping network rule addition as private endpoint is configured"

# Step 2: Create DNS A record in the private DNS zone in another subscription
echo "Creating DNS A record in subscription $DNS_SUBSCRIPTION_ID"
az account set --subscription "$DNS_SUBSCRIPTION_ID"
check_status "Switching to DNS subscription"

RECORD_EXISTS=$(az network private-dns record-set a show \
    --resource-group "$DNS_RESOURCE_GROUP" \
    --zone-name "$DNS_ZONE_NAME" \
    --name "$DNS_RECORD_NAME" \
    --query "id" -o tsv 2>/dev/null || echo "")
if [ -n "$RECORD_EXISTS" ]; then
    echo "Updating existing A record"
    az network private-dns record-set a update \
        --resource-group "$DNS_RESOURCE_GROUP" \
        --zone-name "$DNS_ZONE_NAME" \
        --name "$DNS_RECORD_NAME" \
        --set "aRecords[0].ipv4Address=$PRIVATE_ENDPOINT_IP" \
        --output none
    check_status "A record update"
else
    echo "Creating new A record"
    az network private-dns record-set a create \
        --resource-group "$DNS_RESOURCE_GROUP" \
        --zone-name "$DNS_ZONE_NAME" \
        --name "$DNS_RECORD_NAME" \
        --ttl 3600 \
        --output none
    check_status "A record creation"
    az network private-dns record-set a add-record \
        --resource-group "$DNS_RESOURCE_GROUP" \
        --zone-name "$DNS_ZONE_NAME" \
        --record-set-name "$DNS_RECORD_NAME" \
        --ipv4-address "$PRIVATE_ENDPOINT_IP" \
        --output none
    check_status "A record IP addition"
fi

echo "Switching back to original subscription: $ORIGINAL_SUBSCRIPTION"
az account set --subscription "$ORIGINAL_SUBSCRIPTION"
check_status "Switching back to original subscription"

# Step 3: Create storage containers for Terraform state
echo "Creating storage containers: $CONTAINER_NAMES"
for CONTAINER_NAME in $CONTAINER_NAMES; do
    echo "Creating container: $CONTAINER_NAME"
    az storage container create \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --name "$CONTAINER_NAME" \
        --public-access "off" \
        --auth-mode login \
        --output none
    check_status "Storage container creation ($CONTAINER_NAME)"
done

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Private Endpoint IP: $PRIVATE_ENDPOINT_IP"
echo "DNS A Record: $DNS_RECORD_NAME.$DNS_ZONE_NAME"
echo "Containers: $CONTAINER_NAMES"