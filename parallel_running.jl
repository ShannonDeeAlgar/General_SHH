parameters = Dict(
        :simulation_number_arg => [i for i::Int64 in 1:no_simulations],
        :target_area_arg => target_dods,
        #:left_bias_arg => left_biases
) 

#= Original program runner.
model = initialise(target_area_arg = 1000.0*sqrt(12), simulation_number_arg = 1, no_bird = no_birds)
adf, mdf = @time run!(model, agent_step!, model_step!, no_steps; adata, mdata)
=#

###New thingo for running, just because there's never reason you wouldn't use this general method of running possibly multiple params
adf, mdf  = paramscan(parameters, initialise; adata, mdata, agent_step!, model_step!, n = no_steps, parallel = true)

