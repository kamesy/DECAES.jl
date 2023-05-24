"""
Lightweight polynomial type
"""
struct Poly{T, A<:AbstractVector{T}}
    c::A
end
Poly(c::Number...) = Poly(c)
Poly(c::Tuple) = Poly([float.(c)...])
Poly(c::AbstractVector{Int}) = Poly(float.(c))

coeffs(p::Poly) = p.c
degree(p::Poly) = length(coeffs(p)) - 1
(p::Poly)(x) = evalpoly(x, coeffs(p))

add!(p::Poly, a::Number) = (p.c[1] += a; return p)
sub!(p::Poly, a::Number) = (p.c[1] -= a; return p)

# Recall: p(x) = Σᵢ cᵢ ⋅ xⁱ⁻¹
derivative(p::Poly{T}) where {T} = Poly(T[(i-1) * coeffs(p)[i] for i in 2:degree(p)+1]) # ∂/∂x p(x) = Σᵢ (i-1) ⋅ cᵢ ⋅ xⁱ⁻²
integral(p::Poly{T}) where {T} = Poly(T[i == 0 ? zero(T) : coeffs(p)[i] / i for i in 0:degree(p)+1]) # ∫₀ˣ p(x) = Σᵢ (cᵢ / i) ⋅ xⁱ
PolynomialRoots.roots(p::Poly) = PolynomialRoots.roots(coeffs(p))
Base.extrema(p::Poly) = PolynomialRoots.roots(derivative(p))

####
#### Spline utils
####

function make_spline(X::AbstractVector, Y::AbstractVector; deg_spline = min(3, length(X)-1))
    @assert length(X) == length(Y) && length(X) > 1
    return Dierckx.Spline1D(X, Y; k = deg_spline, bc = "extrapolate")
end

function build_polynomials(spl::Dierckx.Spline1D, knots = Dierckx.get_knots(spl))
    k = spl.k
    @inbounds t = knots[1:end-1]
    coeffs = zeros(k+1, length(t))
    @inbounds coeffs[1, :] .= spl(t)
    @inbounds for m in 1:k
        coeffs[m+1, :] .= Dierckx.derivative(spl, t, m) ./ factorial(m)
    end
    return [Poly(@views coeffs[:, j]) for j in 1:size(coeffs, 2)]
end

function build_polynomial!(coeffs, spl::Dierckx.Spline1D, t)
    @assert length(coeffs) == spl.k+1
    mfact = 1
    @inbounds coeffs[1] = spl(t)
    @inbounds for m in 1:spl.k
        mfact *= m
        coeffs[m+1] = Dierckx.derivative(spl, t, m) / mfact
    end
    return coeffs
end

# Fit a spline to data `(X, Y)` and minimize `spl(x)`
function spline_opt(X::AbstractVector, Y::AbstractVector; deg_spline = min(3, length(X)-1))
    @assert length(X) == length(Y) "X and Y must have the same length"
    @assert 0 < deg_spline <= 3 "Degree of spline must be 1, 2, or 3"
    if deg_spline == 1
        # Linear spline achievies minimum at one of the nodes
        y, i = findmin(Y)
        return (; x = X[i], y)
    end
    spl = make_spline(X, Y; deg_spline)
    knots = Dierckx.get_knots(spl)
    polys = build_polynomials(spl, knots)
    x, y = knots[1], polys[1](0) # initial lefthand point
    @inbounds for (i, p) in enumerate(polys)
        x₀, x₁ = knots[i], knots[i+1] # spline section endpoints
        _x, _y = x₁, p(x₁ - x₀) # check right endpoint
        (_y < y) && (x = _x; y = _y)
        for rᵢ in extrema(p) # extrema(p) returns the zeros of derivative(p)
            if imag(rᵢ) ≈ 0 # real roots only
                xᵢ = x₀ + real(rᵢ)
                if x₀ <= xᵢ <= x₁ # filter roots within range
                    _x, _y = xᵢ, p(real(rᵢ))
                    (_y < y) && (x = _x; y = _y)
                end
            end
        end
    end
    return (; x, y)
end

# Fit a spline to data `(X, Y)` and solve `spl(x) = value`
function spline_root(X::AbstractVector, Y::AbstractVector, value::Number = 0; deg_spline = min(3, length(X)-1))
    x = eltype(X)(NaN)
    if deg_spline == 1
        # Linear spline has at most one root in each section
        @inbounds for i in 1:length(X)-1
            x₀, y₀, x₁, y₁ = X[i], Y[i], X[i+1], Y[i+1]
            if y₀ <= value <= y₁
                slope = (value - y₀) / (y₁ - y₀)
                x = y₀ ≈ value ? x₀ :
                    y₁ ≈ value ? x₁ :
                    x₀ + (x₁ - x₀) * (isfinite(slope) ? slope : zero(slope))
                break
            end
        end
    else
        spl = make_spline(X, Y; deg_spline)
        knots = Dierckx.get_knots(spl)
        polys = build_polynomials(spl)
        @inbounds for (i, p) in enumerate(polys)
            x₀, x₁ = knots[i], knots[i+1] # spline section endpoints
            # Solve `p(rᵢ) = value` via `p(rᵢ) - value = 0`
            for rᵢ in PolynomialRoots.roots(sub!(p, value))
                if imag(rᵢ) ≈ 0 # real roots only
                    xᵢ = x₀ + real(rᵢ)
                    if x₀ <= xᵢ <= x₁ # filter roots within range
                        x = isnan(x) ? xᵢ : min(x, xᵢ)
                    end
                end
            end
        end
    end
    return x
end

####
#### Legacy spline utils
####
####    These algorithms were changed compared to the original MATLAB version:
####    instead of brute force searching through the splines, numerical methods
####    are performed which are much more efficient and much more accurate.
####    For direct comparison of results with the MATLAB version, the brute force
####    version is implimented and can be used by setting the `legacy` flag.
####

# MATLAB spline optimization performs global optimization by sampling the spline
# fit to data (X, Y) at points X[1]:0.001:X[end], and uses the minimum value.
# This isn't very efficient; instead we use exact spline optimization and return
# the (x,y) pair such that x ∈ X[1]:0.001:X[end] is nearest to the exact optimum
function spline_opt_legacy(spl::Dierckx.Spline1D)
    xopt, yopt = spline_opt(spl)
    knots = Dierckx.get_knots(spl)
    xs = knots[1]:eltype(knots)(0.001):knots[end] # from MATLAB version
    _, i0 = find_nearest(xs, xopt) # find nearest x in xs to xopt

    # Note that the above finds the x value nearest the true minimizer, but we need the x value corresponding to
    # the y value nearest the true minimum. Since we are near the minimum, search for a local minimum.
    (; x, y, i) = local_gridsearch(spl, xs, i0)

    return (; x, y)
end
spline_opt_legacy(X::AbstractVector, Y::AbstractVector; deg_spline = min(3, length(X)-1)) = spline_opt_legacy(make_spline(X, Y; deg_spline))

# Similar to above, but removes the extra trick and instead performs
# exactly what the MATLAB implementation does
function spline_opt_legacy_slow(spl::Dierckx.Spline1D)
    knots = Dierckx.get_knots(spl)
    xs = knots[1]:eltype(knots)(0.001):knots[end] # from MATLAB version
    x, y = xs[1], spl(xs[1])
    for (i, xᵢ) in enumerate(xs)
        (i == 1) && continue
        yᵢ = spl(xᵢ)
        (yᵢ < y) && ((x, y) = (xᵢ, yᵢ))
    end
    return (; x, y)
end
spline_opt_legacy_slow(X::AbstractVector, Y::AbstractVector; deg_spline = min(3, length(X)-1)) = spline_opt_legacy_slow(make_spline(X, Y; deg_spline))

# Brute force root finding through fitting a spline to data (X, Y):
# MATLAB implementation of spline root finding performs root finding by sampling the
# spline fit to data (X, Y) at points X[1]:0.001:X[end], and uses the nearest value.
# This isn't very efficient; instead we use exact spline root finding and return
# the nearest x ∈ X[1]:0.001:X[end] such that the y value is nearest zero
function spline_root_legacy(spl::Dierckx.Spline1D, value = 0)
    # Find x value nearest to the root
    knots = Dierckx.get_knots(spl)
    xs = knots[1]:eltype(knots)(0.001):knots[end] # from MATLAB version
    xroot = spline_root(spl, value)
    _, i0 = find_nearest(xs, xroot) # find nearest x in xs to xroot

    # Note that the above finds the x value nearest the true root, but we need the x value corresponding to the
    # y value nearest to `value`. Since we are near the root, search for a local minimum in abs(spl(x)-value).
    dy(x) = abs(spl(x) - value)
    (; x, y, i) = local_gridsearch(dy, xs, i0)

    return x
end
spline_root_legacy(X::AbstractVector, Y::AbstractVector, value = 0; deg_spline = min(3, length(X)-1)) = spline_root_legacy(make_spline(X, Y; deg_spline), value)

# Similar to above, but removes the extra trick and instead performs
# exactly what the MATLAB implementation does
function spline_root_legacy_slow(spl::Dierckx.Spline1D, value = 0)
    knots = Dierckx.get_knots(spl)
    xs = knots[1]:eltype(knots)(0.001):knots[end] # from MATLAB version
    x, y = xs[1], abs(spl(xs[1]) - value)
    for (i, xᵢ) in enumerate(xs)
        (i == 1) && continue
        yᵢ = abs(spl(xᵢ) - value)
        (yᵢ < y) && ((x, y) = (xᵢ, yᵢ))
    end
    return x
end
spline_root_legacy_slow(X::AbstractVector, Y::AbstractVector, value = 0; deg_spline = min(3, length(X)-1)) = spline_root_legacy_slow(make_spline(X, Y; deg_spline), value)

####
#### Surrogate functions over discrete grids
####

abstract type AbstractSurrogate{D,T} end

gridwidths(surr::AbstractSurrogate) = Tuple(abs.(last(surr.grid) - first(surr.grid)))
gridspacings(surr::AbstractSurrogate) = gridwidths(surr) ./ size(surr.grid)

struct CubicSplineSurrogate{T,F} <: AbstractSurrogate{1,T}
    f::F
    grid::Vector{SVector{1,T}}
    p::Vector{SVector{1,T}}
    u::Vector{T}
    npts::Base.RefValue{Int}
    legacy::Bool
end

function CubicSplineSurrogate(f, grid::Vector{SVector{1,T}}; legacy = false) where {T}
    CubicSplineSurrogate(f, grid, SVector{1,T}[], T[], Ref(0), legacy)
end

function update!(surr::CubicSplineSurrogate, I::CartesianIndex{1})
    p = surr.grid[I]
    pos = surr.npts[] + 1
    @inbounds for i in 1:surr.npts[]
        (p[1] <= surr.p[i][1]) && (pos = i; break)
    end
    u = surr.f(I)
    insertat!(surr.p, pos, p, surr.npts[]+1)
    insertat!(surr.u, pos, u, surr.npts[]+1)
    surr.npts[] += 1
    return surr
end

function insertat!(x::AbstractVector{T}, i, v::T, len = length(x)) where {T}
    if len > length(x)
        append!(x, similar(x, max(length(x), 1)))
    end
    last = v
    @inbounds for j in i:len
        x[j], last = last, x[j]
    end
    return x
end

function Base.empty!(surr::CubicSplineSurrogate)
    surr.npts[] = 0
    return surr
end

function suggest_point(surr::CubicSplineSurrogate{T}) where {T}
    npts = surr.npts[]
    ps = reinterpret(T, view(surr.p, 1:npts))
    us = view(surr.u, 1:npts)
    p, u = surr.legacy ? spline_opt_legacy_slow(ps, us) : spline_opt(ps, us)
    return SVector{1,T}(p), T(u)
end

struct HermiteSplineSurrogate{D,T,F,RK} <: AbstractSurrogate{D,T}
    fg::F
    grid::Array{SVector{D,T},D}
    ugrid::Array{T,D}
    spl::NormalHermiteSplines.ElasticNormalSpline{D,T,RK}
end

function HermiteSplineSurrogate(fg, grid::Array{SVector{D,T},D}, kernel = RK_H1(one(T))) where {D,T}
    spl = NormalHermiteSplines.ElasticNormalSpline(first(grid), last(grid), maximum(size(grid)), kernel)
    HermiteSplineSurrogate(fg, grid, zeros(T, size(grid)), spl)
end

function update!(surr::HermiteSplineSurrogate{D,T}, I::CartesianIndex{D}) where {D,T}
    u, ∇u = surr.fg(I)
    @inbounds p = surr.grid[I]
    insert!(surr.spl, p, u)
    @inbounds for i in 1:D
        eᵢ = basisvector(SVector{D,T}, i)
        insert!(surr.spl, p, eᵢ, ∇u[i])
    end
    return surr
end

function Base.empty!(surr::HermiteSplineSurrogate)
    empty!(surr.spl)
    return surr
end

function suggest_point(surr::HermiteSplineSurrogate{D,T}) where {D,T}
    _, I = findmin(evaluate!(vec(surr.ugrid), surr.spl, vec(surr.grid)))
    @inbounds p = surr.grid[I]
    p, u = local_search(surr, p)
    return p, u
end

# Specialize the 1D case to use the faster and more robust Brent-Dekker method
function suggest_point(surr::HermiteSplineSurrogate{1,T}) where {T}
    u₀, I = findmin(evaluate!(surr.ugrid, surr.spl, surr.grid))
    @inbounds p₀ = surr.grid[I]

    @inbounds if I == 1
        # Grid minimizer is at the left endpoint
        p₁, p₂ = p₀, surr.grid[I+1]
    elseif I == length(surr.ugrid)
        # Grid minimizer is at the right endpoint
        p₁, p₂ = surr.grid[I-1], p₀
    else
        # Check gradient at grid minimizer
        ∇u0 = NormalHermiteSplines.evaluate_gradient(surr.spl, p₀)
        if ∇u0[1] < 0
            p₁, p₂ = p₀, surr.grid[I+1] # negative gradient -> minimum is to the right
        else
            p₁, p₂ = surr.grid[I-1], p₀ # positive gradient -> minimum is to the left
        end
    end

    # Use Brent's method to search for a minimum on the interval (p₁, p₂)
    @inbounds xᵒᵖᵗ, uᵒᵖᵗ = brent(p₁[1], p₂[1]; xrtol = T(1e-4), xtol = T(1e-4), maxiters = 10) do x
        p = SA{T}[x]
        u = NormalHermiteSplines.evaluate(surr.spl, p)
        return u
    end
    pᵒᵖᵗ = SA{T}[xᵒᵖᵗ]

    # Brent's method doesn't evaluate the boundaries of the search interval; check manually
    if u₀ < uᵒᵖᵗ
        pᵒᵖᵗ, uᵒᵖᵗ = p₀, u₀
    end

    return pᵒᵖᵗ, uᵒᵖᵗ
end

####
#### Bounding box for multi-dimensional bisection search
####

struct BoundingBox{D,S,N}
    bounds::NTuple{D,NTuple{2,Int}}
    corners::SArray{S,CartesianIndex{D},D,N}
end
corners(box::BoundingBox) = box.corners
bounds(box::BoundingBox) = box.bounds
widths(box::BoundingBox{D}) where {D} = ntuple(d -> abs(box.bounds[d][2] - box.bounds[d][1]), D)
Base.show(io::IO, ::MIME"text/plain", box::BoundingBox{D}) where {D} = print(io, "$D-D BoundingBox with dimensions: " * join(bounds(box), " × "))

BoundingBox(widths::NTuple{D,Int}) where {D} = BoundingBox(tuple.(1, widths))
BoundingBox(bounds::NTuple{D,NTuple{2,Int}}) where {D} = BoundingBox(bounds, corners(bounds))

@generated function corners(bounds::NTuple{D,NTuple{2,Int}}) where {D}
    corners = Iterators.product([(true, false) for d in 1:D]...)
    S = Tuple{ntuple(d -> 2, D)...}
    vals = [:(CartesianIndex($(ntuple(d -> I[d] ? :(bounds[$d][1]) : :(bounds[$d][2]), D)...))) for I in corners]
    :(Base.@_inline_meta; SArray{$S, CartesianIndex{$D}, $D, $(2^D)}(tuple($(vals...))))
end

function opposite_corner(box::BoundingBox{D}, I::CartesianIndex{D}) where {D}
    @inbounds lo, hi = first(corners(box)), last(corners(box))
    return lo + hi - I
end

function bisect(box::BoundingBox{D}) where {D}
    _, i = findmax(widths(box))
    left_bounds = ntuple(D) do d
        i !== d ? box.bounds[d] : (box.bounds[i][1], (box.bounds[i][1] + box.bounds[i][2]) ÷ 2)
    end
    right_bounds = ntuple(D) do d
        i !== d ? box.bounds[d] : ((box.bounds[i][1] + box.bounds[i][2]) ÷ 2, box.bounds[i][2])
    end
    return BoundingBox(left_bounds), BoundingBox(right_bounds)
end

splittable(box::BoundingBox{D}) where {D} = any(widths(box) .> 1)

####
#### Searching on a discrete grid using a surrogate function
####

struct DiscreteSurrogateSearcher{D, T}
    grid::Array{SVector{D,T},D}
    seen::Array{Bool,D}
    numeval::Base.RefValue{Int}
end
function DiscreteSurrogateSearcher(surr::AbstractSurrogate; mineval::Int, maxeval::Int)
    @assert mineval <= maxeval
    state = DiscreteSurrogateSearcher(surr.grid, fill(false, size(surr.grid)), Ref(0))
    initialize!(surr, state; mineval = mineval, maxeval = maxeval)
end

function initialize!(surr::AbstractSurrogate{D}, state::DiscreteSurrogateSearcher{D}; mineval::Int, maxeval::Int) where {D}
    # Evaluate at least `mineval` points by repeatedly bisecting the grid in a breadth-first manner
    box = BoundingBox(size(state.grid))
    for depth in 1:mineval # should never reach `mineval` depth, this is just to ensure the loop terminates in case `mineval` is greater than the number of gridpoints
        initialize!(surr, state, box, depth; mineval = mineval, maxeval = maxeval)
        state.numeval[] >= mineval && break
    end
    return state
end

function initialize!(surr::AbstractSurrogate{D}, state::DiscreteSurrogateSearcher{D}, box::BoundingBox{D}, depth::Int; mineval::Int, maxeval::Int) where {D}
    depth <= 0 && return state
    evaluate_box!(surr, state, box; maxeval = maxeval)
    state.numeval[] ≥ mineval && return state
    left, right = bisect(box)
    initialize!(surr, state, left, depth-1; mineval = mineval, maxeval = maxeval)
    initialize!(surr, state, right, depth-1; mineval = mineval, maxeval = maxeval)
end

function update!(surr::AbstractSurrogate{D}, state::DiscreteSurrogateSearcher{D}, I::CartesianIndex{D}; maxeval::Int) where {D}
    # Update the surrogate function with a new point, returning whether the maximum number of function evaluations has been reached or not
    state.numeval[] >= maxeval && return true # check if already exceeded number of evals
    @inbounds state.seen[I] && return false # point already evaluated
    update!(surr, I) # update surrogate
    @inbounds state.seen[I] = true # mark as now seen
    @inbounds state.numeval[] += 1 # increment function call counter
    return state.numeval[] >= maxeval
end

####
#### Global optimization using multi-dimensional bisection with surrogate functions
####

function bisection_search(
        surr::AbstractSurrogate{D,T},
        state::DiscreteSurrogateSearcher{D,T};
        maxeval::Int,
    ) where {D,T}

    # Algorithm:
    #   0. Get initial optimum suggestion from surrogate
    #   REPEAT:
    #       1. Find smallest bounding box containing the optimum suggestion
    #       2. Evaluate the box corners
    #       3. Get new optimum suggestion from surrogate:
    #           IF: Box is sufficiently small or if the maximum number of evaluations has been reached:
    #               RETURN: Current optimum
    #           ELSE:
    #               GOTO:   1.
    x, u = suggest_point(surr)
    while true
        box = minimal_bounding_box(state, x)
        evaluate_box!(surr, state, box, x; maxeval = maxeval)
        x, u = suggest_point(surr)
        if state.numeval[] ≥ maxeval || converged(state, box)
            return x, u
        end
    end
end

# Update observed evaluations, returning true if converged
function minimal_bounding_box(
        state::DiscreteSurrogateSearcher{D,T},
        x::SVector{D,T},
    ) where {D,T}

    box = BoundingBox(size(state.grid))
    while true
        left, right = bisect(box)
        if contains(state, left, x) # left box contains `x`
            if !is_evaluated(state, left) || !splittable(left)
                return left # left box not fully evaluated, or we have reached bottom; return
            else
                box = left # whole left box already evaluated; continue search
            end
        else # contains(state, right, x), i.e. right box contains `x`
            if !is_evaluated(state, right) || !splittable(right)
                return right # right box not fully evaluated, or we have reached bottom; return
            else
                box = right # whole right box already evaluated; continue search
            end
        end
    end
end

function evaluate_box!(
        surr::AbstractSurrogate{D,T},
        state::DiscreteSurrogateSearcher{D,T},
        box::BoundingBox{D},
        x::Union{Nothing, SVector{D,T}} = nothing;
        maxeval::Int,
    ) where {D,T}
    cs = x === nothing ? corners(box) : sorted_corners(state, box, x)
    @inbounds for I in cs
        is_evaluated(state, box) && break # box sufficiently evaluated
        update!(surr, state, I; maxeval = maxeval) && break # update surrogate, breaking if max evals reached
    end
    return state
end

function is_evaluated(state::DiscreteSurrogateSearcher{D}, box::BoundingBox{D}) where {D}
    # Box is considered sufficiently evaluated when all of the corners have been evaluted
    count(I -> @inbounds(state.seen[I]), corners(box)) >= 2^D
end

function converged(::DiscreteSurrogateSearcher{D}, box::BoundingBox{D}) where {D}
    # Convergence is defined as: bounding box has at least one side of length <= 1
    any(widths(box) .<= 1)
end

function centre(state::DiscreteSurrogateSearcher{D,T}, box::BoundingBox{D}) where {D,T}
    @inbounds lo = state.grid[first(corners(box))]
    @inbounds hi = state.grid[last(corners(box))]
    (lo + hi)/2
end

function sorted_corners(state::DiscreteSurrogateSearcher{D,T}, box::BoundingBox{D}, x::SVector{D,T}) where {D,T}
    dist²(I) = @inbounds sum(abs2.(state.grid[I] - x))
    cs = corners(box)
    typeof(cs)(TupleTools.sort(Tuple(cs); by = dist²))
end

function contains(state::DiscreteSurrogateSearcher{D,T}, box::BoundingBox{D}, x::SVector{D,T}) where {D,T}
    @inbounds lo = state.grid[first(corners(box))]
    @inbounds hi = state.grid[last(corners(box))]
    all(lo .<= x .<= hi)
end

function is_inside(grid::AbstractArray{SVector{D,T},D}, x::SVector{D,T}) where {D,T}
    @inbounds lo = first(grid)
    @inbounds hi = last(grid)
    all(lo .< x .< hi)
end
is_inside(state::DiscreteSurrogateSearcher{D,T}, x::SVector{D,T}) where {D,T} = is_inside(state.grid, x)

####
#### Local optimization using surrogate functions
####

function local_search(
        surr::HermiteSplineSurrogate{D,T},
        x₀::SVector{D,T},
        state::Union{Nothing, DiscreteSurrogateSearcher{D,T}} = nothing;
        maxiter::Int = 100,
        maxeval::Int = maxiter,
        xtol_rel = 1e-4,
        xtol_abs = 1e-4,
        initial_step = maximum(gridwidths(surr)) / 100,
        xeval_radius = √sum(abs2, gridspacings(surr)) - sqrt(eps(T)),
    ) where {D,T}

    if state !== nothing
        # Initialize surrogate with domain corners
        box = BoundingBox(size(surr.grid))
        for I in corners(box)
            update!(surr, state, I; maxeval = maxeval)
        end
    end

    x, xlast = x₀, x₀
    xlo, xhi = first(surr.grid), last(surr.grid)
    opt = ADAM{D,T}(initial_step)

    for _ in 1:maxiter
        if state !== nothing
            # Find nearest gridpoint to `x` and update surrogate
            I, xI = nearest_gridpoint(state, x)
            dmin = minimum(NormalHermiteSplines._get_nodes(surr.spl)) do p
                norm(xI - NormalHermiteSplines._unnormalize(surr.spl, p))
            end
            if dmin > xeval_radius
                update!(surr, state, I; maxeval = maxeval)
            end
        end

        # Perform gradient descent step using surrogate function
        ∇u = NormalHermiteSplines.evaluate_gradient(surr.spl, x)
        Δx, opt = update(∇u, opt)
        xlast, x = x, @. clamp(x - Δx, xlo, xhi)

        # Check for convergence
        maximum(abs.(x - xlast)) <= max(T(xtol_abs), T(xtol_rel) * maximum(abs.(x))) && break
    end

    u = NormalHermiteSplines.evaluate(surr.spl, x)

    return x, u
end

#=
function local_search(
        surr::HermiteSplineSurrogate{D,T},
        x₀::SVector{D,T};
        maxeval::Int = 100,
        xtol_rel = 1e-4,
        xtol_abs = 1e-4,
    ) where {D,T}

    # alg = :LN_COBYLA # local, gradient-free, linear approximation of objective
    # alg = :LN_BOBYQA # local, gradient-free, quadratic approximation of objective
    # alg = :LD_SLSQP # local, with-gradient, "Sequential Least-Squares Quadratic Programming"; uses dense-matrix methods (ordinary BFGS, not low-storage BFGS)
    alg = :LD_LBFGS # local, with-gradient, low-storage BFGS

    opt = NLopt.Opt(alg, D)
    opt.lower_bounds = Vector{Float64}(first(surr.grid))
    opt.upper_bounds = Vector{Float64}(last(surr.grid))
    opt.xtol_rel = xtol_rel
    opt.xtol_abs = xtol_abs
    opt.maxeval = maxeval
    opt.min_objective = function (x, g)
        x⃗ = SVector{D,T}(ntuple(d -> @inbounds(x[d]), D))
        @inbounds if length(g) > 0
            g .= Float64.(NormalHermiteSplines.evaluate_gradient(surr.spl, x⃗))
        end
        return Float64(NormalHermiteSplines.evaluate(spl, x⃗))
    end
    minf, minx, ret = NLopt.optimize(opt, Vector{Float64}(x₀))

    x = SVector{D,T}(ntuple(d -> @inbounds(minx[d]), D))
    u = T(minf)

    return x, u
end
=#

function nearest_gridpoint(grid::AbstractArray{SVector{D,T},D}, x::SVector{D,T}) where {D,T}
    @inbounds xlo, xhi = first(grid), last(grid)
    @inbounds Ilo, Ihi = first(CartesianIndices(grid)), last(CartesianIndices(grid))
    lo, hi = SVector(Tuple(Ilo)), SVector(Tuple(Ihi))
    i = @. clamp(round(Int, (x - xlo) * (hi - lo) / (xhi - xlo) + lo), lo, hi)
    I = CartesianIndex(Tuple(i))
    xI = @inbounds grid[I]
    return I, xI
end
nearest_gridpoint(state::DiscreteSurrogateSearcher{D,T}, x::SVector{D,T}) where {D,T} = nearest_gridpoint(state.grid, x)

function nearest_interior_gridpoint(grid::AbstractArray{SVector{D,T},D}, x::SVector{D,T}) where {D,T}
    R = CartesianIndices(grid)
    One = CartesianIndex(ntuple(d -> 1, D))
    Ilo, Ihi = first(R) + One, last(R) - One
    return nearest_gridpoint(@views(grid[Ilo:Ihi]), x)
end
nearest_interior_gridpoint(state::DiscreteSurrogateSearcher{D,T}, x::SVector{D,T}) where {D,T} = nearest_interior_gridpoint(state.grid, x)

####
#### Global optimization for NNLS problem
####

struct NNLSDiscreteSurrogateSearch{D, T, TA <: AbstractArray{T}, TdA <: AbstractArray{T}, Tb <: AbstractVector{T}, W}
    As::TA
    ∇As::TdA
    αs::Array{SVector{D,T},D}
    b::Tb
    u::Array{T,D}
    ∂Ax⁺::Vector{T}
    Ax⁺b::Vector{T}
    nnls_work::W
    legacy::Bool
end

function NNLSDiscreteSurrogateSearch(
        As::AbstractArray{T},  # size(As)  = (M, N, P1..., PD)
        ∇As::AbstractArray{T}, # size(∇As) = (M, N, D, P1..., PD)
        αs::NTuple{D},         # size(αs)  = (P1..., PD)
        b::AbstractVector{T};  # size(b)   = (M,)
        legacy::Bool = false,
    ) where {D,T}
    M, N = size(As, 1), size(As, 2)
    @assert ndims(As) == 2 + D && ndims(∇As) == 3 + D # ∇As has extra dimension for parameter gradients
    @assert size(∇As)[1:3] == (M, N, D) # matrix dimensions must match, and gradient dimension must equal number of parameters
    @assert size(As)[3:end] == size(∇As)[4:end] == length.(αs) # dimension size must match parameters lengths
    @assert size(b) == (M,)

    αs   = meshgrid(SVector{D,T}, αs...)
    u    = zeros(T, size(αs))
    ∂Ax⁺ = zeros(T, M)
    Ax⁺b = zeros(T, M)
    nnls_work = lsqnonneg_work(zeros(T, M, N), zeros(T, M))
    NNLSDiscreteSurrogateSearch(As, ∇As, αs, b, u, ∂Ax⁺, Ax⁺b, nnls_work, legacy)
end

load!(prob::NNLSDiscreteSurrogateSearch{D,T}, b::AbstractVector{T}) where {D,T} = copyto!(prob.b, b)

function loss!(prob::NNLSDiscreteSurrogateSearch{D,T}, I::CartesianIndex{D}) where {D,T}
    (; As, b, nnls_work) = prob
    solve!(nnls_work, uview(As, :, :, I), b)
    ℓ = chi2(nnls_work)
    u = prob.legacy ? ℓ : log(max(ℓ, eps(T))) # loss capped at eps(T) from below to avoid log(0) error
    return u
end

function ∇loss!(prob::NNLSDiscreteSurrogateSearch{D,T}, I::CartesianIndex{D}) where {D,T}
    (; As, ∇As, b, ∂Ax⁺, Ax⁺b, nnls_work) = prob
    ℓ = chi2(nnls_work)
    ℓ <= eps(T) && return zero(SVector{D,T}) # loss capped at eps(T) from below; return zero gradient
    x = solution(nnls_work)
    @inbounds @. Ax⁺b = -b
    @inbounds for j in 1:size(As, 2)
        (x[j] > 0) && axpy!(x[j], uview(As, :, j, I), Ax⁺b)
    end
    ∇u = ntuple(D) do d
        @inbounds ∂Ax⁺ .= zero(T)
        @inbounds for j in 1:size(∇As, 2)
            (x[j] > 0) && axpy!(x[j], uview(∇As, :, j, d, I), ∂Ax⁺)
        end
        ∂ℓ = 2 * dot(∂Ax⁺, Ax⁺b)
        ∂u = prob.legacy ? ∂ℓ : ∂ℓ / ℓ
        return ∂u
    end
    return SVector{D,T}(∇u)
end

function CubicSplineSurrogate(prehook!, prob::NNLSDiscreteSurrogateSearch{1,T}; legacy = false) where {T}
    function f(I)
        prehook!(I)
        loss!(prob, I)
    end
    CubicSplineSurrogate(f, prob.αs, SVector{1,T}[], T[], Ref(0), legacy)
end
CubicSplineSurrogate(prob::NNLSDiscreteSurrogateSearch; kwargs...) = CubicSplineSurrogate(I -> nothing, prob; kwargs...)

function HermiteSplineSurrogate(prehook!, prob::NNLSDiscreteSurrogateSearch{D,T}) where {D,T}
    function fg(I)
        prehook!(I)
        u = loss!(prob, I)
        ∇u = ∇loss!(prob, I)
        return u, ∇u
    end
    return HermiteSplineSurrogate(fg, prob.αs, RK_H1(one(T)))
end
HermiteSplineSurrogate(prob::NNLSDiscreteSurrogateSearch) = HermiteSplineSurrogate(I -> nothing, prob)

function surrogate_spline_opt(
        prob::NNLSDiscreteSurrogateSearch{D},
        surr::AbstractSurrogate{D};
        mineval::Int = min(2^D, length(prob.αs)),
        maxeval::Int = length(prob.αs),
    ) where {D}
    state = DiscreteSurrogateSearcher(surr; mineval = mineval, maxeval = maxeval)
    bisection_search(surr, state; maxeval = maxeval)
end

function spline_opt(
        spl::NormalSpline{D,T},
        prob::NNLSDiscreteSurrogateSearch{D,T};
        # alg = :LN_COBYLA,        # local, gradient-free, linear approximation of objective
        # alg = :LN_BOBYQA,        # local, gradient-free, quadratic approximation of objective
        # alg = :GN_ORIG_DIRECT_L, # global, gradient-free, systematically divides search space into smaller hyper-rectangles via a branch-and-bound technique, systematic division of the search domain into smaller and smaller hyperrectangles, "more biased towards local search"
        # alg = :GN_AGS,           # global, gradient-free, employs the Hilbert curve to reduce the source problem to the univariate one.
        # alg = :GD_STOGO,         # global, with-gradient, systematically divides search space into smaller hyper-rectangles via a branch-and-bound technique, and searching them by a gradient-based local-search algorithm (a BFGS variant)
        alg = :LD_SLSQP,         # local, with-gradient, "Sequential Least-Squares Quadratic Programming"; uses dense-matrix methods (ordinary BFGS, not low-storage BFGS)
    ) where {D,T}

    evaluate!(prob.u, spl, prob.αs)
    _, i = findmin(prob.u)
    α₀ = prob.αs[i]

    opt = NLopt.Opt(alg, D)
    opt.lower_bounds = Float64[prob.αs[begin]...]
    opt.upper_bounds = Float64[prob.αs[end]...]
    opt.xtol_rel = 0.001
    opt.min_objective = function (x, g)
        if length(g) > 0
            @inbounds g[1] = Float64(evaluate_derivative(spl, x[1]))
        end
        @inbounds Float64(evaluate(spl, x[1]))
    end
    minf, minx, ret = NLopt.optimize(opt, Vector{Float64}(α₀))
    x, f = SVector{D,T}(minx), T(minf)
    return x, f
end

function mock_surrogate_search_problem(
        b::AbstractVector{T},
        opts::T2mapOptions{T},
        ::Val{D},
        ::Val{ETL};
        alphas = range(50, 180, length = opts.nRefAngles),
        betas = range(50, 180, length = opts.nRefAngles),
    ) where {D, T, ETL}

    # Mock CPMG image
    @assert opts.nTE == ETL
    opt_vars = D == 1 ? (:α,) : (:α, :β)
    opt_ranges = D == 1 ? (alphas,) : (alphas, betas)
    As = zeros(T, ETL, opts.nT2, length.(opt_ranges)...)
    ∇As = zeros(T, ETL, opts.nT2, D, length.(opt_ranges)...)
    T2s = logrange(opts.T2Range..., opts.nT2)
    θ = EPGOptions((; α = T(165.0), TE = opts.TE, T2 = zero(T), T1 = opts.T1, β = T(180.0)), Val(ETL), T)
    j! = EPGJacobianFunctor(θ, opt_vars)

    _, Rαs = SplitCartesianIndices(As, Val(2))
    for Iαs in Rαs
        @inbounds for j in 1:opts.nT2
            θαs = D == 1 ?
                restructure(θ, (T2 = T2s[j], α = alphas[Iαs[1]],)) :
                restructure(θ, (T2 = T2s[j], α = alphas[Iαs[1]], β = alphas[Iαs[2]]))
            j!(uview(∇As, :, j, :, Iαs), uview(As, :, j, Iαs), θαs)
        end
    end

    return NNLSDiscreteSurrogateSearch(As, ∇As, opt_ranges, b)
end
function mock_surrogate_search_problem(::Val{D}, ::Val{ETL}, opts = mock_t2map_opts(; MatrixSize = (1, 1, 1), nTE = ETL); kwargs...) where {D,ETL}
    b = vec(mock_image(opts))
    mock_surrogate_search_problem(b, opts, Val(D), Val(ETL); kwargs...)
end
function mock_surrogate_search_problem(b::AbstractVector, opts::T2mapOptions, ::Val{D}; kwargs...) where {D}
    @assert length(b) == opts.nTE
    mock_surrogate_search_problem(b, opts, Val(D), Val(length(b)); kwargs...)
end
