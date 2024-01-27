
## OS replace test

### How to run OS replace test

    ./os-replace.sh

### Required environment variables

    TEST_OS        The OS to run the tests in. Currently supported values:
                       "rhel-9-4"
                       "centos-stream-9"
                       "fedora-eln"
    ARCH           Test architecture
                       "x86_64"
                       "aarch64"

    PLATFORM       Run test on:
                       "openstack"
                       "gcp"
                       "aws"
    QUAY_USERNAME      quay.io username
    QUAY_PASSWORD      quay.io password
    DOWNLOAD_NODE      RHEL nightly compose download URL
    RHEL_REGISTRY_URL  RHEL bootc image URL
    QUAY_SECRET        Save into /etc/ostree/auth.json for authenticated registry
    GCP_PROJECT                 Google Cloud Platform project name
    GCP_SERVICE_ACCOUNT_NAME    Google Cloud Platform service account name
    GCP_SERVICE_ACCOUNT_FILE    Google Cloud Platform service account file path
    AWS_ACCESS_KEY_ID           AWS access key id
    AWS_SECRET_ACCESS_KEY       AWS secrety key
    AWS_REGION                  AWS region
