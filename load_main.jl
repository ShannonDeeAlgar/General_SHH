###Introduction
#Hello, this is the file that defines all of the main data structures and functions for simulating our program. If you want to actually run the program, use the program.jl file instead. Run using "julia program.jl".

###Preliminaries
#using Agents
include("agent_definition.jl")
using Random
using VoronoiCells
using GeometryBasics
using Plots
using InteractiveDynamics
using CairoMakie # choosing a plotting backend
using ColorSchemes
import ColorSchemes.balance
print("Packages loaded\n")

include("half_plane_fast.jl")
include("half_plane_bounded.jl")
include("convex_hull.jl")
include("rot_ord.jl")
include("rot_ord_check.jl")
include("init_pos.jl")
print("All homemade files included\n")
print("Hello\n")
include("global_vars.jl")

tracked_agent::Int64 = rand(1:no_birds)
tracked_path::Vector{Tuple{Float64, Float64}} = []
rect = Rectangle(Point2(0,0), Point2(Int64(rect_bound), Int64(rect_bound)))

###Function that takes a vector and calculates the mean of the elements in the vector
function mean(v)
	total = 0.0
	for i in 1:length(v)
		total += v[i]
	end
	
	return total/length(v)
end

include("voronoi_area_file.jl")
include("move_gradient_file.jl")

print("Agent template created\n")



###Create the initialisation function
using Random #for reproducibility
function initialise(pos_vels_file, step; target_area_arg = 1000*sqrt(12), simulation_number_arg = 1, no_bird = 100, seed = 123, tracked_agent_arg = 42, no_moves_arg = 100)
	#Create the space
	space = ContinuousSpace((rect_bound, rect_bound); periodic = true)
	#Create the properties of the model
	properties = Dict(:t => 0.0, :dt => 1.0, :n => step, :CHA => 0.0, :target_area => target_area_arg, :simulation_number => simulation_number_arg, :tracked_agent => tracked_agent_arg, :no_moves => no_moves_arg)
	
	#Create the rng
	rng = Random.MersenneTwister(seed)
	
	print("Before model\n")

	#Create the model
	model = UnremovableABM(
		bird, space; 
		properties, rng, scheduler = Schedulers.fastest
	)	


	#Generate random initial positions for each bird, then calculate the DoDs
	initial_positions::Vector{Tuple{Float64, Float64}} = []
	initial_vels::Vector{Tuple{Float64, Float64}} = []
	temp_hp::Vector{Tuple{Float64, Tuple{Float64, Float64}, Tuple{Float64, Float64}, Int64}}= []
	pack_positions = Vector{Point2{Float64}}(undef, no_birds)
	
	

	#Initialise the positions based on the spawn-error free function of assign_positions
	assign_pos_vels(pos_vels_file, initial_positions, initial_vels, step, no_birds) 
	print("The length of initial positions is $(length(initial_positions))\n")
	for i in 1:no_bird

		pack_positions[i] = initial_positions[i]
		print("Pack positions i is $(pack_positions[i])\n")
		if(i == tracked_agent)
			push!(tracked_path, initial_positions[i])
		end
	end 

	#Calculate the DOD based off the initial positions
	init_tess = voronoicells(pack_positions, rect)
	init_tess_areas = voronoiarea(init_tess)

	#Calculate the DoDs based off the initial positions
	#initial_dods = voronoi_area(model, initial_positions, rho)
	initial_dods::Vector{Float64} = []
	true_initial_dods::Vector{Float64} = []
	for i::Int32 in 1:no_birds
		print("\n\nCalculatin initial DOD for agent $i, at position $(initial_positions[i]).")
		ri::Tuple{Float64, Float64}  = Tuple(initial_positions[i])
		neighbouring_positions = Vector{Tuple{Tuple{Float64, Float64}, Int64}}(undef, 0)
		for j::Int32 in 1:no_birds
			if(i == j)
				continue 
			end
			push!(neighbouring_positions, (Tuple(initial_positions[j]), j))
		end
		vix::Float64 = initial_vels[i][1]
		viy::Float64 = initial_vels[i][2]
		relic_x::Float64 = -1.0*(-viy)
        	relic_y::Float64 = -vix
        	relic_pq::Tuple{Float64, Float64} = (relic_x, relic_y)
        	relic_angle::Float64 = atan(relic_y, relic_x)
        	relic_is_box::Int64 = -1
        	relic_half_plane::Tuple{Float64, Tuple{Float64, Float64}, Tuple{Float64, Float64}, Int64} = (relic_angle, relic_pq, ri, relic_is_box)

		initial_cell::Vector{Tuple{Tuple{Float64, Float64}, Int64, Int64}} = @time voronoi_cell_bounded(model, ri, neighbouring_positions, rho, eps, inf, temp_hp, initial_vels[i], [relic_half_plane])
		initial_A::Float64 = voronoi_area(model, ri, initial_cell, rho) 
	
		true_initial_cell::Vector{Tuple{Tuple{Float64, Float64}, Int64, Int64}} = @time voronoi_cell(model, ri, neighbouring_positions, rho,eps, inf, temp_hp, initial_vels[i])
                true_initial_A::Float64 = voronoi_area(model, ri, true_initial_cell, rho)

		#=print("The half planes that generated the cell for agent $i were \n")
                        for i in 1:length(temp_hp)
                                print("$(temp_hp[i])\n")
                        end
		=#
		#What is this? last_half_planes[i], (initial_cell, temp_hp, ri)
			
		print("Initial DOD calculated to be $initial_A\n")
		if(abs(initial_A) > pi*rho^2/2)
			print("Main file here. Conventional area exceeded by agent $(i)in position $(initial_positions[i])\n")	
			print("The cell was \n")
			for i in 1:length(initial_cell)
				print("$(initial_cell[i])\n")
			end
			print("The half planes that generated it were \n")
			for i in 1:length(temp_hp)
				print("$(temp_hp[i])\n")
			end
			exit()
		elseif initial_A < eps
			print("Effective area of 0. The cell was comprised of vertices $(initial_cell)\n")
			
			area_zero[i] = 1
		end
		if(abs(initial_A-init_tess_areas[i]) > eps)
			print("Difference in area calculated between our code and the voronoi package. Our code calculated $initial_A, theirs $(init_tess_areas[i])\n")
		end
		push!(initial_dods, initial_A)
		push!(true_initial_dods, true_initial_A)
			
		#print("The initial half planes for agent $(i) is \n")
		#print("$(last_half_planes[i][2])\n")

		#print("The initial vertices for agent $i is \n")
		#print("$(last_half_planes[i][1])\n")
 

	end
	#Now make the agents with their respective DoDs and add to the model
	total_area::Float64 = 0.0
	total_speed::Float64 = 0.0
	for i::Int32 in 1:no_birds
		agent = bird(i, initial_positions[i], initial_vels[i], 1.0, initial_dods[i], true_initial_dods[i], target_area_arg, initial_dods[i]/target_area_arg, 0)
		agent.vel = agent.vel ./ norm(agent.vel)
		#print("Initial velocity of $(agent.vel) \n")
		add_agent!(agent, initial_positions[i], model)
		total_area += true_initial_dods[i]/(pi*rho^2)
		total_speed += agent.speed
	end	

	#Calculate the actual area of the convex hull of the group of birds
	convexhullbro = update_convex_hull(model)
	initial_convex_hull_area::Float64 = voronoi_area(model, -1, convexhullbro, rho)
	model.CHA = initial_convex_hull_area
	packing_fraction = nagents(model)*pi*1^2/model.CHA
	init_rot_ord::Float64 = rot_ord(allagents(model))
	init_rot_ord_alt::Float64 = rot_ord_alt(allagents(model))
	print("Packing fraction at n = 0 is $(packing_fraction)\n")
	write(compac_frac_file, "$packing_fraction ")
	average_area::Float64 = total_area / nagents(model)
        write(mean_a_file, "$average_area ")
	average_speed::Float64 = total_speed/no_birds
	write(mean_speed_file, "$average_speed ")
	write(rot_o_file, "$init_rot_ord ")
	write(rot_o_alt_file, "$init_rot_ord_alt ")
	print("Initialisation complete. \n\n\n")
	global initialised = 1
	

	###Plotting
	print("About to start figure thing\n")
	previous_areas::Vector{Float64} = zeros(nagents(model))
        actual_areas::Vector{Float64} = zeros(nagents(model))
        delta_max = max(abs(model.target_area - 0), abs(model.target_area-pi*rho^2/2))
        draw_figures(model, actual_areas, previous_areas, delta_max, initial_positions, tracked_path)
        print("Finished initial figure\n")

	
	return model
end  



###Create the agent step function. This will call upon the force or acceleration function. I'm assuming that this function will be applied to each agent in turn
function agent_step!(agent, model)		
	#Update the agent position and velocities, but only if it is a 
	#print("Step!\n", agent.planet)
	dt::Float64 = model.dt
	k1::Vector{Float64} = [0.0, 0.0, 0.0, 0.0]
	target_area::Float64 = model.target_area	

        #Now, why have we separated the position and velocity as two different vectors unlike PHYS4070? Because the pos is intrinsically a 2D vector for Julia Agents.
        move_made_main::Int32 = move_gradient(agent, model, k1, 8, 100, rho, target_area)
	no_move[Int64(agent.id)] = move_made_main
	
	#Update the agent position and velocity
	new_agent_pos::Tuple{Float64, Float64} = Tuple(agent.pos .+ dt .* k1[1:2])
        new_agent_vel::Tuple{Float64, Float64} = Tuple(k1[1:2]) #So note that we're not doing incremental additions to the old velocity anymore, and that's because under Shannon's model, the velocity is just set automatically to whatever is needed to go to a better place. 
	change_in_position::Tuple{Float64, Float64} = new_agent_pos .- (agent.pos)
	if(move_made_main==1)
		agent.vel = new_agent_vel
		#agent.speed = 1.0
	else 
		#print("No movement made, agent area was $(agent.A)\n")
		agent.vel = new_agent_vel
		#agent.speed = 0.0
	end
	#print("New agent pos of $new_agent_pos representing change of $change_in_position\n")
	#print(k1, "\n")
	#print(new_agent_pos, new_agent_vel, "\n")
	#move_agent!(agent, new_agent_pos, model)	
end
	



###Create the model_step function
function model_step!(model)
	#Calculate the rotational order of the agents. After some debate, we've decided that position \times desired_velocity is the way to go. 
        all_agents_iterable = allagents(model)
	rot_order::Float64 = rot_ord(allagents(model))
        rot_order_alt::Float64 = rot_ord_alt(allagents(model))
	print("Alternate rotational order returned as $rot_order_alt\n")	
	#Move the agents to their predetermined places 
	for agent in all_agents_iterable
                move_agent!(agent, Tuple(new_pos[agent.id]), model)
		#print("Agent position is now $(agent.pos) for a new agent pos of $(new_pos[agent.id])\n")
        end
	
        #Now recalculate the agent DODs based off their new positions
        total_area::Float64 = 0.0
	total_speed::Float64 = 0.0
	temp_hp::Vector{Tuple{Float64, Tuple{Float64, Float64}, Tuple{Float64, Float64}, Int64}} = []
	previous_areas::Vector{Float64} = zeros(nagents(model))
	actual_areas::Vector{Float64} = zeros(nagents(model))
	model.no_moves = 0
	for agent_i in all_agents_iterable
		previous_areas[agent_i.id] = agent_i.A #Just stores the area for the agent in the previous step for plotting
                
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

                new_cell_i::Vector{Tuple{Tuple{Float64, Float64}, Int64, Int64}} = voronoi_cell_bounded(model, ri, neighbour_positions, rho, eps, inf, temp_hp, agent_i.vel, [relic_half_plane])
		new_area::Float64 = voronoi_area(model, ri, new_cell_i, rho)	
                agent_i.A = new_area
		print("The area was $(agent_i.A)\n")
		agent_i.tdodr = agent_i.A/agent_i.tdod
		if(agent_i.A > pi*rho^2)
			print("Conventional area exceeded for agent. Cell was $(new_cell_i), and area was $(new_area)\n")
                        exit()
                end
		#For measuring parameters, we measure the true voronoi cell, which will not use the bounded vision. 
		#print("\n\n\n The time for calulating the voronoi cell in model step is ")
		true_new_cell_i::Vector{Tuple{Tuple{Float64, Float64}, Int64, Int64}} =  voronoi_cell(model, ri, neighbour_positions, rho,eps, inf, temp_hp, agent_i.vel)
                true_new_area = voronoi_area(model, ri, true_new_cell_i, rho)
		
		actual_areas[agent_i.id] = true_new_area
		#print("The bounded DOD was calculated as $new_area, while the unbounded was calculated as $true_new_area\n")
		agent_i.true_A = true_new_area
		total_area += true_new_area/(pi*rho^2)
		total_speed += agent_i.speed
		model.no_moves += no_move[agent_i.id]
        end
        
	#Now update the model's convex hull
	convexhullbro = update_convex_hull(model)
	convex_hull_area = voronoi_area(model, -1, convexhullbro, rho)
	model.CHA = convex_hull_area
	model.t += model.dt
        model.n += 1
	
	###Plotting
	delta_max = max(abs(model.target_area - 0), abs(model.target_area - 0.5*pi*rho^2))
	if(model.simulation_number == 1)
		draw_figures(model, actual_areas, previous_areas, delta_max, new_pos, tracked_path)
		figure = draw_model_cell(model)	
		save("./Cell_Images/shannon_flock_n_=_$(model.n).png", figure)
	end	
	push!(tracked_path, new_pos[tracked_agent])
	
		
	##Statistics recording
	packing_fraction = nagents(model)*pi/model.CHA
	print("Packing fraction at n = $(model.n) is $(packing_fraction)\n")
	if(model.n < no_steps)
		write(compac_frac_file, "$packing_fraction ")
		write(rot_o_file, "$rot_order ")
		write(rot_o_alt_file, "$rot_order_alt ")
	else
		write(compac_frac_file, "$packing_fraction\n")
		write(rot_o_file, "$rot_order\n")
		write(rot_o_alt_file, "$rot_order_alt\n")
	end
	average_area = total_area / nagents(model)
	average_speed = total_speed/nagents(model)
	if(model.n < no_steps)
		write(mean_a_file, "$average_area ")
		write(mean_speed_file, "$average_speed ")
	else 
		write(mean_a_file, "$average_area\n")
		write(mean_speed_file, "$average_speed\n")
	end

	last_hp_vert = open("Last_hp_vert.txt", "w")
	for i in 1:nagents(model)
		write(last_hp_vert, "Agent $i, position of $(new_pos[i]), considering position of $(last_half_planes[i][3])\n")
		write(last_hp_vert, "$(last_half_planes[i][1])\n")
		write(last_hp_vert, "$(last_half_planes[i][2])\n")
		write(last_hp_vert, "\n\n")
	end
	close(last_hp_vert)

	print("Finished step $(model.n) for simulation $(model.simulation_number) with a target DOD of $(model.target_area).\n\n\n")
end



###This is for the actual running of the model
#const no_simulations::Int64 = 1
#const no_steps::Int64 = 5000

function run_ABM(i, target_area, pos_vels_file, step) #Note that we're asking to input no simulations 
	#global compac_frac_file
        #global mean_a_file
        #global rot_o_file
        #global rot_o_alt_file
	#global mean_speed_file
	model = initialise(pos_vels_file, step, target_area_arg = target_area, simulation_number_arg = i, no_bird = no_birds)
	#figure, _ = abmplot(model)
        #save("./Simulation_Images/shannon_flock_n_=_$(0).png", figure)
	step!(model, agent_step!, model_step!, no_steps)
	write(compac_frac_file, "\n")
	write(mean_a_file, "\n")
	write(rot_o_file, "\n")
	write(rot_o_alt_file, "\n")
	write(mean_speed_file, "\n")
end #This should be the end of the function or running the ABM

###This line simulates the model
#run_ABM()
