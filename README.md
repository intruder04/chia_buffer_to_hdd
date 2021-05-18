# chia_buffer_to_hdd
## A PowerShell script to copy Chia plots from a buffer disk to several HDDs.

Admin privileges are required. To allow script execution:

`Set-ExecutionPolicy RemoteSigned`

`$bfr_folder` contains your buffer path.

HDD destinations are defined as an array:

`$farm_hdd_destinations = @('K:\Plots','L:\Plots','I:\Plots')`

There is a free space check for the HDDs and automatic rotation (Destinations are selected consecutively)
