# Geomorphic Change

This repository contains MATLAB code for computing geomorphic change from multi-temporal digital elevation models (DEMs). Linear elevation trends (i.e. elevation change through time) are estimated based on two or more DEMs (geotiff format) with known acquisition times and overlapping spatial extent. Regions of interest are specified as user-defined polygon(s) (ESRI shapefile format). Volume changes, mean elevation changes, and geodetic mass balances are also estimated (for each polygon) along with their uncertainties as described by Maurer et al. (2019).

## Requirements

* MATLAB version 2018a or newer

* MATLAB image processing, mapping, statistics, and optimization toolboxes. Enter `ver` in the MATLAB command window to see if you have them installed.

* The HEXIMAP "shared" [library](https://github.com/gmorky/heximap/tree/master/main/shared).

## Tips

* Any external data used as input must be georeferenced in the WGS84 geographic coordinate system, with elevations specified in meters.

* All DEMs should be horizontally and vertically aligned (relative to one another or to a common reference DEM) prior to being used as input here.

* If input geotiffs have varying spatial resolutions, the code will resample them all to match the input dataset with the lowest spatial resolution.

* The quality of the output elevation change maps should be inspected carefully before assuming that the geomorphic change computations are meaningful or accurate.

## Installation

After downloading the repository, add it to your MATLAB path including all subdirectories as `addpath(genpath('/path/to/geomorphic-change'))`. Also add the required HEXIMAP shared library as `addpath('/path/to/heximap/main/shared')`.

## Usage

*Any external data used as input must be georeferenced in the WGS84 geographic coordinate system, with elevations specified in meters.* The *computeGeomorphicChange.m* script demonstrates the general workflow using an example dataset from the [aster-dems-cleanup](https://github.com/gmorky/aster-dems-cleanup) repository. Inputs for the two primary functions are as follows:

* `geomorphicChange(modernShapefilePath,demParams,params);`

	* `modernShapefilePath` (char): Path to the shapefile containing "modern" polygons (i.e. at end of timespan of interest). Corresponding historical and modern polygons will be matched up based on their ID field values (see `params.polygonIdField` below).

	* `demParams` (1xN struct): Required information about each DEM used as input. This is a 1xN struct array, where N is the number of input DEMs (see demo script):

		* `demParams.file` (char): Path to a DEM geotiff file.

		* `demParams.boundingBox` (4x2 double): Matrix specifying the spatial bounding box of a DEM geotiff file. See demo script for an example.

		* `demParams.acquisitionDate` (1x1 datetime): A DEM acquisition date (i.e. time of observation) in matlab datetime format. This is necessary so that the code can sort all the input DEMs into the correct temporal order.

	* `params` (struct): Input parameters for the geomorphic change function:

		* `params.maskDir` (char): Path to the directory containing shapefile(s) with polygons enclosing terrain known to be unstable through time. In the example dataset, polygons representing glacier extents are used.

		* `params.maxVertices` (1x1 double): Elevation trends and geomorphic changes will not be computed for polygons with vertex counts greater than this threshold.

		* `params.polygonIdField` (char): ID field used to match up historical and modern shapefile polygons.

		* `params.polygonOverlapCheck` (1x1 logical): If set to true, the code will check whether input DEMs overlap with the actual polygon boundaries (defined by the polygon vertices) rather than simply checking overlap with the polygon bounding box.

		* `params.boundingBoxPctBuffer` (1x1 double): Percent extension of polygon bounding box edges. This determines how much "stable terrain" (i.e. terrain surrounding the polygon) is included in the computations (stable terrain is used for a final vertical alignment of the DEMs and for estimating uncertainties). Units: percentage of original box width and height.

		* `params.alignThresh` (1x1 double): Before computing geomorphic change, DEMs are vertically shifted to remove any biases (using stable terrain only in this step). When determining the shift, any elevation differences larger than this threshold are ignored. This helps prevent erroneous outlier elevation pixels from biasing the results.

		* `params.nullVal` (1x1 double or char): Value used in the input DEMs to represent missing or null data. To assume all elevation pixel values less than -500 or greater than 9000 are null, set this parameter to `'dem'`.

		* `params.ransac` (struct): Parameters for the random sample consensus (RANSAC) trend fitting procedure:

			* `params.ransac.iterations` (1x1 double): Number of RANSAC iterations to perform.

			* `params.ransac.threshold` (1x1 double): When fitting linear (elevation versus time) trends during RANSAC iterations, absolute elevation differences (i.e. vertical distance from the fitted trend line) greater than this threshold are considered outliers during any given iteration. Units: meters.

		* `params.filterWindow` (1x2 double or char): Specifies the neighborhood when performing median filtering of the elevation change map in two dimensions. To skip median filtering, specify `'none'`.

		* `params.slopeMax` (1x1 double): Any regions with slope (i.e. terrain gradient) greater than this threshold are removed. Units: degrees from horizontal.

		* `params.trendMax` (1x1 double): Any elevation trends greater in magnitude than this value are removed. Units: meters year<sup>-1</sup>.

		* `params.trendMinCount` (1x1 double): Any elevation trends with less than this number of data points (i.e. elevation pixels) are removed.

		* `params.trendMinTimespan` (1x1 double): Any elevation trends with less than this duration of data coverage are removed. Units: years.

		* `params.trendMaxStd` (1x1 double): Any elevation trends with local neighborhood standard deviations (i.e. local standard deviations of the elevation change map) greater than this value are removed. 

		* `params.trendMaxGrad` (1x1 double): Any elevation trends with local neighborhood gradients (i.e. local gradient of the elevation change map) greater than this value are removed.

		* `params.refDem` (struct): Parameters for the reference DEM:

			* `params.refDem.path` (char): Path to a reference DEM geotiff file.

			* `params.refDem.nullVal` (1x1 double or char): Value in the reference DEM used to represent missing or null data. To assume all elevation pixel values less than -500 or greater than 9000 are null, set this parameter to `'dem'`.

		* `params.interpParams` (struct): Parameters for interpolating data gaps in the elevation change maps:

			* `method` (char): Method used to interpolate data gaps inside the polygon. Can be specified as `'simpleFill'`, `'spatialInterp'`, or `'elevationBins'`. For the `'simpleFill'` option, a user-specified constant value is used to fill data gaps. For the `'spatialInterp'` option, 2D linear spatial interpolation is used to fill the data gaps. If desired, all pixels outside the polygon can be set to a specified (constant) value before interpolating data gaps within the polygon. This can help prevent large extrapolation errors in regions with large data gaps. For the `'elevationBins'` option, elevation change pixels are grouped into elevation bins, and data gaps are interpolated using the means of each bin. This method is ideal for situations where a correlation between elevation and elevation change is expected (mountain glaciers, for example).

			* Parameters for the `'simpleFill'` option:

				* `fillVal` (1x1 double): All data gaps inside the polygon will be filled using this value.

			* Parameters for the `'spatialInterp'` option:
				
				* `polygonEdges` (1x1 double or char): All pixels outside the polygon will be set to this value before interpolating data gaps within the polygon. To leave outside pixels undisturbed, set this parameter to `'keep'`;

			* Parameters for the `'elevationBins'` option:

				* `binWidth` (1x1 double): Width of elevation bins. Units: meters.

				* `binOutlierQuantiles` (1x2 double): Quantiles for which elevation change pixels are considered outliers within a bin. Any elevation change pixels falling outside the specified quantiles are removed from the bin. Must be a 1x2 vector with values between 0 and 1.

				* `binMinValidCount` (1x1 double): Bins with less than this number of pixels are removed. The bin means are subsequently interpolated using adjacent bins.

				* `endBinsFillVal` (1x2 double): If the first bin (lowest elevation) or last bin (highest elevation) have pixel counts less than `binMinValidCount`, their bin means are set to the first value (first bin) or the second value (last bin) in this 1x2 vector during interpolation. Units: meters year<sup>-1</sup>.

		* `params.materialDensity` (1x1 double): Average density of material for estimating geodetic mass balance. Units: kg meters<sup>3</sup>.

		* `params.maskDilateRadius` (1x1 double): The unstable terrain mask is morphologically dilatated with a "disk" structuring element. The radius of the disk is specified here. Units: meters.

		* `params.spatialCorrelationRange` (1x1 double): Maximum distance over which the terrain is expected to exhibit spatial autocorrelation. Units: meters.

		* `params.simulationCount` (1x1 double): Number of simulations to perform in the random sampling procedure when estimating geomorphic change uncertainties.

		* `params.extrapolationSigma` (1x1 double): 1-sigma uncertainty associated with interpolation or extrapolation of missing data, used in error propagation calculations.

		* `params.materialDensitySigma` (1x1 double): 1-sigma uncertainty of material density, used in error propagation calculations.

		* `params.areaPercentError` (1x1 double): 1-sigma uncertainty of polygon area estimates (in percent), used in error propagation calculations.


* `shapefileLoop(historicalShapefilePath,saveDir,polygonIdField,numBlocksX,numBlocksY,functionHandles,parallel);`

	* `historicalShapefilePath` (char): Path to the shapefile containing "historical" polygons (i.e. at beginning of timespan of interest). Corresponding historical and modern polygons will be matched up based on their ID field values (see `params.polygonIdField` above).

	* `saveDir` (char): Directory to save the *.mat* file outputs.

	* `polygonIdField` (char): ID field used to match up historical and modern polygons (the same as `params.polygonIdField` above).

	* `numBlocksX` (1x1 double): Number of processing blocks (within geographic extent of the historical shapefile) in horizontal direction.

	* `numBlocksY` (1x1 double): Number of processing blocks (within geographic extent of the historical shapefile) in vertical direction.

	* `functionHandles` (1xN cell): Array of function handles to be called for each shapefile polygon. Custom user-defined functions can be specified here if desired.

	* `parallel` (1x1 logical): Flag specifying whether to execute for-loop iterations in parallel (requires the parallel computing toolbox).

The *geomorphicChange.m* function outputs results in individual *.mat* files corresponding to each polygon processed. The output (struct) fields are as follows:

* `bins` (struct): If `'elevationBins'` is specified in `params.interpParams` (see above), this contains statistics for the elevation bins such as mean, median, and std.

* `change` (struct): Contains the geomorphic change values:

	* `historicalArea` (1x1 double): The area of the historical polygon. Units: m<sup>2</sup>.

	* `modernArea` (1x1 double): The area of the modern polygon. Units: m<sup>2</sup>.

	* `percentDataCoverage` (1x1 double): The percentage of the polygon area where elevation changes were computed.

	* `volumeChange` (1x1 double): Total estimated volume change within the polygon. Units: meters<sup>3</sup> year<sup>-1</sup>.

	* `meanElevationChange` (1x1 double): Mean elevation change within the polygon area. Units: meters year<sup>-1</sup>.

	* `geodeticMassBalance` (1x1 double): Geodetic mass balance of the polygon. Units: kg meters<sup>-2</sup> year<sup>-1</sup>. Note: for glaciers, divide this value by 1000 to convert to meters of water equivalent per year (m w.e. yr<sup>-1</sup>) with ice/snow density specified in `params.materialDensity`.

* `demParams` (struct): Contains a copy of the DEM parameters (see above) for each DEM used to calculate geomorphic change for the polygon.

* `grid` (struct): Gridded data (MxN matrices) for the polygon, including longitude, latitude, elevation, slope, historical and modern polygon masks, elevation change map, data gaps mask, unstable terrain mask, and a spatial referencing structure (useful for exporting grids as geotiffs).

* `historicalShapefile` (struct): The historical shapefile polygon data. Also see `historicalShapefilePath` above.

* `modernShapefile` (struct): The modern shapefile polygon data. Also see `modernShapefilePath` above.

* `params` (struct): Contains a copy of the `geomorphicChange` input parameters (see above).

* `sigma` (struct): 1-sigma uncertainty estimates for the geomorphic change values contained in `change` (see above).

* `timespan` (1x1 double): Timespan (duration) covered by the input data. Units: years.

## References

* Maurer, J. M., Schaefer, J. M., Rupper, S., & Corley, A. (2019). Acceleration of ice loss across the Himalayas over the past 40 years. Science advances, 5(6), eaav7266.