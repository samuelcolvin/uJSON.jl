using JSON
using uJSON
using Base.Test

function print_object_summary(ob, max_depth::Int, depth=0)
	if isa(ob, Union(Dict, Array))
		println(string(typeof(ob)), "(len ", length(ob), "): ")
		if depth*4 + 1 < max_depth*4
			d2 = depth + 1
			if isa(ob, Dict)
				for (key, ob2) in ob
					print(" "^4d2, key, ": ")
					print_object_summary(ob2, max_depth, d2)
				end
			elseif isa(ob,Array)
				for ob2 in ob
					print(" "^4d2)
					print_object_summary(ob2, max_depth, d2)
				end
			end
		end
	else
		println("(", string(typeof(ob)), ") ", string(ob))
	end
end

function generate_jagged(l1, l2)
	data = Any[]
	arrays_only = true
	randrand(maxlen) = rand(int(rand()*maxlen))
	for r in rand(int(l1))
	    if r < 0.25
	    	if arrays_only
	        	push!(data, string(randrand(l2)))
	        else
	        	push!(data, {string(i)=>int(i*10) for i = randrand(l2)})
	    	end
	    elseif r < 0.5
	        push!(data, randrand(l2))
	    elseif r < 0.75
	        push!(data, int(10*randrand(l2)))
	    else
	    	if arrays_only
	        	push!(data, [nothing for i = randrand(l2)])
	    	else
	        	push!(data, {string(int(i))=>nothing for i = 10*randrand(l2)})
	        end
	    end
	end
	data
end
data = generate_jagged(1e5, 500)
json_str = json(data)
fn = "testing.json"
f=open(fn, "w")
write(f, json_str)
close(f)

print("parsing with uJSON:      ")
@time uJSON.parse(json_str)
print("parsing with uJSON:      ")
@time uJSON.parse(json_str)
print("parsing with JSON:       ")
@time JSON.parse(json_str)
print("parsing with JSON:       ")
@time JSON.parse(json_str)
# @test uresult == result

fn = Pkg.dir("uJSON", "test", "sample_u4c.json")

print("JSON running deep test:  ")
@time result = JSON.parse(open(fn, "r"))
print("uJSON running deep test: ")
@time uresult = uJSON.parse(open(fn, "r"))

# @profile result = uJSON.parse(json_str)
# # Profile.print()
# using ProfileView
# ProfileView.view()
# readline(STDIN)