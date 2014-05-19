module uJSON
	export parse

	const ujsonlib = find_library(["ujsonlib"],[Pkg.dir("uJSON", "deps")])

	type UltraObject
	    # array to put JSON data in
	    array::Array{Any, 1}
	    # array to hold keys in
	    route::Array{Any, 1}
	    # whether we are in a dict (as opposed to an array)
	    in_dict::Bool
	    # working object used as a reference to where we're putting data now
	    working_obj::Any
	    UltraObject() = new(Any[], Any[], false, nothing)
	end

	function set_last!{T}(uo::UltraObject, value::T, key::Union(String, Nothing))
	    if key == nothing
	        push!(uo.working_obj, value)
	    else
	        uo.working_obj[key] = value
	    end
	end

	function get_string(key_::Ptr{Int32}, key_length_::Ptr{Int32})
	    key_length = int64(unsafe_load(key_length_))
	    UTF32String(pointer_to_array(key_, key_length, false))
	end
	        
	function startnew(uobj_::Ptr{Void}, 
	                  key_::Ptr{Int32},
	                  key_length_::Ptr{Int32},
	                  is_dict_::Ptr{Int32})
	    uo = unsafe_pointer_to_objref(uobj_)::UltraObject
	    key = uo.in_dict ? get_string(key_, key_length_) : nothing
	    is_dict = bool(unsafe_load(is_dict_))
	    new_item = is_dict ? Dict{String, Any}() : Any[]
	    
	    if uo.working_obj == nothing
	        uo.working_obj = uo.array
	    end
	    set_last!(uo, new_item, key)
	    push!(uo.route, new_item)
	    uo.in_dict = is_dict
	    uo.working_obj = last(uo.route)
	    return nothing
	end
	const startnew_c = cfunction(startnew, Void, (Ptr{Void}, 
	                                              Ptr{Int32},
	                                              Ptr{Int32},
	                                              Ptr{Int32}))
	        
	function exit_ob(uobj_::Ptr{Void})
	    uo = unsafe_pointer_to_objref(uobj_)::UltraObject
	    # uo.in_dict = last(uo.route).key != nothing
	    pop!(uo.route)
	    uo.working_obj = length(uo.route) > 0 ? last(uo.route) : nothing
	    uo.in_dict = isa(uo.working_obj, Dict)
	    return nothing
	end
	const exit_ob_c = cfunction(exit_ob, Void, (Ptr{Void},))

	function print_val(key, value)
	    if key == nothing
	        println(" Adding: ",value, ", type: ", typeof(value))
	    else
	        println(" Adding '", key, "': ", value, ", type: ", typeof(value))
	    end
	end
	                            
	function add_null_bool_int(uobj_::Ptr{Void}, 
	                           key_::Ptr{Int32},
	                           key_length_::Ptr{Int32},
	                           value_::Ptr{Int64},
	                           value_type_::Ptr{Int32})
	    uo = unsafe_pointer_to_objref(uobj_)::UltraObject
	    key = uo.in_dict ? get_string(key_, key_length_) : nothing
	    
	    value_type = unsafe_load(value_type_)
	    if value_type == -1
	        value = nothing
	    elseif value_type == 0
	        value = bool(unsafe_load(value_))
	    elseif value_type == 1
	        value = unsafe_load(value_)
	    else
	        error("value type unknown: ", value_type)
	    end
	#     print_val(key, value)
	    set_last!(uo, value, key)
	    return nothing
	end
	const add_null_bool_int_c = cfunction(add_null_bool_int, 
	                                      Void, 
	                                      (Ptr{Void}, 
	                                       Ptr{Int32},
	                                       Ptr{Int32},
	                                       Ptr{Int64},
	                                       Ptr{Int32}))

	function add_double(uobj_::Ptr{Void}, 
	                   key_::Ptr{Int32},
	                   key_length_::Ptr{Int32},
	                   value_::Ptr{Float64})
	    uo = unsafe_pointer_to_objref(uobj_)::UltraObject
	    key = uo.in_dict ? get_string(key_, key_length_) : nothing
	    value = unsafe_load(value_)::Float64
	#     print_val(key, value)
	    set_last!(uo, value, key)
	    return nothing
	end
	const add_double_c = cfunction(add_double, Void, (Ptr{Void}, Ptr{Int32}, Ptr{Int32}, Ptr{Float64}))


	                            
	function add_string(uobj_::Ptr{Void}, 
	                    key_::Ptr{Int32},
	                    key_length_::Ptr{Int32},
	                    value_::Ptr{Int32},
	                    value_length_::Ptr{Int32})
	    uo = unsafe_pointer_to_objref(uobj_)::UltraObject
	    key = uo.in_dict ? get_string(key_, key_length_) : nothing
	    
	    value = get_string(value_, value_length_)
	#     print_val(key, value)
	    set_last!(uo, value, key)
	    return nothing
	end
	const add_string_c = cfunction(add_string, 
	                               Void, 
	                               (Ptr{Void}, 
	                                Ptr{Int32},
	                                Ptr{Int32},
	                                Ptr{Int32},
	                                Ptr{Int32}))

# not used as reading the string in is
	# function parsefile(filename::String)
	#     uo = UltraObject()

	#     result = ccall( (:process_file, ujsonlib), 
	#                     Int32, 
	#                     (Ptr{Uint8}, Ptr{Void}, Ptr{Void}, Ptr{Void}, Ptr{Void}, Ptr{Void}, Any), 
	#                     pointer(filename), startnew_c, exit_ob_c, add_null_bool_int_c, add_double_c, add_string_c, uo)
	#     # the first (and only) item in the base array is the actual data structure
	#     if result != 1
	#         error("error processing JSON")
	#     end
	#     if length(uo.array) == 0
	#         error("no JSON found")
	#     end
	#     return uo.array[1]
	# end

	function parse(io::IO)
		str = readall(io)
		return parse(str)
	end

	function parse(str::String)
	    uo = UltraObject()
	    result = ccall( (:process_string, ujsonlib), 
	                    Int32, 
	                    (Ptr{Uint8}, Ptr{Void}, Ptr{Void}, Ptr{Void}, Ptr{Void}, Ptr{Void}, Any), 
	                    utf8(str), startnew_c, exit_ob_c, add_null_bool_int_c, add_double_c, add_string_c, uo)
	    # the first (and only) item in the base array is the actual data structure
	    if result != 1
	        error("error processing JSON")
	    end
	    if length(uo.array) == 0
	        error("no JSON found")
	    end
	    return uo.array[1]
	end
end
