JAVASDK_VERSION=$(yum list java-oci-sdk | grep -o "[0-9].[0-9]\+.[0-9]\+")

# Validate Java SDK
cp -r /usr/lib64/java-oci-sdk/examples/shared .
javac -cp .:/usr/lib64/java-oci-sdk/lib/oci-java-sdk-full-$JAVASDK_VERSION.jar:/usr/lib64/java-oci-sdk/third-party/lib/* JavaSDKValidation.java
java -cp .:/usr/lib64/java-oci-sdk/lib/oci-java-sdk-full-$JAVASDK_VERSION.jar:/usr/lib64/java-oci-sdk/third-party/lib/* JavaSDKValidation

# Validate Python SDK
python3 pythonsdk-validation.py

# Validate Go SDK
go run gosdk-validation.go

# Validate terraform
terraform init
terraform apply -auto-approve 