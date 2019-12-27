# DPi30 Modern Data Warehouse Deployment Template

This template is for medium to large data estates that need to do complex analytics and transformations against their data to get true insights into their business. It is based on the architecture outlined in the [Azure Modern Data Warehouse Architecture](https://docs.microsoft.com/en-us/azure/architecture/solution-ideas/articles/modern-data-warehouse) article.

It will deploy:
* Azure Data Factory
* Azure Data Lake Gen 2
* Azure Databricks
* Azure Synapse Analytics (formerly Azure Data Warehouse)

## Getting Started
To deploy the DPi30 Modern Data Warehouse Template click the button below and fill in the required information.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcbattlegear%2Fdpi30%2Fmaster%2Fmoderndatawarehouse%2Fdpi30moderndatawarehouse.json" target ="_blank">
    <img src="https://azurecomcdn.azureedge.net/mediahandler/acomblog/media/Default/blog/deploybutton.png"></img>
</a>

## Next Steps
After deploying the template you will want to start getting data into your data warehouse and doing analytics. Here a few links to help you get started:

* [Best practices for SQL Analytics in Azure Synapse Analytics (formerly SQL DW)](https://docs.microsoft.com/en-us/azure/sql-data-warehouse/sql-data-warehouse-best-practices)
* [Data loading strategies for Azure SQL Data Warehouse](https://docs.microsoft.com/en-us/azure/sql-data-warehouse/design-elt-data-loading)
* [Create an Azure Databricks Spark cluster](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-quickstart-create-databricks-account#create-a-spark-cluster-in-databricks)
* [Run a Databricks notebook with the Databricks Notebook Activity in Azure Data Factory](https://docs.microsoft.com/en-us/azure/data-factory/transform-data-using-databricks-notebook)
