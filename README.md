# wbt_nim
 A Nim-based API for using the [WhiteboxTools](https://jblindsay.github.io/wbt_book/preface.html) geospatial data analysis library.
 WhiteboxTools contain over 400 tools for manipulating raster, vector, and LiDAR data. This API allows these tools to be called
 from a Nim coding environment.

Documentation for the API can be found [here](https://jblindsay.github.io/wbt_nim/wbt_nim.html).

Code example:

```nim
import wbt_nim
import options, strformat, strutils

proc main() =
    # Create a new WhiteboxTools object
    var wbt = newWhiteboxTools()

    # Tell the wbt object where to find the WhiteboxTools executable.
    # If you don't do this, it assumes that it is in the same directory as 
    # your Nim code.
    wbt.setExecutableDirectory("/Users/johnlindsay/Documents/programming/whitebox-tools/")

    # Set the working directory
    let wd = "/Users/johnlindsay/Documents/data/LakeErieLidar/"
    wbt.setWorkingDirectory(wd)

    # Set the verbose mode. By default it is 'true', which prints all output
    # from WBT. If you need to make it less chatty, set it to false.
    wbt.setVerboseMode(false)

    # By default, all GeoTiff outputs of tools will be compressed. You can 
    # modify this with the following:
    wbt.setCompressRasters(false)

    # Print out the version of WBT:
    echo(wbt.getVersionInfo())

    # WhiteboxTools is open-access software. If you'd like to see the source 
    # code for any tool, simply use the following:
    discard wbt.viewCode("balanceContrastEnhancement")

    # To get a brief description of a tool and it's parameters:
    echo(wbt.getToolHelp("breachDepressionsLeastCost"))

    # If you'd like to see more detailed help documentation:
    discard wbt.viewHelpPage("breachDepressionsLeastCost")
    # This will open the default browser and navigate to the relevant tool help.

    # Here's an example of how to run a tool:
    if wbt.hillshade(
        dem="90m_DEM.tif",
        output="tmp1.tif",
        azimuth=180.0,
        altitude=45.0,
        zFactor=1.0
    ) != 0:
        echo("Error while running hillshade.")

    # If you haven't previously set the working directory, you need to include
    # full file path names.

    # You can capture tool output by creating a custom callback function
    proc myCallback(value: string) =
        if not value.contains("%"):
            echo(value)
        else:
            let s = value.replace("%", "").strip()
            echo(fmt"{s} percent")

    wbt.setCallback(myCallback)
    
    # And to reset the default callback, which just prints to stdout
    wbt.setDefaultCallback()

main()