using DataFrames
using Random
using Clustering
using Distances
using HiGHS
using JuMP
using TravelingSalesmanHeuristics
using XLSX
using Gadfly
using LinearAlgebra

include("constants.jl")
include("data_preparation.jl")
include("kmeans_clustering.jl")
include("drone_assignment.jl")
include("tsp_solver.jl")
include("results.jl")
include("plotting.jl")

using .Constants
using .DataPreparation
using .KMeansClustering
using .DroneAssignment
using .TSPSolver
using .Results
using .Plotting

# Prepare data
X, kx, ky, kz = prepare_data(Constants.tas)

# Perform K-means clustering
ds, R, as, c, M, T, U, DEUE = perform_kmeans(X, Constants.tas, Constants.drh, Constants.dbus, Constants.ddus)

println("Süre Cinsinden Menzil = ", round((Constants.dbus / (1 + (Constants.dbus / Constants.ddus))); digits=2))
println("En Küçük Durak Sayısı = ", ds)

for i in 1:ds
    DEUE[i] = maximum(U[:, i])
    println("$i. Duraktaki Toplanma Alanı Sayısı = ", c[i])
    println("$i. Durağa En Uzak Toplanma Alanının Mesafesi(süre cinsinden) = ", round(DEUE[i]; digits=2))
end

# Drone assignment
V, sure_d = assign_drones(c, U, Constants.drh, Constants.drs, ds, Constants.tas, Constants.w_max, Constants.CUAV, Constants.CUGV)

# TSP Solver
duraklar = zeros(Float64, 2, ds + 1)
duraklar[1, 1] = 900
duraklar[2, 1] = 2300
for i in 1:ds
    duraklar[1, i + 1] = M[1, i]
    duraklar[2, i + 1] = M[2, i]
end

path, kths = solve_tsp_problem(duraklar, ds, Constants.drh)

println("Kara Taşıtının Harcadığı Süre = ", round(kths; digits=2))

sure = sum(sure_d[:]) + kths

println("Toplam Harcanan Süre = ", round(sure; digits=2))

# Save results
filename = "results/Results.xlsx"
save_results(filename, Constants.tas, X, as, ds, T, V, U, c, DEUE, sure_d, sure, kths)

# Plotting
df = DataFrame(X=kx, Y=ky, K1=as)
plot_results(df, duraklar, path, ds)
