## AKS Migration Demos

#### Info
* Original repo. https://github.com/spring-projects/spring-petclinic
* Full lab. https://github.com/appdevgbb/mm-springboot-petclinic-to-aks-automatic-ignite/blob/main/lab.md 

#### Local Setup

* Install openjdk-25
`brew install openjdk@25`

* Run local
    ```
    git clone https://github.com/spring-projects/spring-petclinic.git 

    cp -r ./spring-petclinic ./spring-petclinic-2

    cd spring-petclinic
    ./mvnw package
    java -jar target/*.jar
    ```

* Deploy AKS
    ```
    export RG=briar-aks
    export CLUSTERNAME=briar-aks
    export K8SVERSION=1.33.3
    export NODECOUNT=5
    export LOCATION=westus3

    az group create --name $RG --location $LOCATION

    # Standard
    az aks create \
        --resource-group $RG \
        --name $CLUSTERNAME \
        --node-count $NODECOUNT \
        --kubernetes-version $K8SVERSION \
        --location $LOCATION \
        --enable-managed-identity

    az aks get-credentials -n $CLUSTERNAME -g $RG

    # Automatic
    export CLUSTERNAME=briar-aks-auto-test

    az aks create \
        --name ${AKS_NAME} \
        --resource-group ${RG_NAME} \
        --os-sku AzureLinuxOSGuard \
        --node-osdisk-type Managed \
        --enable-fips-image \
        --enable-secure-boot \ 
        --enable-vtpm
    ```

* Deploy other Azure resources
    ```
    RESOURCE_GROUP_NAME="briar-aks"
    AKS_CLUSTER_NAME="briar-aks"
    LOCATION="westus3"
    NAME_SUFFIX=$(openssl rand -hex 4)  # Generates 8-character random suffix
    POSTGRES_SERVER_NAME="db-petclinic${NAME_SUFFIX:0:4}"
    POSTGRES_DATABASE_NAME="petclinic"
    USER_ASSIGNED_IDENTITY_NAME="mi-petclinic"
    ACR_NAME="acrpetclinic${NAME_SUFFIX:0:6}"
    ```


