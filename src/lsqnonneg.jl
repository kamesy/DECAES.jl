####
#### Unregularized NNLS problem
####

struct NNLSProblem{T, MC <: AbstractMatrix{T}, Vd <: AbstractVector{T}, Vdp <: AbstractVector{T}, Vr <: AbstractVector{T}, W}
    C::MC
    d::Vd
    m::Int
    n::Int
    d_backproj::Vdp
    resid::Vr
    nnls_work::W
end
function NNLSProblem(C::AbstractMatrix{T}, d::AbstractVector{T}) where {T}
    m, n = size(C)
    d_backproj = zeros(T, m)
    resid = zeros(T, m)
    nnls_work = NNLS.NNLSWorkspace(C, d)
    NNLSProblem(C, d, m, n, d_backproj, resid, nnls_work)
end

function solve!(work::NNLSProblem)
    # Solve NNLS problem
    @unpack C, d, m, n, d_backproj, resid, nnls_work = work
    NNLS.load!(nnls_work, C, d)
    NNLS.nnls!(nnls_work)
    return solution(work)
end

function solve!(work::NNLSProblem, C, d)
    @inbounds work.C .= C
    @inbounds work.d .= d
    solve!(work)
end

function residuals!(work::NNLSProblem)
    # Calculate predicted curve, calculate residuals, chi-squared
    @unpack C, d, m, n, d_backproj, resid, nnls_work = work
    mul!(d_backproj, C, solution(work))
    @inbounds resid .= d .- d_backproj
    return resid
end

solution(work::NNLSProblem) = work.nnls_work.x

chi2(work::NNLSProblem) = sum(abs2, work.resid)

"""
    lsqnonneg(C::AbstractMatrix, d::AbstractVector)

Returns the nonnegative least-squares (NNLS) solution, X, of the equation:

```math
X = \\mathrm{argmin}_{x \\ge 0} ||Cx - d||_2^2
```

# Arguments
- `C::AbstractMatrix`: Left hand side matrix acting on `x`
- `d::AbstractVector`: Right hand side vector

# Outputs
- `X::AbstractVector`: NNLS solution
"""
lsqnonneg(C, d) = lsqnonneg!(lsqnonneg_work(C, d))
lsqnonneg_work(C, d) = NNLSProblem(C, d)
lsqnonneg!(work::NNLSProblem) = solve!(work)
lsqnonneg!(work::NNLSProblem{T}, C::AbstractMatrix{T}, d::AbstractVector{T}) where {T} = solve!(work, C, d)
