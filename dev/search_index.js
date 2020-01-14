var documenterSearchIndex = {"docs":
[{"location":"cli/#Command-Line-Interface-1","page":"Command Line Interface","title":"Command Line Interface","text":"","category":"section"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"DECAES.jl provides a command line interface (CLI) for calling the main analysis functions: T2mapSEcorr for computing T_2-distributions, and T2partSEcorr for computing T_2-parts analysis, such as computing the myelin water fraction.","category":"page"},{"location":"cli/#Using-the-CLI-1","page":"Command Line Interface","title":"Using the CLI","text":"","category":"section"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"Assuming you have DECAES.jl installed, there are two equivalent ways to use the CLI:","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"1. Helper script: Create a simple Julia script which calls the entrypoint function main provided by this package. For example, save the following code in a Julia script called decaes.jl:","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"using DECAES # load the package\nmain() # call command line interface","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"Run this script from the command line using julia as follows:","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"$ julia decaes.jl image.nii <COMMAND LINE ARGS>","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"2. Julia -e flag: The contents of the above script can equivalently be passed directly to Julia using the -e flag (-e for \"evaluate\"):","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"$ julia -e 'using DECAES; main()' image.nii <COMMAND LINE ARGS>","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"Either way of calling the CLI forwards the arguments <COMMAND LINE ARGS> to the entrypoint function main. Available arguments are detailed in the Arguments section.","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"For the remainder of this section, we will make use of the decaes.jl script from option 1.","category":"page"},{"location":"cli/#Multithreading-1","page":"Command Line Interface","title":"Multithreading","text":"","category":"section"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"Multithreaded parallel processing can be enabled by setting the JULIA_NUM_THREADS environment variable as follows:","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"println(\"\\$ export JULIA_NUM_THREADS=$(Threads.nthreads())\") # hide\nprintln(\"\\$ julia decaes.jl image.nii <COMMAND LINE ARGS>\") # hide","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"This is highly recommended to speed up computation time, but is not strictly required.","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"note: Note\nFrom the Julia documentation:[The keyword export] works on bourne shells on Linux and OSX. Note that if you're using a C shell on these platforms, you should use the keyword set instead of export. If you're on Windows, start up the command line in the location of julia.exe and use set instead of export.","category":"page"},{"location":"cli/#File-types-1","page":"Command Line Interface","title":"File types","text":"","category":"section"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"The input image (image.nii above) must be one of two file types:","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"NIfTI file with extension .nii, or gzip compressed NIfTI file with extension .nii.gz. See NIfTI.jl for more information\nMATLAB file with extension .mat. Note: .mat files saved in the oldest format v4 are not supported, but all newer formats (v6, v7, and v7.3) are supported. See MAT.jl for more information","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"All output files are saved as .mat files in format v7.3. ","category":"page"},{"location":"cli/#Arguments-1","page":"Command Line Interface","title":"Arguments","text":"","category":"section"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"Available command line arguments are broken into three categories:","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"Positional arguments: these are the input files. Input files are typically placed at the beginning of <COMMAND LINE ARGS>.\nOptional arguments: settings governing the analysis pipeline. See below for details.\nT2mapSEcorr/T2partSEcorr arguments: settings for computing the T_2-distribution and subsequent T_2-parts analysis. See below for the full parameter list; see T2mapSEcorr and T2partSEcorr for parameter descriptions. Note: if no default is shown, the parameter is unused by default.","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"using DECAES # hide\nDECAES.ArgParse.show_help(DECAES.ARGPARSE_SETTINGS; exit_when_done = false) # hide","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"note: Note\nIf desired, the T_2-distribution computation and the T_2-parts analysis may be performed separately:When the --T2map flag is passed, or both --T2map and --T2part flags are passed, input arrays should be 4D with data as (row, column, slice, echo)\nWhen only the --T2part flag is passed, input arrays should be 4D with data as (row, column, slice, T_2 bin)","category":"page"},{"location":"cli/#Examples-1","page":"Command Line Interface","title":"Examples","text":"","category":"section"},{"location":"cli/#Default-options-1","page":"Command Line Interface","title":"Default options","text":"","category":"section"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"using DECAES\nconst imfile = \"image.nii.gz\"\nfunction callmain(args...)\n    image = DECAES.mock_image(MatrixSize = (100,100,1))\n    cd(tempdir()) do\n        try\n            DECAES.NIfTI.niwrite(imfile, DECAES.NIfTI.NIVolume(image))\n            main(String[args...])\n        finally\n            isfile(imfile) && rm(imfile)\n        end\n    end\n    nothing\nend","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"Suppose you have a multi spin-echo image file image.nii which you would like to perform T_2 analysis on. We can call T2mapSEcorr and T2partSEcorr on the file image.nii with default options using decaes.jl as follows:","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"println(\"\\$ export JULIA_NUM_THREADS=$(Threads.nthreads())\") # hide\nprintln(\"\\$ julia decaes.jl image.nii --T2map --T2part\") # hide","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"After a few seconds, the script should begin running with the following messages appearing as the script progresses (note that real images will take longer to process than this toy example):","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"callmain(imfile, \"--T2map\", \"--T2part\") # hide","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"The script will produce four files, each with the input filename (without suffix) used as a prefix:","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"image.t2dist.mat: MATLAB file containing the T_2-distributions\nimage.t2maps.mat: MATLAB file containing T_2-distribution property maps and NNLS fit parameters; see T2mapSEcorr\nimage.t2parts.mat: MATLAB file containing T_2-parts analysis results such as the MWF; see T2partSEcorr\nimage.log: Log file containing the console output","category":"page"},{"location":"cli/#multiinput-1","page":"Command Line Interface","title":"Multiple input files","text":"","category":"section"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"Multiple input files (possibly of different file types) can be passed in the obvious way:","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"println(\"\\$ export JULIA_NUM_THREADS=$(Threads.nthreads())\") # hide\nprintln(\"\\$ julia decaes.jl image1.nii image2.mat image3.nii.gz --T2map --T2part\") # hide","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"note: Note\n.nii and .nii.gz input image files are assumed to be 4D when loaded; an error will occur if they are not 4D. For .mat files, the first 4D array which is found within the .mat file is used (multiple 4D arrays should not be stored in the same .mat file); an error will occur if no 4D image is found.","category":"page"},{"location":"cli/#outfolder-1","page":"Command Line Interface","title":"Specify output folder","text":"","category":"section"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"By default, output files are saved in the same location as the corresponding input file. If you'd like to save them in a different folder, you can use the -o or --output flag:","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"println(\"\\$ export JULIA_NUM_THREADS=$(Threads.nthreads())\") # hide\nprintln(\"\\$ julia decaes.jl image.nii --T2map --T2part --output /path/to/output/folder/\") # hide","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"The requested output folder will be created if it does not already exist.","category":"page"},{"location":"cli/#nondefault-1","page":"Command Line Interface","title":"Non-default parameters","text":"","category":"section"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"Parameter values can be set to non-default values at the command line. For example, we can set the echo time TE to 8ms, the number of T_2 bins nT2 to 60, and the T_2 distribution range to [10ms, 1.5s] as follows:","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"println(\"\\$ export JULIA_NUM_THREADS=$(Threads.nthreads())\") # hide\nprintln(\"\\$ julia decaes.jl image.nii --T2map --T2part --TE 0.008 --nT2 60 --T2Range 0.010 1.5\") # hide","category":"page"},{"location":"cli/#outfolder-2","page":"Command Line Interface","title":"Passing image masks","text":"","category":"section"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"Image masks can be passed into DECAES.jl using the --mask flag:","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"println(\"\\$ export JULIA_NUM_THREADS=$(Threads.nthreads())\") # hide\nprintln(\"\\$ julia decaes.jl image.nii --T2map --T2part --mask mask.nii\") # hide","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"The mask is loaded and applied to the input image via elementwise multiplication over the spatial dimensions, e.g. the mask is applied for each echo of a 4D multi-echo input image.","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"If multiple images are passed along with a single mask, the mask is used for all images:","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"println(\"\\$ export JULIA_NUM_THREADS=$(Threads.nthreads())\") # hide\nprintln(\"\\$ julia decaes.jl image1.nii image2.mat --T2map --T2part --mask mask.nii\") # hide","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"Alternatively, a mask can be passed for each input image (note that masks, too, can be any valid file type):","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"println(\"\\$ export JULIA_NUM_THREADS=$(Threads.nthreads())\") # hide\nprintln(\"\\$ julia decaes.jl image1.nii image2.mat --T2map --T2part --mask mask1.mat mask2.nii.gz\") # hide","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"note: Note\nIf input images have been manually masked such that they are e.g. zero outside of regions of interest, a mask need not be passed. The --Threshold parameter of T2mapSEcorr controls a first echo intensity cutoff threshold (default value 200.0), below which voxels are automatically skipped during processing.","category":"page"},{"location":"cli/#Automatic-brain-masking-with-BET-1","page":"Command Line Interface","title":"Automatic brain masking with BET","text":"","category":"section"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"The BET brain extraction tool from the FSL library of analysis tools can be used to automatically generate a brain mask prior to analysis. Only voxels within the generated brain mask will be processed, greatly reducing analysis time. To use BET, pass the --bet flag:","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"println(\"\\$ export JULIA_NUM_THREADS=$(Threads.nthreads())\") # hide\nprintln(\"\\$ julia decaes.jl image.nii --T2map --T2part --bet\") # hide","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"If bet is not on your system path, you can pass the path to the bet binary with the --betpath flag. Additionally, you can pass arguments to bet with the --betargs flag:","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"println(\"\\$ export JULIA_NUM_THREADS=$(Threads.nthreads())\") # hide\nprintln(\"\\$ julia decaes.jl image.nii --T2map --T2part --bet --betpath /path/to/bet --betargs '-m -n'\") # hide","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"Note that bet arguments must be passed as a single string to --betargs, separated by spaces, as shown above.","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"note: Note\nIf a mask file is passed using the --mask flag, the --bet flag will be ignored and the mask file will be used.","category":"page"},{"location":"cli/#Settings-files-1","page":"Command Line Interface","title":"Settings files","text":"","category":"section"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"Parameter values can be read in from a settings file. For example, we can combine the examples from the Specify output folder and Non-default parameters sections by creating a settings.txt file with the following contents:","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"/path/to/image.nii\n--output\n/path/to/output/folder/\n--T2map\n--T2part\n--TE\n0.008\n--nT2\n60\n--T2Range\n0.010\n1.5","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"If this file is located at /path/to/settings.txt, simply prefix the filepath with the @ character to have the file contents read into the main function:","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"println(\"\\$ export JULIA_NUM_THREADS=$(Threads.nthreads())\") # hide\nprintln(\"\\$ julia decaes.jl @/path/to/settings.txt\") # hide","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"note: Note\nThe use of settings files is highly recommended for both reproducibility and for self-documentation. The input settings file will be automatically copied into the output folder for each processed image, with the image filename prepended. In this case, for example, the copied settings file would be called image.settings.txt\nOnly one flag or value is allowed per line within a settings file. Flags which require multiple inputs (e.g. --T2Range above) must use one line for each input\nThe extension of the settings file is ignored; .txt is arbitrary in this example\nThough not strictly necessary, using full input- and output paths is recommended. This way, one doesn't rely on relative paths and can e.g. call julia /path/to/decaes.jl @/path/to/settings.txt from any directory","category":"page"},{"location":"cli/#Legacy-options-1","page":"Command Line Interface","title":"Legacy options","text":"","category":"section"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"During the MATLAB port to Julia, some algorithms were replaced with mathematically identical but computationally more efficient algorithms which may cause small differences in output parameter maps, and some default options were changed.","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"For example, the flip angle optimization procedure requires finding the root of a cubic spline. In MATLAB this was performed by evaluating the spline on a very fine mesh and choosing the value nearest zero. During profiling it was found that this was a time consuming operation, and therefore in Julia this was replaced by an efficient spline rootfinding method.","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"The differences due to algorithmic changes like the one above are quite small. For example, most tests will pass when using a relative tolerance of 10^-3, and almost all tests pass with a relative tolerance of 10^-2. That is to say that nearly all outputs are identical to 3 or more significant digits, which includes T_2-distributions, MWF maps, etc.","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"The --legacy flag is available if exact reproducibility is required compared to the MATLAB version. This will ensure that all outputs match to nearly machine precision (a relative tolerance of 10^-10 is used during testing). Note however that the --legacy flag may cause a significant slowdown in processing time due to less efficient internal algorithms being used, and is therefore not recommended unless absolutely necessary. Differences due to changes in default parameters can always be overridden by passing in the desired value explicitly (e.g. --SPWin 0.014 0.040) without the need for the --legacy flag.","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"Default options with the --legacy flag","category":"page"},{"location":"cli/#","page":"Command Line Interface","title":"Command Line Interface","text":"using DECAES # hide\nDECAES.ArgParse.show_help(DECAES.ARGPARSE_SETTINGS_LEGACY; exit_when_done = false) # hide","category":"page"},{"location":"ref/#API-Reference-1","page":"API Reference","title":"API Reference","text":"","category":"section"},{"location":"ref/#t2map-1","page":"API Reference","title":"T_2-Distribution Mapping","text":"","category":"section"},{"location":"ref/#","page":"API Reference","title":"API Reference","text":"T2mapOptions\nT2mapSEcorr","category":"page"},{"location":"ref/#DECAES.T2mapOptions","page":"API Reference","title":"DECAES.T2mapOptions","text":"T2mapOptions(; <keyword arguments>)\n\nOptions structure for T2mapSEcorr. This struct collects keyword arguments passed to T2mapSEcorr, performs checks on parameter types and values, and assigns default values to unspecified parameters.\n\nArguments\n\nMatrixSize:     size of first 3 dimensions of input 4D image. This argument is has no default, but is inferred automatically as size(image)[1:3] when calling T2mapSEcorr(image; kwargs...)\nnTE:            number of echoes in input signal. This argument is has no default, but is inferred automatically as size(image, 4) when calling T2mapSEcorr(image; kwargs...)\nTE:             interecho spacing (Default: 10e-3, Units: seconds)\nT1:             assumed value of T1 (Default: 1.0, Units: seconds)\nThreshold:      first echo intensity cutoff for empty voxels (Default: 200.0)\nChi2Factor:     constraint on chi^2 used for regularization when Reg == \"chi2\" (Default: 1.02)\nnT2:            number of T2 times to use (Default: 40)\nT2Range:        min and max T2 values (Default: (10e-3, 2.0), Units: seconds)\nRefConAngle:    refocusing pulse control angle (Default: 180.0, Units: degrees)\nMinRefAngle:    minimum refocusing angle for flip angle optimization (Default: 50.0, Units: degrees)\nnRefAngles:     during flip angle optimization, goodness of fit is checked for up to nRefAngles angles in the range [MinRefAngle, 180]. The optimal angle is then determined through interpolation from these samples (Default: 32)\nnRefAnglesMin:  initial number of angles to check during flip angle optimization before refinement near likely optima; nRefAnglesMin == nRefAngles forces all angles to be checked (Default: 5)\nReg:            regularization routine to use:\n\"no\":       no regularization of solution\n\"chi2\":     use Chi2Factor based regularization (Default)\n\"lcurve\":   use L-Curve based regularization\nSetFlipAngle:   instead of optimizing flip angle, use this flip angle for all voxels (Default: nothing, Units: degrees)\nSaveRegParam:   true/false option to include the resulting regularization parameter mu and chi^2 factor as outputs within the maps dictionary (Default: false)\nSaveNNLSBasis:  true/false option to include a 5-D array of NNLS basis matrices as an output within the maps dictionary (Default: false)\n\nnote: Note\nThe 5-D array that is saved when SaveNNLSBasis is set to true has dimensions MatrixSize x nTE x nT2, and therefore is typically extremely large; by default, it is nT2 = 40 times the size of the input image. Saving the NNLS basis is only advised for very small images\n\nSilent:         suppress printing to the console (Default: false)\n\nSee also:\n\nT2mapSEcorr\n\n\n\n\n\n","category":"type"},{"location":"ref/#DECAES.T2mapSEcorr","page":"API Reference","title":"DECAES.T2mapSEcorr","text":"T2mapSEcorr(image; <keyword arguments>)\nT2mapSEcorr(image, opts::T2mapOptions)\n\nUses nonnegative least squares (NNLS) to compute T2 distributions in the presence of stimulated echos by optimizing the refocusing pulse flip angle. Records parameter maps and T2 distributions for further partitioning.\n\nArguments\n\nimage: 4-D array with intensity data as (row, column, slice, echo)\nA series of optional keyword argument settings which will be used to construct a T2mapOptions struct internally, or a T2mapOptions struct directly\n\nOutputs\n\nmaps: dictionary containing 3D maps with the following fields:\n\"gdn\": general density\n\"ggm\": general geometric mean\n\"gva\": general variance\n\"fnr\": fit to noise ratio = gdn / sqrt(sum(residuals.^2) / (nTE-1))\n\"snr\": signal to noise ratio = maximum(signal) / std(residuals)\n\"alpha\": refocusing pulse flip angle\n\"mu\": (optional) regularization parameter from NNLS fit\n\"chi2factor\": (optional) chi^2 increase factor from NNLS fit\n\"decaybasis\": (optional) decay basis from EPGdecaycurve\ndistributions: 4-D array with data as (row, column, slice, T2 amplitude) containing T2 distributions\n\nExamples\n\njulia> image = DECAES.mock_image(MatrixSize = (100,100,1), nTE = 32); # mock image with size 100x100x1x32\n\njulia> maps, dist = T2mapSEcorr(image; TE = 10e-3, Silent = true); # compute the T2-maps and T2-distribution\n\njulia> maps\nDict{String,Array{Float64,N} where N} with 6 entries:\n  \"gdn\"   => [10052.7 10117.6 … 10030.9 10290.4; 10110.2 10193.6 … 9953.01 10085.3; … ; 1004…\n  \"alpha\" => [176.666 177.116 … 177.557 176.503; 177.455 177.83 … 177.558 177.639; … ; 176.6…\n  \"snr\"   => [541.095 636.746 … 492.519 787.512; 503.934 592.39 … 455.082 509.539; … ; 448.9…\n  \"fnr\"   => [677.631 807.875 … 626.881 1012.96; 625.444 764.197 … 571.902 653.781; … ; 569.…\n  \"gva\"   => [0.280518 0.307561 … 0.372818 0.423089; 0.330033 0.377154 … 0.218693 0.260413; …\n  \"ggm\"   => [0.0494424 0.0456093 … 0.0467535 0.0454226; 0.0480455 0.0444683 … 0.0473485 0.0…\n\nSee also:\n\nT2partSEcorr\nlsqnonneg\nlsqnonneg_reg\nlsqnonneg_lcurve\nEPGdecaycurve\n\n\n\n\n\n","category":"function"},{"location":"ref/#t2part-1","page":"API Reference","title":"T_2-Parts and the Myelin Water Fraction","text":"","category":"section"},{"location":"ref/#","page":"API Reference","title":"API Reference","text":"T2partOptions\nT2partSEcorr","category":"page"},{"location":"ref/#DECAES.T2partOptions","page":"API Reference","title":"DECAES.T2partOptions","text":"T2partOptions(; <keyword arguments>)\n\nOptions structure for T2partSEcorr. This struct collects keyword arguments passed to T2partSEcorr, performs checks on parameter types and values, and assigns default values to unspecified parameters.\n\nArguments\n\nMatrixSize: size of first 3 dimensions of input 4D T2 distribution. This argument is has no default, but is inferred automatically as size(T2distribution)[1:3] when calling T2partSEcorr(T2distribution; kwargs...)\nnT2:        number of T2 values in distribution. This argument is has no default, but is inferred automatically as size(T2distribution, 4) when calling T2partSEcorr(T2distribution; kwargs...)\nT2Range:    min and max T2 values of distribution (Default: (10e-3, 2.0), Units: seconds)\nSPWin:      min and max T2 values of the short peak window (Default: (10e-3, 25e-3), Units: seconds)\nMPWin:      min and max T2 values of the middle peak window (Default: (25e-3, 200e-3), Units: seconds)\nSigmoid:    apply sigmoidal weighting to the upper limit of the short peak window.               Sigmoid is the delta-T2 parameter, which is the distance in seconds on either side of the SPWin upper limit where the sigmoid curve reaches 10% and 90% (Default: nothing, Units: seconds)\nSilent:     suppress printing to the console (Default: false)\n\nSee also:\n\nT2partSEcorr\n\n\n\n\n\n","category":"type"},{"location":"ref/#DECAES.T2partSEcorr","page":"API Reference","title":"DECAES.T2partSEcorr","text":"T2partSEcorr(T2distributions; <keyword arguments>)\nT2partSEcorr(T2distributions, opts::T2partOptions)\n\nAnalyzes T2 distributions produced by T2mapSEcorr to produce data maps of a series of parameters.\n\nArguments\n\nT2distributions: 4-D array with data as (row, column, slice, T2 amplitude)\nA series of optional keyword argument settings which will be used to construct a T2partOptions struct internally, or a T2partOptions struct directly\n\nOuputs\n\nmaps: a dictionary containing the following 3D data maps as fields:\n\"sfr\": small pool fraction, e.g. myelin water fraction\n\"sgm\": small pool geometric mean T2\n\"mfr\": medium pool fraction, e.g. intra/extracellular water fraction\n\"mgm\": medium pool geometric mean T2\n\nExamples\n\njulia> dist = DECAES.mock_T2_dist(MatrixSize = (100,100,1), nT2 = 40); # mock distribution with size 100x100x1x40\n\njulia> maps = T2partSEcorr(dist; Silent = true); # compute T2-parts maps\n\njulia> maps # MWF is contained in maps[\"sfr\"]\nDict{String,Array{Float64,3}} with 4 entries:\n  \"sgm\" => [0.0159777 0.0156194 … 0.0149169 0.0121455; 0.015296 0.0143854 … 0.018459 0.01627…\n  \"mfr\" => [0.852735 0.814759 … 0.808621 0.859088; 0.830943 0.804878 … 0.836248 0.816681; … …\n  \"sfr\" => [0.147265 0.185241 … 0.191379 0.140912; 0.169057 0.195122 … 0.163752 0.183319; … …\n  \"mgm\" => [0.0600928 0.0581919 … 0.0612683 0.0563942; 0.0606434 0.0584615 … 0.0569397 0.054…\n\nSee also:\n\nT2mapSEcorr\n\n\n\n\n\n","category":"function"},{"location":"ref/#nnls-1","page":"API Reference","title":"NNLS Analysis","text":"","category":"section"},{"location":"ref/#","page":"API Reference","title":"API Reference","text":"lsqnonneg\nlsqnonneg_reg\nlsqnonneg_lcurve","category":"page"},{"location":"ref/#DECAES.lsqnonneg","page":"API Reference","title":"DECAES.lsqnonneg","text":"lsqnonneg(C::AbstractMatrix, d::AbstractVector)\n\nReturns the nonnegative least-squares (NNLS) solution, X, of the equation:\n\nX = mathrmargmin_x ge 0 Cx - d_2^2\n\nArguments\n\nC::AbstractMatrix: Left hand side matrix acting on x\nd::AbstractVector: Right hand side vector\n\nOutputs\n\nX::AbstractVector: NNLS solution\n\n\n\n\n\n","category":"function"},{"location":"ref/#DECAES.lsqnonneg_reg","page":"API Reference","title":"DECAES.lsqnonneg_reg","text":"lsqnonneg_reg(C::AbstractMatrix, d::AbstractVector, Chi2Factor::Real)\n\nReturns the regularized NNLS solution, X, that incurrs an increase in chi^2 approximately by a factor of Chi2Factor. The regularized NNLS problem solved internally is:\n\nX = mathrmargmin_x ge 0 Cx - d_2^2 + mux_2^2\n\nwhere mu is determined by approximating a solution to the nonlinear equation\n\nfracchi^2(mu)chi^2_min = mathrmChi2Factor\nquad\ntextwhere\nquad\nchi^2_min = chi^2(mu = 0)\n\nArguments\n\nC::AbstractMatrix: Decay basis matrix\nd::AbstractVector: Decay curve data\nChi2Factor::Real: Desired chi^2 increase due to regularization\n\nOutputs\n\nX::AbstractVector: Regularized NNLS solution\nmu::Real: Resulting regularization parameter mu\nChi2Factor::Real: Actual increase chi^2(mu)chi^2_min, which will be approximately equal to the input Chi2Factor\n\n\n\n\n\n","category":"function"},{"location":"ref/#DECAES.lsqnonneg_lcurve","page":"API Reference","title":"DECAES.lsqnonneg_lcurve","text":"lsqnonneg_lcurve(C::AbstractMatrix, d::AbstractVector)\n\nReturns the regularized NNLS solution, X, of the equation\n\nX = mathrmargmin_x ge 0 Cx - d_2^2 + muH x_2^2\n\nwhere H is the identity matrix and mu is chosen by the L-curve theory using the Generalized Cross-Validation method. Details of L-curve and GCV methods can be found in: Hansen, P.C., 1992. Analysis of Discrete Ill-Posed Problems by Means of the L-Curve. SIAM Review, 34(4), 561-580\n\nArguments\n\nC::AbstractMatrix: Decay basis matrix\nd::AbstractVector: Decay curve data\n\nOutputs\n\nX::AbstractVector: Regularized NNLS solution\nmu::Real: Resulting regularization parameter mu\nChi2Factor::Real: Resulting increase in chi^2 relative to unregularized (mu = 0) solution\n\n\n\n\n\n","category":"function"},{"location":"ref/#epg-1","page":"API Reference","title":"Extended Phase Graph Algorithm","text":"","category":"section"},{"location":"ref/#","page":"API Reference","title":"API Reference","text":"EPGdecaycurve","category":"page"},{"location":"ref/#DECAES.EPGdecaycurve","page":"API Reference","title":"DECAES.EPGdecaycurve","text":"EPGdecaycurve(ETL::Int, flip_angle::Real, TE::Real, T2::Real, T1::Real, refcon::Real)\n\nComputes the normalized echo decay curve for a MR spin echo sequence using the extended phase graph algorithm using the given input parameters.\n\nArguments\n\nETL::Int:         echo train length, i.e. number of echos\nflip_angle::Real: angle of refocusing pulses (Units: degrees)\nTE::Real:         inter-echo time (Units: seconds)\nT2::Real:         transverse relaxation time (Units: seconds)\nT1::Real:         longitudinal relaxation time (Units: seconds)\nrefcon::Real:     value of Refocusing Pulse Control Angle (Units: degrees)\n\nOutputs\n\ndecay_curve::AbstractVector: normalized echo decay curve with length ETL\n\n\n\n\n\n","category":"function"},{"location":"ref/#main-1","page":"API Reference","title":"Main Entrypoint Function","text":"","category":"section"},{"location":"ref/#","page":"API Reference","title":"API Reference","text":"main","category":"page"},{"location":"ref/#DECAES.main","page":"API Reference","title":"DECAES.main","text":"main(command_line_args = ARGS)\n\nEntry point function for command line interface, parsing the command line arguments ARGS and subsequently calling one or both of T2mapSEcorr and T2partSEcorr with the parsed settings. See the Arguments section for available options.\n\nSee also:\n\nT2mapSEcorr\nT2partSEcorr\n\n\n\n\n\n","category":"function"},{"location":"#DEcomposition-and-Component-Analysis-of-Exponential-Signals-(DECAES)-1","page":"Home","title":"DEcomposition and Component Analysis of Exponential Signals (DECAES)","text":"","category":"section"},{"location":"#Introduction-1","page":"Home","title":"Introduction","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"DECAES.jl provides tools for decomposing multi-exponential signals which arise from multi spin-echo magnetic resonance imaging (MRI) scans into exponential components. The main decomposition method used is a regularized nonnegative inverse Laplace transform-based technique. This method involves solving the regularized nonnegative least squares (NNLS) inverse problem","category":"page"},{"location":"#","page":"Home","title":"Home","text":"X = mathrmargmin_x ge 0 Cx - d_2^2 + mux_2^2","category":"page"},{"location":"#","page":"Home","title":"Home","text":"where d is the signal magnitude data, C is a matrix of exponential decay bases, and mu is a regularization parameter. C is constructed using the extended phase graph algorithm with stimulated echo correction. The columns of C are exponential bases with differing characteristic T_2 decay times T_2j.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"The output X is the spectrum of (nonnegative) exponential decay amplitudes. Amplitude X_j of the spectrum X is therefore interpreted physically as the amount of the signal d which decays with time constant T_2j. For this reason, the spectrum X is commonly referred to as the T_2 distribution. DECAES.jl provides methods for computing T_2-distributions.","category":"page"},{"location":"#Myelin-Water-Imaging-1","page":"Home","title":"Myelin Water Imaging","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Myelin water imaging (MWI) is an MRI technique used to visualize the myelin water contained within the sheaths of myelinated axons within the body, such as within the brain's white matter.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Through analysing T_2-distributions computed from multi spin-echo MRI scans, one can separate the contribution due to the myelin water from the intra- and extra-cellular water and compute the myelin water fraction (MWF). The MWF describes the fraction of water trapped between myelin lipid bilayers relative to the total water in the region. DECAES.jl provides methods for computing the MWF.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"MWI was pioneered at the University of British Columbia (UBC) by Alex MacKay and Ken Whittal.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Basics of myelin water imaging:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"https://doi.org/10.1002/mrm.1910310614\nhttps://doi.org/10.1016/0022-2364(89)90011-5\nhttps://doi.org/10.1016/j.neuroimage.2012.06.064\nhttps://doi.org/10.1002/mrm.23157","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Validation of myelin water imaging:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"https://doi.org/10.1016/j.neuroimage.2007.12.008\nhttps://doi.org/10.1016/j.neuroimage.2017.03.065\nhttps://doi.org/10.1016/j.neuroimage.2019.05.042","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Some applications of myelin water imaging:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"https://doi.org/10.1177/1352458517723717\nhttps://doi.org/10.1038/s41598-018-33112-8\nhttps://doi.org/10.1371/journal.pone.0150215","category":"page"},{"location":"#installation-1","page":"Home","title":"Installation","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Start julia from the command line, type ] to enter the package manager REPL mode (the julia> prompt will be replaced by a pkg> prompt), and enter the following command:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"pkg> add https://github.com/jondeuce/DECAES.jl.git","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Once the package is finished installing, type the backspace key to exit the package manager REPL mode (the julia> prompt should reappear). Exit Julia using the keyboard shortcut Ctrl+D, or by typing exit().","category":"page"},{"location":"#Table-of-contents-1","page":"Home","title":"Table of contents","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Pages = [\n    \"t2map.md\",\n    \"t2part.md\",\n    \"cli.md\",\n    \"ref.md\",\n]\nDepth = 1","category":"page"},{"location":"#Acknowledgements-1","page":"Home","title":"Acknowledgements","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Porting to Julia was done by Jonathan Doucette (email: jdoucette@phas.ubc.ca) in November 2019. This work was funded by NSERC (016-05371) and CIHR (RN382474-418628) (PI Alexander Rauscher, University of British Columbia)\nChristian Kames (email: ckames@phas.ubc.ca) contributed to optimizing the Julia port for both speed and memory efficiency\nOriginal MATLAB code was written by Thomas Prasloski (email: tprasloski@gmail.com). Modifications to the MATLAB code were made by Vanessa Wiggermann to enable processing on various MATLAB versions in February 2019. The Julia port is based on this modified version.","category":"page"}]
}
