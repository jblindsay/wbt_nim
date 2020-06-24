# wbt_nim
 A Nim-based API for using the [WhiteboxTools](https://jblindsay.github.io/wbt_book/preface.html) geospatial data analysis library.
 WhiteboxTools contain over 400 tools for manipulating raster, vector, and LiDAR data. This API allows these tools to be called
 from a Nim coding environment.

Documentation for the API can be found [here](https://jblindsay.github.io/wbt_nim/wbt_nim.html).

Code example:

```nim
import wbt_nim
 
when isMainModule:
  var wbt = newWhiteboxTools()
  wbt.setWorkingDirectory("/path/to/data/")
  let dem = "DigitalElevationModel.tif"

  wbt.hillshade(
  input=dem, 
    output="output.tif",
    azimuth=315.0, 
    altitude=30.0
  )