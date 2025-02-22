include("half_plane_fast.jl")
include("half_plane_bounded.jl")
include("move_gradient_file.jl")
include("draw_circle_part.jl")
include("global_vars.jl")


###Given a position and neighbouring positions, give the uncircled, unbounded cell
function give_cell(pos::Tuple{Float64, Float64}, neighbour_positions::Vector{Tuple{Tuple{Float64, Float64}, Int64}}, model, vel::Tuple{Float64, Float64} = (0.0, 0.0), relic_half_plane::Tuple{Float64, Tuple{Float64, Float64}, Tuple{Float64, Float64}, Int64} = (0.0, (0.0, 0.0), (0.0, 0.0), 0); rhop = rho)
	temp_hp::Vector{Tuple{Float64, Tuple{Float64, Float64}, Tuple{Float64, Float64}, Int64}} = []
	new_cell_i::Vector{Tuple{Tuple{Float64, Float64}, Int64, Int64}} = voronoi_cell(model, pos, neighbour_positions, rhop, eps, inf, temp_hp)
        #new_area::Float64 = voronoi_area(model, ri, new_cell_i, rho)
        #print("Now calculating the voronoi area for agent $(agent_i.id), which was $new_area\n")
        return new_cell_i
end

function give_cell_forward(pos::Tuple{Float64, Float64}, neighbour_positions::Vector{Tuple{Tuple{Float64, Float64}, Int64}}, model, vel::Tuple{Float64, Float64} = (0.0, 0.0), relic_half_plane_arg::Tuple{Float64, Tuple{Float64, Float64}, Tuple{Float64, Float64}, Int64} = (0.0, (0.0, 0.0), (0.0, 0.0), 0); rhop = rho, relic_passed = 0)
        temp_hp::Vector{Tuple{Float64, Tuple{Float64, Float64}, Tuple{Float64, Float64}, Int64}} = []
	
	ri::Tuple{Float64, Float64} = pos
	relic_half_plane::Tuple{Float64, Tuple{Float64, Float64}, Tuple{Float64, Float64}, Int64} = relic_half_plane_arg
	if(relic_passed == 0)
                vix::Float64 = vel[1]
                viy::Float64 = vel[2]
                relic_x::Float64 = -1.0*(-viy)
                relic_y::Float64 = -vix
                relic_pq::Tuple{Float64, Float64} = (relic_x, relic_y)
                relic_angle::Float64 = atan(relic_y, relic_x)
                relic_is_box::Int64 = 2
                relic_half_plane = (relic_angle, relic_pq, pos, relic_is_box)
	end

                new_cell_i::Vector{Tuple{Tuple{Float64, Float64}, Int64, Int64}} = voronoi_cell_bounded(model, ri, neighbour_positions, rhop, eps, inf, temp_hp, vel, [relic_half_plane])

        #new_area::Float64 = voronoi_area(model, ri, new_cell_i, rho)
        #print("Now calculating the voronoi area for agent $(agent_i.id), which was $new_area\n")
        return new_cell_i
end


###Given a cell, circle it so that plot functions can draw the circle part 
function give_cell_circled(cell, pos; rhop = rho, show_calcs = 0)
        cell_including_circle = []
        new_cell_i = cell
		if(show_calcs == 1)
			for point in new_cell_i 
                print("$point\n")
			end
		end
        print("Starting\n")
                if(length(cell) <=  1)
			circle_points = circle_seg(pos, rhop, 0.0, 2*pi)
                        for j in 1:length(circle_points[1])
                                 push!(cell_including_circle, ((circle_points[1][j], circle_points[2][j]), 0, 0))
                        end

		end
		for i in 1:length(new_cell_i)
                        point = new_cell_i[i]
                        point_pp = new_cell_i[(i)%length(new_cell_i)+1]
                        push!(cell_including_circle, point)
                        #print("$(point[3]) $(point_pp[2])\n")
                        if(point[3] == 0 && point_pp[2] == 0)
                                print("State helper.jl here. Circle confirmed\n")
                                vec_to_point = point[1] .- pos
                                vec_to_pointpp = point_pp[1] .- pos
                                theta_1 = atan(vec_to_point[2], vec_to_point[1])
                                theta_2 = atan(vec_to_pointpp[2], vec_to_pointpp[1])
                                if(theta_2 < theta_1)
                                        theta_2 += 2*pi
                                end
                                circle_points = circle_seg(pos, rhop, theta_1, theta_2)
                                for j in 1:length(circle_points[1])
                                        push!(cell_including_circle, ((circle_points[1][j], circle_points[2][j]), 0, 0))
                                end
                        end
                end
                return cell_including_circle
end


##Function that takes an agent, and given the model, gives the cell of that agent under that configuration
function give_agent_cell(agent_i::bird, model; rhop = rho)
        all_agents_iterable =  allagents(model)
        temp_hp::Vector{Tuple{Float64, Tuple{Float64, Float64}, Tuple{Float64, Float64}, Int64}} = []
        previous_areas::Vector{Float64} = zeros(nagents(model))
        actual_areas::Vector{Float64} = zeros(nagents(model))

                neighbour_positions::Vector{Tuple{Tuple{Float64, Float64}, Int64}} = []
                for agent_j in all_agents_iterable
                        if(agent_i.id == agent_j.id)
                                continue
                        end
                        push!(neighbour_positions, (agent_j.pos, agent_j.id))
                end
                ri::Tuple{Float64, Float64} = agent_i.pos
                vix::Float64 = agent_i.vel[1]
                viy::Float64 = agent_i.vel[2]
                relic_x::Float64 = -1.0*(-viy)
                relic_y::Float64 = -vix
                relic_pq::Tuple{Float64, Float64} = (relic_x, relic_y)
                relic_angle::Float64 = atan(relic_y, relic_x)
                relic_is_box::Int64 = 2
                relic_half_plane::Tuple{Float64, Tuple{Float64, Float64}, Tuple{Float64, Float64}, Int64} = (relic_angle, relic_pq, agent_i.pos, relic_is_box)

                new_cell_i::Vector{Tuple{Tuple{Float64, Float64}, Int64, Int64}} = voronoi_cell(model, ri, neighbour_positions, rhop, eps, inf, temp_hp, agent_i.vel, [relic_half_plane])

                ##Procedure for adding the
                #print("Starting\n")
                
		return new_cell_i
end


###Given an agent and the current model state, give the cell of the agent with intermediate circle points added. 
function give_agent_cell_circled(agent_i, model; rhop = rho)
        all_agents_iterable =  allagents(model)
        temp_hp::Vector{Tuple{Float64, Tuple{Float64, Float64}, Tuple{Float64, Float64}, Int64}} = []

                neighbour_positions::Vector{Tuple{Tuple{Float64, Float64}, Int64}} = []
                for agent_j in all_agents_iterable
                        if(agent_i.id == agent_j.id)
                                continue
                        end
                        push!(neighbour_positions, (agent_j.pos, agent_j.id))
                end

                uncircled_cell = give_cell(agent_i.pos, neighbour_positions, model; rhop = rhop)
                circle_bounded_cell = give_cell_circled(uncircled_cell, agent_i.pos)
                return circle_bounded_cell
end

function give_cell_forward_quick(id::Int64, model; rhop = rho)
	neighbour_positions::Vector{Tuple{Tuple{Float64, Float64}, Int64}} = Vector{Tuple{Tuple{Float64, Float64}, Int64}}(undef, 0)
	
	for i in 1:nagents(model)
		if(i == id) continue end
		push!(neighbour_positions, (model[i].pos, i))
	end
	return give_cell_forward(model[id].pos, neighbour_positions, model, model[id].vel; rhop = rhop)
end

###Function that calculates the potential cell for agent id at a potential position of pos given the state of the current model, and also limiting the view of the agent's current heading to a total of angle
function give_potential_cell_angled(id::Int64, model, pos::Tuple{Float64, Float64}; angle = pi)
	neighbour_positions::Vector{Tuple{Tuple{Float64, Float64}, Int64}} = Vector{Tuple{Tuple{Float64, Float64}, Int64}}(undef, 0)
	for i in 1:nagents(model)
        if(i == id) continue end
        push!(neighbour_positions, (model[i].pos, i))
    end

	left_half_plane = generate_relic_alt(model[id].pos, rotate_vector(angle/2, model[id].vel), pi)
    right_half_plane = generate_relic_alt(model[id].pos, rotate_vector(-angle/2, model[id].vel))

	temp_hp::Vector{Tuple{Float64, Tuple{Float64, Float64}, Tuple{Float64, Float64}, Int64}} = Vector{Tuple{Float64, Tuple{Float64, Float64}, Tuple{Float64, Float64}, Int64}}(undef, 0)

	sampled_cell = voronoi_cell_bounded(model, pos, neighbour_positions, rho, eps, inf, temp_hp, model[id].vel, [left_half_plane, right_half_plane])
	return sampled_cell
end

function give_potential_cell_angled_direction(id::Int64, model; angle = pi, m = 1, q = 8, qp = 1)
	return give_potential_cell_angled(id, model, model[id].pos .+ m .* rotate_vector(qp*2*pi/q, model[id].vel), angle=angle)
end
