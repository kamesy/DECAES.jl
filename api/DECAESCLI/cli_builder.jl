# The below code was modified from Comonicon.jl:
#   https://github.com/comonicon/Comonicon.jl/blob/49e4972b61c9f08338a998f081a836c6af103639/src/builder/install.jl

using DECAES # ensure precompiled

function execute(cmd::Cmd)
    # See: https://discourse.julialang.org/t/capture-stdout-and-stderr-in-case-a-command-fails/101772/3
    err = Pipe()
    process = run(pipeline(ignorestatus(cmd); stdout = err, stderr = err))
    close(err.in)
    return (; stderr = String(read(err)), exitcode = process.exitcode)
end

function install()
    # Install DECAES CLI script into ~/.julia/bin
    homedepot = first(DEPOT_PATH)
    bin = mkpath(joinpath(homedepot, "bin"))

    cli = joinpath(bin, "decaes")
    if Sys.iswindows()
        cli = cli * ".cmd"
    end

    @info "DECAES: Installing CLI script: $(cli)"
    ispath(cli) && rm(cli; force = true, recursive = true)
    open(cli; write = true) do io
        print(io, cli_script())
        return nothing
    end
    chmod(cli, 0o777)

    if Sys.iswindows()
        cmd = `cmd /c $(cli) --help`
    else
        cmd = `bash -c "$(cli) --help"`
    end
    @info "DECAES: Testing CLI script: running $(cmd)"
    st = execute(cmd)

    if st.exitcode == 0
        @info "DECAES: CLI script output:\n" * st.stderr
    else
        @error "DECAES: CLI script output:\n" * st.stderr
        @warn "DECAES: CLI script installation failed." *
              "\nTo run DECAES, the following command can be used instead:" *
              "\n    julia --threads=auto -e 'using DECAES; main()' -- <COMMAND LINE ARGS>"
    end

    return nothing
end

function cli_script()
    # Create a batch (Windows) or bash (Unix) script for running DECAES CLI
    cmds = String[]

    # Julia executable path
    exe = joinpath(Sys.BINDIR, Base.julia_exename())
    push!(cmds, exe)

    # Julia flags. Note that --threads and --project are set via environment variables below so that users can overload them
    push!(cmds, "--startup-file=no")
    push!(cmds, "--color=yes")

    # Forward remaining arguments to DECAES.main()
    if Sys.iswindows()
        push!(cmds, "-e \"using DECAES; main()\" %*")
    else
        push!(cmds, "-- \"\${BASH_SOURCE[0]}\" \"\$@\"")
    end

    if Sys.iswindows()
        # Windows batch script
        """
        @echo off
        setlocal
        if not defined JULIA_PROJECT set JULIA_PROJECT=$(DECAES_PROJECT_SCRATCH)
        if not defined JULIA_NUM_THREADS set JULIA_NUM_THREADS=auto
        $(join(cmds, " ^\n    "))
        if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
        endlocal
        """
    else
        # Unix shell script
        """
        #!/usr/bin/env bash
        #=
        JULIA_PROJECT=\"\${JULIA_PROJECT:-$(DECAES_PROJECT_SCRATCH)}\" \\
        JULIA_NUM_THREADS=\"\${JULIA_NUM_THREADS:-auto}\" \\
        exec $(join(cmds, " \\\n    "))
        =#
        using DECAES
        main()
        """
    end
end

if !isinteractive()
    install()
end

nothing
