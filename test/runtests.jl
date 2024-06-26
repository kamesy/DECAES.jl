using Aqua
using Test

using DoubleFloats
using ForwardDiff
using LinearAlgebra
using Pkg
using PolynomialRoots: PolynomialRoots
using Random
using StaticArrays
using Statistics
using TOML

using DECAES
using DECAES: NNLS
using DECAES: NormalHermiteSplines
using DECAES:
    GrowableCache, GrowableCachePairs, CachedFunction, MappedArray,
    LCurveCornerPoint, LCurveCornerState, LCurveCornerCachedFunction,
    NNLSProblem, NNLSTikhonovRegProblem, NNLSTikhonovRegProblemCache,
    lcurve_corner

# Environment flags
is_ci() = lowercase(get(ENV, "CI", "false")) == "true"
RUN_MATLAB_TESTS = !is_ci() && get(ENV, "DECAES_RUN_MATLAB_TESTS", "") != "0"
MWI_TOOLBOX_PATH = get(ENV, "DECAES_MWI_TOOLBOX_PATH", "")
RUN_MWI_TOOLBOX_TESTS = get(ENV, "DECAES_RUN_MWI_TOOLBOX_TESTS", "") != "0"

# Try loading MATLAB.jl
if RUN_MATLAB_TESTS
    try
        @eval using MATLAB
        mxcall(:addpath, 0, joinpath(pkgdir(DECAES), "api"))
    catch e
        global RUN_MATLAB_TESTS = false
        @warn "Failed to load Julia package MATLAB.jl; skipping MATLAB tests"
        @warn sprint(showerror, e, catch_backtrace())
    end
end

# Try finding UBC MWI toolbox
mfile_exists(fname) = MATLAB.mxcall(:exist, 1, fname) == 2
if RUN_MATLAB_TESTS && RUN_MWI_TOOLBOX_TESTS
    try
        if !isempty(MWI_TOOLBOX_PATH)
            mxcall(:addpath, 0, MWI_TOOLBOX_PATH)
        end
        if !mfile_exists("T2map_SEcorr_nechoes_2019") || !mfile_exists("T2part_SEcorr_2019")
            global RUN_MWI_TOOLBOX_TESTS = false
            @warn "Files T2map_SEcorr_nechoes_2019.m and T2part_SEcorr_2019.m were not found on the default MATLAB path. " *
                  "Modify your default MATLAB path to include these files, or set the DECAES_MWI_TOOLBOX_PATH environment variable.\n\n" *
                  "For example, on unix-like systems run" *
                  "\n\n    export DECAES_MWI_TOOLBOX_PATH=/path/to/MWI_NNLS_toolbox_0319\n\n" *
                  "before testing DECAES, or add a command such as" *
                  "\n\n    addpath /path/to/MWI_NNLS_toolbox_0319\n\n" *
                  "to your startup.m file in MATLAB."
        end
    catch e
        global RUN_MWI_TOOLBOX_TESTS = false
        @warn "Failed to find the UBC MWI toolbox; skipping tests"
        @warn sprint(showerror, e, catch_backtrace())
    end
end

@testset "misc.jl" verbose = true begin
    include("misc.jl")
end

@testset "nhs.jl" verbose = true begin
    include("nhs.jl")
end

@testset "utils.jl" verbose = true begin
    include("utils.jl")
end

@testset "optimization.jl" verbose = true begin
    include("optimization.jl")
end

@testset "splines.jl" verbose = true begin
    include("splines.jl")
end

@testset "nnls.jl" verbose = true begin
    include("nnls.jl")
end

@testset "epg.jl" verbose = true begin
    include("epg.jl")
end

@testset "cli.jl" verbose = true begin
    include("cli.jl")
end

@testset "aqua" begin
    # Typically causes a lot of false positives with ambiguities and/or unbound args checks;
    # unfortunately have to periodically check this manually
    Aqua.test_all(DECAES; ambiguities = false, unbound_args = true)
end
