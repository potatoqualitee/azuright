# azuright

This GitHub Action automatically installs azurite (Azure Storage Emulator) on Windows, macOS and Linux.

https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azurite

Azurite provides a free local environment for testing your Azure blob, queue storage, and table storage applications. When you're satisfied with how your application is working locally, you can then switch to using an Azure Storage account in the cloud. The emulator provides cross-platform support on Windows, Linux, and macOS.

Azurite supersedes the Azure Storage Emulator. Azurite will continue to be updated to support the latest versions of Azure Storage APIs - [Microsoft docs](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azurite)

## Documentation

Just copy the code below to install and run Azure blob, queue storage, and table storage services over http.

```yaml
    - name: Install Azurite
      id: azuright
      uses: potatoqualitee/azuright@initial
```

By default, blob storage runs over port 10000, queue storage runs over port 10001 and table storage runs over port 10002.

```yaml
    - name: Install Azurite
      id: azuright
      uses: potatoqualitee/azuright@initial
      with:
        self-signed-cert: true

    - name: Test
      shell: pwsh
      run: |
        Import-Module Az.Storage
        $connstring = "${{ steps.azuright.outputs.connstring }}"
        $blob = New-Object Azure.Storage.Blobs.BlobContainerClient($connstring, "sample-container")
        $blob.CreateIfNotExists()
```

## Usage

### Pre-requisites

Create a workflow `.yml` file in your repositories `.github/workflows` directory. An [example workflow](#example-workflow) is available below. For more information, reference the GitHub Help Documentation for [Creating a workflow file](https://help.github.com/en/articles/configuring-a-workflow#creating-a-workflow-file).

### Inputs

* `directory` - The workspace location path. The default is the OS temp directory.
* `blob-port` - The Blob service listening port. The default port is 10000.
* `queue-port` - The Queue service listening port. The default port is 10001.
* `table-port` - The Table service listening port, by default 10002.
* `silent` - Silent mode disables the access log. The default value is false.
* `loose` - Enables loose mode, which ignores unsupported headers and parameters.
* `oauth` - Optional OAuth level.
* `self-signed-cert` - Create and trust a self-signed cert for `localhost` to easily enable HTTPS.
* `cert-path` - Path to a locally trusted PEM or PFX certificate file path to enable HTTPS mode.
* `cert-password` - Password for PFX file. Required when cert-path points to a PFX file.
* `cert-key-path` - Path to a locally trusted PEM key file, required when cert-path points to a PEM file.

### Outputs

* `connstring` - a usable connection string to connect to the services

### Details

Azurite accepts the same [well-known storage account and key](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azurite#well-known-storage-account-and-key) and key used by the legacy Azure Storage Emulator.

> Account name: devstoreaccount1
> Account key: Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==

If you'd like to use alternative crednetials, check out this article on [custom storage accounts and keys](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azurite#custom-storage-accounts-and-keys).

### Example workflows

In the workflow below, `Az.Storage` is installed on Linux, Windows and OSX, a self-signed cert is installed then a blob is created over https.

```yaml
on: [push]
jobs:
  test-everywhere:
    name: Test Action on all platforms
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macOS-latest]

    steps:
      - uses: actions/checkout@v2

      - name: Create variables for module cacher
        id: psmodulecache
        uses: potatoqualitee/psmodulecache@v3.5
        with:
          modules-to-cache: Az.Storage
      - name: Run module cacher action
        id: cacher
        uses: actions/cache@v2
        with:
          path: ${{ steps.psmodulecache.outputs.modulepath }}
          key: ${{ steps.psmodulecache.outputs.keygen }}
      - name: Install PowerShell modules
        if: steps.cacher.outputs.cache-hit != 'true'
        uses: potatoqualitee/psmodulecache@v3.5

      - name: Install Azurite
        id: azuright
        uses: potatoqualitee/azuright@initial
        with:
          self-signed-cert: true

      - name: Test
        shell: pwsh
        run: |
          Import-Module Az.Storage
          $connstring = "${{ steps.azuright.outputs.connstring }}"
          $blob = New-Object Azure.Storage.Blobs.BlobContainerClient($connstring, "sample-container")
          $blob.CreateIfNotExists()
```

## Contributing
Pull requests are welcome!

## License
The scripts and documentation in this project are released under the [MIT License](LICENSE)

## Notes

You can find more information about what's installed on GitHub runners on their [docs page](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners#supported-software).

