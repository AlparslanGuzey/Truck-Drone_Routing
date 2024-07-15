module TSPSolver

using TravelingSalesmanHeuristics

export solve_tsp_problem

function solve_tsp_problem(duraklar, ds, drh)
    distmat = [norm(duraklar[:, i] - duraklar[:, j]) for i in 1:ds + 1, j in 1:ds + 1]

    @time path, cost = solve_tsp(distmat; quality_factor = 100)
    kths = cost / drh

    return path, kths
end

end
