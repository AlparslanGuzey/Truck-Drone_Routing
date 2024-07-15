module DroneAssignment

using JuMP
using HiGHS

export assign_drones

function assign_drones(c, U, drh, drs, ds, tas, w_max, CUAV, CUGV)
    V = zeros(Int, tas, ds)
    sure_d = zeros(Float64, ds)

    for dngd in 1:ds
        global dng
        dng = dngd

        model = Model(HiGHS.Optimizer)

        @variable(model, D[1:c[dng], 1:drs], Bin)
        @variable(model, SE[1:c[dng], 1:drs])
        @variable(model, SD[1:drs])
        @variable(model, SDM)
        @variable(model, M_loc[1:c[dng], 1:drs], Bin)
        @variable(model, B[1:drs, 1:w_max], Bin)

        @objective(model, Min, SDM)

        # Ensure each gathering point is assigned to exactly one drone
        for i in 1:c[dng]
            @constraint(model, sum(D[i, k] for k in 1:drs) == 1)
        end

        # Ensure flight time constraints are within limits
        for i in 1:c[dng]
            for k in 1:drs
                @constraint(model, 2.5 * U[i, dng] * D[i, k] <= 60)
            end
        end

        # Define SE based on U and D
        for i in 1:c[dng]
            for k in 1:drs
                @constraint(model, SE[i, k] == 2.5 * U[i, dng] * D[i, k])
            end
        end

        # Total flight times
        for k in 1:drs
            @constraint(model, sum(2 * U[i, dng] * D[i, k] + SE[i, k] for i in 1:c[dng]) == SD[k])
        end

        # Ensure SD[k] <= SDM
        for k in 1:drs
            @constraint(model, SD[k] <= SDM)
        end

        # UAV medical kit capacity
        for q in 1:drs
            @constraint(model, sum(M_loc[p, q] for p in 1:c[dng]) <= CUAV)
        end

        # UGV medical kit capacity
        @constraint(model, sum(M_loc[p, q] for p in 1:c[dng], q in 1:drs) <= CUGV)

        # Battery replacement count
        @constraint(model, sum(B[q, w] for q in 1:drs, w in 1:w_max) <= w_max)

        # UAVs fly from UGV stops
        for p in 1:c[dng], q in 1:drs
            @constraint(model, M_loc[p, q] <= V[p, q])
        end

        JuMP.optimize!(model)

        sure_d[dng] = JuMP.objective_value(model)
        println("$dng. Durakta Harcanan Süre = ", round(sure_d[dng]; digits=2))

        for i in 1:c[dng]
            for j in 1:drs
                if value(D[i, j]) > 0.5
                    V[i, dng] = j
                end
            end
        end
    end

    return V, sure_d
end

end
