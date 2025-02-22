###Function that calculates the area of a voronoi cell given the vertices that
#comprise the cell.
using Random
function voronoi_area(model, ri, cell, rho)
       	Area = 0.0
	circle_area = 0.0
	circle_detected = 0
	segment_detected = 0
	balloon_detected = 0
	num_points = length(cell)
	if(num_points == 0)
		#print("Number of points is 0\n")
		Area = pi*rho^2
		return Area
	end

	#=	
	print("Top of voronoi_area_file here. The vertices for the cell are ")
	for i in 1:num_points
        	print("$(cell[i])\n")
		vector_to_vertex = cell[i][1] .- ri
        	angle_to_vertex = atan(vector_to_vertex[2], vector_to_vertex[1])
        	#print("$angle_to_vertex ")
                #print("$(atan(cell[i][1][2], cell[i][1][1])) ")
        end
        print("\n") 
	=#

	#Iterate through successive pairs of vertices in the cell
	for i in 1:length(cell)
		#Use the shoestring formula to calcualte the area
		j = (i)%num_points+1
		#print("i and j are $i $j\n")
		xi = cell[i][1][1]
		yi = cell[i][1][2]
		xj = cell[j][1][1]
		yj = cell[j][1][2]
                Area += 0.5 * (yi + yj)* (xi - xj)
		#print("Added area of $(0.5 * (yi + yj)* (xi - xj))\n")
		#If the two vertices are actually intersects with the circle, then in addition to the area calculated from the shoestring formula, you should also add the area of the circle segment 
		if(cell[i][3] == 0 && cell[j][2] == 0) #If the forward line segment for intersect i aand the backward lines segment for intersect j is a circle, then we have a chord
			#print("Circle segments detected\n")
			if(cell[i][2] == -1 && cell[j][3] == -1) #This is if the vertices were generated by the stemler relic half plane
                                circle_area += 0.5*pi*rho^2
				#print("Added circle area of $(0.5*pi*rho^2)\n")
                                continue
                        end
			circle_detected = 1
			chord_length = norm(cell[j][1] .- cell[i][1]) #Calculates the length of the chord between the two vertices lying on the bounding circle
			r = 0.0
			if(rho^2 < (0.5*chord_length)^2)
				#=
				print("Voronoi area file: Half chord length is longer than radius of vision. Offending vertices were $(cell[i]) and $(cell[j]) for an agent position of $ri. Chord length calculated to be $chord_length, against a rho value of $rho\n")
				print("The vertices of the cell were\n")
				for i in 1:num_points
					print(cell[i], "\n")				
				end			
				if(abs(0.5*chord_length - rho)/rho < 10^(-5))
					r = 0.0
				else
					print("Bro, chord length is still cooked\n")
				end
				=#
				#exit()
			else
                       		r = sqrt(rho^2 - (0.5 * chord_length)^2)
			end
			h = rho - r
			circle_segment_area = rho^2*acos((rho-h)/rho) - (rho-h)*sqrt(2*rho*h-h^2) #Calculated according to Wolfram formula 
			
			vec_to_i = cell[i][1] .- ri
			vec_to_ip1 = cell[j][1] .- ri
			angle_to_i = atan(vec_to_i[2], vec_to_i[1])
			angle_to_ip1 = atan(vec_to_ip1[2], vec_to_ip1[1])
			theta = min((angle_to_ip1 - angle_to_i + 2*pi)%(2*pi), (angle_to_i - angle_to_ip1 + 2*pi)%(2*pi))
			alt_circle_segment_area = 0.5* rho^2 * (theta - sin(theta))
			#= if(abs(alt_circle_segment_area - circle_segment_area)/circle_segment_area > 0.01)
				print("Voronoi area file here. Divergence in area calculated, the angle formula calculated $alt_circle_segment_area, the other $circle_segment_area.\n")
				#exit()
			end =#

			#Check, if the agent position is inside the chord half plane. 
			chord_vector = cell[j][1] .- cell[i][1]
			chord_point = 0.5 .* chord_vector .+ cell[i][1]
			chord_half_plane = (atan(chord_vector[2], chord_vector[1]), chord_vector, Tuple(chord_point), 0)
			if(num_points == 2)
                        	return pi*rho^2 - circle_segment_area
                        end
			if(outside(chord_half_plane, ri, eps, inf))
				balloon = pi*rho^2 - circle_segment_area
				balloon_detected = 1
					
				#print("Ballon segment detected between points $i and $j, balloon area was $balloon.\n")
				#=
				for i in 1:num_points
					vector_to_vertex = cell[i][1] .- ri
					angle_to_vertex = atan(vector_to_vertex[2], vector_to_vertex[1])
					print("$angle_to_vertex ")
				end
				
				#print("\n")
				=#
				
				circle_area += balloon
				#exit()
			else 
				segment_detected = 1
				#print("Added circle area of $circle_segment_area between points $i and $j\n")
				circle_area += circle_segment_area
			end
		end
	end
		#=
		if(abs(Area)+circle_area > 0.5*pi*rho^2 && initialised == 0)
			print("Voronoi_area file here. Conventional area exceeded for agent, circle detected? $circle_detected. Balloon detected? $balloon_detected. Segment detected? $segment_detected. The circle area was $circle_area and the normal area was $(abs(Area)).\n")
			AgentsIO.save_checkpoint("simulation_save.jld2", model)
			exit()
		end =#
		return  abs(Area)+circle_area
end


















###Function that calculates the area of a voronoi cell given the vertices that
#comprise the cell.
function voronoi_area_alt(ri, cell, rho)
       	Area = 0.0
	circle_area = 0.0
	circle_detected = 0
	segment_detected = 0
	balloon_detected = 0
	num_points = length(cell)
	if(num_points == 0)
		print("Number of points is 0\n")
		Area = pi*rho^2
		return Area
	end

	#=	
	print("Top of voronoi_area_file here. The vertices for the cell are ")
	for i in 1:num_points
        	print("$(cell[i])\n")
		vector_to_vertex = cell[i][1] .- ri
        	angle_to_vertex = atan(vector_to_vertex[2], vector_to_vertex[1])
        	#print("$angle_to_vertex ")
                #print("$(atan(cell[i][1][2], cell[i][1][1])) ")
        end
        print("\n") 
	=#

	#Iterate through successive pairs of vertices in the cell
	for i in 1:length(cell)
		#Use the shoestring formula to calcualte the area
		j = (i)%num_points+1
		#print("i and j are $i $j\n")
		xi = cell[i][1][1]
		yi = cell[i][1][2]
		xj = cell[j][1][1]
		yj = cell[j][1][2]
                Area += 0.5 * (yi + yj)* (xi - xj)
		#print("Added area of $(0.5 * (yi + yj)* (xi - xj))\n")
		#If the two vertices are actually intersects with the circle, then in addition to the area calculated from the shoestring formula, you should also add the area of the circle segment 
		if(cell[i][3] == 0 && cell[j][2] == 0) #If the forward line segment for intersect i aand the backward lines segment for intersect j is a circle, then we have a chord
			#print("Circle segments detected\n")
			if(cell[i][2] == -1 && cell[j][3] == -1) #This is if the vertices were generated by the stemler relic half plane
                                circle_area += 0.5*pi*rho^2
				#print("Added circle area of $(0.5*pi*rho^2)\n")
                                continue
                        end
			circle_detected = 1
			chord_length = norm(cell[j][1] .- cell[i][1]) #Calculates the length of the chord between the two vertices lying on the bounding circle
			r = 0.0
			if(rho^2 < (0.5*chord_length)^2)
				#print("Voronoi area file: Half chord length is longer than radius of vision. Offending vertices were $(cell[i]) and $(cell[j]) for an agent position of $ri. Chord length calculated to be $chord_length, against a rho value of $rho\n")
				print("The vertices of the cell were\n")
				for i in 1:num_points
					print(cell[i], "\n")				
				end			
				if(abs(0.5*chord_length - rho)/rho < 10^(-5))
					r = 0.0
				else
					print("Bro, chord length is still cooked\n")
				end
				#exit()
			else
                       		r = sqrt(rho^2 - (0.5 * chord_length)^2)
			end
			h = rho - r
			circle_segment_area = rho^2*acos((rho-h)/rho) - (rho-h)*sqrt(2*rho*h-h^2) #Calculated according to Wolfram formula 
			
			vec_to_i = cell[i][1] .- ri
			vec_to_ip1 = cell[j][1] .- ri
			angle_to_i = atan(vec_to_i[2], vec_to_i[1])
			angle_to_ip1 = atan(vec_to_ip1[2], vec_to_ip1[1])
			theta = min((angle_to_ip1 - angle_to_i + 2*pi)%(2*pi), (angle_to_i - angle_to_ip1 + 2*pi)%(2*pi))
			alt_circle_segment_area = 0.5* rho^2 * (theta - sin(theta))
			if(abs(alt_circle_segment_area - circle_segment_area)/circle_segment_area > 0.01)
				print("Voronoi area file here. Divergence in area calculated, the angle formula calculated $alt_circle_segment_area, the other $circle_segment_area.\n")
				#exit()
			end

			#Check, if the agent position is inside the chord half plane. 
			chord_vector = cell[j][1] .- cell[i][1]
			chord_point = 0.5 .* chord_vector .+ cell[i][1]
			chord_half_plane = (atan(chord_vector[2], chord_vector[1]), chord_vector, Tuple(chord_point), 0)
			if(num_points == 2)
                        	return pi*rho^2 - circle_segment_area
                        end
			if(outside(chord_half_plane, ri, eps, inf))
				balloon = pi*rho^2 - circle_segment_area
				balloon_detected = 1
					
				#print("Ballon segment detected between points $i and $j, balloon area was $balloon.\n")
				#=
				for i in 1:num_points
					vector_to_vertex = cell[i][1] .- ri
					angle_to_vertex = atan(vector_to_vertex[2], vector_to_vertex[1])
					print("$angle_to_vertex ")
				end
				
				#print("\n")
				=#
				
				circle_area += balloon
				#exit()
			else 
				segment_detected = 1
				#print("Added circle area of $circle_segment_area between points $i and $j\n")
				circle_area += circle_segment_area
			end
		end
	end
		#=
		if(abs(Area)+circle_area > 0.5*pi*rho^2 && initialised == 0)
			print("Voronoi_area file here. Conventional area exceeded for agent, circle detected? $circle_detected. Balloon detected? $balloon_detected. Segment detected? $segment_detected. The circle area was $circle_area and the normal area was $(abs(Area)).\n")
			AgentsIO.save_checkpoint("simulation_save.jld2", model)
			exit()
		end =#
		return  abs(Area)+circle_area
end





function polygon_area(vertices::Vector{Tuple{Float64, Float64}})
	Area::Float64 = 0.0
	num_points::Int32 = length(vertices)
	for i in 1:length(vertices)
                #Use the shoestring formula to calcualte the area
                j = (i)%num_points+1
                #print("i and j are $i $j\n")
                xi = cell[i][1][1]
                yi = cell[i][1][2]
                xj = cell[j][1][1]
                yj = cell[j][1][2]
                Area += 0.5 * (yi + yj)* (xi - xj)
	end

	return Area
end
