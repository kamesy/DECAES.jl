@testset "version numbers" begin
    DECAES_PATH = pkgdir(DECAES)
    decaes_proj = TOML.parsefile(joinpath(DECAES_PATH, "Project.toml"))
    decaes_app_proj = TOML.parsefile(joinpath(DECAES_PATH, "api", "DECAESApp", "Project.toml"))
    decaes_cli_proj = TOML.parsefile(joinpath(DECAES_PATH, "api", "DECAESCLI", "Project.toml"))

    @test DECAES.VERSION == VersionNumber(decaes_proj["version"])
    @test DECAES.VERSION == VersionNumber(decaes_app_proj["version"])

    (; major, minor, patch, prerelease) = DECAES.VERSION
    if prerelease == ()
        @test DECAES.VERSION == VersionNumber(decaes_app_proj["compat"]["DECAES"])
        @test DECAES.VERSION == VersionNumber(decaes_cli_proj["compat"]["DECAES"])
    else
        @test prerelease == ("DEV",)
        @test decaes_app_proj["compat"]["DECAES"] == "=$(major).$(minor).$(patch)"
        @test decaes_cli_proj["compat"]["DECAES"] == "=$(major).$(minor).$(patch)"
    end

    for file in ["decaes.m", "decaes.py", "decaes.sh"]
        contents = readchomp(joinpath(DECAES_PATH, "api", file))
        @test contains(contents, "was written for DECAES v$(DECAES.VERSION)")
    end
end

@testset "install cli script" begin
    homedepot = first(DEPOT_PATH)
    bin = mkpath(joinpath(homedepot, "bin"))

    rm(pkgdir(DECAES, "api", "DECAESCLI", "Manifest.toml"); force = true)
    Pkg.activate(pkgdir(DECAES, "api", "DECAESCLI")) do
        # Need to instantiate this development version of DECAES
        Pkg.develop(; path = pkgdir(DECAES))
    end

    # st = DECAES.redirect_to_devnull() do
    #     return DECAES.install_decaes_cli()
    # end
    st = DECAES.install_decaes_cli()
    @test success(st)

    if Sys.iswindows()
        cli = joinpath(bin, "decaes.cmd")
        @test isfile(cli)
        @test success(`cmd /c $(cli) "--help"`)
    else
        cli = joinpath(bin, "decaes")
        @test isfile(cli)
        @test success(`bash -c "$(cli) --help"`)
    end
end
