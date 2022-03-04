# Bicep - Azure Storage Queue API Connection #

This code is only a sample to demonstrate the how to create a logic app connected to the Azure Queue using Bicep.

## Bicep Structure ##

The Bicep file creates the following resources:

- A Datalake Storage Account
- Datalake Blob Container
- An Azure Storage Queue
- API Connection to Storage Blob Container
- API Connection to Storage Queue
- Logic App to write the queue message into an Azure Blob Storage

## Files ##

The repository folder contains 2 files:

- main.bicep: The Bicep definition of the sample Logic App
- main.json: The ARM Template generated by the Bicep file