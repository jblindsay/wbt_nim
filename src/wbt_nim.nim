import browsers, json, options, os, osproc, streams, strformat, strutils

## This library provides an application programming interface (API) 
## into the WhiteboxTools library. WhiteboxTools is an advanced geospatial 
## data analysis platform created by Prof. John Lindsay at the University 
## of Guelph's Geomorphometry and Hydrogeomatics Research Group (GHRG). 
## For more details, see the [WhiteboxTools User Manual](https://jblindsay.github.io/wbt_book/intro.html)
## The WhiteboxTools [executable](https://github.com/jblindsay/whitebox-tools/releases)
## must be copied into the same folder as this code.
## 
## .. code-block:: nim
##   import wbt_nim
## 
##   when isMainModule:
##     var wbt = newWhiteboxTools()
##     wbt.setWorkingDirectory("/path/to/data/")
##     let dem = "DigitalElevationModel.tif"
##
##     if wbt.hillshade(
##       input=dem, 
##       output="output.tif",
##       azimuth=315.0, 
##       altitude=30.0
##     ) != 0:
##         echo("ERROR running hillshade")

proc defaultCallback(line: string) =
    echo(line)

type WhiteboxTools = object of RootObj
    exePath: string
    workingDirectory: string
    verbose: bool
    compressRasters: bool
    cancelOp: bool
    callbackFunc: proc(line: string)

proc newWhiteboxTools*(): WhiteboxTools =
    ## Creates a new WhiteboxTools object to interface with the
    ## WhiteboxTools library. The working directory is initially set
    ## to the current directory. The WhiteboxTools executable is
    ## assumed to be within the same directory as this application.
    var exePath = os.getAppDir()
    let workingDirectory = os.getCurrentDir()
    result = WhiteboxTools(
        exePath: exePath, 
        workingDirectory: workingDirectory, 
        verbose: true, 
        compressRasters: true,
        cancelOp: false, 
        callbackFunc: defaultCallback
    )

proc setWorkingDirectory*(self: var WhiteboxTools, wd: string) = 
    ## Sets the working directory, i.e. the directory in which
    ## the data files are located. By setting the working 
    ## directory, tool input parameters that are files need only
    ## specify the file name rather than the complete file path.
    self.workingDirectory = wd

proc getWorkingDirectory*(self: WhiteboxTools): string = 
    ## Returns the current working directory.
    self.workingDirectory

proc setExecutableDirectory*(self: var WhiteboxTools, dir: string) = 
    ## Sets the directory to the WhiteboxTools executable file.
    self.exePath = dir

proc getExecutableDirectory*(self: WhiteboxTools): string = 
    ## Returns the directory to the WhiteboxTools executable file.
    self.exePath

proc setVerboseMode*(self: var WhiteboxTools, val: bool) = 
    ## Sets verbose mode. If verbose mode is false, tools will not
    ## print output messages. Tools will frequently provide substantial
    ## feedback while they are operating, e.g. updating progress for 
    ## various sub-routines. When the user has scripted a workflow
    ## that ties many tools in sequence, this level of tool output
    ## can be problematic. By setting verbose mode to false, these
    ## messages are suppressed and tools run as background processes.
    self.verbose = val

proc getVerboseMode*(self: WhiteboxTools): bool = 
    ## Returns the current verbose mode.
    self.verbose

proc setCallback*(self: var WhiteboxTools, callback: proc(line:string)) = 
    ## Sets the callback used for handling tool text outputs.
    self.callbackFunc = callback

proc setDefaultCallback*(self: var WhiteboxTools) = 
    ## Sets the callback used for handling tool text outputs to the 
    ## default, which simply prints any tool output to stdout.
    self.callbackFunc = defaultCallback

proc setCompressRasters*(self: var WhiteboxTools, val: bool) = 
    ## Sets the flag used by WhiteboxTools to determine whether to 
    ## use compression for output rasters. This is only valid for
    ## GeoTIFF tool outputs.
    self.compressRasters = val

proc getCompressRasters*(self: WhiteboxTools): bool = 
    ## Returns the current compress raster flag value.
    self.compressRasters

proc setCancelOp*(self: var WhiteboxTools, val: bool) = 
    ## Sets the cancel flag.
    self.cancelOp = val

proc getCancelOp*(self: WhiteboxTools): bool = 
    ## Returns the current cancel flag value.
    self.cancelOp

proc getLicense*(self: WhiteboxTools): string = 
    ## Retrieves the license information for WhiteboxTools.
    result = execProcess(fmt"{self.exePath}whitebox_tools", args=["--license"], options={poUsePath})
    
proc getVersionInfo*(self: WhiteboxTools): string =
    ## Retrieves the version information for WhiteboxTools.
    result = execProcess(fmt"{self.exePath}whitebox_tools", args=["--version"], options={poUsePath})

proc help*(self: WhiteboxTools): string =
    ## Retrieves the help description for WhiteboxTools.
    result = execProcess(fmt"{self.exePath}whitebox_tools", args=["-h"], options={poUsePath})

proc listTools*(self: WhiteboxTools): string =
    ## Returns a listing of each available tool and a brief tool 
    ## description for each entry.
    result = execProcess(fmt"{self.exePath}whitebox_tools", args=["--listtools"], options={poUsePath})

proc getToolHelp*(self: WhiteboxTools, toolName: string): string =
    ## Retrieves the help description for a specific tool.
    result = execProcess(fmt"{self.exePath}whitebox_tools", args=[fmt"--toolhelp={toolName}"], options={poUsePath})

proc getToolParameters*(self: WhiteboxTools, toolName: string): string =
    ## Retrieves the tool parameter descriptions for a specific tool.
    result = execProcess(fmt"{self.exePath}whitebox_tools", args=[fmt"--toolparameters={toolName}"], options={poUsePath})

proc getToolbox*(self: WhiteboxTools, toolName: string): string =
    ## Retrieves the tool parameter descriptions for a specific tool.
    let tb = execProcess(fmt"{self.exePath}whitebox_tools", args=[fmt"--toolbox={toolName}"], options={poUsePath})
    result = tb.strip()

proc viewCode*(self: WhiteboxTools, toolName: string): string =
    ## Returns and navigates to the URL of the source code for a specific tool
    ## on the projects source code repository. 
    let tn = fmt"{toolName[0].toUpperAscii()}{toolName[1..<len(toolName)]}"
    let cp = execProcess(fmt"{self.exePath}whitebox_tools", args=[fmt"--viewcode={tn}"], options={poUsePath})
    result = cp.strip()
    openDefaultBrowser(result)

proc viewHelpPage*(self: WhiteboxTools, toolName: string): string =
    ## Returns and navigates to the URL of the help within the user manual
    ## for a specific tool on the projects source code repository. 
    let tn = fmt"{toolName[0].toUpperAscii()}{toolName[1..<len(toolName)]}"
    let d = "https://jblindsay.github.io/wbt_book/available_tools/"
    var toolbox = self.getToolbox(tn).replace(" ", "_").replace("/", "_").toLowerAscii()
    if toolbox == "math_and_stats_tools":
        toolbox = "mathand_stats_tools"
    result = fmt"{d}{toolbox}.html#{tn}"
    openDefaultBrowser(result)

proc runTool(self: var WhiteboxTools, toolName: string, toolArgs: seq[string]): byte =
    #[ 
    Runs a tool and specifies tool arguments.
    Returns 0 if completes without error.
    Returns 1 if error encountered (details are sent to callback).
    Returns 2 if process is cancelled by user.
    ]#
    try:
        let cmd = self.exePath & "whitebox_tools"

        var args = newSeq[string]()
        args.add(fmt"--wd={self.workingDirectory}")
        
        if self.verbose:
            args.add("-v")

        if self.compressRasters:
            args.add("--compress_rasters")
        
        args.add(fmt"-r={toolName}")

        for a in toolArgs:
            if len(a) > 0:
                args.add(a)

        if self.verbose:
            echo(fmt"./whitebox_tools {args}")

        # let outp = execProcess(fmt"{exePath}whitebox_tools", args=args, options={poUsePath})
        # echo outp

        var p = startProcess(command=cmd, args=args, options={poStdErrToStdOut, poUsePath})
        defer: close(p)
        let sub = outputStream(p)
        while true:
            let line = readLine(sub)
            if self.verbose and len(line) > 0:
                self.callbackFunc(line)
            if self.cancelOp:
                p.terminate()
                self.cancelOp = false
                return 2
        
        return 0
        
    except IOError: # as e:
        discard # Do nothing. The end of the process always throughs an I/O error, and I don't know why.
        return 0
    except:
        echo(fmt"Unknown error while running tool {toolName}")
        return 1

converter toOption*[T](x:T):Option[T] =
    ## This is necessary for optional parameters that don't have default values.
    some(x)

proc absoluteValue*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Calculates the absolute value of every cell in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#AbsoluteValue) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("AbsoluteValue", args)

proc adaptiveFilter*(self: var WhiteboxTools, input: string, output: string, filterx: int = 11, filtery: int = 11, threshold: float = 2.0): byte =
    ## Performs an adaptive filter on an image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#AdaptiveFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    ## - threshold: Difference from mean threshold, in standard deviations.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    args.add(fmt"--threshold={threshold}")
    result = self.runTool("AdaptiveFilter", args)

proc add*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## Performs an addition operation on two rasters or a raster and a constant value.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Add) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file or constant value.
    ## - input2: Input raster file or constant value.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("Add", args)

proc addPointCoordinatesToTable*(self: var WhiteboxTools, input: string): byte =
    ## Modifies the attribute table of a point vector by adding fields containing each point's X and Y coordinates.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#AddPointCoordinatesToTable) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector Points file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    result = self.runTool("AddPointCoordinatesToTable", args)

proc aggregateRaster*(self: var WhiteboxTools, input: string, output: string, agg_factor: int = 2, type_val: string = "mean"): byte =
    ## Aggregates a raster to a lower resolution.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#AggregateRaster) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - agg_factor: Aggregation factor, in pixels.
    ## - type_val: Statistic used to fill output pixels.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--agg_factor={agg_factor}")
    args.add(fmt"--type_val={type_val}")
    result = self.runTool("AggregateRaster", args)

proc And*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## Performs a logical AND operator on two Boolean raster images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#And) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file.
    ## - input2: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("And", args)

proc anova*(self: var WhiteboxTools, input: string, features: string, output: string): byte =
    ## Performs an analysis of variance (ANOVA) test on a raster dataset.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Anova) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - features: Feature definition (or class) raster.
    ## - output: Output HTML file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--features={features}")
    args.add(fmt"--output={output}")
    result = self.runTool("Anova", args)

proc arcCos*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the inverse cosine (arccos) of each values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#ArcCos) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("ArcCos", args)

proc arcSin*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the inverse sine (arcsin) of each values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#ArcSin) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("ArcSin", args)

proc arcTan*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the inverse tangent (arctan) of each values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#ArcTan) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("ArcTan", args)

proc arcosh*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the inverse hyperbolic cosine (arcosh) of each values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Arcosh) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Arcosh", args)

proc arsinh*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the inverse hyperbolic sine (arsinh) of each values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Arsinh) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Arsinh", args)

proc artanh*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the inverse hyperbolic tangent (arctanh) of each values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Artanh) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Artanh", args)

proc asciiToLas*(self: var WhiteboxTools, inputs: string, pattern: string, proj: string = ""): byte =
    ## Converts one or more ASCII files containing LiDAR points into LAS files.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#AsciiToLas) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input LiDAR  ASCII files (.csv).
    ## - pattern: Input field pattern.
    ## - proj: Well-known-text string or EPSG code describing projection.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--pattern={pattern}")
    args.add(fmt"--proj={proj}")
    result = self.runTool("AsciiToLas", args)

proc aspect*(self: var WhiteboxTools, dem: string, output: string, zfactor: float = 1.0): byte =
    ## Calculates an aspect raster from an input DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#Aspect) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - zfactor: Optional multiplier for when the vertical and horizontal units are not the same.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--zfactor={zfactor}")
    result = self.runTool("Aspect", args)

proc atan2*(self: var WhiteboxTools, input_y: string, input_x: string, output: string): byte =
    ## Returns the 2-argument inverse tangent (atan2).
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Atan2) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input_y: Input y raster file or constant value (rise).
    ## - input_x: Input x raster file or constant value (run).
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input_y={input_y}")
    args.add(fmt"--input_x={input_x}")
    args.add(fmt"--output={output}")
    result = self.runTool("Atan2", args)

proc attributeCorrelation*(self: var WhiteboxTools, input: string, output: string = ""): byte =
    ## Performs a correlation analysis on attribute fields from a vector database.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#AttributeCorrelation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    ## - output: Output HTML file (default name will be based on input file if unspecified).
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("AttributeCorrelation", args)

proc attributeCorrelationNeighbourhoodAnalysis*(self: var WhiteboxTools, input: string, field1: string, field2: string, radius = none(float), min_points = none(int), stat: string = "pearson"): byte =
    ## Performs a correlation on two input vector attributes within a neighbourhood search windows.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#AttributeCorrelationNeighbourhoodAnalysis) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    ## - field1: First input field name (dependent variable) in attribute table.
    ## - field2: Second input field name (independent variable) in attribute table.
    ## - radius: Search Radius (in map units).
    ## - min_points: Minimum number of points.
    ## - stat: Correlation type; one of 'pearson' (default) and 'spearman'.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--field1={field1}")
    args.add(fmt"--field2={field2}")
    if radius.isSome:
        args.add(fmt"--radius={radius}")
    if min_points.isSome:
        args.add(fmt"--min_points={min_points}")
    args.add(fmt"--stat={stat}")
    result = self.runTool("AttributeCorrelationNeighbourhoodAnalysis", args)

proc attributeHistogram*(self: var WhiteboxTools, input: string, field: string, output: string): byte =
    ## Creates a histogram for the field values of a vector's attribute table.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#AttributeHistogram) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - field: Input field name in attribute table.
    ## - output: Output HTML file (default name will be based on input file if unspecified).
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--field={field}")
    args.add(fmt"--output={output}")
    result = self.runTool("AttributeHistogram", args)

proc attributeScattergram*(self: var WhiteboxTools, input: string, fieldx: string, fieldy: string, output: string, trendline: bool = false): byte =
    ## Creates a scattergram for two field values of a vector's attribute table.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#AttributeScattergram) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - fieldx: Input field name in attribute table for the x-axis.
    ## - fieldy: Input field name in attribute table for the y-axis.
    ## - output: Output HTML file (default name will be based on input file if unspecified).
    ## - trendline: Draw the trendline.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--fieldx={fieldx}")
    args.add(fmt"--fieldy={fieldy}")
    args.add(fmt"--output={output}")
    args.add(fmt"--trendline={trendline}")
    result = self.runTool("AttributeScattergram", args)

proc averageFlowpathSlope*(self: var WhiteboxTools, dem: string, output: string): byte =
    ## Measures the average slope gradient from each grid cell to all upslope divide cells.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#AverageFlowpathSlope) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    result = self.runTool("AverageFlowpathSlope", args)

proc averageNormalVectorAngularDeviation*(self: var WhiteboxTools, dem: string, output: string, filter: int = 11): byte =
    ## Calculates the circular variance of aspect at a scale for a DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#AverageNormalVectorAngularDeviation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - filter: Size of the filter kernel.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filter={filter}")
    result = self.runTool("AverageNormalVectorAngularDeviation", args)

proc averageOverlay*(self: var WhiteboxTools, inputs: string, output: string): byte =
    ## Calculates the average for each grid cell from a group of raster images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#AverageOverlay) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--output={output}")
    result = self.runTool("AverageOverlay", args)

proc averageUpslopeFlowpathLength*(self: var WhiteboxTools, dem: string, output: string): byte =
    ## Measures the average length of all upslope flowpaths draining each grid cell.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#AverageUpslopeFlowpathLength) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    result = self.runTool("AverageUpslopeFlowpathLength", args)

proc balanceContrastEnhancement*(self: var WhiteboxTools, input: string, output: string, band_mean: float = 100.0): byte =
    ## Performs a balance contrast enhancement on a colour-composite image of multispectral data.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_image_enhancement.html#BalanceContrastEnhancement) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input colour composite image file.
    ## - output: Output raster file.
    ## - band_mean: Band mean value.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--band_mean={band_mean}")
    result = self.runTool("BalanceContrastEnhancement", args)

proc basins*(self: var WhiteboxTools, d8_pntr: string, output: string, esri_pntr: bool = false): byte =
    ## Identifies drainage basins that drain to the DEM edge.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#Basins) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    result = self.runTool("Basins", args)

proc bilateralFilter*(self: var WhiteboxTools, input: string, output: string, sigma_dist: float = 0.75, sigma_int: float = 1.0): byte =
    ## A bilateral filter is an edge-preserving smoothing filter introduced by Tomasi and Manduchi (1998).
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#BilateralFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - sigma_dist: Standard deviation in distance in pixels.
    ## - sigma_int: Standard deviation in intensity in pixels.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--sigma_dist={sigma_dist}")
    args.add(fmt"--sigma_int={sigma_int}")
    result = self.runTool("BilateralFilter", args)

proc blockMaximumGridding*(self: var WhiteboxTools, input: string, field: string, use_z: bool = false, output: string, cell_size = none(float), base: string = ""): byte =
    ## Creates a raster grid based on a set of vector points and assigns grid values using a block maximum scheme.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#BlockMaximumGridding) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector Points file.
    ## - field: Input field name in attribute table.
    ## - use_z: Use z-coordinate instead of field?
    ## - output: Output raster file.
    ## - cell_size: Optionally specified cell size of output raster. Not used when base raster is specified.
    ## - base: Optionally specified input base raster file. Not used when a cell size is specified.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--field={field}")
    args.add(fmt"--use_z={use_z}")
    args.add(fmt"--output={output}")
    if cell_size.isSome:
        args.add(fmt"--cell_size={cell_size}")
    args.add(fmt"--base={base}")
    result = self.runTool("BlockMaximumGridding", args)

proc blockMinimumGridding*(self: var WhiteboxTools, input: string, field: string, use_z: bool = false, output: string, cell_size = none(float), base: string = ""): byte =
    ## Creates a raster grid based on a set of vector points and assigns grid values using a block minimum scheme.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#BlockMinimumGridding) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector Points file.
    ## - field: Input field name in attribute table.
    ## - use_z: Use z-coordinate instead of field?
    ## - output: Output raster file.
    ## - cell_size: Optionally specified cell size of output raster. Not used when base raster is specified.
    ## - base: Optionally specified input base raster file. Not used when a cell size is specified.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--field={field}")
    args.add(fmt"--use_z={use_z}")
    args.add(fmt"--output={output}")
    if cell_size.isSome:
        args.add(fmt"--cell_size={cell_size}")
    args.add(fmt"--base={base}")
    result = self.runTool("BlockMinimumGridding", args)

proc boundaryShapeComplexity*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Calculates the complexity of the boundaries of raster polygons.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_patch_shape_tools.html#BoundaryShapeComplexity) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("BoundaryShapeComplexity", args)

proc breachDepressions*(self: var WhiteboxTools, dem: string, output: string, max_depth = none(float), max_length = none(float), flat_increment = none(float), fill_pits: bool = false): byte =
    ## Breaches all of the depressions in a DEM using Lindsay's (2016) algorithm. This should be preferred over depression filling in most cases.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#BreachDepressions) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - max_depth: Optional maximum breach depth (default is Inf).
    ## - max_length: Optional maximum breach channel length (in grid cells; default is Inf).
    ## - flat_increment: Optional elevation increment applied to flat areas.
    ## - fill_pits: Optional flag indicating whether to fill single-cell pits.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    if max_depth.isSome:
        args.add(fmt"--max_depth={max_depth}")
    if max_length.isSome:
        args.add(fmt"--max_length={max_length}")
    if flat_increment.isSome:
        args.add(fmt"--flat_increment={flat_increment}")
    args.add(fmt"--fill_pits={fill_pits}")
    result = self.runTool("BreachDepressions", args)

proc breachDepressionsLeastCost*(self: var WhiteboxTools, dem: string, output: string, dist: int, max_cost = none(float), min_dist: bool = true, flat_increment = none(float), fill: bool = true): byte =
    ## Breaches the depressions in a DEM using a least-cost pathway method.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#BreachDepressionsLeastCost) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - dist: Maximum search distance for breach paths in cells.
    ## - max_cost: Optional maximum breach cost (default is Inf).
    ## - min_dist: Optional flag indicating whether to minimize breach distances.
    ## - flat_increment: Optional elevation increment applied to flat areas.
    ## - fill: Optional flag indicating whether to fill any remaining unbreached depressions.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--dist={dist}")
    if max_cost.isSome:
        args.add(fmt"--max_cost={max_cost}")
    args.add(fmt"--min_dist={min_dist}")
    if flat_increment.isSome:
        args.add(fmt"--flat_increment={flat_increment}")
    args.add(fmt"--fill={fill}")
    result = self.runTool("BreachDepressionsLeastCost", args)

proc breachSingleCellPits*(self: var WhiteboxTools, dem: string, output: string): byte =
    ## Removes single-cell pits from an input DEM by breaching.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#BreachSingleCellPits) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    result = self.runTool("BreachSingleCellPits", args)

proc bufferRaster*(self: var WhiteboxTools, input: string, output: string, size: float, gridcells = none(bool)): byte =
    ## Maps a distance-based buffer around each non-background (non-zero/non-nodata) grid cell in an input image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_distance_tools.html#BufferRaster) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - size: Buffer size.
    ## - gridcells: Optional flag to indicate that the 'size' threshold should be measured in grid cells instead of the default map units.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--size={size}")
    if gridcells.isSome:
        args.add(fmt"--gridcells={gridcells}")
    result = self.runTool("BufferRaster", args)

proc burnStreamsAtRoads*(self: var WhiteboxTools, dem: string, streams: string, roads: string, output: string, width = none(float)): byte =
    ## Burns-in streams at the sites of road embankments.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#BurnStreamsAtRoads) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster digital elevation model (DEM) file.
    ## - streams: Input vector streams file.
    ## - roads: Input vector roads file.
    ## - output: Output raster file.
    ## - width: Maximum road embankment width, in map units
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--roads={roads}")
    args.add(fmt"--output={output}")
    if width.isSome:
        args.add(fmt"--width={width}")
    result = self.runTool("BurnStreamsAtRoads", args)

proc ceil*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the smallest (closest to negative infinity) value that is greater than or equal to the values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Ceil) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Ceil", args)

proc centroid*(self: var WhiteboxTools, input: string, output: string, text_output: bool): byte =
    ## Calculates the centroid, or average location, of raster polygon objects.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#Centroid) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - text_output: Optional text output.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--text_output={text_output}")
    result = self.runTool("Centroid", args)

proc centroidVector*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Identifes the centroid point of a vector polyline or polygon feature or a group of vector points.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#CentroidVector) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    ## - output: Output vector file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("CentroidVector", args)

proc changeVectorAnalysis*(self: var WhiteboxTools, date1: string, date2: string, magnitude: string, direction: string): byte =
    ## Performs a change vector analysis on a two-date multi-spectral dataset.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#ChangeVectorAnalysis) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - date1: Input raster files for the earlier date.
    ## - date2: Input raster files for the later date.
    ## - magnitude: Output vector magnitude raster file.
    ## - direction: Output vector Direction raster file.
    var args = newSeq[string]()
    args.add(fmt"--date1={date1}")
    args.add(fmt"--date2={date2}")
    args.add(fmt"--magnitude={magnitude}")
    args.add(fmt"--direction={direction}")
    result = self.runTool("ChangeVectorAnalysis", args)

proc circularVarianceOfAspect*(self: var WhiteboxTools, dem: string, output: string, filter: int = 11): byte =
    ## Calculates the circular variance of aspect at a scale for a DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#CircularVarianceOfAspect) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - filter: Size of the filter kernel.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filter={filter}")
    result = self.runTool("CircularVarianceOfAspect", args)

proc classifyBuildingsInLidar*(self: var WhiteboxTools, input: string, buildings: string, output: string): byte =
    ## Reclassifies a LiDAR points that lie within vector building footprints.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#ClassifyBuildingsInLidar) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - buildings: Input vector polygons file.
    ## - output: Output LiDAR file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--buildings={buildings}")
    args.add(fmt"--output={output}")
    result = self.runTool("ClassifyBuildingsInLidar", args)

proc classifyOverlapPoints*(self: var WhiteboxTools, input: string, output: string, resolution: float = 2.0, filter: bool = false): byte =
    ## Classifies or filters LAS points in regions of overlapping flight lines.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#ClassifyOverlapPoints) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output LiDAR file.
    ## - resolution: The size of the square area used to evaluate nearby points in the LiDAR data.
    ## - filter: Filter out points from overlapping flightlines? If false, overlaps will simply be classified.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--resolution={resolution}")
    args.add(fmt"--filter={filter}")
    result = self.runTool("ClassifyOverlapPoints", args)

proc cleanVector*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Removes null features and lines/polygons with fewer than the required number of vertices.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#CleanVector) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    ## - output: Output vector file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("CleanVector", args)

proc clip*(self: var WhiteboxTools, input: string, clip: string, output: string): byte =
    ## Extract all the features, or parts of features, that overlap with the features of the clip vector.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#Clip) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    ## - clip: Input clip polygon vector file.
    ## - output: Output vector file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--clip={clip}")
    args.add(fmt"--output={output}")
    result = self.runTool("Clip", args)

proc clipLidarToPolygon*(self: var WhiteboxTools, input: string, polygons: string, output: string): byte =
    ## Clips a LiDAR point cloud to a vector polygon or polygons.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#ClipLidarToPolygon) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - polygons: Input vector polygons file.
    ## - output: Output LiDAR file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--polygons={polygons}")
    args.add(fmt"--output={output}")
    result = self.runTool("ClipLidarToPolygon", args)

proc clipRasterToPolygon*(self: var WhiteboxTools, input: string, polygons: string, output: string, maintain_dimensions: bool = false): byte =
    ## Clips a raster to a vector polygon.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#ClipRasterToPolygon) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - polygons: Input vector polygons file.
    ## - output: Output raster file.
    ## - maintain_dimensions: Maintain input raster dimensions?
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--polygons={polygons}")
    args.add(fmt"--output={output}")
    args.add(fmt"--maintain_dimensions={maintain_dimensions}")
    result = self.runTool("ClipRasterToPolygon", args)

proc closing*(self: var WhiteboxTools, input: string, output: string, filterx: int = 11, filtery: int = 11): byte =
    ## A closing is a mathematical morphology operation involving an erosion (min filter) of a dilation (max filter) set.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#Closing) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    result = self.runTool("Closing", args)

proc clump*(self: var WhiteboxTools, input: string, output: string, diag: bool = true, zero_back: bool): byte =
    ## Groups cells that form discrete areas, assigning them unique identifiers.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#Clump) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - diag: Flag indicating whether diagonal connections should be considered.
    ## - zero_back: Flag indicating whether zero values should be treated as a background.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--diag={diag}")
    args.add(fmt"--zero_back={zero_back}")
    result = self.runTool("Clump", args)

proc compactnessRatio*(self: var WhiteboxTools, input: string): byte =
    ## Calculates the compactness ratio (A/P), a measure of shape complexity, for vector polygons.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_patch_shape_tools.html#CompactnessRatio) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector polygon file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    result = self.runTool("CompactnessRatio", args)

proc conservativeSmoothingFilter*(self: var WhiteboxTools, input: string, output: string, filterx: int = 3, filtery: int = 3): byte =
    ## Performs a conservative-smoothing filter on an image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#ConservativeSmoothingFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    result = self.runTool("ConservativeSmoothingFilter", args)

proc constructVectorTIN*(self: var WhiteboxTools, input: string, field: string = "", use_z: bool = false, output: string, max_triangle_edge_length = none(float)): byte =
    ## Creates a vector triangular irregular network (TIN) for a set of vector points.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#ConstructVectorTIN) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector points file.
    ## - field: Input field name in attribute table.
    ## - use_z: Use the 'z' dimension of the Shapefile's geometry instead of an attribute field?
    ## - output: Output vector polygon file.
    ## - max_triangle_edge_length: Optional maximum triangle edge length; triangles larger than this size will not be gridded.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--field={field}")
    args.add(fmt"--use_z={use_z}")
    args.add(fmt"--output={output}")
    if max_triangle_edge_length.isSome:
        args.add(fmt"--max_triangle_edge_length={max_triangle_edge_length}")
    result = self.runTool("ConstructVectorTIN", args)

proc contoursFromPoints*(self: var WhiteboxTools, input: string, field: string = "", use_z: bool = false, output: string, max_triangle_edge_length = none(float), interval: float = 10.0, base: float = 0.0, smooth: int = 5): byte =
    ## Creates a contour coverage from a set of input points.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#ContoursFromPoints) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector points file.
    ## - field: Input field name in attribute table.
    ## - use_z: Use the 'z' dimension of the Shapefile's geometry instead of an attribute field?
    ## - output: Output vector lines file.
    ## - max_triangle_edge_length: Optional maximum triangle edge length; triangles larger than this size will not be gridded.
    ## - interval: Contour interval.
    ## - base: Base contour height.
    ## - smooth: Smoothing filter size (in num. points), e.g. 3, 5, 7, 9, 11...
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--field={field}")
    args.add(fmt"--use_z={use_z}")
    args.add(fmt"--output={output}")
    if max_triangle_edge_length.isSome:
        args.add(fmt"--max_triangle_edge_length={max_triangle_edge_length}")
    args.add(fmt"--interval={interval}")
    args.add(fmt"--base={base}")
    args.add(fmt"--smooth={smooth}")
    result = self.runTool("ContoursFromPoints", args)

proc contoursFromRaster*(self: var WhiteboxTools, input: string, output: string, interval: float = 10.0, base: float = 0.0, smooth: int = 9, tolerance: float = 10.0): byte =
    ## Derives a vector contour coverage from a raster surface.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#ContoursFromRaster) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input surface raster file.
    ## - output: Output vector contour file.
    ## - interval: Contour interval.
    ## - base: Base contour height.
    ## - smooth: Smoothing filter size (in num. points), e.g. 3, 5, 7, 9, 11...
    ## - tolerance: Tolerance factor, in degrees (0-45); determines generalization level.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--interval={interval}")
    args.add(fmt"--base={base}")
    args.add(fmt"--smooth={smooth}")
    args.add(fmt"--tolerance={tolerance}")
    result = self.runTool("ContoursFromRaster", args)

proc convertNodataToZero*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Converts nodata values in a raster to zero.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#ConvertNodataToZero) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("ConvertNodataToZero", args)

proc convertRasterFormat*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Converts raster data from one format to another.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#ConvertRasterFormat) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("ConvertRasterFormat", args)

proc cornerDetection*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Identifies corner patterns in boolean images using hit-and-miss pattern matching.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#CornerDetection) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input boolean image.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("CornerDetection", args)

proc correctVignetting*(self: var WhiteboxTools, input: string, pp: string, output: string, focal_length: float = 304.8, image_width: float = 228.6, n: float = 4.0): byte =
    ## Corrects the darkening of images towards corners.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_image_enhancement.html#CorrectVignetting) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - pp: Input principal point file.
    ## - output: Output raster file.
    ## - focal_length: Camera focal length, in millimeters.
    ## - image_width: Distance between photograph edges, in millimeters.
    ## - n: The 'n' parameter.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--pp={pp}")
    args.add(fmt"--output={output}")
    args.add(fmt"--focal_length={focal_length}")
    args.add(fmt"--image_width={image_width}")
    args.add(fmt"-n={n}")
    result = self.runTool("CorrectVignetting", args)

proc cos*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the cosine (cos) of each values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Cos) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Cos", args)

proc cosh*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the hyperbolic cosine (cosh) of each values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Cosh) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Cosh", args)

proc costAllocation*(self: var WhiteboxTools, source: string, backlink: string, output: string): byte =
    ## Identifies the source cell to which each grid cell is connected by a least-cost pathway in a cost-distance analysis.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_distance_tools.html#CostAllocation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - source: Input source raster file.
    ## - backlink: Input backlink raster file generated by the cost-distance tool.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--source={source}")
    args.add(fmt"--backlink={backlink}")
    args.add(fmt"--output={output}")
    result = self.runTool("CostAllocation", args)

proc costDistance*(self: var WhiteboxTools, source: string, cost: string, out_accum: string, out_backlink: string): byte =
    ## Performs cost-distance accumulation on a cost surface and a group of source cells.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_distance_tools.html#CostDistance) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - source: Input source raster file.
    ## - cost: Input cost (friction) raster file.
    ## - out_accum: Output cost accumulation raster file.
    ## - out_backlink: Output backlink raster file.
    var args = newSeq[string]()
    args.add(fmt"--source={source}")
    args.add(fmt"--cost={cost}")
    args.add(fmt"--out_accum={out_accum}")
    args.add(fmt"--out_backlink={out_backlink}")
    result = self.runTool("CostDistance", args)

proc costPathway*(self: var WhiteboxTools, destination: string, backlink: string, output: string, zero_background: bool): byte =
    ## Performs cost-distance pathway analysis using a series of destination grid cells.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_distance_tools.html#CostPathway) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - destination: Input destination raster file.
    ## - backlink: Input backlink raster file generated by the cost-distance tool.
    ## - output: Output cost pathway raster file.
    ## - zero_background: Flag indicating whether zero values should be treated as a background.
    var args = newSeq[string]()
    args.add(fmt"--destination={destination}")
    args.add(fmt"--backlink={backlink}")
    args.add(fmt"--output={output}")
    args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("CostPathway", args)

proc countIf*(self: var WhiteboxTools, inputs: string, output: string, value: float): byte =
    ## Counts the number of occurrences of a specified value in a cell-stack of rasters.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#CountIf) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - output: Output raster file.
    ## - value: Search value (e.g. countif value = 5.0).
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--output={output}")
    args.add(fmt"--value={value}")
    result = self.runTool("CountIf", args)

proc createColourComposite*(self: var WhiteboxTools, red: string, green: string, blue: string, opacity: string = "", output: string, enhance: bool = true, zeros: bool = false): byte =
    ## Creates a colour-composite image from three bands of multispectral imagery.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#CreateColourComposite) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - red: Input red band image file.
    ## - green: Input green band image file.
    ## - blue: Input blue band image file.
    ## - opacity: Input opacity band image file (optional).
    ## - output: Output colour composite file.
    ## - enhance: Optional flag indicating whether a balance contrast enhancement is performed.
    ## - zeros: Optional flag to indicate if zeros are nodata values.
    var args = newSeq[string]()
    args.add(fmt"--red={red}")
    args.add(fmt"--green={green}")
    args.add(fmt"--blue={blue}")
    args.add(fmt"--opacity={opacity}")
    args.add(fmt"--output={output}")
    args.add(fmt"--enhance={enhance}")
    args.add(fmt"--zeros={zeros}")
    result = self.runTool("CreateColourComposite", args)

proc createHexagonalVectorGrid*(self: var WhiteboxTools, input: string, output: string, width: float, orientation: string = "horizontal"): byte =
    ## Creates a hexagonal vector grid.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#CreateHexagonalVectorGrid) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input base file.
    ## - output: Output vector polygon file.
    ## - width: The grid cell width.
    ## - orientation: Grid Orientation, 'horizontal' or 'vertical'.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--width={width}")
    args.add(fmt"--orientation={orientation}")
    result = self.runTool("CreateHexagonalVectorGrid", args)

proc createPlane*(self: var WhiteboxTools, base: string, output: string, gradient: float = 15.0, aspect: float = 90.0, constant: float = 0.0): byte =
    ## Creates a raster image based on the equation for a simple plane.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#CreatePlane) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - base: Input base raster file.
    ## - output: Output raster file.
    ## - gradient: Slope gradient in degrees (-85.0 to 85.0).
    ## - aspect: Aspect (direction) in degrees clockwise from north (0.0-360.0).
    ## - constant: Constant value.
    var args = newSeq[string]()
    args.add(fmt"--base={base}")
    args.add(fmt"--output={output}")
    args.add(fmt"--gradient={gradient}")
    args.add(fmt"--aspect={aspect}")
    args.add(fmt"--constant={constant}")
    result = self.runTool("CreatePlane", args)

proc createRectangularVectorGrid*(self: var WhiteboxTools, input: string, output: string, width: float, height: float, xorig: float = 0, yorig: float = 0): byte =
    ## Creates a rectangular vector grid.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#CreateRectangularVectorGrid) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input base file.
    ## - output: Output vector polygon file.
    ## - width: The grid cell width.
    ## - height: The grid cell height.
    ## - xorig: The grid origin x-coordinate.
    ## - yorig: The grid origin y-coordinate.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--width={width}")
    args.add(fmt"--height={height}")
    args.add(fmt"--xorig={xorig}")
    args.add(fmt"--yorig={yorig}")
    result = self.runTool("CreateRectangularVectorGrid", args)

proc crispnessIndex*(self: var WhiteboxTools, input: string, output: string = ""): byte =
    ## Calculates the Crispness Index, which is used to quantify how crisp (or conversely how fuzzy) a probability image is.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#CrispnessIndex) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Optional output html file (default name will be based on input file if unspecified).
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("CrispnessIndex", args)

proc crossTabulation*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## Performs a cross-tabulation on two categorical images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#CrossTabulation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file 1.
    ## - input2: Input raster file 1.
    ## - output: Output HTML file (default name will be based on input file if unspecified).
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("CrossTabulation", args)

proc csvPointsToVector*(self: var WhiteboxTools, input: string, output: string, xfield: int = 0, yfield: int = 1, epsg = none(int)): byte =
    ## Converts a CSV text file to vector points.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#CsvPointsToVector) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input CSV file (i.e. source of data to be imported).
    ## - output: Output vector file.
    ## - xfield: X field number (e.g. 0 for first field).
    ## - yfield: Y field number (e.g. 1 for second field).
    ## - epsg: EPSG projection (e.g. 2958).
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--xfield={xfield}")
    args.add(fmt"--yfield={yfield}")
    if epsg.isSome:
        args.add(fmt"--epsg={epsg}")
    result = self.runTool("CsvPointsToVector", args)

proc cumulativeDistribution*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Converts a raster image to its cumulative distribution function.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#CumulativeDistribution) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("CumulativeDistribution", args)

proc d8FlowAccumulation*(self: var WhiteboxTools, input: string, output: string, out_type: string = "cells", log = none(bool), clip = none(bool), pntr = none(bool), esri_pntr: bool = false): byte =
    ## Calculates a D8 flow accumulation raster from an input DEM or flow pointer.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#D8FlowAccumulation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster DEM or D8 pointer file.
    ## - output: Output raster file.
    ## - out_type: Output type; one of 'cells' (default), 'catchment area', and 'specific contributing area'.
    ## - log: Optional flag to request the output be log-transformed.
    ## - clip: Optional flag to request clipping the display max by 1%.
    ## - pntr: Is the input raster a D8 flow pointer rather than a DEM?
    ## - esri_pntr: Input  D8 pointer uses the ESRI style scheme.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--out_type={out_type}")
    if log.isSome:
        args.add(fmt"--log={log}")
    if clip.isSome:
        args.add(fmt"--clip={clip}")
    if pntr.isSome:
        args.add(fmt"--pntr={pntr}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    result = self.runTool("D8FlowAccumulation", args)

proc d8MassFlux*(self: var WhiteboxTools, dem: string, loading: string, efficiency: string, absorption: string, output: string): byte =
    ## Performs a D8 mass flux calculation.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#D8MassFlux) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - loading: Input loading raster file.
    ## - efficiency: Input efficiency raster file.
    ## - absorption: Input absorption raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--loading={loading}")
    args.add(fmt"--efficiency={efficiency}")
    args.add(fmt"--absorption={absorption}")
    args.add(fmt"--output={output}")
    result = self.runTool("D8MassFlux", args)

proc d8Pointer*(self: var WhiteboxTools, dem: string, output: string, esri_pntr: bool = false): byte =
    ## Calculates a D8 flow pointer raster from an input DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#D8Pointer) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    result = self.runTool("D8Pointer", args)

proc dInfFlowAccumulation*(self: var WhiteboxTools, input: string, output: string, out_type: string = "Specific Contributing Area", threshold = none(float), log = none(bool), clip = none(bool), pntr = none(bool)): byte =
    ## Calculates a D-infinity flow accumulation raster from an input DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#DInfFlowAccumulation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster DEM or D-infinity pointer file.
    ## - output: Output raster file.
    ## - out_type: Output type; one of 'cells', 'sca' (default), and 'ca'.
    ## - threshold: Optional convergence threshold parameter, in grid cells; default is inifinity.
    ## - log: Optional flag to request the output be log-transformed.
    ## - clip: Optional flag to request clipping the display max by 1%.
    ## - pntr: Is the input raster a D-infinity flow pointer rather than a DEM?
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--out_type={out_type}")
    if threshold.isSome:
        args.add(fmt"--threshold={threshold}")
    if log.isSome:
        args.add(fmt"--log={log}")
    if clip.isSome:
        args.add(fmt"--clip={clip}")
    if pntr.isSome:
        args.add(fmt"--pntr={pntr}")
    result = self.runTool("DInfFlowAccumulation", args)

proc dInfMassFlux*(self: var WhiteboxTools, dem: string, loading: string, efficiency: string, absorption: string, output: string): byte =
    ## Performs a D-infinity mass flux calculation.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#DInfMassFlux) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - loading: Input loading raster file.
    ## - efficiency: Input efficiency raster file.
    ## - absorption: Input absorption raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--loading={loading}")
    args.add(fmt"--efficiency={efficiency}")
    args.add(fmt"--absorption={absorption}")
    args.add(fmt"--output={output}")
    result = self.runTool("DInfMassFlux", args)

proc dInfPointer*(self: var WhiteboxTools, dem: string, output: string): byte =
    ## Calculates a D-infinity flow pointer (flow direction) raster from an input DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#DInfPointer) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    result = self.runTool("DInfPointer", args)

proc decrement*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Decreases the values of each grid cell in an input raster by 1.0 (see also InPlaceSubtract).
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Decrement) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Decrement", args)

proc depthInSink*(self: var WhiteboxTools, dem: string, output: string, zero_background = none(bool)): byte =
    ## Measures the depth of sinks (depressions) in a DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#DepthInSink) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - zero_background: Flag indicating whether the background value of zero should be used.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    if zero_background.isSome:
        args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("DepthInSink", args)

proc devFromMeanElev*(self: var WhiteboxTools, dem: string, output: string, filterx: int = 11, filtery: int = 11): byte =
    ## Calculates deviation from mean elevation.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#DevFromMeanElev) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    result = self.runTool("DevFromMeanElev", args)

proc diffFromMeanElev*(self: var WhiteboxTools, dem: string, output: string, filterx: int = 11, filtery: int = 11): byte =
    ## Calculates difference from mean elevation (equivalent to a high-pass filter).
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#DiffFromMeanElev) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    result = self.runTool("DiffFromMeanElev", args)

proc diffOfGaussianFilter*(self: var WhiteboxTools, input: string, output: string, sigma1: float = 2.0, sigma2: float = 4.0): byte =
    ## Performs a Difference of Gaussian (DoG) filter on an image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#DiffOfGaussianFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - sigma1: Standard deviation distance in pixels.
    ## - sigma2: Standard deviation distance in pixels.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--sigma1={sigma1}")
    args.add(fmt"--sigma2={sigma2}")
    result = self.runTool("DiffOfGaussianFilter", args)

proc difference*(self: var WhiteboxTools, input: string, overlay: string, output: string): byte =
    ## Outputs the features that occur in one of the two vector inputs but not both, i.e. no overlapping features.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#Difference) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    ## - overlay: Input overlay vector file.
    ## - output: Output vector file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--overlay={overlay}")
    args.add(fmt"--output={output}")
    result = self.runTool("Difference", args)

proc directDecorrelationStretch*(self: var WhiteboxTools, input: string, output: string, k: float = 0.5, clip: float = 1.0): byte =
    ## Performs a direct decorrelation stretch enhancement on a colour-composite image of multispectral data.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_image_enhancement.html#DirectDecorrelationStretch) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input colour composite image file.
    ## - output: Output raster file.
    ## - k: Achromatic factor (k) ranges between 0 (no effect) and 1 (full saturation stretch), although typical values range from 0.3 to 0.7.
    ## - clip: Optional percent to clip the upper tail by during the stretch.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"-k={k}")
    args.add(fmt"--clip={clip}")
    result = self.runTool("DirectDecorrelationStretch", args)

proc directionalRelief*(self: var WhiteboxTools, dem: string, output: string, azimuth: float = 0.0, max_dist = none(float)): byte =
    ## Calculates relief for cells in an input DEM for a specified direction.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#DirectionalRelief) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - azimuth: Wind azimuth in degrees.
    ## - max_dist: Optional maximum search distance (unspecified if none; in xy units).
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--azimuth={azimuth}")
    if max_dist.isSome:
        args.add(fmt"--max_dist={max_dist}")
    result = self.runTool("DirectionalRelief", args)

proc dissolve*(self: var WhiteboxTools, input: string, field: string = "", output: string, snap: float = 0.0): byte =
    ## Removes the interior, or shared, boundaries within a vector polygon coverage.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#Dissolve) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    ## - field: Dissolve field attribute (optional).
    ## - output: Output vector file.
    ## - snap: Snap tolerance.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--field={field}")
    args.add(fmt"--output={output}")
    args.add(fmt"--snap={snap}")
    result = self.runTool("Dissolve", args)

proc distanceToOutlet*(self: var WhiteboxTools, d8_pntr: string, streams: string, output: string, esri_pntr: bool = false, zero_background = none(bool)): byte =
    ## Calculates the distance of stream grid cells to the channel network outlet cell.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#DistanceToOutlet) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    ## - zero_background: Flag indicating whether a background value of zero should be used.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    if zero_background.isSome:
        args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("DistanceToOutlet", args)

proc diversityFilter*(self: var WhiteboxTools, input: string, output: string, filterx: int = 11, filtery: int = 11): byte =
    ## Assigns each cell in the output grid the number of different values in a moving window centred on each grid cell in the input raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#DiversityFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    result = self.runTool("DiversityFilter", args)

proc divide*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## Performs a division operation on two rasters or a raster and a constant value.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Divide) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file or constant value.
    ## - input2: Input raster file or constant value.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("Divide", args)

proc downslopeDistanceToStream*(self: var WhiteboxTools, dem: string, streams: string, output: string): byte =
    ## Measures distance to the nearest downslope stream cell.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#DownslopeDistanceToStream) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    result = self.runTool("DownslopeDistanceToStream", args)

proc downslopeFlowpathLength*(self: var WhiteboxTools, d8_pntr: string, watersheds: string = "", weights: string = "", output: string, esri_pntr: bool = false): byte =
    ## Calculates the downslope flowpath length from each cell to basin outlet.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#DownslopeFlowpathLength) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input D8 pointer raster file.
    ## - watersheds: Optional input watershed raster file.
    ## - weights: Optional input weights raster file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--watersheds={watersheds}")
    args.add(fmt"--weights={weights}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    result = self.runTool("DownslopeFlowpathLength", args)

proc downslopeIndex*(self: var WhiteboxTools, dem: string, output: string, drop: float = 2.0, out_type: string = "tangent"): byte =
    ## Calculates the Hjerdt et al. (2004) downslope index.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#DownslopeIndex) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - drop: Vertical drop value (default is 2.0).
    ## - out_type: Output type, options include 'tangent', 'degrees', 'radians', 'distance' (default is 'tangent').
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--drop={drop}")
    args.add(fmt"--out_type={out_type}")
    result = self.runTool("DownslopeIndex", args)

proc edgeDensity*(self: var WhiteboxTools, dem: string, output: string, filter: int = 11, norm_diff: float = 5.0, zfactor: float = 1.0): byte =
    ## Calculates the density of edges, or breaks-in-slope within DEMs.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#EdgeDensity) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - filter: Size of the filter kernel.
    ## - norm_diff: Maximum difference in normal vectors, in degrees.
    ## - zfactor: Optional multiplier for when the vertical and horizontal units are not the same.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filter={filter}")
    args.add(fmt"--norm_diff={norm_diff}")
    args.add(fmt"--zfactor={zfactor}")
    result = self.runTool("EdgeDensity", args)

proc edgePreservingMeanFilter*(self: var WhiteboxTools, input: string, output: string, filter: int = 11, threshold: float): byte =
    ## Performs a simple edge-preserving mean filter on an input image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#EdgePreservingMeanFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filter: Size of the filter kernel.
    ## - threshold: Maximum difference in values.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filter={filter}")
    args.add(fmt"--threshold={threshold}")
    result = self.runTool("EdgePreservingMeanFilter", args)

proc edgeProportion*(self: var WhiteboxTools, input: string, output: string, output_text = none(bool)): byte =
    ## Calculate the proportion of cells in a raster polygon that are edge cells.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_patch_shape_tools.html#EdgeProportion) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - output_text: flag indicating whether a text report should also be output.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    if output_text.isSome:
        args.add(fmt"--output_text={output_text}")
    result = self.runTool("EdgeProportion", args)

proc elevAbovePit*(self: var WhiteboxTools, dem: string, output: string): byte =
    ## Calculate the elevation of each grid cell above the nearest downstream pit cell or grid edge cell.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#ElevAbovePit) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    result = self.runTool("ElevAbovePit", args)

proc elevPercentile*(self: var WhiteboxTools, dem: string, output: string, filterx: int = 11, filtery: int = 11, sig_digits: int = 2): byte =
    ## Calculates the elevation percentile raster from a DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#ElevPercentile) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    ## - sig_digits: Number of significant digits.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    args.add(fmt"--sig_digits={sig_digits}")
    result = self.runTool("ElevPercentile", args)

proc elevRelativeToMinMax*(self: var WhiteboxTools, dem: string, output: string): byte =
    ## Calculates the elevation of a location relative to the minimum and maximum elevations in a DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#ElevRelativeToMinMax) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    result = self.runTool("ElevRelativeToMinMax", args)

proc elevRelativeToWatershedMinMax*(self: var WhiteboxTools, dem: string, watersheds: string, output: string): byte =
    ## Calculates the elevation of a location relative to the minimum and maximum elevations in a watershed.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#ElevRelativeToWatershedMinMax) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - watersheds: Input raster watersheds file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--watersheds={watersheds}")
    args.add(fmt"--output={output}")
    result = self.runTool("ElevRelativeToWatershedMinMax", args)

proc elevationAboveStream*(self: var WhiteboxTools, dem: string, streams: string, output: string): byte =
    ## Calculates the elevation of cells above the nearest downslope stream cell.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#ElevationAboveStream) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    result = self.runTool("ElevationAboveStream", args)

proc elevationAboveStreamEuclidean*(self: var WhiteboxTools, dem: string, streams: string, output: string): byte =
    ## Calculates the elevation of cells above the nearest (Euclidean distance) stream cell.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#ElevationAboveStreamEuclidean) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    result = self.runTool("ElevationAboveStreamEuclidean", args)

proc eliminateCoincidentPoints*(self: var WhiteboxTools, input: string, output: string, tolerance: float): byte =
    ## Removes any coincident, or nearly coincident, points from a vector points file.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#EliminateCoincidentPoints) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    ## - output: Output vector polygon file.
    ## - tolerance: The distance tolerance for points.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--tolerance={tolerance}")
    result = self.runTool("EliminateCoincidentPoints", args)

proc elongationRatio*(self: var WhiteboxTools, input: string): byte =
    ## Calculates the elongation ratio for vector polygons.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_patch_shape_tools.html#ElongationRatio) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector polygon file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    result = self.runTool("ElongationRatio", args)

proc embossFilter*(self: var WhiteboxTools, input: string, output: string, direction: string = "n", clip: float = 0.0): byte =
    ## Performs an emboss filter on an image, similar to a hillshade operation.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#EmbossFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - direction: Direction of reflection; options include 'n', 's', 'e', 'w', 'ne', 'se', 'nw', 'sw'
    ## - clip: Optional amount to clip the distribution tails by, in percent.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--direction={direction}")
    args.add(fmt"--clip={clip}")
    result = self.runTool("EmbossFilter", args)

proc equalTo*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## Performs a equal-to comparison operation on two rasters or a raster and a constant value.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#EqualTo) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file or constant value.
    ## - input2: Input raster file or constant value.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("EqualTo", args)

proc erase*(self: var WhiteboxTools, input: string, erase: string, output: string): byte =
    ## Removes all the features, or parts of features, that overlap with the features of the erase vector polygon.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#Erase) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    ## - erase: Input erase polygon vector file.
    ## - output: Output vector file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--erase={erase}")
    args.add(fmt"--output={output}")
    result = self.runTool("Erase", args)

proc erasePolygonFromLidar*(self: var WhiteboxTools, input: string, polygons: string, output: string): byte =
    ## Erases (cuts out) a vector polygon or polygons from a LiDAR point cloud.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#ErasePolygonFromLidar) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - polygons: Input vector polygons file.
    ## - output: Output LiDAR file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--polygons={polygons}")
    args.add(fmt"--output={output}")
    result = self.runTool("ErasePolygonFromLidar", args)

proc erasePolygonFromRaster*(self: var WhiteboxTools, input: string, polygons: string, output: string): byte =
    ## Erases (cuts out) a vector polygon from a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#ErasePolygonFromRaster) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - polygons: Input vector polygons file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--polygons={polygons}")
    args.add(fmt"--output={output}")
    result = self.runTool("ErasePolygonFromRaster", args)

proc euclideanAllocation*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Assigns grid cells in the output raster the value of the nearest target cell in the input image, measured by the Shih and Wu (2004) Euclidean distance transform.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_distance_tools.html#EuclideanAllocation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("EuclideanAllocation", args)

proc euclideanDistance*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Calculates the Shih and Wu (2004) Euclidean distance transform.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_distance_tools.html#EuclideanDistance) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("EuclideanDistance", args)

proc exp*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the exponential (base e) of values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Exp) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Exp", args)

proc exp2*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the exponential (base 2) of values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Exp2) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Exp2", args)

proc exportTableToCsv*(self: var WhiteboxTools, input: string, output: string, headers: bool = true): byte =
    ## Exports an attribute table to a CSV text file.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#ExportTableToCsv) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    ## - output: Output raster file.
    ## - headers: Export field names as file header?
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--headers={headers}")
    result = self.runTool("ExportTableToCsv", args)

proc extendVectorLines*(self: var WhiteboxTools, input: string, output: string, dist: float, extend: string = "both ends"): byte =
    ## Extends vector lines by a specified distance.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#ExtendVectorLines) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector polyline file.
    ## - output: Output vector polyline file.
    ## - dist: The distance to extend.
    ## - extend: Extend direction, 'both ends' (default), 'line start', 'line end'.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--dist={dist}")
    args.add(fmt"--extend={extend}")
    result = self.runTool("ExtendVectorLines", args)

proc extractNodes*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Converts vector lines or polygons into vertex points.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#ExtractNodes) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector lines or polygon file.
    ## - output: Output vector points file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("ExtractNodes", args)

proc extractRasterValuesAtPoints*(self: var WhiteboxTools, inputs: string, points: string, out_text: bool = false): byte =
    ## Extracts the values of raster(s) at vector point locations.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#ExtractRasterValuesAtPoints) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - points: Input vector points file.
    ## - out_text: Output point values as text? Otherwise, the only output is to to the points file's attribute table.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--points={points}")
    args.add(fmt"--out_text={out_text}")
    result = self.runTool("ExtractRasterValuesAtPoints", args)

proc extractStreams*(self: var WhiteboxTools, flow_accum: string, output: string, threshold: float, zero_background = none(bool)): byte =
    ## Extracts stream grid cells from a flow accumulation raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#ExtractStreams) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - flow_accum: Input raster D8 flow accumulation file.
    ## - output: Output raster file.
    ## - threshold: Threshold in flow accumulation values for channelization.
    ## - zero_background: Flag indicating whether a background value of zero should be used.
    var args = newSeq[string]()
    args.add(fmt"--flow_accum={flow_accum}")
    args.add(fmt"--output={output}")
    args.add(fmt"--threshold={threshold}")
    if zero_background.isSome:
        args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("ExtractStreams", args)

proc extractValleys*(self: var WhiteboxTools, dem: string, output: string, variant: string = "LQ", line_thin: bool = true, filter: int = 5): byte =
    ## Identifies potential valley bottom grid cells based on local topolography alone.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#ExtractValleys) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - variant: Options include 'LQ' (lower quartile), 'JandR' (Johnston and Rosenfeld), and 'PandD' (Peucker and Douglas); default is 'LQ'.
    ## - line_thin: Optional flag indicating whether post-processing line-thinning should be performed.
    ## - filter: Optional argument (only used when variant='lq') providing the filter size, in grid cells, used for lq-filtering (default is 5).
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--variant={variant}")
    args.add(fmt"--line_thin={line_thin}")
    args.add(fmt"--filter={filter}")
    result = self.runTool("ExtractValleys", args)

proc fD8FlowAccumulation*(self: var WhiteboxTools, dem: string, output: string, out_type: string = "specific contributing area", exponent: float = 1.1, threshold = none(float), log = none(bool), clip = none(bool)): byte =
    ## Calculates an FD8 flow accumulation raster from an input DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#FD8FlowAccumulation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - out_type: Output type; one of 'cells', 'specific contributing area' (default), and 'catchment area'.
    ## - exponent: Optional exponent parameter; default is 1.1.
    ## - threshold: Optional convergence threshold parameter, in grid cells; default is inifinity.
    ## - log: Optional flag to request the output be log-transformed.
    ## - clip: Optional flag to request clipping the display max by 1%.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--out_type={out_type}")
    args.add(fmt"--exponent={exponent}")
    if threshold.isSome:
        args.add(fmt"--threshold={threshold}")
    if log.isSome:
        args.add(fmt"--log={log}")
    if clip.isSome:
        args.add(fmt"--clip={clip}")
    result = self.runTool("FD8FlowAccumulation", args)

proc fD8Pointer*(self: var WhiteboxTools, dem: string, output: string): byte =
    ## Calculates an FD8 flow pointer raster from an input DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#FD8Pointer) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    result = self.runTool("FD8Pointer", args)

proc farthestChannelHead*(self: var WhiteboxTools, d8_pntr: string, streams: string, output: string, esri_pntr: bool = false, zero_background = none(bool)): byte =
    ## Calculates the distance to the furthest upstream channel head for each stream cell.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#FarthestChannelHead) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    ## - zero_background: Flag indicating whether a background value of zero should be used.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    if zero_background.isSome:
        args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("FarthestChannelHead", args)

proc fastAlmostGaussianFilter*(self: var WhiteboxTools, input: string, output: string, sigma: float = 1.8): byte =
    ## Performs a fast approximate Gaussian filter on an image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#FastAlmostGaussianFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - sigma: Standard deviation distance in pixels.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--sigma={sigma}")
    result = self.runTool("FastAlmostGaussianFilter", args)

proc featurePreservingSmoothing*(self: var WhiteboxTools, dem: string, output: string, filter: int = 11, norm_diff: float = 15.0, num_iter: int = 3, max_diff: float = 0.5, zfactor: float = 1.0): byte =
    ## Reduces short-scale variation in an input DEM using a modified Sun et al. (2007) algorithm.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#FeaturePreservingSmoothing) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - filter: Size of the filter kernel.
    ## - norm_diff: Maximum difference in normal vectors, in degrees.
    ## - num_iter: Number of iterations.
    ## - max_diff: Maximum allowable absolute elevation change (optional).
    ## - zfactor: Optional multiplier for when the vertical and horizontal units are not the same.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filter={filter}")
    args.add(fmt"--norm_diff={norm_diff}")
    args.add(fmt"--num_iter={num_iter}")
    args.add(fmt"--max_diff={max_diff}")
    args.add(fmt"--zfactor={zfactor}")
    result = self.runTool("FeaturePreservingSmoothing", args)

proc fetchAnalysis*(self: var WhiteboxTools, dem: string, output: string, azimuth: float = 0.0, hgt_inc: float = 0.05): byte =
    ## Performs an analysis of fetch or upwind distance to an obstacle.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#FetchAnalysis) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - azimuth: Wind azimuth in degrees in degrees.
    ## - hgt_inc: Height increment value.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--azimuth={azimuth}")
    args.add(fmt"--hgt_inc={hgt_inc}")
    result = self.runTool("FetchAnalysis", args)

proc fillBurn*(self: var WhiteboxTools, dem: string, streams: string, output: string): byte =
    ## Burns streams into a DEM using the FillBurn (Saunders, 1999) method.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#FillBurn) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - streams: Input vector streams file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    result = self.runTool("FillBurn", args)

proc fillDepressions*(self: var WhiteboxTools, dem: string, output: string, fix_flats: bool = true, flat_increment = none(float), max_depth = none(float)): byte =
    ## Fills all of the depressions in a DEM. Depression breaching should be preferred in most cases.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#FillDepressions) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - fix_flats: Optional flag indicating whether flat areas should have a small gradient applied.
    ## - flat_increment: Optional elevation increment applied to flat areas.
    ## - max_depth: Optional maximum depression depth to fill.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--fix_flats={fix_flats}")
    if flat_increment.isSome:
        args.add(fmt"--flat_increment={flat_increment}")
    if max_depth.isSome:
        args.add(fmt"--max_depth={max_depth}")
    result = self.runTool("FillDepressions", args)

proc fillDepressionsPlanchonAndDarboux*(self: var WhiteboxTools, dem: string, output: string, fix_flats: bool = true, flat_increment = none(float)): byte =
    ## Fills all of the depressions in a DEM using the Planchon and Darboux (2002) method.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#FillDepressionsPlanchonAndDarboux) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - fix_flats: Optional flag indicating whether flat areas should have a small gradient applied.
    ## - flat_increment: Optional elevation increment applied to flat areas.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--fix_flats={fix_flats}")
    if flat_increment.isSome:
        args.add(fmt"--flat_increment={flat_increment}")
    result = self.runTool("FillDepressionsPlanchonAndDarboux", args)

proc fillDepressionsWangAndLiu*(self: var WhiteboxTools, dem: string, output: string, fix_flats: bool = true, flat_increment = none(float)): byte =
    ## Fills all of the depressions in a DEM using the Wang and Liu (2006) method. Depression breaching should be preferred in most cases.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#FillDepressionsWangAndLiu) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - fix_flats: Optional flag indicating whether flat areas should have a small gradient applied.
    ## - flat_increment: Optional elevation increment applied to flat areas.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--fix_flats={fix_flats}")
    if flat_increment.isSome:
        args.add(fmt"--flat_increment={flat_increment}")
    result = self.runTool("FillDepressionsWangAndLiu", args)

proc fillMissingData*(self: var WhiteboxTools, input: string, output: string, filter: int = 11, weight: float = 2.0, no_edges: bool = true): byte =
    ## Fills NoData holes in a DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#FillMissingData) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filter: Filter size (cells).
    ## - weight: IDW weight value.
    ## - no_edges: Optional flag indicating whether to exclude NoData cells in edge regions.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filter={filter}")
    args.add(fmt"--weight={weight}")
    args.add(fmt"--no_edges={no_edges}")
    result = self.runTool("FillMissingData", args)

proc fillSingleCellPits*(self: var WhiteboxTools, dem: string, output: string): byte =
    ## Raises pit cells to the elevation of their lowest neighbour.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#FillSingleCellPits) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    result = self.runTool("FillSingleCellPits", args)

proc filterLidarClasses*(self: var WhiteboxTools, input: string, output: string, exclude_cls: string = ""): byte =
    ## Removes points in a LAS file with certain specified class values.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#FilterLidarClasses) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output LiDAR file.
    ## - exclude_cls: Optional exclude classes from interpolation; Valid class values range from 0 to 18, based on LAS specifications. Example, --exclude_cls='3,4,5,6,7,18'.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--exclude_cls={exclude_cls}")
    result = self.runTool("FilterLidarClasses", args)

proc filterLidarScanAngles*(self: var WhiteboxTools, input: string, output: string, threshold: float): byte =
    ## Removes points in a LAS file with scan angles greater than a threshold.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#FilterLidarScanAngles) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output LiDAR file.
    ## - threshold: Scan angle threshold.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--threshold={threshold}")
    result = self.runTool("FilterLidarScanAngles", args)

proc findFlightlineEdgePoints*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Identifies points along a flightline's edge in a LAS file.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#FindFlightlineEdgePoints) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("FindFlightlineEdgePoints", args)

proc findLowestOrHighestPoints*(self: var WhiteboxTools, input: string, output: string, out_type: string = "lowest"): byte =
    ## Locates the lowest and/or highest valued cells in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#FindLowestOrHighestPoints) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output vector points file.
    ## - out_type: Output type; one of 'area' (default) and 'volume'.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--out_type={out_type}")
    result = self.runTool("FindLowestOrHighestPoints", args)

proc findMainStem*(self: var WhiteboxTools, d8_pntr: string, streams: string, output: string, esri_pntr: bool = false, zero_background = none(bool)): byte =
    ## Finds the main stem, based on stream lengths, of each stream network.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#FindMainStem) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    ## - zero_background: Flag indicating whether a background value of zero should be used.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    if zero_background.isSome:
        args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("FindMainStem", args)

proc findNoFlowCells*(self: var WhiteboxTools, dem: string, output: string): byte =
    ## Finds grid cells with no downslope neighbours.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#FindNoFlowCells) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    result = self.runTool("FindNoFlowCells", args)

proc findParallelFlow*(self: var WhiteboxTools, d8_pntr: string, streams: string, output: string): byte =
    ## Finds areas of parallel flow in D8 flow direction rasters.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#FindParallelFlow) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input D8 pointer raster file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    result = self.runTool("FindParallelFlow", args)

proc findPatchOrClassEdgeCells*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Finds all cells located on the edge of patch or class features.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_patch_shape_tools.html#FindPatchOrClassEdgeCells) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("FindPatchOrClassEdgeCells", args)

proc findRidges*(self: var WhiteboxTools, dem: string, output: string, line_thin: bool = true): byte =
    ## Identifies potential ridge and peak grid cells.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#FindRidges) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - line_thin: Optional flag indicating whether post-processing line-thinning should be performed.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--line_thin={line_thin}")
    result = self.runTool("FindRidges", args)

proc flattenLakes*(self: var WhiteboxTools, dem: string, lakes: string, output: string): byte =
    ## Flattens lake polygons in a raster DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#FlattenLakes) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - lakes: Input lakes vector polygons file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--lakes={lakes}")
    args.add(fmt"--output={output}")
    result = self.runTool("FlattenLakes", args)

proc flightlineOverlap*(self: var WhiteboxTools, input: string = "", output: string = "", resolution: float = 1.0): byte =
    ## Reads a LiDAR (LAS) point file and outputs a raster containing the number of overlapping flight lines in each grid cell.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#FlightlineOverlap) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output file.
    ## - resolution: Output raster's grid resolution.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--resolution={resolution}")
    result = self.runTool("FlightlineOverlap", args)

proc flipImage*(self: var WhiteboxTools, input: string, output: string, direction: string = "vertical"): byte =
    ## Reflects an image in the vertical or horizontal axis.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#FlipImage) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - direction: Direction of reflection; options include 'v' (vertical), 'h' (horizontal), and 'b' (both).
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--direction={direction}")
    result = self.runTool("FlipImage", args)

proc floodOrder*(self: var WhiteboxTools, dem: string, output: string): byte =
    ## Assigns each DEM grid cell its order in the sequence of inundations that are encountered during a search starting from the edges, moving inward at increasing elevations.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#FloodOrder) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    result = self.runTool("FloodOrder", args)

proc floor*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the largest (closest to positive infinity) value that is less than or equal to the values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Floor) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Floor", args)

proc flowAccumulationFullWorkflow*(self: var WhiteboxTools, dem: string, out_dem: string, out_pntr: string, out_accum: string, out_type: string = "Specific Contributing Area", log = none(bool), clip = none(bool), esri_pntr: bool = false): byte =
    ## Resolves all of the depressions in a DEM, outputting a breached DEM, an aspect-aligned non-divergent flow pointer, and a flow accumulation raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#FlowAccumulationFullWorkflow) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - out_dem: Output raster DEM file.
    ## - out_pntr: Output raster flow pointer file.
    ## - out_accum: Output raster flow accumulation file.
    ## - out_type: Output type; one of 'cells', 'sca' (default), and 'ca'.
    ## - log: Optional flag to request the output be log-transformed.
    ## - clip: Optional flag to request clipping the display max by 1%.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--out_dem={out_dem}")
    args.add(fmt"--out_pntr={out_pntr}")
    args.add(fmt"--out_accum={out_accum}")
    args.add(fmt"--out_type={out_type}")
    if log.isSome:
        args.add(fmt"--log={log}")
    if clip.isSome:
        args.add(fmt"--clip={clip}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    result = self.runTool("FlowAccumulationFullWorkflow", args)

proc flowLengthDiff*(self: var WhiteboxTools, d8_pntr: string, output: string, esri_pntr: bool = false): byte =
    ## Calculates the local maximum absolute difference in downslope flowpath length, useful in mapping drainage divides and ridges.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#FlowLengthDiff) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input D8 pointer raster file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    result = self.runTool("FlowLengthDiff", args)

proc gammaCorrection*(self: var WhiteboxTools, input: string, output: string, gamma: float = 0.5): byte =
    ## Performs a gamma correction on an input images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_image_enhancement.html#GammaCorrection) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - gamma: Gamma value.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--gamma={gamma}")
    result = self.runTool("GammaCorrection", args)

proc gaussianContrastStretch*(self: var WhiteboxTools, input: string, output: string, num_tones: int = 256): byte =
    ## Performs a Gaussian contrast stretch on input images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_image_enhancement.html#GaussianContrastStretch) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - num_tones: Number of tones in the output image.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--num_tones={num_tones}")
    result = self.runTool("GaussianContrastStretch", args)

proc gaussianFilter*(self: var WhiteboxTools, input: string, output: string, sigma: float = 0.75): byte =
    ## Performs a Gaussian filter on an image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#GaussianFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - sigma: Standard deviation distance in pixels.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--sigma={sigma}")
    result = self.runTool("GaussianFilter", args)

proc greaterThan*(self: var WhiteboxTools, input1: string, input2: string, output: string, incl_equals = none(bool)): byte =
    ## Performs a greater-than comparison operation on two rasters or a raster and a constant value.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#GreaterThan) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file or constant value.
    ## - input2: Input raster file or constant value.
    ## - output: Output raster file.
    ## - incl_equals: Perform a greater-than-or-equal-to operation.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    if incl_equals.isSome:
        args.add(fmt"--incl_equals={incl_equals}")
    result = self.runTool("GreaterThan", args)

proc hackStreamOrder*(self: var WhiteboxTools, d8_pntr: string, streams: string, output: string, esri_pntr: bool = false, zero_background = none(bool)): byte =
    ## Assigns the Hack stream order to each tributary in a stream network.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#HackStreamOrder) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    ## - zero_background: Flag indicating whether a background value of zero should be used.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    if zero_background.isSome:
        args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("HackStreamOrder", args)

proc heightAboveGround*(self: var WhiteboxTools, input: string = "", output: string = ""): byte =
    ## Normalizes a LiDAR point cloud, providing the height above the nearest ground-classified point.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#HeightAboveGround) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file (including extension).
    ## - output: Output raster file (including extension).
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("HeightAboveGround", args)

proc highPassFilter*(self: var WhiteboxTools, input: string, output: string, filterx: int = 11, filtery: int = 11): byte =
    ## Performs a high-pass filter on an input image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#HighPassFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    result = self.runTool("HighPassFilter", args)

proc highPassMedianFilter*(self: var WhiteboxTools, input: string, output: string, filterx: int = 11, filtery: int = 11, sig_digits: int = 2): byte =
    ## Performs a high pass median filter on an input image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#HighPassMedianFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    ## - sig_digits: Number of significant digits.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    args.add(fmt"--sig_digits={sig_digits}")
    result = self.runTool("HighPassMedianFilter", args)

proc highestPosition*(self: var WhiteboxTools, inputs: string, output: string): byte =
    ## Identifies the stack position of the maximum value within a raster stack on a cell-by-cell basis.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#HighestPosition) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--output={output}")
    result = self.runTool("HighestPosition", args)

proc hillshade*(self: var WhiteboxTools, dem: string, output: string, azimuth: float = 315.0, altitude: float = 30.0, zfactor: float = 1.0): byte =
    ## Calculates a hillshade raster from an input DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#Hillshade) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - azimuth: Illumination source azimuth in degrees.
    ## - altitude: Illumination source altitude in degrees.
    ## - zfactor: Optional multiplier for when the vertical and horizontal units are not the same.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--azimuth={azimuth}")
    args.add(fmt"--altitude={altitude}")
    args.add(fmt"--zfactor={zfactor}")
    result = self.runTool("Hillshade", args)

proc hillslopes*(self: var WhiteboxTools, d8_pntr: string, streams: string, output: string, esri_pntr: bool = false): byte =
    ## Identifies the individual hillslopes draining to each link in a stream network.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#Hillslopes) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    result = self.runTool("Hillslopes", args)

proc histogramEqualization*(self: var WhiteboxTools, input: string, output: string, num_tones: int = 256): byte =
    ## Performs a histogram equalization contrast enhancment on an image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_image_enhancement.html#HistogramEqualization) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - num_tones: Number of tones in the output image.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--num_tones={num_tones}")
    result = self.runTool("HistogramEqualization", args)

proc histogramMatching*(self: var WhiteboxTools, input: string, histo_file: string, output: string): byte =
    ## Alters the statistical distribution of a raster image matching it to a specified PDF.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_image_enhancement.html#HistogramMatching) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - histo_file: Input reference probability distribution function (pdf) text file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--histo_file={histo_file}")
    args.add(fmt"--output={output}")
    result = self.runTool("HistogramMatching", args)

proc histogramMatchingTwoImages*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## This tool alters the cumulative distribution function of a raster image to that of another image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_image_enhancement.html#HistogramMatchingTwoImages) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file to modify.
    ## - input2: Input reference raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("HistogramMatchingTwoImages", args)

proc holeProportion*(self: var WhiteboxTools, input: string): byte =
    ## Calculates the proportion of the total area of a polygon's holes relative to the area of the polygon's hull.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_patch_shape_tools.html#HoleProportion) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector polygon file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    result = self.runTool("HoleProportion", args)

proc horizonAngle*(self: var WhiteboxTools, dem: string, output: string, azimuth: float = 0.0, max_dist = none(float)): byte =
    ## Calculates horizon angle (maximum upwind slope) for each grid cell in an input DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#HorizonAngle) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - azimuth: Wind azimuth in degrees.
    ## - max_dist: Optional maximum search distance (unspecified if none; in xy units).
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--azimuth={azimuth}")
    if max_dist.isSome:
        args.add(fmt"--max_dist={max_dist}")
    result = self.runTool("HorizonAngle", args)

proc hortonStreamOrder*(self: var WhiteboxTools, d8_pntr: string, streams: string, output: string, esri_pntr: bool = false, zero_background = none(bool)): byte =
    ## Assigns the Horton stream order to each tributary in a stream network.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#HortonStreamOrder) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    ## - zero_background: Flag indicating whether a background value of zero should be used.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    if zero_background.isSome:
        args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("HortonStreamOrder", args)

proc hypsometricAnalysis*(self: var WhiteboxTools, inputs: string, watershed: string = "", output: string): byte =
    ## Calculates a hypsometric curve for one or more DEMs.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#HypsometricAnalysis) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input DEM files.
    ## - watershed: Input watershed files (optional).
    ## - output: Output HTML file (default name will be based on input file if unspecified).
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--watershed={watershed}")
    args.add(fmt"--output={output}")
    result = self.runTool("HypsometricAnalysis", args)

proc idwInterpolation*(self: var WhiteboxTools, input: string, field: string, use_z: bool = false, output: string, weight: float = 2.0, radius = none(float), min_points = none(int), cell_size = none(float), base: string = ""): byte =
    ## Interpolates vector points into a raster surface using an inverse-distance weighted scheme.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#IdwInterpolation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector Points file.
    ## - field: Input field name in attribute table.
    ## - use_z: Use z-coordinate instead of field?
    ## - output: Output raster file.
    ## - weight: IDW weight value.
    ## - radius: Search Radius in map units.
    ## - min_points: Minimum number of points.
    ## - cell_size: Optionally specified cell size of output raster. Not used when base raster is specified.
    ## - base: Optionally specified input base raster file. Not used when a cell size is specified.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--field={field}")
    args.add(fmt"--use_z={use_z}")
    args.add(fmt"--output={output}")
    args.add(fmt"--weight={weight}")
    if radius.isSome:
        args.add(fmt"--radius={radius}")
    if min_points.isSome:
        args.add(fmt"--min_points={min_points}")
    if cell_size.isSome:
        args.add(fmt"--cell_size={cell_size}")
    args.add(fmt"--base={base}")
    result = self.runTool("IdwInterpolation", args)

proc ihsToRgb*(self: var WhiteboxTools, intensity: string, hue: string, saturation: string, red: string = "", green: string = "", blue: string = "", output: string = ""): byte =
    ## Converts intensity, hue, and saturation (IHS) images into red, green, and blue (RGB) images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#IhsToRgb) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - intensity: Input intensity file.
    ## - hue: Input hue file.
    ## - saturation: Input saturation file.
    ## - red: Output red band file. Optionally specified if colour-composite not specified.
    ## - green: Output green band file. Optionally specified if colour-composite not specified.
    ## - blue: Output blue band file. Optionally specified if colour-composite not specified.
    ## - output: Output colour-composite file. Only used if individual bands are not specified.
    var args = newSeq[string]()
    args.add(fmt"--intensity={intensity}")
    args.add(fmt"--hue={hue}")
    args.add(fmt"--saturation={saturation}")
    args.add(fmt"--red={red}")
    args.add(fmt"--green={green}")
    args.add(fmt"--blue={blue}")
    args.add(fmt"--output={output}")
    result = self.runTool("IhsToRgb", args)

proc imageAutocorrelation*(self: var WhiteboxTools, inputs: string, contiguity: string = "Rook", output: string): byte =
    ## Performs Moran's I analysis on two or more input images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#ImageAutocorrelation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - contiguity: Contiguity type.
    ## - output: Output HTML file (default name will be based on input file if unspecified).
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--contiguity={contiguity}")
    args.add(fmt"--output={output}")
    result = self.runTool("ImageAutocorrelation", args)

proc imageCorrelation*(self: var WhiteboxTools, inputs: string, output: string = ""): byte =
    ## Performs image correlation on two or more input images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#ImageCorrelation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - output: Output HTML file (default name will be based on input file if unspecified).
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--output={output}")
    result = self.runTool("ImageCorrelation", args)

proc imageCorrelationNeighbourhoodAnalysis*(self: var WhiteboxTools, input1: string, input2: string, output1: string, output2: string, filter: int = 11, stat: string = "pearson"): byte =
    ## Performs image correlation on two input images neighbourhood search windows.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#ImageCorrelationNeighbourhoodAnalysis) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file.
    ## - input2: Input raster file.
    ## - output1: Output correlation (r-value or rho) raster file.
    ## - output2: Output significance (p-value) raster file.
    ## - filter: Size of the filter kernel.
    ## - stat: Correlation type; one of 'pearson' (default) and 'spearman'.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output1={output1}")
    args.add(fmt"--output2={output2}")
    args.add(fmt"--filter={filter}")
    args.add(fmt"--stat={stat}")
    result = self.runTool("ImageCorrelationNeighbourhoodAnalysis", args)

proc imageRegression*(self: var WhiteboxTools, input1: string, input2: string, output: string, out_residuals: string = "", standardize = none(bool), scattergram = none(bool), num_samples: int = 1000): byte =
    ## Performs image regression analysis on two input images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#ImageRegression) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file (independent variable, X).
    ## - input2: Input raster file (dependent variable, Y).
    ## - output: Output HTML file for regression summary report.
    ## - out_residuals: Output raster regression resdidual file.
    ## - standardize: Optional flag indicating whether to standardize the residuals map.
    ## - scattergram: Optional flag indicating whether to output a scattergram.
    ## - num_samples: Number of samples used to create scattergram
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    args.add(fmt"--out_residuals={out_residuals}")
    if standardize.isSome:
        args.add(fmt"--standardize={standardize}")
    if scattergram.isSome:
        args.add(fmt"--scattergram={scattergram}")
    args.add(fmt"--num_samples={num_samples}")
    result = self.runTool("ImageRegression", args)

proc imageStackProfile*(self: var WhiteboxTools, inputs: string, points: string, output: string): byte =
    ## Plots an image stack profile (i.e. signature) for a set of points and multispectral images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#ImageStackProfile) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input multispectral image files.
    ## - points: Input vector points file.
    ## - output: Output HTML file.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--points={points}")
    args.add(fmt"--output={output}")
    result = self.runTool("ImageStackProfile", args)

proc impoundmentSizeIndex*(self: var WhiteboxTools, dem: string, output: string, out_type: string = "mean depth", damlength: float): byte =
    ## Calculates the impoundment size resulting from damming a DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#ImpoundmentSizeIndex) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output file.
    ## - out_type: Output type; one of 'mean depth' (default), 'volume', 'area', 'max depth'.
    ## - damlength: Maximum length of the dam.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--out_type={out_type}")
    args.add(fmt"--damlength={damlength}")
    result = self.runTool("ImpoundmentSizeIndex", args)

proc inPlaceAdd*(self: var WhiteboxTools, input1: string, input2: string): byte =
    ## Performs an in-place addition operation (input1 += input2).
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#InPlaceAdd) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file.
    ## - input2: Input raster file or constant value.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    result = self.runTool("InPlaceAdd", args)

proc inPlaceDivide*(self: var WhiteboxTools, input1: string, input2: string): byte =
    ## Performs an in-place division operation (input1 /= input2).
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#InPlaceDivide) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file.
    ## - input2: Input raster file or constant value.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    result = self.runTool("InPlaceDivide", args)

proc inPlaceMultiply*(self: var WhiteboxTools, input1: string, input2: string): byte =
    ## Performs an in-place multiplication operation (input1 * = input2).
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#InPlaceMultiply) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file.
    ## - input2: Input raster file or constant value.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    result = self.runTool("InPlaceMultiply", args)

proc inPlaceSubtract*(self: var WhiteboxTools, input1: string, input2: string): byte =
    ## Performs an in-place subtraction operation (input1 -= input2).
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#InPlaceSubtract) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file.
    ## - input2: Input raster file or constant value.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    result = self.runTool("InPlaceSubtract", args)

proc increment*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Increases the values of each grid cell in an input raster by 1.0. (see also InPlaceAdd)
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Increment) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Increment", args)

proc insertDams*(self: var WhiteboxTools, dem: string, dam_pts: string, output: string, damlength: float): byte =
    ## Calculates the impoundment size resulting from damming a DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#InsertDams) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - dam_pts: Input vector dam points file.
    ## - output: Output file.
    ## - damlength: Maximum length of the dam.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--dam_pts={dam_pts}")
    args.add(fmt"--output={output}")
    args.add(fmt"--damlength={damlength}")
    result = self.runTool("InsertDams", args)

proc integerDivision*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## Performs an integer division operation on two rasters or a raster and a constant value.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#IntegerDivision) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file or constant value.
    ## - input2: Input raster file or constant value.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("IntegerDivision", args)

proc integralImage*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Transforms an input image (summed area table) into its integral image equivalent.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#IntegralImage) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("IntegralImage", args)

proc intersect*(self: var WhiteboxTools, input: string, overlay: string, output: string, snap: float = 0.0): byte =
    ## Identifies the parts of features in common between two input vector layers.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#Intersect) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    ## - overlay: Input overlay vector file.
    ## - output: Output vector file.
    ## - snap: Snap tolerance.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--overlay={overlay}")
    args.add(fmt"--output={output}")
    args.add(fmt"--snap={snap}")
    result = self.runTool("Intersect", args)

proc isNoData*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Identifies NoData valued pixels in an image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#IsNoData) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("IsNoData", args)

proc isobasins*(self: var WhiteboxTools, dem: string, output: string, size: int): byte =
    ## Divides a landscape into nearly equal sized drainage basins (i.e. watersheds).
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#Isobasins) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - size: Target basin size, in grid cells.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--size={size}")
    result = self.runTool("Isobasins", args)

proc jensonSnapPourPoints*(self: var WhiteboxTools, pour_pts: string, streams: string, output: string, snap_dist: float): byte =
    ## Moves outlet points used to specify points of interest in a watershedding operation to the nearest stream cell.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#JensonSnapPourPoints) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - pour_pts: Input vector pour points (outlet) file.
    ## - streams: Input raster streams file.
    ## - output: Output vector file.
    ## - snap_dist: Maximum snap distance in map units.
    var args = newSeq[string]()
    args.add(fmt"--pour_pts={pour_pts}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    args.add(fmt"--snap_dist={snap_dist}")
    result = self.runTool("JensonSnapPourPoints", args)

proc joinTables*(self: var WhiteboxTools, input1: string, pkey: string, input2: string, fkey: string, import_field: string): byte =
    ## Merge a vector's attribute table with another table based on a common field.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#JoinTables) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input primary vector file (i.e. the table to be modified).
    ## - pkey: Primary key field.
    ## - input2: Input foreign vector file (i.e. source of data to be imported).
    ## - fkey: Foreign key field.
    ## - import_field: Imported field (all fields will be imported if not specified).
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--pkey={pkey}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--fkey={fkey}")
    args.add(fmt"--import_field={import_field}")
    result = self.runTool("JoinTables", args)

proc kMeansClustering*(self: var WhiteboxTools, inputs: string, output: string, out_html: string = "", classes: int, max_iterations: int = 10, class_change: float = 2.0, initialize: string = "diagonal", min_class_size: int = 10): byte =
    ## Performs a k-means clustering operation on a multi-spectral dataset.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#KMeansClustering) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - output: Output raster file.
    ## - out_html: Output HTML report file.
    ## - classes: Number of classes
    ## - max_iterations: Maximum number of iterations
    ## - class_change: Minimum percent of cells changed between iterations before completion
    ## - initialize: How to initialize cluster centres?
    ## - min_class_size: Minimum class size, in pixels
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--output={output}")
    args.add(fmt"--out_html={out_html}")
    args.add(fmt"--classes={classes}")
    args.add(fmt"--max_iterations={max_iterations}")
    args.add(fmt"--class_change={class_change}")
    args.add(fmt"--initialize={initialize}")
    args.add(fmt"--min_class_size={min_class_size}")
    result = self.runTool("KMeansClustering", args)

proc kNearestMeanFilter*(self: var WhiteboxTools, input: string, output: string, filterx: int = 11, filtery: int = 11, k: int = 5): byte =
    ## A k-nearest mean filter is a type of edge-preserving smoothing filter.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#KNearestMeanFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    ## - k: k-value in pixels; this is the number of nearest-valued neighbours to use.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    args.add(fmt"-k={k}")
    result = self.runTool("KNearestMeanFilter", args)

proc kappaIndex*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## Performs a kappa index of agreement (KIA) analysis on two categorical raster files.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#KappaIndex) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input classification raster file.
    ## - input2: Input reference raster file.
    ## - output: Output HTML file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("KappaIndex", args)

proc ksTestForNormality*(self: var WhiteboxTools, input: string, output: string, num_samples = none(int)): byte =
    ## Evaluates whether the values in a raster are normally distributed.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#KsTestForNormality) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output HTML file.
    ## - num_samples: Number of samples. Leave blank to use whole image.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    if num_samples.isSome:
        args.add(fmt"--num_samples={num_samples}")
    result = self.runTool("KsTestForNormality", args)

proc laplacianFilter*(self: var WhiteboxTools, input: string, output: string, variant: string = "3x3(1)", clip: float = 0.0): byte =
    ## Performs a Laplacian filter on an image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#LaplacianFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - variant: Optional variant value. Options include 3x3(1), 3x3(2), 3x3(3), 3x3(4), 5x5(1), and 5x5(2) (default is 3x3(1)).
    ## - clip: Optional amount to clip the distribution tails by, in percent.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--variant={variant}")
    args.add(fmt"--clip={clip}")
    result = self.runTool("LaplacianFilter", args)

proc laplacianOfGaussianFilter*(self: var WhiteboxTools, input: string, output: string, sigma: float = 0.75): byte =
    ## Performs a Laplacian-of-Gaussian (LoG) filter on an image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#LaplacianOfGaussianFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - sigma: Standard deviation in pixels.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--sigma={sigma}")
    result = self.runTool("LaplacianOfGaussianFilter", args)

proc lasToAscii*(self: var WhiteboxTools, inputs: string): byte =
    ## Converts one or more LAS files into ASCII text files.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LasToAscii) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input LiDAR files.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    result = self.runTool("LasToAscii", args)

proc lasToMultipointShapefile*(self: var WhiteboxTools, input: string = ""): byte =
    ## Converts one or more LAS files into MultipointZ vector Shapefiles. When the input parameter is not specified, the tool grids all LAS files contained within the working directory.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LasToMultipointShapefile) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    result = self.runTool("LasToMultipointShapefile", args)

proc lasToShapefile*(self: var WhiteboxTools, input: string = ""): byte =
    ## Converts one or more LAS files into a vector Shapefile of POINT ShapeType.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LasToShapefile) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    result = self.runTool("LasToShapefile", args)

proc lasToZlidar*(self: var WhiteboxTools, inputs: string = "", outdir: string = ""): byte =
    ## Converts one or more LAS files into the zlidar compressed LiDAR data format.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LasToZlidar) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input LAS files.
    ## - outdir: Output directory into which zlidar files are created. If unspecified, it is assumed to be the same as the inputs.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--outdir={outdir}")
    result = self.runTool("LasToZlidar", args)

proc layerFootprint*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Creates a vector polygon footprint of the area covered by a raster grid or vector layer.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#LayerFootprint) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster or vector file.
    ## - output: Output vector polygon file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("LayerFootprint", args)

proc leeSigmaFilter*(self: var WhiteboxTools, input: string, output: string, filterx: int = 11, filtery: int = 11, sigma: float = 10.0, m: float = 5.0): byte =
    ## Performs a Lee (Sigma) smoothing filter on an image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#LeeSigmaFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    ## - sigma: Sigma value should be related to the standarad deviation of the distribution of image speckle noise.
    ## - m: M-threshold value the minimum allowable number of pixels within the intensity range
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    args.add(fmt"--sigma={sigma}")
    args.add(fmt"-m={m}")
    result = self.runTool("LeeSigmaFilter", args)

proc lengthOfUpstreamChannels*(self: var WhiteboxTools, d8_pntr: string, streams: string, output: string, esri_pntr: bool = false, zero_background = none(bool)): byte =
    ## Calculates the total length of channels upstream.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#LengthOfUpstreamChannels) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    ## - zero_background: Flag indicating whether a background value of zero should be used.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    if zero_background.isSome:
        args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("LengthOfUpstreamChannels", args)

proc lessThan*(self: var WhiteboxTools, input1: string, input2: string, output: string, incl_equals = none(bool)): byte =
    ## Performs a less-than comparison operation on two rasters or a raster and a constant value.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#LessThan) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file or constant value.
    ## - input2: Input raster file or constant value.
    ## - output: Output raster file.
    ## - incl_equals: Perform a less-than-or-equal-to operation.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    if incl_equals.isSome:
        args.add(fmt"--incl_equals={incl_equals}")
    result = self.runTool("LessThan", args)

proc lidarBlockMaximum*(self: var WhiteboxTools, input: string = "", output: string = "", resolution: float = 1.0): byte =
    ## Creates a block-maximum raster from an input LAS file. When the input/output parameters are not specified, the tool grids all LAS files contained within the working directory.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarBlockMaximum) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output file.
    ## - resolution: Output raster's grid resolution.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--resolution={resolution}")
    result = self.runTool("LidarBlockMaximum", args)

proc lidarBlockMinimum*(self: var WhiteboxTools, input: string = "", output: string = "", resolution: float = 1.0): byte =
    ## Creates a block-minimum raster from an input LAS file. When the input/output parameters are not specified, the tool grids all LAS files contained within the working directory.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarBlockMinimum) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output file.
    ## - resolution: Output raster's grid resolution.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--resolution={resolution}")
    result = self.runTool("LidarBlockMinimum", args)

proc lidarClassifySubset*(self: var WhiteboxTools, base: string, subset: string, output: string, subset_class: float, nonsubset_class = none(float)): byte =
    ## Classifies the values in one LiDAR point cloud that correpond with points in a subset cloud.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarClassifySubset) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - base: Input base LiDAR file.
    ## - subset: Input subset LiDAR file.
    ## - output: Output LiDAR file.
    ## - subset_class: Subset point class value (must be 0-18; see LAS specifications).
    ## - nonsubset_class: Non-subset point class value (must be 0-18; see LAS specifications).
    var args = newSeq[string]()
    args.add(fmt"--base={base}")
    args.add(fmt"--subset={subset}")
    args.add(fmt"--output={output}")
    args.add(fmt"--subset_class={subset_class}")
    if nonsubset_class.isSome:
        args.add(fmt"--nonsubset_class={nonsubset_class}")
    result = self.runTool("LidarClassifySubset", args)

proc lidarColourize*(self: var WhiteboxTools, in_lidar: string, in_image: string, output: string): byte =
    ## Adds the red-green-blue colour fields of a LiDAR (LAS) file based on an input image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarColourize) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - in_lidar: Input LiDAR file.
    ## - in_image: Input colour image file.
    ## - output: Output LiDAR file.
    var args = newSeq[string]()
    args.add(fmt"--in_lidar={in_lidar}")
    args.add(fmt"--in_image={in_image}")
    args.add(fmt"--output={output}")
    result = self.runTool("LidarColourize", args)

proc lidarElevationSlice*(self: var WhiteboxTools, input: string, output: string, minz = none(float), maxz = none(float), class = none(bool), inclassval: int = 2, outclassval: int = 1): byte =
    ## Outputs all of the points within a LiDAR (LAS) point file that lie between a specified elevation range.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarElevationSlice) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output LiDAR file.
    ## - minz: Minimum elevation value (optional).
    ## - maxz: Maximum elevation value (optional).
    ## - class: Optional boolean flag indicating whether points outside the range should be retained in output but reclassified.
    ## - inclassval: Optional parameter specifying the class value assigned to points within the slice.
    ## - outclassval: Optional parameter specifying the class value assigned to points within the slice.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    if minz.isSome:
        args.add(fmt"--minz={minz}")
    if maxz.isSome:
        args.add(fmt"--maxz={maxz}")
    if class.isSome:
        args.add(fmt"--class={class}")
    args.add(fmt"--inclassval={inclassval}")
    args.add(fmt"--outclassval={outclassval}")
    result = self.runTool("LidarElevationSlice", args)

proc lidarGroundPointFilter*(self: var WhiteboxTools, input: string, output: string, radius: float = 2.0, min_neighbours: int = 0, slope_threshold: float = 45.0, height_threshold: float = 1.0, classify: bool = true, slope_norm: bool = true, height_above_ground: bool = false): byte =
    ## Identifies ground points within LiDAR dataset using a slope-based method.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarGroundPointFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output LiDAR file.
    ## - radius: Search Radius.
    ## - min_neighbours: The minimum number of neighbouring points within search areas. If fewer points than this threshold are idenfied during the fixed-radius search, a subsequent kNN search is performed to identify the k number of neighbours.
    ## - slope_threshold: Maximum inter-point slope to be considered an off-terrain point.
    ## - height_threshold: Inter-point height difference to be considered an off-terrain point.
    ## - classify: Classify points as ground (2) or off-ground (1).
    ## - slope_norm: Perform initial ground slope normalization?
    ## - height_above_ground: Transform output to height above average ground elevation?
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--radius={radius}")
    args.add(fmt"--min_neighbours={min_neighbours}")
    args.add(fmt"--slope_threshold={slope_threshold}")
    args.add(fmt"--height_threshold={height_threshold}")
    args.add(fmt"--classify={classify}")
    args.add(fmt"--slope_norm={slope_norm}")
    args.add(fmt"--height_above_ground={height_above_ground}")
    result = self.runTool("LidarGroundPointFilter", args)

proc lidarHexBinning*(self: var WhiteboxTools, input: string, output: string, width: float, orientation: string = "horizontal"): byte =
    ## Hex-bins a set of LiDAR points.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarHexBinning) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input base file.
    ## - output: Output vector polygon file.
    ## - width: The grid cell width.
    ## - orientation: Grid Orientation, 'horizontal' or 'vertical'.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--width={width}")
    args.add(fmt"--orientation={orientation}")
    result = self.runTool("LidarHexBinning", args)

proc lidarHillshade*(self: var WhiteboxTools, input: string, output: string, azimuth: float = 315.0, altitude: float = 30.0, radius: float = 1.0): byte =
    ## Calculates a hillshade value for points within a LAS file and stores these data in the RGB field.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarHillshade) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output file.
    ## - azimuth: Illumination source azimuth in degrees.
    ## - altitude: Illumination source altitude in degrees.
    ## - radius: Search Radius.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--azimuth={azimuth}")
    args.add(fmt"--altitude={altitude}")
    args.add(fmt"--radius={radius}")
    result = self.runTool("LidarHillshade", args)

proc lidarHistogram*(self: var WhiteboxTools, input: string, output: string, parameter: string = "elevation", clip: float = 1.0): byte =
    ## Creates a histogram of LiDAR data.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarHistogram) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output HTML file (default name will be based on input file if unspecified).
    ## - parameter: Parameter; options are 'elevation' (default), 'intensity', 'scan angle', 'class'.
    ## - clip: Amount to clip distribution tails (in percent).
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--parameter={parameter}")
    args.add(fmt"--clip={clip}")
    result = self.runTool("LidarHistogram", args)

proc lidarIdwInterpolation*(self: var WhiteboxTools, input: string = "", output: string = "", parameter: string = "elevation", returns: string = "all", resolution: float = 1.0, weight: float = 1.0, radius: float = 2.5, exclude_cls: string = "", minz = none(float), maxz = none(float)): byte =
    ## Interpolates LAS files using an inverse-distance weighted (IDW) scheme. When the input/output parameters are not specified, the tool interpolates all LAS files contained within the working directory.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarIdwInterpolation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file (including extension).
    ## - output: Output raster file (including extension).
    ## - parameter: Interpolation parameter; options are 'elevation' (default), 'intensity', 'class', 'return_number', 'number_of_returns', 'scan angle', 'rgb', 'user data'.
    ## - returns: Point return types to include; options are 'all' (default), 'last', 'first'.
    ## - resolution: Output raster's grid resolution.
    ## - weight: IDW weight value.
    ## - radius: Search Radius.
    ## - exclude_cls: Optional exclude classes from interpolation; Valid class values range from 0 to 18, based on LAS specifications. Example, --exclude_cls='3,4,5,6,7,18'.
    ## - minz: Optional minimum elevation for inclusion in interpolation.
    ## - maxz: Optional maximum elevation for inclusion in interpolation.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--parameter={parameter}")
    args.add(fmt"--returns={returns}")
    args.add(fmt"--resolution={resolution}")
    args.add(fmt"--weight={weight}")
    args.add(fmt"--radius={radius}")
    args.add(fmt"--exclude_cls={exclude_cls}")
    if minz.isSome:
        args.add(fmt"--minz={minz}")
    if maxz.isSome:
        args.add(fmt"--maxz={maxz}")
    result = self.runTool("LidarIdwInterpolation", args)

proc lidarInfo*(self: var WhiteboxTools, input: string, output: string = "", vlr: bool = true, geokeys: bool = true): byte =
    ## Prints information about a LiDAR (LAS) dataset, including header, point return frequency, and classification data and information about the variable length records (VLRs) and geokeys.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarInfo) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output HTML file for summary report.
    ## - vlr: Flag indicating whether or not to print the variable length records (VLRs).
    ## - geokeys: Flag indicating whether or not to print the geokeys.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--vlr={vlr}")
    args.add(fmt"--geokeys={geokeys}")
    result = self.runTool("LidarInfo", args)

proc lidarJoin*(self: var WhiteboxTools, inputs: string, output: string): byte =
    ## Joins multiple LiDAR (LAS) files into a single LAS file.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarJoin) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input LiDAR files.
    ## - output: Output LiDAR file.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--output={output}")
    result = self.runTool("LidarJoin", args)

proc lidarKappaIndex*(self: var WhiteboxTools, input1: string, input2: string, output: string, class_accuracy: string, resolution: float = 1.0): byte =
    ## Performs a kappa index of agreement (KIA) analysis on the classifications of two LAS files.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarKappaIndex) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input LiDAR classification file.
    ## - input2: Input LiDAR reference file.
    ## - output: Output HTML file.
    ## - class_accuracy: Output classification accuracy raster file.
    ## - resolution: Output raster's grid resolution.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    args.add(fmt"--class_accuracy={class_accuracy}")
    args.add(fmt"--resolution={resolution}")
    result = self.runTool("LidarKappaIndex", args)

proc lidarNearestNeighbourGridding*(self: var WhiteboxTools, input: string = "", output: string = "", parameter: string = "elevation", returns: string = "all", resolution: float = 1.0, radius: float = 2.5, exclude_cls: string = "", minz = none(float), maxz = none(float)): byte =
    ## Grids LAS files using nearest-neighbour scheme. When the input/output parameters are not specified, the tool grids all LAS files contained within the working directory.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarNearestNeighbourGridding) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file (including extension).
    ## - output: Output raster file (including extension).
    ## - parameter: Interpolation parameter; options are 'elevation' (default), 'intensity', 'class', 'return_number', 'number_of_returns', 'scan angle', 'rgb', 'user data'.
    ## - returns: Point return types to include; options are 'all' (default), 'last', 'first'.
    ## - resolution: Output raster's grid resolution.
    ## - radius: Search Radius.
    ## - exclude_cls: Optional exclude classes from interpolation; Valid class values range from 0 to 18, based on LAS specifications. Example, --exclude_cls='3,4,5,6,7,18'.
    ## - minz: Optional minimum elevation for inclusion in interpolation.
    ## - maxz: Optional maximum elevation for inclusion in interpolation.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--parameter={parameter}")
    args.add(fmt"--returns={returns}")
    args.add(fmt"--resolution={resolution}")
    args.add(fmt"--radius={radius}")
    args.add(fmt"--exclude_cls={exclude_cls}")
    if minz.isSome:
        args.add(fmt"--minz={minz}")
    if maxz.isSome:
        args.add(fmt"--maxz={maxz}")
    result = self.runTool("LidarNearestNeighbourGridding", args)

proc lidarPointDensity*(self: var WhiteboxTools, input: string = "", output: string = "", returns: string = "all", resolution: float = 1.0, radius: float = 2.5, exclude_cls: string = "", minz = none(float), maxz = none(float)): byte =
    ## Calculates the spatial pattern of point density for a LiDAR data set. When the input/output parameters are not specified, the tool grids all LAS files contained within the working directory.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarPointDensity) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file (including extension).
    ## - output: Output raster file (including extension).
    ## - returns: Point return types to include; options are 'all' (default), 'last', 'first'.
    ## - resolution: Output raster's grid resolution.
    ## - radius: Search radius.
    ## - exclude_cls: Optional exclude classes from interpolation; Valid class values range from 0 to 18, based on LAS specifications. Example, --exclude_cls='3,4,5,6,7,18'.
    ## - minz: Optional minimum elevation for inclusion in interpolation.
    ## - maxz: Optional maximum elevation for inclusion in interpolation.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--returns={returns}")
    args.add(fmt"--resolution={resolution}")
    args.add(fmt"--radius={radius}")
    args.add(fmt"--exclude_cls={exclude_cls}")
    if minz.isSome:
        args.add(fmt"--minz={minz}")
    if maxz.isSome:
        args.add(fmt"--maxz={maxz}")
    result = self.runTool("LidarPointDensity", args)

proc lidarPointStats*(self: var WhiteboxTools, input: string = "", resolution: float = 1.0, num_points: bool = true, num_pulses = none(bool), avg_points_per_pulse: bool = true, z_range = none(bool), intensity_range = none(bool), predom_class = none(bool)): byte =
    ## Creates several rasters summarizing the distribution of LAS point data. When the input/output parameters are not specified, the tool works on all LAS files contained within the working directory.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarPointStats) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - resolution: Output raster's grid resolution.
    ## - num_points: Flag indicating whether or not to output the number of points (returns) raster.
    ## - num_pulses: Flag indicating whether or not to output the number of pulses raster.
    ## - avg_points_per_pulse: Flag indicating whether or not to output the average number of points (returns) per pulse raster.
    ## - z_range: Flag indicating whether or not to output the elevation range raster.
    ## - intensity_range: Flag indicating whether or not to output the intensity range raster.
    ## - predom_class: Flag indicating whether or not to output the predominant classification raster.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--resolution={resolution}")
    args.add(fmt"--num_points={num_points}")
    if num_pulses.isSome:
        args.add(fmt"--num_pulses={num_pulses}")
    args.add(fmt"--avg_points_per_pulse={avg_points_per_pulse}")
    if z_range.isSome:
        args.add(fmt"--z_range={z_range}")
    if intensity_range.isSome:
        args.add(fmt"--intensity_range={intensity_range}")
    if predom_class.isSome:
        args.add(fmt"--predom_class={predom_class}")
    result = self.runTool("LidarPointStats", args)

proc lidarRansacPlanes*(self: var WhiteboxTools, input: string, output: string, radius: float = 2.0, num_iter: int = 50, num_samples: int = 5, threshold: float = 0.35, model_size: int = 8, max_slope: float = 80.0, classify: bool = false): byte =
    ## Performs a RANSAC analysis to identify points within a LiDAR point cloud that belong to linear planes.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarRansacPlanes) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output LiDAR file.
    ## - radius: Search Radius.
    ## - num_iter: Number of iterations.
    ## - num_samples: Number of sample points on which to build the model.
    ## - threshold: Threshold used to determine inlier points.
    ## - model_size: Acceptable model size.
    ## - max_slope: Maximum planar slope.
    ## - classify: Classify points as ground (2) or off-ground (1).
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--radius={radius}")
    args.add(fmt"--num_iter={num_iter}")
    args.add(fmt"--num_samples={num_samples}")
    args.add(fmt"--threshold={threshold}")
    args.add(fmt"--model_size={model_size}")
    args.add(fmt"--max_slope={max_slope}")
    args.add(fmt"--classify={classify}")
    result = self.runTool("LidarRansacPlanes", args)

proc lidarRbfInterpolation*(self: var WhiteboxTools, input: string = "", output: string = "", parameter: string = "elevation", returns: string = "all", resolution: float = 1.0, num_points: int = 20, exclude_cls: string = "", minz = none(float), maxz = none(float), func_type: string = "ThinPlateSpline", poly_order: string = "none", weight: float = 5): byte =
    ## Interpolates LAS files using a radial basis function (RBF) scheme. When the input/output parameters are not specified, the tool interpolates all LAS files contained within the working directory.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarRbfInterpolation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file (including extension).
    ## - output: Output raster file (including extension).
    ## - parameter: Interpolation parameter; options are 'elevation' (default), 'intensity', 'class', 'return_number', 'number_of_returns', 'scan angle', 'rgb', 'user data'.
    ## - returns: Point return types to include; options are 'all' (default), 'last', 'first'.
    ## - resolution: Output raster's grid resolution.
    ## - num_points: Number of points.
    ## - exclude_cls: Optional exclude classes from interpolation; Valid class values range from 0 to 18, based on LAS specifications. Example, --exclude_cls='3,4,5,6,7,18'.
    ## - minz: Optional minimum elevation for inclusion in interpolation.
    ## - maxz: Optional maximum elevation for inclusion in interpolation.
    ## - func_type: Radial basis function type; options are 'ThinPlateSpline' (default), 'PolyHarmonic', 'Gaussian', 'MultiQuadric', 'InverseMultiQuadric'.
    ## - poly_order: Polynomial order; options are 'none' (default), 'constant', 'affine'.
    ## - weight: Weight parameter used in basis function.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--parameter={parameter}")
    args.add(fmt"--returns={returns}")
    args.add(fmt"--resolution={resolution}")
    args.add(fmt"--num_points={num_points}")
    args.add(fmt"--exclude_cls={exclude_cls}")
    if minz.isSome:
        args.add(fmt"--minz={minz}")
    if maxz.isSome:
        args.add(fmt"--maxz={maxz}")
    args.add(fmt"--func_type={func_type}")
    args.add(fmt"--poly_order={poly_order}")
    args.add(fmt"--weight={weight}")
    result = self.runTool("LidarRbfInterpolation", args)

proc lidarRemoveDuplicates*(self: var WhiteboxTools, input: string, output: string, include_z: bool = false): byte =
    ## Removes duplicate points from a LiDAR data set.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarRemoveDuplicates) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output LiDAR file.
    ## - include_z: Include z-values in point comparison?
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--include_z={include_z}")
    result = self.runTool("LidarRemoveDuplicates", args)

proc lidarRemoveOutliers*(self: var WhiteboxTools, input: string, output: string, radius: float = 2.0, elev_diff: float = 50.0, use_median = none(bool), classify: bool = true): byte =
    ## Removes outliers (high and low points) in a LiDAR point cloud.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarRemoveOutliers) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output LiDAR file.
    ## - radius: Search Radius.
    ## - elev_diff: Max. elevation difference.
    ## - use_median: Optional flag indicating whether to use the difference from median elevation rather than mean.
    ## - classify: Classify points as ground (2) or off-ground (1).
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--radius={radius}")
    args.add(fmt"--elev_diff={elev_diff}")
    if use_median.isSome:
        args.add(fmt"--use_median={use_median}")
    args.add(fmt"--classify={classify}")
    result = self.runTool("LidarRemoveOutliers", args)

proc lidarRooftopAnalysis*(self: var WhiteboxTools, input: string = "", buildings: string, output: string, radius: float = 2.0, num_iter: int = 50, num_samples: int = 10, threshold: float = 0.15, model_size: int = 15, max_slope: float = 65.0, norm_diff: float = 10.0, azimuth: float = 180.0, altitude: float = 30.0): byte =
    ## Identifies roof segments in a LiDAR point cloud.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarRooftopAnalysis) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - buildings: Input vector build footprint polygons file.
    ## - output: Output vector polygon file.
    ## - radius: Search Radius.
    ## - num_iter: Number of iterations.
    ## - num_samples: Number of sample points on which to build the model.
    ## - threshold: Threshold used to determine inlier points.
    ## - model_size: Acceptable model size.
    ## - max_slope: Maximum planar slope.
    ## - norm_diff: Maximum difference in normal vectors, in degrees.
    ## - azimuth: Illumination source azimuth in degrees.
    ## - altitude: Illumination source altitude in degrees.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--buildings={buildings}")
    args.add(fmt"--output={output}")
    args.add(fmt"--radius={radius}")
    args.add(fmt"--num_iter={num_iter}")
    args.add(fmt"--num_samples={num_samples}")
    args.add(fmt"--threshold={threshold}")
    args.add(fmt"--model_size={model_size}")
    args.add(fmt"--max_slope={max_slope}")
    args.add(fmt"--norm_diff={norm_diff}")
    args.add(fmt"--azimuth={azimuth}")
    args.add(fmt"--altitude={altitude}")
    result = self.runTool("LidarRooftopAnalysis", args)

proc lidarSegmentation*(self: var WhiteboxTools, input: string, output: string, radius: float = 2.0, num_iter: int = 50, num_samples: int = 10, threshold: float = 0.15, model_size: int = 15, max_slope: float = 80.0, norm_diff: float = 10.0, maxzdiff: float = 1.0, classes: bool = false, ground: bool = false): byte =
    ## Segments a LiDAR point cloud based on differences in the orientation of fitted planar surfaces and point proximity.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarSegmentation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output LiDAR file.
    ## - radius: Search Radius.
    ## - num_iter: Number of iterations.
    ## - num_samples: Number of sample points on which to build the model.
    ## - threshold: Threshold used to determine inlier points.
    ## - model_size: Acceptable model size.
    ## - max_slope: Maximum planar slope.
    ## - norm_diff: Maximum difference in normal vectors, in degrees.
    ## - maxzdiff: Maximum difference in elevation (z units) between neighbouring points of the same segment.
    ## - classes: Segments don't cross class boundaries.
    ## - ground: Classify the largest segment as ground points?
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--radius={radius}")
    args.add(fmt"--num_iter={num_iter}")
    args.add(fmt"--num_samples={num_samples}")
    args.add(fmt"--threshold={threshold}")
    args.add(fmt"--model_size={model_size}")
    args.add(fmt"--max_slope={max_slope}")
    args.add(fmt"--norm_diff={norm_diff}")
    args.add(fmt"--maxzdiff={maxzdiff}")
    args.add(fmt"--classes={classes}")
    args.add(fmt"--ground={ground}")
    result = self.runTool("LidarSegmentation", args)

proc lidarSegmentationBasedFilter*(self: var WhiteboxTools, input: string, output: string, radius: float = 5.0, norm_diff: float = 2.0, maxzdiff: float = 1.0, classify = none(bool)): byte =
    ## Identifies ground points within LiDAR point clouds using a segmentation based approach.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarSegmentationBasedFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output file.
    ## - radius: Search Radius.
    ## - norm_diff: Maximum difference in normal vectors, in degrees.
    ## - maxzdiff: Maximum difference in elevation (z units) between neighbouring points of the same segment.
    ## - classify: Classify points as ground (2) or off-ground (1).
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--radius={radius}")
    args.add(fmt"--norm_diff={norm_diff}")
    args.add(fmt"--maxzdiff={maxzdiff}")
    if classify.isSome:
        args.add(fmt"--classify={classify}")
    result = self.runTool("LidarSegmentationBasedFilter", args)

proc lidarTINGridding*(self: var WhiteboxTools, input: string = "", output: string = "", parameter: string = "elevation", returns: string = "all", resolution: float = 1.0, exclude_cls: string = "", minz = none(float), maxz = none(float), max_triangle_edge_length = none(float)): byte =
    ## Creates a raster grid based on a Delaunay triangular irregular network (TIN) fitted to LiDAR points.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarTINGridding) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file (including extension).
    ## - output: Output raster file (including extension).
    ## - parameter: Interpolation parameter; options are 'elevation' (default), 'intensity', 'class', 'return_number', 'number_of_returns', 'scan angle', 'rgb', 'user data'.
    ## - returns: Point return types to include; options are 'all' (default), 'last', 'first'.
    ## - resolution: Output raster's grid resolution.
    ## - exclude_cls: Optional exclude classes from interpolation; Valid class values range from 0 to 18, based on LAS specifications. Example, --exclude_cls='3,4,5,6,7,18'.
    ## - minz: Optional minimum elevation for inclusion in interpolation.
    ## - maxz: Optional maximum elevation for inclusion in interpolation.
    ## - max_triangle_edge_length: Optional maximum triangle edge length; triangles larger than this size will not be gridded.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--parameter={parameter}")
    args.add(fmt"--returns={returns}")
    args.add(fmt"--resolution={resolution}")
    args.add(fmt"--exclude_cls={exclude_cls}")
    if minz.isSome:
        args.add(fmt"--minz={minz}")
    if maxz.isSome:
        args.add(fmt"--maxz={maxz}")
    if max_triangle_edge_length.isSome:
        args.add(fmt"--max_triangle_edge_length={max_triangle_edge_length}")
    result = self.runTool("LidarTINGridding", args)

proc lidarThin*(self: var WhiteboxTools, input: string, output: string, resolution: float = 2.0, method_val: string = "lowest", save_filtered: bool = false): byte =
    ## Thins a LiDAR point cloud, reducing point density.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarThin) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output LiDAR file.
    ## - resolution: The size of the square area used to evaluate nearby points in the LiDAR data.
    ## - method_val: Point selection method; options are 'first', 'last', 'lowest' (default), 'highest', 'nearest'.
    ## - save_filtered: Save filtered points to seperate file?
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--resolution={resolution}")
    args.add(fmt"--method_val={method_val}")
    args.add(fmt"--save_filtered={save_filtered}")
    result = self.runTool("LidarThin", args)

proc lidarThinHighDensity*(self: var WhiteboxTools, input: string, output: string, resolution: float = 1.0, density: float, save_filtered: bool = false): byte =
    ## Thins points from high density areas within a LiDAR point cloud.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarThinHighDensity) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output LiDAR file.
    ## - resolution: Output raster's grid resolution.
    ## - density: Max. point density (points / m^3).
    ## - save_filtered: Save filtered points to seperate file?
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--resolution={resolution}")
    args.add(fmt"--density={density}")
    args.add(fmt"--save_filtered={save_filtered}")
    result = self.runTool("LidarThinHighDensity", args)

proc lidarTile*(self: var WhiteboxTools, input: string, width: float = 1000.0, height: float = 1000.0, origin_x: float = 0.0, origin_y: float = 0.0, min_points: int = 2): byte =
    ## Tiles a LiDAR LAS file into multiple LAS files.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarTile) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - width: Width of tiles in the X dimension; default 1000.0.
    ## - height: Height of tiles in the Y dimension.
    ## - origin_x: Origin point X coordinate for tile grid.
    ## - origin_y: Origin point Y coordinate for tile grid.
    ## - min_points: Minimum number of points contained in a tile for it to be saved.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--width={width}")
    args.add(fmt"--height={height}")
    args.add(fmt"--origin_x={origin_x}")
    args.add(fmt"--origin_y={origin_y}")
    args.add(fmt"--min_points={min_points}")
    result = self.runTool("LidarTile", args)

proc lidarTileFootprint*(self: var WhiteboxTools, input: string = "", output: string, hull: bool = false): byte =
    ## Creates a vector polygon of the convex hull of a LiDAR point cloud. When the input/output parameters are not specified, the tool works with all LAS files contained within the working directory.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarTileFootprint) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output vector polygon file.
    ## - hull: Identify the convex hull around points.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--hull={hull}")
    result = self.runTool("LidarTileFootprint", args)

proc lidarTophatTransform*(self: var WhiteboxTools, input: string, output: string, radius: float = 1.0): byte =
    ## Performs a white top-hat transform on a Lidar dataset; as an estimate of height above ground, this is useful for modelling the vegetation canopy.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#LidarTophatTransform) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output LiDAR file.
    ## - radius: Search Radius.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--radius={radius}")
    result = self.runTool("LidarTophatTransform", args)

proc lineDetectionFilter*(self: var WhiteboxTools, input: string, output: string, variant: string = "vertical", absvals = none(bool), clip: float = 0.0): byte =
    ## Performs a line-detection filter on an image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#LineDetectionFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - variant: Optional variant value. Options include 'v' (vertical), 'h' (horizontal), '45', and '135' (default is 'v').
    ## - absvals: Optional flag indicating whether outputs should be absolute values.
    ## - clip: Optional amount to clip the distribution tails by, in percent.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--variant={variant}")
    if absvals.isSome:
        args.add(fmt"--absvals={absvals}")
    args.add(fmt"--clip={clip}")
    result = self.runTool("LineDetectionFilter", args)

proc lineIntersections*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## Identifies points where the features of two vector line layers intersect.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#LineIntersections) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input vector polyline file.
    ## - input2: Input vector polyline file.
    ## - output: Output vector point file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("LineIntersections", args)

proc lineThinning*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Performs line thinning a on Boolean raster image; intended to be used with the RemoveSpurs tool.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#LineThinning) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("LineThinning", args)

proc linearityIndex*(self: var WhiteboxTools, input: string): byte =
    ## Calculates the linearity index for vector polygons.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_patch_shape_tools.html#LinearityIndex) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector polygon file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    result = self.runTool("LinearityIndex", args)

proc linesToPolygons*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Converts vector polylines to polygons.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#LinesToPolygons) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector line file.
    ## - output: Output vector polygon file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("LinesToPolygons", args)

proc listUniqueValues*(self: var WhiteboxTools, input: string, field: string, output: string): byte =
    ## Lists the unique values contained in a field witin a vector's attribute table.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#ListUniqueValues) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - field: Input field name in attribute table.
    ## - output: Output HTML file (default name will be based on input file if unspecified).
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--field={field}")
    args.add(fmt"--output={output}")
    result = self.runTool("ListUniqueValues", args)

proc ln*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the natural logarithm of values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Ln) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Ln", args)

proc log10*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the base-10 logarithm of values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Log10) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Log10", args)

proc log2*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the base-2 logarithm of values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Log2) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Log2", args)

proc longProfile*(self: var WhiteboxTools, d8_pntr: string, streams: string, dem: string, output: string, esri_pntr: bool = false): byte =
    ## Plots the stream longitudinal profiles for one or more rivers.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#LongProfile) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - streams: Input raster streams file.
    ## - dem: Input raster DEM file.
    ## - output: Output HTML file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    result = self.runTool("LongProfile", args)

proc longProfileFromPoints*(self: var WhiteboxTools, d8_pntr: string, points: string, dem: string, output: string, esri_pntr: bool = false): byte =
    ## Plots the longitudinal profiles from flow-paths initiating from a set of vector points.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#LongProfileFromPoints) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - points: Input vector points file.
    ## - dem: Input raster DEM file.
    ## - output: Output HTML file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--points={points}")
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    result = self.runTool("LongProfileFromPoints", args)

proc longestFlowpath*(self: var WhiteboxTools, dem: string, basins: string, output: string): byte =
    ## Delineates the longest flowpaths for a group of subbasins or watersheds.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#LongestFlowpath) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - basins: Input raster basins file.
    ## - output: Output vector file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--basins={basins}")
    args.add(fmt"--output={output}")
    result = self.runTool("LongestFlowpath", args)

proc lowestPosition*(self: var WhiteboxTools, inputs: string, output: string): byte =
    ## Identifies the stack position of the minimum value within a raster stack on a cell-by-cell basis.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#LowestPosition) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--output={output}")
    result = self.runTool("LowestPosition", args)

proc mDInfFlowAccumulation*(self: var WhiteboxTools, dem: string, output: string, out_type: string = "specific contributing area", exponent: float = 1.1, threshold = none(float), log = none(bool), clip = none(bool)): byte =
    ## Calculates an FD8 flow accumulation raster from an input DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#MDInfFlowAccumulation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - out_type: Output type; one of 'cells', 'specific contributing area' (default), and 'catchment area'.
    ## - exponent: Optional exponent parameter; default is 1.1.
    ## - threshold: Optional convergence threshold parameter, in grid cells; default is inifinity.
    ## - log: Optional flag to request the output be log-transformed.
    ## - clip: Optional flag to request clipping the display max by 1%.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--out_type={out_type}")
    args.add(fmt"--exponent={exponent}")
    if threshold.isSome:
        args.add(fmt"--threshold={threshold}")
    if log.isSome:
        args.add(fmt"--log={log}")
    if clip.isSome:
        args.add(fmt"--clip={clip}")
    result = self.runTool("MDInfFlowAccumulation", args)

proc majorityFilter*(self: var WhiteboxTools, input: string, output: string, filterx: int = 11, filtery: int = 11): byte =
    ## Assigns each cell in the output grid the most frequently occurring value (mode) in a moving window centred on each grid cell in the input raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#MajorityFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    result = self.runTool("MajorityFilter", args)

proc max*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## Performs a MAX operation on two rasters or a raster and a constant value.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Max) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file or constant value.
    ## - input2: Input raster file or constant value.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("Max", args)

proc maxAbsoluteOverlay*(self: var WhiteboxTools, inputs: string, output: string): byte =
    ## Evaluates the maximum absolute value for each grid cell from a stack of input rasters.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#MaxAbsoluteOverlay) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--output={output}")
    result = self.runTool("MaxAbsoluteOverlay", args)

proc maxAnisotropyDev*(self: var WhiteboxTools, dem: string, out_mag: string, out_scale: string, min_scale: int = 3, max_scale: int, step: int = 2): byte =
    ## Calculates the maximum anisotropy (directionality) in elevation deviation over a range of spatial scales.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#MaxAnisotropyDev) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - out_mag: Output raster DEVmax magnitude file.
    ## - out_scale: Output raster DEVmax scale file.
    ## - min_scale: Minimum search neighbourhood radius in grid cells.
    ## - max_scale: Maximum search neighbourhood radius in grid cells.
    ## - step: Step size as any positive non-zero integer.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--out_mag={out_mag}")
    args.add(fmt"--out_scale={out_scale}")
    args.add(fmt"--min_scale={min_scale}")
    args.add(fmt"--max_scale={max_scale}")
    args.add(fmt"--step={step}")
    result = self.runTool("MaxAnisotropyDev", args)

proc maxAnisotropyDevSignature*(self: var WhiteboxTools, dem: string, points: string, output: string, min_scale: int = 1, max_scale: int, step: int = 1): byte =
    ## Calculates the anisotropy in deviation from mean for points over a range of spatial scales.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#MaxAnisotropyDevSignature) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - points: Input vector points file.
    ## - output: Output HTML file.
    ## - min_scale: Minimum search neighbourhood radius in grid cells.
    ## - max_scale: Maximum search neighbourhood radius in grid cells.
    ## - step: Step size as any positive non-zero integer.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--points={points}")
    args.add(fmt"--output={output}")
    args.add(fmt"--min_scale={min_scale}")
    args.add(fmt"--max_scale={max_scale}")
    args.add(fmt"--step={step}")
    result = self.runTool("MaxAnisotropyDevSignature", args)

proc maxBranchLength*(self: var WhiteboxTools, dem: string, output: string, log = none(bool)): byte =
    ## Lindsay and Seibert's (2013) branch length index is used to map drainage divides or ridge lines.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#MaxBranchLength) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - log: Optional flag to request the output be log-transformed.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    if log.isSome:
        args.add(fmt"--log={log}")
    result = self.runTool("MaxBranchLength", args)

proc maxDifferenceFromMean*(self: var WhiteboxTools, dem: string, out_mag: string, out_scale: string, min_scale: int, max_scale: int, step: int = 1): byte =
    ## Calculates the maximum difference from mean elevation over a range of spatial scales.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#MaxDifferenceFromMean) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - out_mag: Output raster DIFFmax magnitude file.
    ## - out_scale: Output raster DIFFmax scale file.
    ## - min_scale: Minimum search neighbourhood radius in grid cells.
    ## - max_scale: Maximum search neighbourhood radius in grid cells.
    ## - step: Step size as any positive non-zero integer.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--out_mag={out_mag}")
    args.add(fmt"--out_scale={out_scale}")
    args.add(fmt"--min_scale={min_scale}")
    args.add(fmt"--max_scale={max_scale}")
    args.add(fmt"--step={step}")
    result = self.runTool("MaxDifferenceFromMean", args)

proc maxDownslopeElevChange*(self: var WhiteboxTools, dem: string, output: string): byte =
    ## Calculates the maximum downslope change in elevation between a grid cell and its eight downslope neighbors.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#MaxDownslopeElevChange) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    result = self.runTool("MaxDownslopeElevChange", args)

proc maxElevDevSignature*(self: var WhiteboxTools, dem: string, points: string, output: string, min_scale: int, max_scale: int, step: int = 10): byte =
    ## Calculates the maximum elevation deviation over a range of spatial scales and for a set of points.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#MaxElevDevSignature) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - points: Input vector points file.
    ## - output: Output HTML file.
    ## - min_scale: Minimum search neighbourhood radius in grid cells.
    ## - max_scale: Maximum search neighbourhood radius in grid cells.
    ## - step: Step size as any positive non-zero integer.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--points={points}")
    args.add(fmt"--output={output}")
    args.add(fmt"--min_scale={min_scale}")
    args.add(fmt"--max_scale={max_scale}")
    args.add(fmt"--step={step}")
    result = self.runTool("MaxElevDevSignature", args)

proc maxElevationDeviation*(self: var WhiteboxTools, dem: string, out_mag: string, out_scale: string, min_scale: int, max_scale: int, step: int = 1): byte =
    ## Calculates the maximum elevation deviation over a range of spatial scales.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#MaxElevationDeviation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - out_mag: Output raster DEVmax magnitude file.
    ## - out_scale: Output raster DEVmax scale file.
    ## - min_scale: Minimum search neighbourhood radius in grid cells.
    ## - max_scale: Maximum search neighbourhood radius in grid cells.
    ## - step: Step size as any positive non-zero integer.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--out_mag={out_mag}")
    args.add(fmt"--out_scale={out_scale}")
    args.add(fmt"--min_scale={min_scale}")
    args.add(fmt"--max_scale={max_scale}")
    args.add(fmt"--step={step}")
    result = self.runTool("MaxElevationDeviation", args)

proc maxOverlay*(self: var WhiteboxTools, inputs: string, output: string): byte =
    ## Evaluates the maximum value for each grid cell from a stack of input rasters.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#MaxOverlay) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--output={output}")
    result = self.runTool("MaxOverlay", args)

proc maxUpslopeFlowpathLength*(self: var WhiteboxTools, dem: string, output: string): byte =
    ## Measures the maximum length of all upslope flowpaths draining each grid cell.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#MaxUpslopeFlowpathLength) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    result = self.runTool("MaxUpslopeFlowpathLength", args)

proc maximumFilter*(self: var WhiteboxTools, input: string, output: string, filterx: int = 11, filtery: int = 11): byte =
    ## Assigns each cell in the output grid the maximum value in a moving window centred on each grid cell in the input raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#MaximumFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    result = self.runTool("MaximumFilter", args)

proc meanFilter*(self: var WhiteboxTools, input: string, output: string, filterx: int = 3, filtery: int = 3): byte =
    ## Performs a mean filter (low-pass filter) on an input image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#MeanFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    result = self.runTool("MeanFilter", args)

proc medianFilter*(self: var WhiteboxTools, input: string, output: string, filterx: int = 11, filtery: int = 11, sig_digits: int = 2): byte =
    ## Performs a median filter on an input image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#MedianFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    ## - sig_digits: Number of significant digits.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    args.add(fmt"--sig_digits={sig_digits}")
    result = self.runTool("MedianFilter", args)

proc medoid*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Calculates the medoid for a series of vector features contained in a shapefile.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#Medoid) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    ## - output: Output vector file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Medoid", args)

proc mergeLineSegments*(self: var WhiteboxTools, input: string, output: string, snap: float = 0.0): byte =
    ## Merges vector line segments into larger features.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#MergeLineSegments) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    ## - output: Output vector file.
    ## - snap: Snap tolerance.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--snap={snap}")
    result = self.runTool("MergeLineSegments", args)

proc mergeTableWithCsv*(self: var WhiteboxTools, input: string, pkey: string, csv: string, fkey: string, import_field: string = ""): byte =
    ## Merge a vector's attribute table with a table contained within a CSV text file.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#MergeTableWithCsv) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input primary vector file (i.e. the table to be modified).
    ## - pkey: Primary key field.
    ## - csv: Input CSV file (i.e. source of data to be imported).
    ## - fkey: Foreign key field.
    ## - import_field: Imported field (all fields will be imported if not specified).
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--pkey={pkey}")
    args.add(fmt"--csv={csv}")
    args.add(fmt"--fkey={fkey}")
    args.add(fmt"--import_field={import_field}")
    result = self.runTool("MergeTableWithCsv", args)

proc mergeVectors*(self: var WhiteboxTools, inputs: string, output: string): byte =
    ## Combines two or more input vectors of the same ShapeType creating a single, new output vector.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#MergeVectors) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input vector files.
    ## - output: Output vector file.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--output={output}")
    result = self.runTool("MergeVectors", args)

proc min*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## Performs a MIN operation on two rasters or a raster and a constant value.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Min) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file or constant value.
    ## - input2: Input raster file or constant value.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("Min", args)

proc minAbsoluteOverlay*(self: var WhiteboxTools, inputs: string, output: string): byte =
    ## Evaluates the minimum absolute value for each grid cell from a stack of input rasters.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#MinAbsoluteOverlay) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--output={output}")
    result = self.runTool("MinAbsoluteOverlay", args)

proc minDownslopeElevChange*(self: var WhiteboxTools, dem: string, output: string): byte =
    ## Calculates the minimum downslope change in elevation between a grid cell and its eight downslope neighbors.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#MinDownslopeElevChange) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    result = self.runTool("MinDownslopeElevChange", args)

proc minMaxContrastStretch*(self: var WhiteboxTools, input: string, output: string, min_val: float, max_val: float, num_tones: int = 256): byte =
    ## Performs a min-max contrast stretch on an input greytone image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_image_enhancement.html#MinMaxContrastStretch) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - min_val: Lower tail clip value.
    ## - max_val: Upper tail clip value.
    ## - num_tones: Number of tones in the output image.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--min_val={min_val}")
    args.add(fmt"--max_val={max_val}")
    args.add(fmt"--num_tones={num_tones}")
    result = self.runTool("MinMaxContrastStretch", args)

proc minOverlay*(self: var WhiteboxTools, inputs: string, output: string): byte =
    ## Evaluates the minimum value for each grid cell from a stack of input rasters.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#MinOverlay) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--output={output}")
    result = self.runTool("MinOverlay", args)

proc minimumBoundingBox*(self: var WhiteboxTools, input: string, output: string, criterion: string = "area", features: bool = true): byte =
    ## Creates a vector minimum bounding rectangle around vector features.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#MinimumBoundingBox) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    ## - output: Output vector polygon file.
    ## - criterion: Minimization criterion; options include 'area' (default), 'length', 'width', and 'perimeter'.
    ## - features: Find the minimum bounding rectangles around each individual vector feature
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--criterion={criterion}")
    args.add(fmt"--features={features}")
    result = self.runTool("MinimumBoundingBox", args)

proc minimumBoundingCircle*(self: var WhiteboxTools, input: string, output: string, features: bool = true): byte =
    ## Delineates the minimum bounding circle (i.e. smallest enclosing circle) for a group of vectors.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#MinimumBoundingCircle) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    ## - output: Output vector polygon file.
    ## - features: Find the minimum bounding circle around each individual vector feature
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--features={features}")
    result = self.runTool("MinimumBoundingCircle", args)

proc minimumBoundingEnvelope*(self: var WhiteboxTools, input: string, output: string, features: bool = true): byte =
    ## Creates a vector axis-aligned minimum bounding rectangle (envelope) around vector features.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#MinimumBoundingEnvelope) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    ## - output: Output vector polygon file.
    ## - features: Find the minimum bounding envelop around each individual vector feature
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--features={features}")
    result = self.runTool("MinimumBoundingEnvelope", args)

proc minimumConvexHull*(self: var WhiteboxTools, input: string, output: string, features: bool = true): byte =
    ## Creates a vector convex polygon around vector features.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#MinimumConvexHull) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    ## - output: Output vector polygon file.
    ## - features: Find the hulls around each vector feature
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--features={features}")
    result = self.runTool("MinimumConvexHull", args)

proc minimumFilter*(self: var WhiteboxTools, input: string, output: string, filterx: int = 11, filtery: int = 11): byte =
    ## Assigns each cell in the output grid the minimum value in a moving window centred on each grid cell in the input raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#MinimumFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    result = self.runTool("MinimumFilter", args)

proc modifiedKMeansClustering*(self: var WhiteboxTools, inputs: string, output: string, out_html: string = "", start_clusters: int = 1000, merge_dist = none(float), max_iterations: int = 10, class_change: float = 2.0): byte =
    ## Performs a modified k-means clustering operation on a multi-spectral dataset.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#ModifiedKMeansClustering) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - output: Output raster file.
    ## - out_html: Output HTML report file.
    ## - start_clusters: Initial number of clusters
    ## - merge_dist: Cluster merger distance
    ## - max_iterations: Maximum number of iterations
    ## - class_change: Minimum percent of cells changed between iterations before completion
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--output={output}")
    args.add(fmt"--out_html={out_html}")
    args.add(fmt"--start_clusters={start_clusters}")
    if merge_dist.isSome:
        args.add(fmt"--merge_dist={merge_dist}")
    args.add(fmt"--max_iterations={max_iterations}")
    args.add(fmt"--class_change={class_change}")
    result = self.runTool("ModifiedKMeansClustering", args)

proc modifyNoDataValue*(self: var WhiteboxTools, input: string, new_value: float = -32768.0): byte =
    ## Converts nodata values in a raster to zero.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#ModifyNoDataValue) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - new_value: New NoData value.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--new_value={new_value}")
    result = self.runTool("ModifyNoDataValue", args)

proc modulo*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## Performs a modulo operation on two rasters or a raster and a constant value.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Modulo) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file or constant value.
    ## - input2: Input raster file or constant value.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("Modulo", args)

proc mosaic*(self: var WhiteboxTools, inputs: string = "", output: string, method_val: string = "nn"): byte =
    ## Mosaics two or more images together.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#Mosaic) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - output: Output raster file.
    ## - method_val: Resampling method; options include 'nn' (nearest neighbour), 'bilinear', and 'cc' (cubic convolution)
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--output={output}")
    args.add(fmt"--method_val={method_val}")
    result = self.runTool("Mosaic", args)

proc mosaicWithFeathering*(self: var WhiteboxTools, input1: string, input2: string, output: string, method_val: string = "cc", weight: float = 4.0): byte =
    ## Mosaics two images together using a feathering technique in overlapping areas to reduce edge-effects.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#MosaicWithFeathering) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file to modify.
    ## - input2: Input reference raster file.
    ## - output: Output raster file.
    ## - method_val: Resampling method; options include 'nn' (nearest neighbour), 'bilinear', and 'cc' (cubic convolution)
    ## - weight: 
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    args.add(fmt"--method_val={method_val}")
    args.add(fmt"--weight={weight}")
    result = self.runTool("MosaicWithFeathering", args)

proc multiPartToSinglePart*(self: var WhiteboxTools, input: string, output: string, exclude_holes: bool = true): byte =
    ## Converts a vector file containing multi-part features into a vector containing only single-part features.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#MultiPartToSinglePart) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector line or polygon file.
    ## - output: Output vector line or polygon file.
    ## - exclude_holes: Exclude hole parts from the feature splitting? (holes will continue to belong to their features in output.)
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--exclude_holes={exclude_holes}")
    result = self.runTool("MultiPartToSinglePart", args)

proc multiply*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## Performs a multiplication operation on two rasters or a raster and a constant value.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Multiply) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file or constant value.
    ## - input2: Input raster file or constant value.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("Multiply", args)

proc multiscaleElevationPercentile*(self: var WhiteboxTools, dem: string, out_mag: string, out_scale: string, sig_digits: int = 3, min_scale: int = 4, step: int = 1, num_steps: int = 10, step_nonlinearity: float = 1.0): byte =
    ## Calculates surface roughness over a range of spatial scales.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#MultiscaleElevationPercentile) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - out_mag: Output raster roughness magnitude file.
    ## - out_scale: Output raster roughness scale file.
    ## - sig_digits: Number of significant digits.
    ## - min_scale: Minimum search neighbourhood radius in grid cells.
    ## - step: Step size as any positive non-zero integer.
    ## - num_steps: Number of steps
    ## - step_nonlinearity: Step nonlinearity factor (1.0-2.0 is typical)
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--out_mag={out_mag}")
    args.add(fmt"--out_scale={out_scale}")
    args.add(fmt"--sig_digits={sig_digits}")
    args.add(fmt"--min_scale={min_scale}")
    args.add(fmt"--step={step}")
    args.add(fmt"--num_steps={num_steps}")
    args.add(fmt"--step_nonlinearity={step_nonlinearity}")
    result = self.runTool("MultiscaleElevationPercentile", args)

proc multiscaleRoughness*(self: var WhiteboxTools, dem: string, out_mag: string, out_scale: string, min_scale: int = 1, max_scale: int, step: int = 1): byte =
    ## Calculates surface roughness over a range of spatial scales.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#MultiscaleRoughness) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - out_mag: Output raster roughness magnitude file.
    ## - out_scale: Output raster roughness scale file.
    ## - min_scale: Minimum search neighbourhood radius in grid cells.
    ## - max_scale: Maximum search neighbourhood radius in grid cells.
    ## - step: Step size as any positive non-zero integer.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--out_mag={out_mag}")
    args.add(fmt"--out_scale={out_scale}")
    args.add(fmt"--min_scale={min_scale}")
    args.add(fmt"--max_scale={max_scale}")
    args.add(fmt"--step={step}")
    result = self.runTool("MultiscaleRoughness", args)

proc multiscaleRoughnessSignature*(self: var WhiteboxTools, dem: string, points: string, output: string, min_scale: int = 1, max_scale: int, step: int = 1): byte =
    ## Calculates the surface roughness for points over a range of spatial scales.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#MultiscaleRoughnessSignature) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - points: Input vector points file.
    ## - output: Output HTML file.
    ## - min_scale: Minimum search neighbourhood radius in grid cells.
    ## - max_scale: Maximum search neighbourhood radius in grid cells.
    ## - step: Step size as any positive non-zero integer.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--points={points}")
    args.add(fmt"--output={output}")
    args.add(fmt"--min_scale={min_scale}")
    args.add(fmt"--max_scale={max_scale}")
    args.add(fmt"--step={step}")
    result = self.runTool("MultiscaleRoughnessSignature", args)

proc multiscaleStdDevNormals*(self: var WhiteboxTools, dem: string, out_mag: string, out_scale: string, min_scale: int = 1, step: int = 1, num_steps: int = 10, step_nonlinearity: float = 1.0): byte =
    ## Calculates surface roughness over a range of spatial scales.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#MultiscaleStdDevNormals) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - out_mag: Output raster roughness magnitude file.
    ## - out_scale: Output raster roughness scale file.
    ## - min_scale: Minimum search neighbourhood radius in grid cells.
    ## - step: Step size as any positive non-zero integer.
    ## - num_steps: Number of steps
    ## - step_nonlinearity: Step nonlinearity factor (1.0-2.0 is typical)
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--out_mag={out_mag}")
    args.add(fmt"--out_scale={out_scale}")
    args.add(fmt"--min_scale={min_scale}")
    args.add(fmt"--step={step}")
    args.add(fmt"--num_steps={num_steps}")
    args.add(fmt"--step_nonlinearity={step_nonlinearity}")
    result = self.runTool("MultiscaleStdDevNormals", args)

proc multiscaleStdDevNormalsSignature*(self: var WhiteboxTools, dem: string, points: string, output: string, min_scale: int = 1, step: int = 1, num_steps: int = 10, step_nonlinearity: float = 1.0): byte =
    ## Calculates the surface roughness for points over a range of spatial scales.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#MultiscaleStdDevNormalsSignature) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - points: Input vector points file.
    ## - output: Output HTML file.
    ## - min_scale: Minimum search neighbourhood radius in grid cells.
    ## - step: Step size as any positive non-zero integer.
    ## - num_steps: Number of steps
    ## - step_nonlinearity: Step nonlinearity factor (1.0-2.0 is typical)
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--points={points}")
    args.add(fmt"--output={output}")
    args.add(fmt"--min_scale={min_scale}")
    args.add(fmt"--step={step}")
    args.add(fmt"--num_steps={num_steps}")
    args.add(fmt"--step_nonlinearity={step_nonlinearity}")
    result = self.runTool("MultiscaleStdDevNormalsSignature", args)

proc multiscaleTopographicPositionImage*(self: var WhiteboxTools, local: string, meso: string, broad: string, output: string, lightness: float = 1.2): byte =
    ## Creates a multiscale topographic position image from three DEVmax rasters of differing spatial scale ranges.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#MultiscaleTopographicPositionImage) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - local: Input local-scale topographic position (DEVmax) raster file.
    ## - meso: Input meso-scale topographic position (DEVmax) raster file.
    ## - broad: Input broad-scale topographic position (DEVmax) raster file.
    ## - output: Output raster file.
    ## - lightness: Image lightness value (default is 1.2).
    var args = newSeq[string]()
    args.add(fmt"--local={local}")
    args.add(fmt"--meso={meso}")
    args.add(fmt"--broad={broad}")
    args.add(fmt"--output={output}")
    args.add(fmt"--lightness={lightness}")
    result = self.runTool("MultiscaleTopographicPositionImage", args)

proc narrownessIndex*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Calculates the narrowness of raster polygons.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_patch_shape_tools.html#NarrownessIndex) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("NarrownessIndex", args)

proc naturalNeighbourInterpolation*(self: var WhiteboxTools, input: string, field: string = "", use_z: bool = false, output: string, cell_size = none(float), base: string = "", clip: bool = true): byte =
    ## Creates a raster grid based on Sibson's natural neighbour method.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#NaturalNeighbourInterpolation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector points file.
    ## - field: Input field name in attribute table.
    ## - use_z: Use the 'z' dimension of the Shapefile's geometry instead of an attribute field?
    ## - output: Output raster file.
    ## - cell_size: Optionally specified cell size of output raster. Not used when base raster is specified.
    ## - base: Optionally specified input base raster file. Not used when a cell size is specified.
    ## - clip: Clip the data to the convex hull of the points?
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--field={field}")
    args.add(fmt"--use_z={use_z}")
    args.add(fmt"--output={output}")
    if cell_size.isSome:
        args.add(fmt"--cell_size={cell_size}")
    args.add(fmt"--base={base}")
    args.add(fmt"--clip={clip}")
    result = self.runTool("NaturalNeighbourInterpolation", args)

proc nearestNeighbourGridding*(self: var WhiteboxTools, input: string, field: string, use_z: bool = false, output: string, cell_size = none(float), base: string = "", max_dist = none(float)): byte =
    ## Creates a raster grid based on a set of vector points and assigns grid values using the nearest neighbour.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#NearestNeighbourGridding) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector Points file.
    ## - field: Input field name in attribute table.
    ## - use_z: Use z-coordinate instead of field?
    ## - output: Output raster file.
    ## - cell_size: Optionally specified cell size of output raster. Not used when base raster is specified.
    ## - base: Optionally specified input base raster file. Not used when a cell size is specified.
    ## - max_dist: Maximum search distance (optional)
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--field={field}")
    args.add(fmt"--use_z={use_z}")
    args.add(fmt"--output={output}")
    if cell_size.isSome:
        args.add(fmt"--cell_size={cell_size}")
    args.add(fmt"--base={base}")
    if max_dist.isSome:
        args.add(fmt"--max_dist={max_dist}")
    result = self.runTool("NearestNeighbourGridding", args)

proc negate*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Changes the sign of values in a raster or the 0-1 values of a Boolean raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Negate) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Negate", args)

proc newRasterFromBase*(self: var WhiteboxTools, base: string, output: string, value: string = "nodata", data_type: string = "float"): byte =
    ## Creates a new raster using a base image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#NewRasterFromBase) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - base: Input base raster file.
    ## - output: Output raster file.
    ## - value: Constant value to fill raster with; either 'nodata' or numeric value.
    ## - data_type: Output raster data type; options include 'double' (64-bit), 'float' (32-bit), and 'integer' (signed 16-bit) (default is 'float').
    var args = newSeq[string]()
    args.add(fmt"--base={base}")
    args.add(fmt"--output={output}")
    args.add(fmt"--value={value}")
    args.add(fmt"--data_type={data_type}")
    result = self.runTool("NewRasterFromBase", args)

proc normalVectors*(self: var WhiteboxTools, input: string, output: string, radius: float = 1.0): byte =
    ## Calculates normal vectors for points within a LAS file and stores these data (XYZ vector components) in the RGB field.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#NormalVectors) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input LiDAR file.
    ## - output: Output LiDAR file.
    ## - radius: Search Radius.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--radius={radius}")
    result = self.runTool("NormalVectors", args)

proc normalizedDifferenceIndex*(self: var WhiteboxTools, input1: string, input2: string, output: string, clip: float = 0.0, correction: float = 0.0): byte =
    ## Calculate a normalized-difference index (NDI) from two bands of multispectral image data.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#NormalizedDifferenceIndex) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input image 1 (e.g. near-infrared band).
    ## - input2: Input image 2 (e.g. red band).
    ## - output: Output raster file.
    ## - clip: Optional amount to clip the distribution tails by, in percent.
    ## - correction: Optional adjustment value (e.g. 1, or 0.16 for the optimal soil adjusted vegetation index, OSAVI).
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    args.add(fmt"--clip={clip}")
    args.add(fmt"--correction={correction}")
    result = self.runTool("NormalizedDifferenceIndex", args)

proc Not*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## Performs a logical NOT operator on two Boolean raster images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Not) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file.
    ## - input2: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("Not", args)

proc notEqualTo*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## Performs a not-equal-to comparison operation on two rasters or a raster and a constant value.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#NotEqualTo) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file or constant value.
    ## - input2: Input raster file or constant value.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("NotEqualTo", args)

proc numDownslopeNeighbours*(self: var WhiteboxTools, dem: string, output: string): byte =
    ## Calculates the number of downslope neighbours to each grid cell in a DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#NumDownslopeNeighbours) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    result = self.runTool("NumDownslopeNeighbours", args)

proc numInflowingNeighbours*(self: var WhiteboxTools, dem: string, output: string): byte =
    ## Computes the number of inflowing neighbours to each cell in an input DEM based on the D8 algorithm.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#NumInflowingNeighbours) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    result = self.runTool("NumInflowingNeighbours", args)

proc numUpslopeNeighbours*(self: var WhiteboxTools, dem: string, output: string): byte =
    ## Calculates the number of upslope neighbours to each grid cell in a DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#NumUpslopeNeighbours) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    result = self.runTool("NumUpslopeNeighbours", args)

proc olympicFilter*(self: var WhiteboxTools, input: string, output: string, filterx: int = 11, filtery: int = 11): byte =
    ## Performs an olympic smoothing filter on an image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#OlympicFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    result = self.runTool("OlympicFilter", args)

proc opening*(self: var WhiteboxTools, input: string, output: string, filterx: int = 11, filtery: int = 11): byte =
    ## An opening is a mathematical morphology operation involving a dilation (max filter) of an erosion (min filter) set.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#Opening) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    result = self.runTool("Opening", args)

proc Or*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## Performs a logical OR operator on two Boolean raster images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Or) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file.
    ## - input2: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("Or", args)

proc pairedSampleTTest*(self: var WhiteboxTools, input1: string, input2: string, output: string, num_samples = none(int)): byte =
    ## Performs a 2-sample K-S test for significant differences on two input rasters.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#PairedSampleTTest) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: First input raster file.
    ## - input2: Second input raster file.
    ## - output: Output HTML file.
    ## - num_samples: Number of samples. Leave blank to use whole image.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    if num_samples.isSome:
        args.add(fmt"--num_samples={num_samples}")
    result = self.runTool("PairedSampleTTest", args)

proc panchromaticSharpening*(self: var WhiteboxTools, red: string = "", green: string = "", blue: string = "", composite: string = "", pan: string, output: string, method_val: string = "brovey"): byte =
    ## Increases the spatial resolution of image data by combining multispectral bands with panchromatic data.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_image_enhancement.html#PanchromaticSharpening) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - red: Input red band image file. Optionally specified if colour-composite not specified.
    ## - green: Input green band image file. Optionally specified if colour-composite not specified.
    ## - blue: Input blue band image file. Optionally specified if colour-composite not specified.
    ## - composite: Input colour-composite image file. Only used if individual bands are not specified.
    ## - pan: Input panchromatic band file.
    ## - output: Output colour composite file.
    ## - method_val: Options include 'brovey' (default) and 'ihs'
    var args = newSeq[string]()
    args.add(fmt"--red={red}")
    args.add(fmt"--green={green}")
    args.add(fmt"--blue={blue}")
    args.add(fmt"--composite={composite}")
    args.add(fmt"--pan={pan}")
    args.add(fmt"--output={output}")
    args.add(fmt"--method_val={method_val}")
    result = self.runTool("PanchromaticSharpening", args)

proc patchOrientation*(self: var WhiteboxTools, input: string): byte =
    ## Calculates the orientation of vector polygons.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_patch_shape_tools.html#PatchOrientation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector polygon file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    result = self.runTool("PatchOrientation", args)

proc pennockLandformClass*(self: var WhiteboxTools, dem: string, output: string, slope: float = 3.0, prof: float = 0.1, plan: float = 0.0, zfactor: float = 1.0): byte =
    ## Classifies hillslope zones based on slope, profile curvature, and plan curvature.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#PennockLandformClass) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - slope: Slope threshold value, in degrees (default is 3.0)
    ## - prof: Profile curvature threshold value (default is 0.1)
    ## - plan: Plan curvature threshold value (default is 0.0).
    ## - zfactor: Optional multiplier for when the vertical and horizontal units are not the same.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--slope={slope}")
    args.add(fmt"--prof={prof}")
    args.add(fmt"--plan={plan}")
    args.add(fmt"--zfactor={zfactor}")
    result = self.runTool("PennockLandformClass", args)

proc percentElevRange*(self: var WhiteboxTools, dem: string, output: string, filterx: int = 3, filtery: int = 3): byte =
    ## Calculates percent of elevation range from a DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#PercentElevRange) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    result = self.runTool("PercentElevRange", args)

proc percentEqualTo*(self: var WhiteboxTools, inputs: string, comparison: string, output: string): byte =
    ## Calculates the percentage of a raster stack that have cell values equal to an input on a cell-by-cell basis.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#PercentEqualTo) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - comparison: Input comparison raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--comparison={comparison}")
    args.add(fmt"--output={output}")
    result = self.runTool("PercentEqualTo", args)

proc percentGreaterThan*(self: var WhiteboxTools, inputs: string, comparison: string, output: string): byte =
    ## Calculates the percentage of a raster stack that have cell values greather than an input on a cell-by-cell basis.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#PercentGreaterThan) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - comparison: Input comparison raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--comparison={comparison}")
    args.add(fmt"--output={output}")
    result = self.runTool("PercentGreaterThan", args)

proc percentLessThan*(self: var WhiteboxTools, inputs: string, comparison: string, output: string): byte =
    ## Calculates the percentage of a raster stack that have cell values less than an input on a cell-by-cell basis.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#PercentLessThan) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - comparison: Input comparison raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--comparison={comparison}")
    args.add(fmt"--output={output}")
    result = self.runTool("PercentLessThan", args)

proc percentageContrastStretch*(self: var WhiteboxTools, input: string, output: string, clip: float = 1.0, tail: string = "both", num_tones: int = 256): byte =
    ## Performs a percentage linear contrast stretch on input images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_image_enhancement.html#PercentageContrastStretch) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - clip: Optional amount to clip the distribution tails by, in percent.
    ## - tail: Specified which tails to clip; options include 'upper', 'lower', and 'both' (default is 'both').
    ## - num_tones: Number of tones in the output image.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--clip={clip}")
    args.add(fmt"--tail={tail}")
    args.add(fmt"--num_tones={num_tones}")
    result = self.runTool("PercentageContrastStretch", args)

proc percentileFilter*(self: var WhiteboxTools, input: string, output: string, filterx: int = 11, filtery: int = 11, sig_digits: int = 2): byte =
    ## Performs a percentile filter on an input image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#PercentileFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    ## - sig_digits: Number of significant digits.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    args.add(fmt"--sig_digits={sig_digits}")
    result = self.runTool("PercentileFilter", args)

proc perimeterAreaRatio*(self: var WhiteboxTools, input: string): byte =
    ## Calculates the perimeter-area ratio of vector polygons.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_patch_shape_tools.html#PerimeterAreaRatio) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector polygon file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    result = self.runTool("PerimeterAreaRatio", args)

proc pickFromList*(self: var WhiteboxTools, inputs: string, pos_input: string, output: string): byte =
    ## Outputs the value from a raster stack specified by a position raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#PickFromList) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - pos_input: Input position raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--pos_input={pos_input}")
    args.add(fmt"--output={output}")
    result = self.runTool("PickFromList", args)

proc planCurvature*(self: var WhiteboxTools, dem: string, output: string, zfactor: float = 1.0): byte =
    ## Calculates a plan (contour) curvature raster from an input DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#PlanCurvature) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - zfactor: Optional multiplier for when the vertical and horizontal units are not the same.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--zfactor={zfactor}")
    result = self.runTool("PlanCurvature", args)

proc polygonArea*(self: var WhiteboxTools, input: string): byte =
    ## Calculates the area of vector polygons.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#PolygonArea) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector polygon file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    result = self.runTool("PolygonArea", args)

proc polygonLongAxis*(self: var WhiteboxTools, input: string, output: string): byte =
    ## This tool can be used to map the long axis of polygon features.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#PolygonLongAxis) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector polygons file.
    ## - output: Output vector polyline file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("PolygonLongAxis", args)

proc polygonPerimeter*(self: var WhiteboxTools, input: string): byte =
    ## Calculates the perimeter of vector polygons.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#PolygonPerimeter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector polygon file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    result = self.runTool("PolygonPerimeter", args)

proc polygonShortAxis*(self: var WhiteboxTools, input: string, output: string): byte =
    ## This tool can be used to map the short axis of polygon features.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#PolygonShortAxis) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector polygons file.
    ## - output: Output vector polyline file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("PolygonShortAxis", args)

proc polygonize*(self: var WhiteboxTools, inputs: string, output: string): byte =
    ## Creates a polygon layer from two or more intersecting line features contained in one or more input vector line files.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#Polygonize) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input vector polyline file.
    ## - output: Output vector polygon file.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--output={output}")
    result = self.runTool("Polygonize", args)

proc polygonsToLines*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Converts vector polygons to polylines.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#PolygonsToLines) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector polygon file.
    ## - output: Output vector lines file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("PolygonsToLines", args)

proc power*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## Raises the values in grid cells of one rasters, or a constant value, by values in another raster or constant value.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Power) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file or constant value.
    ## - input2: Input raster file or constant value.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("Power", args)

proc prewittFilter*(self: var WhiteboxTools, input: string, output: string, clip: float = 0.0): byte =
    ## Performs a Prewitt edge-detection filter on an image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#PrewittFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - clip: Optional amount to clip the distribution tails by, in percent.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--clip={clip}")
    result = self.runTool("PrewittFilter", args)

proc principalComponentAnalysis*(self: var WhiteboxTools, inputs: string, output: string, num_comp = none(int), standardized = none(bool)): byte =
    ## Performs a principal component analysis (PCA) on a multi-spectral dataset.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#PrincipalComponentAnalysis) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - output: Output HTML report file.
    ## - num_comp: Number of component images to output; <= to num. input images
    ## - standardized: Perform standardized PCA?
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--output={output}")
    if num_comp.isSome:
        args.add(fmt"--num_comp={num_comp}")
    if standardized.isSome:
        args.add(fmt"--standardized={standardized}")
    result = self.runTool("PrincipalComponentAnalysis", args)

proc printGeoTiffTags*(self: var WhiteboxTools, input: string): byte =
    ## Prints the tags within a GeoTIFF.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#PrintGeoTiffTags) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input GeoTIFF file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    result = self.runTool("PrintGeoTiffTags", args)

proc profile*(self: var WhiteboxTools, lines: string, surface: string, output: string): byte =
    ## Plots profiles from digital surface models.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#Profile) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - lines: Input vector line file.
    ## - surface: Input raster surface file.
    ## - output: Output HTML file.
    var args = newSeq[string]()
    args.add(fmt"--lines={lines}")
    args.add(fmt"--surface={surface}")
    args.add(fmt"--output={output}")
    result = self.runTool("Profile", args)

proc profileCurvature*(self: var WhiteboxTools, dem: string, output: string, zfactor: float = 1.0): byte =
    ## Calculates a profile curvature raster from an input DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#ProfileCurvature) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - zfactor: Optional multiplier for when the vertical and horizontal units are not the same.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--zfactor={zfactor}")
    result = self.runTool("ProfileCurvature", args)

proc quantiles*(self: var WhiteboxTools, input: string, output: string, num_quantiles: int = 5): byte =
    ## Transforms raster values into quantiles.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Quantiles) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - num_quantiles: Number of quantiles.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--num_quantiles={num_quantiles}")
    result = self.runTool("Quantiles", args)

proc radialBasisFunctionInterpolation*(self: var WhiteboxTools, input: string, field: string, use_z: bool = false, output: string, radius = none(float), min_points = none(int), func_type: string = "ThinPlateSpline", poly_order: string = "none", weight: float = 0.1, cell_size = none(float), base: string = ""): byte =
    ## Interpolates vector points into a raster surface using a radial basis function scheme.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#RadialBasisFunctionInterpolation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector points file.
    ## - field: Input field name in attribute table.
    ## - use_z: Use z-coordinate instead of field?
    ## - output: Output raster file.
    ## - radius: Search Radius (in map units).
    ## - min_points: Minimum number of points.
    ## - func_type: Radial basis function type; options are 'ThinPlateSpline' (default), 'PolyHarmonic', 'Gaussian', 'MultiQuadric', 'InverseMultiQuadric'.
    ## - poly_order: Polynomial order; options are 'none' (default), 'constant', 'affine'.
    ## - weight: Weight parameter used in basis function.
    ## - cell_size: Optionally specified cell size of output raster. Not used when base raster is specified.
    ## - base: Optionally specified input base raster file. Not used when a cell size is specified.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--field={field}")
    args.add(fmt"--use_z={use_z}")
    args.add(fmt"--output={output}")
    if radius.isSome:
        args.add(fmt"--radius={radius}")
    if min_points.isSome:
        args.add(fmt"--min_points={min_points}")
    args.add(fmt"--func_type={func_type}")
    args.add(fmt"--poly_order={poly_order}")
    args.add(fmt"--weight={weight}")
    if cell_size.isSome:
        args.add(fmt"--cell_size={cell_size}")
    args.add(fmt"--base={base}")
    result = self.runTool("RadialBasisFunctionInterpolation", args)

proc radiusOfGyration*(self: var WhiteboxTools, input: string, output: string, text_output: bool): byte =
    ## Calculates the distance of cells from their polygon's centroid.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_patch_shape_tools.html#RadiusOfGyration) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - text_output: Optional text output.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--text_output={text_output}")
    result = self.runTool("RadiusOfGyration", args)

proc raiseWalls*(self: var WhiteboxTools, input: string, breach: string = "", dem: string, output: string, height: float = 100.0): byte =
    ## Raises walls in a DEM along a line or around a polygon, e.g. a watershed.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#RaiseWalls) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector lines or polygons file.
    ## - breach: Optional input vector breach lines.
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - height: Wall height.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--breach={breach}")
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--height={height}")
    result = self.runTool("RaiseWalls", args)

proc randomField*(self: var WhiteboxTools, base: string, output: string): byte =
    ## Creates an image containing random values.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#RandomField) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - base: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--base={base}")
    args.add(fmt"--output={output}")
    result = self.runTool("RandomField", args)

proc randomSample*(self: var WhiteboxTools, base: string, output: string, num_samples: int = 1000): byte =
    ## Creates an image containing randomly located sample grid cells with unique IDs.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#RandomSample) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - base: Input raster file.
    ## - output: Output raster file.
    ## - num_samples: Number of samples
    var args = newSeq[string]()
    args.add(fmt"--base={base}")
    args.add(fmt"--output={output}")
    args.add(fmt"--num_samples={num_samples}")
    result = self.runTool("RandomSample", args)

proc rangeFilter*(self: var WhiteboxTools, input: string, output: string, filterx: int = 11, filtery: int = 11): byte =
    ## Assigns each cell in the output grid the range of values in a moving window centred on each grid cell in the input raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#RangeFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    result = self.runTool("RangeFilter", args)

proc rasterArea*(self: var WhiteboxTools, input: string, output: string = "", out_text: bool, units: string = "grid cells", zero_back: bool): byte =
    ## Calculates the area of polygons or classes within a raster image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#RasterArea) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - out_text: Would you like to output polygon areas to text?
    ## - units: Area units; options include 'grid cells' and 'map units'.
    ## - zero_back: Flag indicating whether zero values should be treated as a background.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--out_text={out_text}")
    args.add(fmt"--units={units}")
    args.add(fmt"--zero_back={zero_back}")
    result = self.runTool("RasterArea", args)

proc rasterCellAssignment*(self: var WhiteboxTools, input: string, output: string, assign: string = "column"): byte =
    ## Assign row or column number to cells.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#RasterCellAssignment) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - assign: Which variable would you like to assign to grid cells? Options include 'column', 'row', 'x', and 'y'.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--assign={assign}")
    result = self.runTool("RasterCellAssignment", args)

proc rasterHistogram*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Creates a histogram from raster values.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#RasterHistogram) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output HTML file (default name will be based on input file if unspecified).
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("RasterHistogram", args)

proc rasterPerimeter*(self: var WhiteboxTools, input: string, output: string = "", out_text: bool, units: string = "grid cells", zero_back: bool): byte =
    ## Calculates the perimeters of polygons or classes within a raster image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#RasterPerimeter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - out_text: Would you like to output polygon areas to text?
    ## - units: Area units; options include 'grid cells' and 'map units'.
    ## - zero_back: Flag indicating whether zero values should be treated as a background.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--out_text={out_text}")
    args.add(fmt"--units={units}")
    args.add(fmt"--zero_back={zero_back}")
    result = self.runTool("RasterPerimeter", args)

proc rasterStreamsToVector*(self: var WhiteboxTools, streams: string, d8_pntr: string, output: string, esri_pntr: bool = false): byte =
    ## Converts a raster stream file into a vector file.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#RasterStreamsToVector) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - streams: Input raster streams file.
    ## - d8_pntr: Input raster D8 pointer file.
    ## - output: Output vector file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    var args = newSeq[string]()
    args.add(fmt"--streams={streams}")
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    result = self.runTool("RasterStreamsToVector", args)

proc rasterSummaryStats*(self: var WhiteboxTools, input: string): byte =
    ## Measures a rasters min, max, average, standard deviation, num. non-nodata cells, and total.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#RasterSummaryStats) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    result = self.runTool("RasterSummaryStats", args)

proc rasterToVectorLines*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Converts a raster lines features into a vector of the POLYLINE shapetype
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#RasterToVectorLines) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster lines file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("RasterToVectorLines", args)

proc rasterToVectorPoints*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Converts a raster dataset to a vector of the POINT shapetype.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#RasterToVectorPoints) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output vector points file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("RasterToVectorPoints", args)

proc rasterToVectorPolygons*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Converts a raster dataset to a vector of the POLYGON shapetype.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#RasterToVectorPolygons) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output vector polygons file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("RasterToVectorPolygons", args)

proc rasterizeStreams*(self: var WhiteboxTools, streams: string, base: string, output: string, nodata: bool = true, feature_id: bool = false): byte =
    ## Rasterizes vector streams based on Lindsay (2016) method.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#RasterizeStreams) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - streams: Input vector streams file.
    ## - base: Input base raster file.
    ## - output: Output raster file.
    ## - nodata: Use NoData value for background?
    ## - feature_id: Use feature number as output value?
    var args = newSeq[string]()
    args.add(fmt"--streams={streams}")
    args.add(fmt"--base={base}")
    args.add(fmt"--output={output}")
    args.add(fmt"--nodata={nodata}")
    args.add(fmt"--feature_id={feature_id}")
    result = self.runTool("RasterizeStreams", args)

proc reciprocal*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the reciprocal (i.e. 1 / z) of values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Reciprocal) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Reciprocal", args)

proc reclass*(self: var WhiteboxTools, input: string, output: string, reclass_vals: string, assign_mode = none(bool)): byte =
    ## Reclassifies the values in a raster image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#Reclass) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - reclass_vals: Reclassification triplet values (new value; from value; to less than), e.g. '0.0;0.0;1.0;1.0;1.0;2.0'
    ## - assign_mode: Optional Boolean flag indicating whether to operate in assign mode, reclass_vals values are interpreted as new value; old value pairs.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--reclass_vals={reclass_vals}")
    if assign_mode.isSome:
        args.add(fmt"--assign_mode={assign_mode}")
    result = self.runTool("Reclass", args)

proc reclassEqualInterval*(self: var WhiteboxTools, input: string, output: string, interval: float = 10.0, start_val = none(float), end_val = none(float)): byte =
    ## Reclassifies the values in a raster image based on equal-ranges.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#ReclassEqualInterval) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - interval: Class interval size.
    ## - start_val: Optional starting value (default is input minimum value).
    ## - end_val: Optional ending value (default is input maximum value).
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--interval={interval}")
    if start_val.isSome:
        args.add(fmt"--start_val={start_val}")
    if end_val.isSome:
        args.add(fmt"--end_val={end_val}")
    result = self.runTool("ReclassEqualInterval", args)

proc reclassFromFile*(self: var WhiteboxTools, input: string, reclass_file: string, output: string): byte =
    ## Reclassifies the values in a raster image using reclass ranges in a text file.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#ReclassFromFile) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - reclass_file: Input text file containing reclass ranges.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--reclass_file={reclass_file}")
    args.add(fmt"--output={output}")
    result = self.runTool("ReclassFromFile", args)

proc reinitializeAttributeTable*(self: var WhiteboxTools, input: string): byte =
    ## Reinitializes a vector's attribute table deleting all fields but the feature ID (FID).
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#ReinitializeAttributeTable) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    result = self.runTool("ReinitializeAttributeTable", args)

proc relatedCircumscribingCircle*(self: var WhiteboxTools, input: string): byte =
    ## Calculates the related circumscribing circle of vector polygons.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_patch_shape_tools.html#RelatedCircumscribingCircle) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector polygon file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    result = self.runTool("RelatedCircumscribingCircle", args)

proc relativeAspect*(self: var WhiteboxTools, dem: string, output: string, azimuth: float = 0.0, zfactor: float = 1.0): byte =
    ## Calculates relative aspect (relative to a user-specified direction) from an input DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#RelativeAspect) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - azimuth: Illumination source azimuth.
    ## - zfactor: Optional multiplier for when the vertical and horizontal units are not the same.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--azimuth={azimuth}")
    args.add(fmt"--zfactor={zfactor}")
    result = self.runTool("RelativeAspect", args)

proc relativeTopographicPosition*(self: var WhiteboxTools, dem: string, output: string, filterx: int = 11, filtery: int = 11): byte =
    ## Calculates the relative topographic position index from a DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#RelativeTopographicPosition) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    result = self.runTool("RelativeTopographicPosition", args)

proc removeOffTerrainObjects*(self: var WhiteboxTools, dem: string, output: string, filter: int = 11, slope: float = 15.0): byte =
    ## Removes off-terrain objects from a raster digital elevation model (DEM).
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#RemoveOffTerrainObjects) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - filter: Filter size (cells).
    ## - slope: Slope threshold value.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filter={filter}")
    args.add(fmt"--slope={slope}")
    result = self.runTool("RemoveOffTerrainObjects", args)

proc removePolygonHoles*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Removes holes within the features of a vector polygon file.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#RemovePolygonHoles) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector polygon file.
    ## - output: Output vector polygon file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("RemovePolygonHoles", args)

proc removeShortStreams*(self: var WhiteboxTools, d8_pntr: string, streams: string, output: string, min_length: float, esri_pntr: bool = false): byte =
    ## Removes short first-order streams from a stream network.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#RemoveShortStreams) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    ## - min_length: Minimum tributary length (in map units) used for network prunning.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    args.add(fmt"--min_length={min_length}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    result = self.runTool("RemoveShortStreams", args)

proc removeSpurs*(self: var WhiteboxTools, input: string, output: string, iterations: int = 10): byte =
    ## Removes the spurs (pruning operation) from a Boolean line image; intended to be used on the output of the LineThinning tool.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#RemoveSpurs) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - iterations: Maximum number of iterations
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--iterations={iterations}")
    result = self.runTool("RemoveSpurs", args)

proc resample*(self: var WhiteboxTools, inputs: string, destination: string, method_val: string = "cc"): byte =
    ## Resamples one or more input images into a destination image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#Resample) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - destination: Destination raster file.
    ## - method_val: Resampling method; options include 'nn' (nearest neighbour), 'bilinear', and 'cc' (cubic convolution)
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--destination={destination}")
    args.add(fmt"--method_val={method_val}")
    result = self.runTool("Resample", args)

proc rescaleValueRange*(self: var WhiteboxTools, input: string, output: string, out_min_val: float, out_max_val: float, clip_min = none(float), clip_max = none(float)): byte =
    ## Performs a min-max contrast stretch on an input greytone image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#RescaleValueRange) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - out_min_val: New minimum value in output image.
    ## - out_max_val: New maximum value in output image.
    ## - clip_min: Optional lower tail clip value.
    ## - clip_max: Optional upper tail clip value.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--out_min_val={out_min_val}")
    args.add(fmt"--out_max_val={out_max_val}")
    if clip_min.isSome:
        args.add(fmt"--clip_min={clip_min}")
    if clip_max.isSome:
        args.add(fmt"--clip_max={clip_max}")
    result = self.runTool("RescaleValueRange", args)

proc rgbToIhs*(self: var WhiteboxTools, red: string = "", green: string = "", blue: string = "", composite: string = "", intensity: string, hue: string, saturation: string): byte =
    ## Converts red, green, and blue (RGB) images into intensity, hue, and saturation (IHS) images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#RgbToIhs) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - red: Input red band image file. Optionally specified if colour-composite not specified.
    ## - green: Input green band image file. Optionally specified if colour-composite not specified.
    ## - blue: Input blue band image file. Optionally specified if colour-composite not specified.
    ## - composite: Input colour-composite image file. Only used if individual bands are not specified.
    ## - intensity: Output intensity raster file.
    ## - hue: Output hue raster file.
    ## - saturation: Output saturation raster file.
    var args = newSeq[string]()
    args.add(fmt"--red={red}")
    args.add(fmt"--green={green}")
    args.add(fmt"--blue={blue}")
    args.add(fmt"--composite={composite}")
    args.add(fmt"--intensity={intensity}")
    args.add(fmt"--hue={hue}")
    args.add(fmt"--saturation={saturation}")
    result = self.runTool("RgbToIhs", args)

proc rho8Pointer*(self: var WhiteboxTools, dem: string, output: string, esri_pntr: bool = false): byte =
    ## Calculates a stochastic Rho8 flow pointer raster from an input DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#Rho8Pointer) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    result = self.runTool("Rho8Pointer", args)

proc robertsCrossFilter*(self: var WhiteboxTools, input: string, output: string, clip: float = 0.0): byte =
    ## Performs a Robert's cross edge-detection filter on an image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#RobertsCrossFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - clip: Optional amount to clip the distribution tails by, in percent.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--clip={clip}")
    result = self.runTool("RobertsCrossFilter", args)

proc rootMeanSquareError*(self: var WhiteboxTools, input: string, base: string): byte =
    ## Calculates the RMSE and other accuracy statistics.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#RootMeanSquareError) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - base: Input base raster file used for comparison.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--base={base}")
    result = self.runTool("RootMeanSquareError", args)

proc round*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Rounds the values in an input raster to the nearest integer value.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Round) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Round", args)

proc ruggednessIndex*(self: var WhiteboxTools, dem: string, output: string, zfactor: float = 1.0): byte =
    ## Calculates the Riley et al.'s (1999) terrain ruggedness index from an input DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#RuggednessIndex) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - zfactor: Optional multiplier for when the vertical and horizontal units are not the same.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--zfactor={zfactor}")
    result = self.runTool("RuggednessIndex", args)

proc scharrFilter*(self: var WhiteboxTools, input: string, output: string, clip: float = 0.0): byte =
    ## Performs a Scharr edge-detection filter on an image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#ScharrFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - clip: Optional amount to clip the distribution tails by, in percent.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--clip={clip}")
    result = self.runTool("ScharrFilter", args)

proc sedimentTransportIndex*(self: var WhiteboxTools, sca: string, slope: string, output: string, sca_exponent: float = 0.4, slope_exponent: float = 1.3): byte =
    ## Calculates the sediment transport index.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#SedimentTransportIndex) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - sca: Input raster specific contributing area (SCA) file.
    ## - slope: Input raster slope file.
    ## - output: Output raster file.
    ## - sca_exponent: SCA exponent value.
    ## - slope_exponent: Slope exponent value.
    var args = newSeq[string]()
    args.add(fmt"--sca={sca}")
    args.add(fmt"--slope={slope}")
    args.add(fmt"--output={output}")
    args.add(fmt"--sca_exponent={sca_exponent}")
    args.add(fmt"--slope_exponent={slope_exponent}")
    result = self.runTool("SedimentTransportIndex", args)

proc selectTilesByPolygon*(self: var WhiteboxTools, indir: string, outdir: string, polygons: string): byte =
    ## Copies LiDAR tiles overlapping with a polygon into an output directory.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#SelectTilesByPolygon) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - indir: Input LAS file source directory.
    ## - outdir: Output directory into which LAS files within the polygon are copied.
    ## - polygons: Input vector polygons file.
    var args = newSeq[string]()
    args.add(fmt"--indir={indir}")
    args.add(fmt"--outdir={outdir}")
    args.add(fmt"--polygons={polygons}")
    result = self.runTool("SelectTilesByPolygon", args)

proc setNodataValue*(self: var WhiteboxTools, input: string, output: string, back_value: float = 0.0): byte =
    ## Assign a specified value in an input image to the NoData value.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#SetNodataValue) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - back_value: Background value to set to nodata.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--back_value={back_value}")
    result = self.runTool("SetNodataValue", args)

proc shapeComplexityIndex*(self: var WhiteboxTools, input: string): byte =
    ## Calculates overall polygon shape complexity or irregularity.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_patch_shape_tools.html#ShapeComplexityIndex) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector polygon file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    result = self.runTool("ShapeComplexityIndex", args)

proc shapeComplexityIndexRaster*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Calculates the complexity of raster polygons or classes.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_patch_shape_tools.html#ShapeComplexityIndexRaster) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("ShapeComplexityIndexRaster", args)

proc shreveStreamMagnitude*(self: var WhiteboxTools, d8_pntr: string, streams: string, output: string, esri_pntr: bool = false, zero_background = none(bool)): byte =
    ## Assigns the Shreve stream magnitude to each link in a stream network.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#ShreveStreamMagnitude) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    ## - zero_background: Flag indicating whether a background value of zero should be used.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    if zero_background.isSome:
        args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("ShreveStreamMagnitude", args)

proc sigmoidalContrastStretch*(self: var WhiteboxTools, input: string, output: string, cutoff: float = 0.0, gain: float = 1.0, num_tones: int = 256): byte =
    ## Performs a sigmoidal contrast stretch on input images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_image_enhancement.html#SigmoidalContrastStretch) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - cutoff: Cutoff value between 0.0 and 0.95.
    ## - gain: Gain value.
    ## - num_tones: Number of tones in the output image.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--cutoff={cutoff}")
    args.add(fmt"--gain={gain}")
    args.add(fmt"--num_tones={num_tones}")
    result = self.runTool("SigmoidalContrastStretch", args)

proc sin*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the sine (sin) of each values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Sin) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Sin", args)

proc singlePartToMultiPart*(self: var WhiteboxTools, input: string, field: string = "", output: string): byte =
    ## Converts a vector file containing multi-part features into a vector containing only single-part features.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#SinglePartToMultiPart) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector line or polygon file.
    ## - field: Grouping ID field name in attribute table.
    ## - output: Output vector line or polygon file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--field={field}")
    args.add(fmt"--output={output}")
    result = self.runTool("SinglePartToMultiPart", args)

proc sinh*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the hyperbolic sine (sinh) of each values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Sinh) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Sinh", args)

proc sink*(self: var WhiteboxTools, input: string, output: string, zero_background = none(bool)): byte =
    ## Identifies the depressions in a DEM, giving each feature a unique identifier.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#Sink) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster DEM file.
    ## - output: Output raster file.
    ## - zero_background: Flag indicating whether a background value of zero should be used.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    if zero_background.isSome:
        args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("Sink", args)

proc slope*(self: var WhiteboxTools, dem: string, output: string, zfactor: float = 1.0, units: string = "degrees"): byte =
    ## Calculates a slope raster from an input DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#Slope) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - zfactor: Optional multiplier for when the vertical and horizontal units are not the same.
    ## - units: Units of output raster; options include 'degrees', 'radians', 'percent'
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--zfactor={zfactor}")
    args.add(fmt"--units={units}")
    result = self.runTool("Slope", args)

proc slopeVsElevationPlot*(self: var WhiteboxTools, inputs: string, watershed: string = "", output: string): byte =
    ## Creates a slope vs. elevation plot for one or more DEMs.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#SlopeVsElevationPlot) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input DEM files.
    ## - watershed: Input watershed files (optional).
    ## - output: Output HTML file (default name will be based on input file if unspecified).
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--watershed={watershed}")
    args.add(fmt"--output={output}")
    result = self.runTool("SlopeVsElevationPlot", args)

proc smoothVectors*(self: var WhiteboxTools, input: string, output: string, filter: int = 3): byte =
    ## Smooths a vector coverage of either a POLYLINE or POLYGON base ShapeType.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#SmoothVectors) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector POLYLINE or POLYGON file.
    ## - output: Output vector file.
    ## - filter: The filter size, any odd integer greater than or equal to 3; default is 3.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filter={filter}")
    result = self.runTool("SmoothVectors", args)

proc snapPourPoints*(self: var WhiteboxTools, pour_pts: string, flow_accum: string, output: string, snap_dist: float): byte =
    ## Moves outlet points used to specify points of interest in a watershedding operation to the cell with the highest flow accumulation in its neighbourhood.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#SnapPourPoints) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - pour_pts: Input vector pour points (outlet) file.
    ## - flow_accum: Input raster D8 flow accumulation file.
    ## - output: Output vector file.
    ## - snap_dist: Maximum snap distance in map units.
    var args = newSeq[string]()
    args.add(fmt"--pour_pts={pour_pts}")
    args.add(fmt"--flow_accum={flow_accum}")
    args.add(fmt"--output={output}")
    args.add(fmt"--snap_dist={snap_dist}")
    result = self.runTool("SnapPourPoints", args)

proc sobelFilter*(self: var WhiteboxTools, input: string, output: string, variant: string = "3x3", clip: float = 0.0): byte =
    ## Performs a Sobel edge-detection filter on an image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#SobelFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - variant: Optional variant value. Options include 3x3 and 5x5 (default is 3x3).
    ## - clip: Optional amount to clip the distribution tails by, in percent (default is 0.0).
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--variant={variant}")
    args.add(fmt"--clip={clip}")
    result = self.runTool("SobelFilter", args)

proc sphericalStdDevOfNormals*(self: var WhiteboxTools, dem: string, output: string, filter: int = 11): byte =
    ## Calculates the spherical standard deviation of surface normals for a DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#SphericalStdDevOfNormals) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - filter: Size of the filter kernel.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filter={filter}")
    result = self.runTool("SphericalStdDevOfNormals", args)

proc splitColourComposite*(self: var WhiteboxTools, input: string, red: string = "", green: string = "", blue: string = ""): byte =
    ## This tool splits an RGB colour composite image into seperate multispectral images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#SplitColourComposite) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input colour composite image file.
    ## - red: Output red band file.
    ## - green: Output green band file.
    ## - blue: Output blue band file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--red={red}")
    args.add(fmt"--green={green}")
    args.add(fmt"--blue={blue}")
    result = self.runTool("SplitColourComposite", args)

proc splitWithLines*(self: var WhiteboxTools, input: string, split: string, output: string): byte =
    ## Splits the lines or polygons in one layer using the lines in another layer.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#SplitWithLines) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector line or polygon file.
    ## - split: Input vector polyline file.
    ## - output: Output vector file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--split={split}")
    args.add(fmt"--output={output}")
    result = self.runTool("SplitWithLines", args)

proc square*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Squares the values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Square) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Square", args)

proc squareRoot*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the square root of the values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#SquareRoot) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("SquareRoot", args)

proc standardDeviationContrastStretch*(self: var WhiteboxTools, input: string, output: string, stdev: float = 2.0, num_tones: int = 256): byte =
    ## Performs a standard-deviation contrast stretch on input images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_image_enhancement.html#StandardDeviationContrastStretch) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - stdev: Standard deviation clip value.
    ## - num_tones: Number of tones in the output image.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--stdev={stdev}")
    args.add(fmt"--num_tones={num_tones}")
    result = self.runTool("StandardDeviationContrastStretch", args)

proc standardDeviationFilter*(self: var WhiteboxTools, input: string, output: string, filterx: int = 11, filtery: int = 11): byte =
    ## Assigns each cell in the output grid the standard deviation of values in a moving window centred on each grid cell in the input raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#StandardDeviationFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    result = self.runTool("StandardDeviationFilter", args)

proc standardDeviationOfSlope*(self: var WhiteboxTools, input: string, output: string, zfactor: float = 1.0, filterx: int = 11, filtery: int = 11): byte =
    ## Calculates the standard deviation of slope from an input DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#StandardDeviationOfSlope) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster DEM file.
    ## - output: Output raster DEM file.
    ## - zfactor: Optional multiplier for when the vertical and horizontal units are not the same.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--zfactor={zfactor}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    result = self.runTool("StandardDeviationOfSlope", args)

proc stochasticDepressionAnalysis*(self: var WhiteboxTools, dem: string, output: string, rmse: float, range: float, iterations: int = 100): byte =
    ## Preforms a stochastic analysis of depressions within a DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#StochasticDepressionAnalysis) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output file.
    ## - rmse: The DEM's root-mean-square-error (RMSE), in z units. This determines error magnitude.
    ## - range: The error field's correlation length, in xy-units.
    ## - iterations: The number of iterations.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--rmse={rmse}")
    args.add(fmt"--range={range}")
    args.add(fmt"--iterations={iterations}")
    result = self.runTool("StochasticDepressionAnalysis", args)

proc strahlerOrderBasins*(self: var WhiteboxTools, d8_pntr: string, streams: string, output: string, esri_pntr: bool = false): byte =
    ## Identifies Strahler-order basins from an input stream network.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#StrahlerOrderBasins) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    result = self.runTool("StrahlerOrderBasins", args)

proc strahlerStreamOrder*(self: var WhiteboxTools, d8_pntr: string, streams: string, output: string, esri_pntr: bool = false, zero_background = none(bool)): byte =
    ## Assigns the Strahler stream order to each link in a stream network.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#StrahlerStreamOrder) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    ## - zero_background: Flag indicating whether a background value of zero should be used.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    if zero_background.isSome:
        args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("StrahlerStreamOrder", args)

proc streamLinkClass*(self: var WhiteboxTools, d8_pntr: string, streams: string, output: string, esri_pntr: bool = false, zero_background = none(bool)): byte =
    ## Identifies the exterior/interior links and nodes in a stream network.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#StreamLinkClass) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    ## - zero_background: Flag indicating whether a background value of zero should be used.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    if zero_background.isSome:
        args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("StreamLinkClass", args)

proc streamLinkIdentifier*(self: var WhiteboxTools, d8_pntr: string, streams: string, output: string, esri_pntr: bool = false, zero_background = none(bool)): byte =
    ## Assigns a unique identifier to each link in a stream network.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#StreamLinkIdentifier) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    ## - zero_background: Flag indicating whether a background value of zero should be used.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    if zero_background.isSome:
        args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("StreamLinkIdentifier", args)

proc streamLinkLength*(self: var WhiteboxTools, d8_pntr: string, linkid: string, output: string, esri_pntr: bool = false, zero_background = none(bool)): byte =
    ## Estimates the length of each link (or tributary) in a stream network.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#StreamLinkLength) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - linkid: Input raster streams link ID (or tributary ID) file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    ## - zero_background: Flag indicating whether a background value of zero should be used.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--linkid={linkid}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    if zero_background.isSome:
        args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("StreamLinkLength", args)

proc streamLinkSlope*(self: var WhiteboxTools, d8_pntr: string, linkid: string, dem: string, output: string, esri_pntr: bool = false, zero_background = none(bool)): byte =
    ## Estimates the average slope of each link (or tributary) in a stream network.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#StreamLinkSlope) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - linkid: Input raster streams link ID (or tributary ID) file.
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    ## - zero_background: Flag indicating whether a background value of zero should be used.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--linkid={linkid}")
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    if zero_background.isSome:
        args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("StreamLinkSlope", args)

proc streamPowerIndex*(self: var WhiteboxTools, sca: string, slope: string, output: string, exponent: float = 1.0): byte =
    ## Calculates the relative stream power index.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#StreamPowerIndex) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - sca: Input raster specific contributing area (SCA) file.
    ## - slope: Input raster slope file.
    ## - output: Output raster file.
    ## - exponent: SCA exponent value.
    var args = newSeq[string]()
    args.add(fmt"--sca={sca}")
    args.add(fmt"--slope={slope}")
    args.add(fmt"--output={output}")
    args.add(fmt"--exponent={exponent}")
    result = self.runTool("StreamPowerIndex", args)

proc streamSlopeContinuous*(self: var WhiteboxTools, d8_pntr: string, streams: string, dem: string, output: string, esri_pntr: bool = false, zero_background = none(bool)): byte =
    ## Estimates the slope of each grid cell in a stream network.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#StreamSlopeContinuous) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - streams: Input raster streams file.
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    ## - zero_background: Flag indicating whether a background value of zero should be used.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    if zero_background.isSome:
        args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("StreamSlopeContinuous", args)

proc subbasins*(self: var WhiteboxTools, d8_pntr: string, streams: string, output: string, esri_pntr: bool = false): byte =
    ## Identifies the catchments, or sub-basin, draining to each link in a stream network.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#Subbasins) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input D8 pointer raster file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    result = self.runTool("Subbasins", args)

proc subtract*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## Performs a differencing operation on two rasters or a raster and a constant value.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Subtract) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file or constant value.
    ## - input2: Input raster file or constant value.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("Subtract", args)

proc sumOverlay*(self: var WhiteboxTools, inputs: string, output: string): byte =
    ## Calculates the sum for each grid cell from a group of raster images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#SumOverlay) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--output={output}")
    result = self.runTool("SumOverlay", args)

proc surfaceAreaRatio*(self: var WhiteboxTools, dem: string, output: string): byte =
    ## Calculates a the surface area ratio of each grid cell in an input DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#SurfaceAreaRatio) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    result = self.runTool("SurfaceAreaRatio", args)

proc symmetricalDifference*(self: var WhiteboxTools, input: string, overlay: string, output: string, snap: float = 0.0): byte =
    ## Outputs the features that occur in one of the two vector inputs but not both, i.e. no overlapping features.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#SymmetricalDifference) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    ## - overlay: Input overlay vector file.
    ## - output: Output vector file.
    ## - snap: Snap tolerance.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--overlay={overlay}")
    args.add(fmt"--output={output}")
    args.add(fmt"--snap={snap}")
    result = self.runTool("SymmetricalDifference", args)

proc tINGridding*(self: var WhiteboxTools, input: string, field: string = "", use_z: bool = false, output: string, resolution = none(float), base: string = "", max_triangle_edge_length = none(float)): byte =
    ## Creates a raster grid based on a triangular irregular network (TIN) fitted to vector points.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#TINGridding) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector points file.
    ## - field: Input field name in attribute table.
    ## - use_z: Use the 'z' dimension of the Shapefile's geometry instead of an attribute field?
    ## - output: Output raster file.
    ## - resolution: Output raster's grid resolution.
    ## - base: Optionally specified input base raster file. Not used when a cell size is specified.
    ## - max_triangle_edge_length: Optional maximum triangle edge length; triangles larger than this size will not be gridded.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--field={field}")
    args.add(fmt"--use_z={use_z}")
    args.add(fmt"--output={output}")
    if resolution.isSome:
        args.add(fmt"--resolution={resolution}")
    args.add(fmt"--base={base}")
    if max_triangle_edge_length.isSome:
        args.add(fmt"--max_triangle_edge_length={max_triangle_edge_length}")
    result = self.runTool("TINGridding", args)

proc tan*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the tangent (tan) of each values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Tan) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Tan", args)

proc tangentialCurvature*(self: var WhiteboxTools, dem: string, output: string, zfactor: float = 1.0): byte =
    ## Calculates a tangential curvature raster from an input DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#TangentialCurvature) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - zfactor: Optional multiplier for when the vertical and horizontal units are not the same.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--zfactor={zfactor}")
    result = self.runTool("TangentialCurvature", args)

proc tanh*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Returns the hyperbolic tangent (tanh) of each values in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Tanh) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("Tanh", args)

proc thickenRasterLine*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Thickens single-cell wide lines within a raster image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#ThickenRasterLine) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("ThickenRasterLine", args)

proc toDegrees*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Converts a raster from radians to degrees.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#ToDegrees) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("ToDegrees", args)

proc toRadians*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Converts a raster from degrees to radians.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#ToRadians) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("ToRadians", args)

proc tophatTransform*(self: var WhiteboxTools, input: string, output: string, filterx: int = 11, filtery: int = 11, variant: string = "white"): byte =
    ## Performs either a white or black top-hat transform on an input image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#TophatTransform) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    ## - variant: Optional variant value. Options include 'white' and 'black'.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    args.add(fmt"--variant={variant}")
    result = self.runTool("TophatTransform", args)

proc topologicalStreamOrder*(self: var WhiteboxTools, d8_pntr: string, streams: string, output: string, esri_pntr: bool = false, zero_background = none(bool)): byte =
    ## Assigns each link in a stream network its topological order.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#TopologicalStreamOrder) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    ## - zero_background: Flag indicating whether a background value of zero should be used.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    if zero_background.isSome:
        args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("TopologicalStreamOrder", args)

proc totalCurvature*(self: var WhiteboxTools, dem: string, output: string, zfactor: float = 1.0): byte =
    ## Calculates a total curvature raster from an input DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#TotalCurvature) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - zfactor: Optional multiplier for when the vertical and horizontal units are not the same.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--zfactor={zfactor}")
    result = self.runTool("TotalCurvature", args)

proc totalFilter*(self: var WhiteboxTools, input: string, output: string, filterx: int = 11, filtery: int = 11): byte =
    ## Performs a total filter on an input image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#TotalFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - filterx: Size of the filter kernel in the x-direction.
    ## - filtery: Size of the filter kernel in the y-direction.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--filterx={filterx}")
    args.add(fmt"--filtery={filtery}")
    result = self.runTool("TotalFilter", args)

proc traceDownslopeFlowpaths*(self: var WhiteboxTools, seed_pts: string, d8_pntr: string, output: string, esri_pntr: bool = false, zero_background = none(bool)): byte =
    ## Traces downslope flowpaths from one or more target sites (i.e. seed points).
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#TraceDownslopeFlowpaths) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - seed_pts: Input vector seed points file.
    ## - d8_pntr: Input D8 pointer raster file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    ## - zero_background: Flag indicating whether a background value of zero should be used.
    var args = newSeq[string]()
    args.add(fmt"--seed_pts={seed_pts}")
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    if zero_background.isSome:
        args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("TraceDownslopeFlowpaths", args)

proc trendSurface*(self: var WhiteboxTools, input: string, output: string, order: int = 1): byte =
    ## Estimates the trend surface of an input raster file.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#TrendSurface) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - order: Polynomial order (1 to 10).
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--order={order}")
    result = self.runTool("TrendSurface", args)

proc trendSurfaceVectorPoints*(self: var WhiteboxTools, input: string, field: string, output: string, order: int = 1, cell_size: float): byte =
    ## Estimates a trend surface from vector points.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#TrendSurfaceVectorPoints) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector Points file.
    ## - field: Input field name in attribute table.
    ## - output: Output raster file.
    ## - order: Polynomial order (1 to 10).
    ## - cell_size: Optionally specified cell size of output raster. Not used when base raster is specified.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--field={field}")
    args.add(fmt"--output={output}")
    args.add(fmt"--order={order}")
    args.add(fmt"--cell_size={cell_size}")
    result = self.runTool("TrendSurfaceVectorPoints", args)

proc tributaryIdentifier*(self: var WhiteboxTools, d8_pntr: string, streams: string, output: string, esri_pntr: bool = false, zero_background = none(bool)): byte =
    ## Assigns a unique identifier to each tributary in a stream network.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/stream_network_analysis.html#TributaryIdentifier) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input raster D8 pointer file.
    ## - streams: Input raster streams file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    ## - zero_background: Flag indicating whether a background value of zero should be used.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--streams={streams}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    if zero_background.isSome:
        args.add(fmt"--zero_background={zero_background}")
    result = self.runTool("TributaryIdentifier", args)

proc truncate*(self: var WhiteboxTools, input: string, output: string, num_decimals = none(int)): byte =
    ## Truncates the values in a raster to the desired number of decimal places.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Truncate) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - num_decimals: Number of decimals left after truncation (default is zero).
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    if num_decimals.isSome:
        args.add(fmt"--num_decimals={num_decimals}")
    result = self.runTool("Truncate", args)

proc turningBandsSimulation*(self: var WhiteboxTools, base: string, output: string, range: float, iterations: int = 1000): byte =
    ## Creates an image containing random values based on a turning-bands simulation.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#TurningBandsSimulation) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - base: Input base raster file.
    ## - output: Output file.
    ## - range: The field's range, in xy-units, related to the extent of spatial autocorrelation.
    ## - iterations: The number of iterations.
    var args = newSeq[string]()
    args.add(fmt"--base={base}")
    args.add(fmt"--output={output}")
    args.add(fmt"--range={range}")
    args.add(fmt"--iterations={iterations}")
    result = self.runTool("TurningBandsSimulation", args)

proc twoSampleKsTest*(self: var WhiteboxTools, input1: string, input2: string, output: string, num_samples = none(int)): byte =
    ## Performs a 2-sample K-S test for significant differences on two input rasters.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#TwoSampleKsTest) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: First input raster file.
    ## - input2: Second input raster file.
    ## - output: Output HTML file.
    ## - num_samples: Number of samples. Leave blank to use whole image.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    if num_samples.isSome:
        args.add(fmt"--num_samples={num_samples}")
    result = self.runTool("TwoSampleKsTest", args)

proc union*(self: var WhiteboxTools, input: string, overlay: string, output: string, snap: float = 0.0): byte =
    ## Splits vector layers at their overlaps, creating a layer containing all the portions from both input and overlay layers.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#Union) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector file.
    ## - overlay: Input overlay vector file.
    ## - output: Output vector file.
    ## - snap: Snap tolerance.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--overlay={overlay}")
    args.add(fmt"--output={output}")
    args.add(fmt"--snap={snap}")
    result = self.runTool("Union", args)

proc unnestBasins*(self: var WhiteboxTools, d8_pntr: string, pour_pts: string, output: string, esri_pntr: bool = false): byte =
    ## Extract whole watersheds for a set of outlet points.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#UnnestBasins) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input D8 pointer raster file.
    ## - pour_pts: Input vector pour points (outlet) file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--pour_pts={pour_pts}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    result = self.runTool("UnnestBasins", args)

proc unsharpMasking*(self: var WhiteboxTools, input: string, output: string, sigma: float = 0.75, amount: float = 100.0, threshold: float = 0.0): byte =
    ## An image sharpening technique that enhances edges.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#UnsharpMasking) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    ## - sigma: Standard deviation distance in pixels.
    ## - amount: A percentage and controls the magnitude of each overshoot.
    ## - threshold: Controls the minimal brightness change that will be sharpened.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--sigma={sigma}")
    args.add(fmt"--amount={amount}")
    args.add(fmt"--threshold={threshold}")
    result = self.runTool("UnsharpMasking", args)

proc updateNodataCells*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## Replaces the NoData values in an input raster with the corresponding values contained in a second update layer.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#UpdateNodataCells) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file 1.
    ## - input2: Input raster file 2; update layer.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("UpdateNodataCells", args)

proc upslopeDepressionStorage*(self: var WhiteboxTools, dem: string, output: string): byte =
    ## Estimates the average upslope depression storage depth.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#UpslopeDepressionStorage) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    result = self.runTool("UpslopeDepressionStorage", args)

proc userDefinedWeightsFilter*(self: var WhiteboxTools, input: string, weights: string, output: string, center: string = "center", normalize: bool = false): byte =
    ## Performs a user-defined weights filter on an image.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools_filters.html#UserDefinedWeightsFilter) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - weights: Input weights file.
    ## - output: Output raster file.
    ## - center: Kernel center cell; options include 'center', 'upper-left', 'upper-right', 'lower-left', 'lower-right'
    ## - normalize: Normalize kernel weights? This can reduce edge effects and lessen the impact of data gaps (nodata) but is not suited when the kernel weights sum to zero.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--weights={weights}")
    args.add(fmt"--output={output}")
    args.add(fmt"--center={center}")
    args.add(fmt"--normalize={normalize}")
    result = self.runTool("UserDefinedWeightsFilter", args)

proc vectorHexBinning*(self: var WhiteboxTools, input: string, output: string, width: float, orientation: string = "horizontal"): byte =
    ## Hex-bins a set of vector points.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#VectorHexBinning) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input base file.
    ## - output: Output vector polygon file.
    ## - width: The grid cell width.
    ## - orientation: Grid Orientation, 'horizontal' or 'vertical'.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    args.add(fmt"--width={width}")
    args.add(fmt"--orientation={orientation}")
    result = self.runTool("VectorHexBinning", args)

proc vectorLinesToRaster*(self: var WhiteboxTools, input: string, field: string = "FID", output: string, nodata: bool = true, cell_size = none(float), base: string = ""): byte =
    ## Converts a vector containing polylines into a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#VectorLinesToRaster) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector lines file.
    ## - field: Input field name in attribute table.
    ## - output: Output raster file.
    ## - nodata: Background value to set to NoData. Without this flag, it will be set to 0.0.
    ## - cell_size: Optionally specified cell size of output raster. Not used when base raster is specified.
    ## - base: Optionally specified input base raster file. Not used when a cell size is specified.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--field={field}")
    args.add(fmt"--output={output}")
    args.add(fmt"--nodata={nodata}")
    if cell_size.isSome:
        args.add(fmt"--cell_size={cell_size}")
    args.add(fmt"--base={base}")
    result = self.runTool("VectorLinesToRaster", args)

proc vectorPointsToRaster*(self: var WhiteboxTools, input: string, field: string = "FID", output: string, assign: string = "last", nodata: bool = true, cell_size = none(float), base: string = ""): byte =
    ## Converts a vector containing points into a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#VectorPointsToRaster) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector Points file.
    ## - field: Input field name in attribute table.
    ## - output: Output raster file.
    ## - assign: Assignment operation, where multiple points are in the same grid cell; options include 'first', 'last' (default), 'min', 'max', 'sum'
    ## - nodata: Background value to set to NoData. Without this flag, it will be set to 0.0.
    ## - cell_size: Optionally specified cell size of output raster. Not used when base raster is specified.
    ## - base: Optionally specified input base raster file. Not used when a cell size is specified.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--field={field}")
    args.add(fmt"--output={output}")
    args.add(fmt"--assign={assign}")
    args.add(fmt"--nodata={nodata}")
    if cell_size.isSome:
        args.add(fmt"--cell_size={cell_size}")
    args.add(fmt"--base={base}")
    result = self.runTool("VectorPointsToRaster", args)

proc vectorPolygonsToRaster*(self: var WhiteboxTools, input: string, field: string = "FID", output: string, nodata: bool = true, cell_size = none(float), base: string = ""): byte =
    ## Converts a vector containing polygons into a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/data_tools.html#VectorPolygonsToRaster) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector polygons file.
    ## - field: Input field name in attribute table.
    ## - output: Output raster file.
    ## - nodata: Background value to set to NoData. Without this flag, it will be set to 0.0.
    ## - cell_size: Optionally specified cell size of output raster. Not used when base raster is specified.
    ## - base: Optionally specified input base raster file. Not used when a cell size is specified.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--field={field}")
    args.add(fmt"--output={output}")
    args.add(fmt"--nodata={nodata}")
    if cell_size.isSome:
        args.add(fmt"--cell_size={cell_size}")
    args.add(fmt"--base={base}")
    result = self.runTool("VectorPolygonsToRaster", args)

proc viewshed*(self: var WhiteboxTools, dem: string, stations: string, output: string, height: float = 2.0): byte =
    ## Identifies the viewshed for a point or set of points.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#Viewshed) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - stations: Input viewing station vector file.
    ## - output: Output raster file.
    ## - height: Viewing station height, in z units.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--stations={stations}")
    args.add(fmt"--output={output}")
    args.add(fmt"--height={height}")
    result = self.runTool("Viewshed", args)

proc visibilityIndex*(self: var WhiteboxTools, dem: string, output: string, height: float = 2.0, res_factor: int = 2): byte =
    ## Estimates the relative visibility of sites in a DEM.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#VisibilityIndex) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - dem: Input raster DEM file.
    ## - output: Output raster file.
    ## - height: Viewing station height, in z units.
    ## - res_factor: The resolution factor determines the density of measured viewsheds.
    var args = newSeq[string]()
    args.add(fmt"--dem={dem}")
    args.add(fmt"--output={output}")
    args.add(fmt"--height={height}")
    args.add(fmt"--res_factor={res_factor}")
    result = self.runTool("VisibilityIndex", args)

proc voronoiDiagram*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Creates a vector Voronoi diagram for a set of vector points.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis.html#VoronoiDiagram) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input vector points file.
    ## - output: Output vector polygon file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("VoronoiDiagram", args)

proc watershed*(self: var WhiteboxTools, d8_pntr: string, pour_pts: string, output: string, esri_pntr: bool = false): byte =
    ## Identifies the watershed, or drainage basin, draining to a set of target cells.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/hydrological_analysis.html#Watershed) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - d8_pntr: Input D8 pointer raster file.
    ## - pour_pts: Input pour points (outlet) file.
    ## - output: Output raster file.
    ## - esri_pntr: D8 pointer uses the ESRI style scheme.
    var args = newSeq[string]()
    args.add(fmt"--d8_pntr={d8_pntr}")
    args.add(fmt"--pour_pts={pour_pts}")
    args.add(fmt"--output={output}")
    args.add(fmt"--esri_pntr={esri_pntr}")
    result = self.runTool("Watershed", args)

proc weightedOverlay*(self: var WhiteboxTools, factors: string, weights: string, cost: string = "", constraints: string = "", output: string, scale_max: float = 1.0): byte =
    ## Performs a weighted sum on multiple input rasters after converting each image to a common scale. The tool performs a multi-criteria evaluation (MCE).
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#WeightedOverlay) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - factors: Input factor raster files.
    ## - weights: Weight values, contained in quotes and separated by commas or semicolons. Must have the same number as factors.
    ## - cost: Weight values, contained in quotes and separated by commas or semicolons. Must have the same number as factors.
    ## - constraints: Input constraints raster files.
    ## - output: Output raster file.
    ## - scale_max: Suitability scale maximum value (common values are 1.0, 100.0, and 255.0).
    var args = newSeq[string]()
    args.add(fmt"--factors={factors}")
    args.add(fmt"--weights={weights}")
    args.add(fmt"--cost={cost}")
    args.add(fmt"--constraints={constraints}")
    args.add(fmt"--output={output}")
    args.add(fmt"--scale_max={scale_max}")
    result = self.runTool("WeightedOverlay", args)

proc weightedSum*(self: var WhiteboxTools, inputs: string, weights: string, output: string): byte =
    ## Performs a weighted-sum overlay on multiple input raster images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/gis_analysis_overlay_tools.html#WeightedSum) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input raster files.
    ## - weights: Weight values, contained in quotes and separated by commas or semicolons.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--weights={weights}")
    args.add(fmt"--output={output}")
    result = self.runTool("WeightedSum", args)

proc wetnessIndex*(self: var WhiteboxTools, sca: string, slope: string, output: string): byte =
    ## Calculates the topographic wetness index, Ln(A / tan(slope)).
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/geomorphometric_analysis.html#WetnessIndex) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - sca: Input raster specific contributing area (SCA) file.
    ## - slope: Input raster slope file (in degrees).
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--sca={sca}")
    args.add(fmt"--slope={slope}")
    args.add(fmt"--output={output}")
    result = self.runTool("WetnessIndex", args)

proc wilcoxonSignedRankTest*(self: var WhiteboxTools, input1: string, input2: string, output: string, num_samples = none(int)): byte =
    ## Performs a 2-sample K-S test for significant differences on two input rasters.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#WilcoxonSignedRankTest) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: First input raster file.
    ## - input2: Second input raster file.
    ## - output: Output HTML file.
    ## - num_samples: Number of samples. Leave blank to use whole image.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    if num_samples.isSome:
        args.add(fmt"--num_samples={num_samples}")
    result = self.runTool("WilcoxonSignedRankTest", args)

proc writeFunctionMemoryInsertion*(self: var WhiteboxTools, input1: string, input2: string, input3: string = "", output: string): byte =
    ## Performs a write function memory insertion for single-band multi-date change detection.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/image_processing_tools.html#WriteFunctionMemoryInsertion) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file associated with the first date.
    ## - input2: Input raster file associated with the second date.
    ## - input3: Optional input raster file associated with the third date.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--input3={input3}")
    args.add(fmt"--output={output}")
    result = self.runTool("WriteFunctionMemoryInsertion", args)

proc Xor*(self: var WhiteboxTools, input1: string, input2: string, output: string): byte =
    ## Performs a logical XOR operator on two Boolean raster images.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#Xor) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input1: Input raster file.
    ## - input2: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input1={input1}")
    args.add(fmt"--input2={input2}")
    args.add(fmt"--output={output}")
    result = self.runTool("Xor", args)

proc zScores*(self: var WhiteboxTools, input: string, output: string): byte =
    ## Standardizes the values in an input raster by converting to z-scores.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#ZScores) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input raster file.
    ## - output: Output raster file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--output={output}")
    result = self.runTool("ZScores", args)

proc zlidarToLas*(self: var WhiteboxTools, inputs: string = "", outdir: string = ""): byte =
    ## Converts one or more zlidar files into the LAS data format.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/lidar_tools.html#ZlidarToLas) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - inputs: Input ZLidar files.
    ## - outdir: Output directory into which zlidar files are created. If unspecified, it is assumed to be the same as the inputs.
    var args = newSeq[string]()
    args.add(fmt"--inputs={inputs}")
    args.add(fmt"--outdir={outdir}")
    result = self.runTool("ZlidarToLas", args)

proc zonalStatistics*(self: var WhiteboxTools, input: string, features: string, output: string = "", stat: string = "mean", out_table: string = ""): byte =
    ## Extracts descriptive statistics for a group of patches in a raster.
    ## See [here](https://jblindsay.github.io/wbt_book/available_tools/mathand_stats_tools.html#ZonalStatistics) for more details.
    ##
    ## Keyword arguments:
    ##
    ## - input: Input data raster file.
    ## - features: Input feature definition raster file.
    ## - output: Output raster file.
    ## - stat: Statistic to extract, including 'mean', 'median', 'minimum', 'maximum', 'range', 'standard deviation', and 'total'.
    ## - out_table: Output HTML Table file.
    var args = newSeq[string]()
    args.add(fmt"--input={input}")
    args.add(fmt"--features={features}")
    args.add(fmt"--output={output}")
    args.add(fmt"--stat={stat}")
    args.add(fmt"--out_table={out_table}")
    result = self.runTool("ZonalStatistics", args)

proc generateFunctions() =
    var 
        wbt = newWhiteboxTools()
        toolName: string
        toolDescription: string
        toolInfo: seq[string]
        toolParameters: string
        lineNum = 1
        funcSig: string

    wbt.setExecutableDirectory("/Users/johnlindsay/Documents/programming/whitebox-tools/target/release/")

    let toolsList = wbt.listTools()
    for a in toolsList.splitLines:
        if len(a.strip()) > 0 and lineNum > 1:
            toolInfo = a.split(":")
            toolName = toolInfo[0].strip()
            let d = "https://jblindsay.github.io/wbt_book/available_tools/"
            var toolbox = wbt.getToolbox(toolName).replace(" ", "_").replace("/", "_").toLowerAscii()
            if toolbox == "math_and_stats_tools":
                toolbox = "mathand_stats_tools"
            let helpPage = fmt"{d}{toolbox}.html#{toolName}"

            let funcToolName = if toolName.toLowerAscii() != "and" and toolName.toLowerAscii() != "not" and toolName.toLowerAscii() != "or" and toolName.toLowerAscii() != "xor":
                toolName[0].toLowerAscii() & toolName[1..<len(toolName)]
            else:
                toolName
            funcSig = fmt"proc {funcToolName}*(self: var WhiteboxTools, "
            toolDescription = toolInfo[1].strip().replace("*=", "* =")
            toolParameters = wbt.getToolParameters(toolname)
            let jsonNode = parseJson(toolParameters)
            var args = ""
            var listOfParams = newSeq[string]()
            var listOfParamDescriptions = newSeq[string]()
            var listOfOptionalParams = newSeq[bool]()
            var listOfDefaultedParams = newSeq[bool]()
            for param in jsonNode["parameters"]:
                let flags = param["flags"]
                var flag = flags[len(flags)-1].getStr().replace("-", "")
                if flag == "type":
                    flag = "type_val"
                if flag == "method":
                    flag = "method_val"
                listOfParams.add(flag)
                listOfParamDescriptions.add(param["description"].getStr())
                let pt = param["parameter_type"]
                let default = param["default_value"]
                let optional = param["optional"].getBool()
                listOfOptionalParams.add(optional)
                listOfDefaultedParams.add(default.kind != JNull)
                if "Boolean" in pt.getStr():
                    if default.kind == JNull:
                        # args.add(fmt"{flag}: bool, ")
                        if not optional:
                            args.add(fmt"{flag}: bool, ")
                        else:
                            args.add(fmt"{flag} = none(bool), ")
                    else:
                        args.add(fmt"{flag}: bool = {default.getStr().toLowerAscii()}, ")
                elif "Integer" in pt.getStr():
                    if default.kind == JNull:
                        # args.add(fmt"{flag}: int, ")
                        if not optional:
                            args.add(fmt"{flag}: int, ")
                        else:
                            args.add(fmt"{flag} = none(int), ")
                    else:
                        args.add(fmt"{flag}: int = {default.getStr()}, ")
                elif "Float" in pt.getStr():
                    if default.kind == JNull:
                        # args.add(fmt"{flag}: float, ")
                        if not optional:
                            args.add(fmt"{flag}: float, ")
                        else:
                            args.add(fmt"{flag} = none(float), ")
                    else:
                        args.add(fmt"{flag}: float = {default.getStr()}, ")
                else:
                    listOfDefaultedParams[len(listOfDefaultedParams)-1] = true
                    if default.kind == JNull:
                        if not optional:
                            args.add(fmt"{flag}: string, ")
                        else:
                            args.add(&"{flag}: string = \"\", ")
                    else:
                        args.add(&"{flag}: string = \"{default.getStr()}\", ")
                    
                # echo param
            
            funcSig.add(fmt"{args[0..args.len()-3]}): byte =")
            echo(funcSig)
            echo(fmt"    ## {toolDescription}")
            echo(fmt"    ## See [here]({helpPage}) for more details.")
            echo("    ##")
            echo("    ## Keyword arguments:")
            echo("    ##")
            for d in 0..<len(listOfParamDescriptions):
                echo(fmt"    ## - {listOfParams[d]}: {listOfParamDescriptions[d]}")
            echo("    var args = newSeq[string]()")

            lineNum = 0
            for f in listOfParams:
                let t = "{" & f & "}"
                if listOfOptionalParams[lineNum] and not listOfDefaultedParams[lineNum]:
                    if len(f) > 1:
                        echo(fmt"    if {f}.isSome:")
                        echo(&"        args.add(fmt\"--{f}={t}\")")
                    else:
                        echo(fmt"    if {f}.isSome:")
                        echo(&"        args.add(fmt\"-{f}={t}\")")
                else:
                    if len(f) > 1:
                        echo(&"    args.add(fmt\"--{f}={t}\")")
                    else:
                        echo(&"    args.add(fmt\"-{f}={t}\")")
                
                lineNum += 1;
            echo(&"    result = self.runTool(\"{toolName}\", args)")
            echo("")

        lineNum += 1

when isMainModule:
    generateFunctions()

    echo("Done!")