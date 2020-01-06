<#
.Synopsis
DPi30 Validation Functions

.Description
Functions to validate the naming conventions and requirements of resources created by the DPi30
#>

### Validation Functions ###
function ResourceGroupNameValidation {
    Param(
        # Name to verify
        $Name
    )
    # Resource Group name restrictions: alphanumeric characters, periods, underscores, hyphens and parenthesis and cannot end in a period, less than 90 characters
    if ($Name -cmatch "^[\w\-\.\(\)]{1,90}[^\.]$"){
        return @{Result=$true; Message="Valid"}
    } else {
        return @{Result=$false; Message="Resource Group name restrictions: alphanumeric characters, periods, underscores, hyphens and parenthesis and cannot end in a period, less than 90 characters"}
    }
}

function StorageAccountNameValidation {
    Param(
        # Name to verify
        $Name
    )
    # Storage Account name restrictions: Lower case leters or numbers, 3 to 24 characters
    if ($Name -cmatch "^[a-z0-9]{3,24}$") {
        return @{Result=$true; Message="Valid"}
    } else {
        return @{Result=$false; Message="Storage Account name restrictions: Lower case leters or numbers, 3 to 24 characters"}
    }
}

function DatabricksNameValidation {
    Param(
        # Name to verify
        $Name
    )
    # Databricks name restrictions: Alphanumeric characters, underscores, and hyphens are allowed, and the name must be 1-30 characters long.
    if ($Name -cmatch "^[\w-]{1,30}$") {
        return @{Result=$true; Message="Valid"}
    } else {
        return @{Result=$false; Message="Databricks name restrictions: Alphanumeric characters, underscores, and hyphens are allowed, and the name must be 1-30 characters long."}
    }
}

function DatabaseNameValidation {
    Param(
        # Name to verify
        $Name
    )
    # Database name restrictions: Alphanumeric characters, underscores 1-128 characters long.
    if ($Name -cmatch "^[\w]{1,128}$") {
        return @{Result=$true; Message="Valid"}
    } else {
        return @{Result=$false; Message="Database name restrictions: Alphanumeric characters, underscores 1-128 characters long."}
    }
}

function DatabaseServerNameValidation {
    Param(
        # Name to verify
        $Name
    )
    # Database Server name restrictions: Your server name can contain only lowercase letters, numbers, and '-', but can't start or end with '-' or have more than 63 characters.
    if ($Name -cmatch "^[^-][a-z0-9-]{1,63}(?<!-)$") {
        return @{Result=$true; Message="Valid"}
    } else {
        return @{Result=$false; Message="Database Server name restrictions: Your server name can contain only lowercase letters, numbers, and '-', but can't start or end with '-' or have more than 63 characters."}
    }
}

function DatabaseLoginNameValidation {
    Param(
        # Name to verify
        $Name
    )
    # Database Login name restrictions: Your login name must not include non-alphanumeric characters and must not start with numbers or symbols
    if ($Name -cmatch "^[^0-9][a-zA-Z0-9]{1,128}$") {
        return @{Result=$true; Message="Valid"}
    } else {
        return @{Result=$false; Message="Database Login name restrictions: Your login name must not include non-alphanumeric characters and must not start with numbers or symbols"}
    }
}

function DataFactoryNameValidation {
    Param(
        # Name to verify
        $Name
    )
    # Data Factory name restrictions: contain only letters, numbers and hyphens. The first and last characters must be a letter or number.
    if ($Name -cmatch "^[^-][a-zA-Z0-9]{1,128}$") {
        return @{Result=$true; Message="Valid"}
    } else {
        return @{Result=$false; Message="Data Factory name restrictions: contain only letters, numbers and hyphens. The first and last characters must be a letter or number."}
    }
}

### End Validation Functions ###