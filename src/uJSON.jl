module uJSON
	export parse

	const ujsonlib = find_library(["ujsonlib"],[Pkg.dir("uJSON", "deps")])
	const TYPES = Any # Union(Dict, Array, String, Number, Bool, Nothing) # Types it may encounter
	const KEY_TYPES = Union(String) # Types it may encounter as object keys

	type UltraObject
	    # array to put JSON data in
	    array::Array{TYPES, 1}
	    # array to hold keys in
	    route::Array{TYPES, 1}
	    # whether we are in a dict (as opposed to an array)
	    in_dict::Bool
	    # working object used as a reference to where we're putting data now
	    working_obj::TYPES
	    UltraObject() = new(TYPES[], TYPES[], false, nothing)
	end

	function set_last!{T}(uo::UltraObject, value::T, key::String)
	    if uo.in_dict
	        setindex!(uo.working_obj, value, key)
	    else
	        push!(uo.working_obj, value)
	    end
	end

	function get_string(key_::Ptr{Int32}, key_length_::Ptr{Int32})
	    UTF32String(pointer_to_array(key_, unsafe_load(key_length_), false))
	end

	function get_key(uobj_::Ptr{Void}, key_::Ptr{Int32}, key_length_::Ptr{Int32})
	    uo = unsafe_pointer_to_objref(uobj_)::UltraObject
	    # seems to be slightly quicker if we don't call get_string
		key = uo.in_dict ?  UTF32String(pointer_to_array(key_, unsafe_load(key_length_), false)): ""
		return uo, key
	end
	        
	function startnew(uobj_::Ptr{Void}, 
	                  key_::Ptr{Int32},
	                  key_length_::Ptr{Int32},
	                  is_dict_::Ptr{Int32})
	    uo, key = get_key(uobj_, key_, key_length_)

	    is_dict = bool(unsafe_load(is_dict_))
	    new_item = is_dict ? Dict{KEY_TYPES, TYPES}() : TYPES[]
	    
	    if uo.working_obj == nothing
	        uo.working_obj = uo.array
	    end
	    set_last!(uo, new_item, key)
	    push!(uo.route, new_item)
	    uo.in_dict = is_dict
	    uo.working_obj = new_item
	    return nothing
	end
	const startnew_c = cfunction(startnew, Void, (Ptr{Void}, 
	                                              Ptr{Int32},
	                                              Ptr{Int32},
	                                              Ptr{Int32}))
	        
	function exitob(uobj_::Ptr{Void})
	    uo = unsafe_pointer_to_objref(uobj_)::UltraObject
	    pop!(uo.route)
	    uo.working_obj = length(uo.route) > 0 ? last(uo.route) : nothing
	    uo.in_dict = isa(uo.working_obj, Dict)
	    return nothing
	end
	const exitob_c = cfunction(exitob, Void, (Ptr{Void},))
	
	# null, bool, int             
	function addnbi(uobj_::Ptr{Void}, 
	                key_::Ptr{Int32},
	                key_length_::Ptr{Int32},
	                value_::Ptr{Int64},
	                value_type_::Ptr{Int32})
	    uo, key = get_key(uobj_, key_, key_length_)
	    
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
	    set_last!(uo, value, key)
	    return nothing
	end
	const addnbi_c = cfunction(addnbi, 
	                           Void, 
	                           (Ptr{Void}, 
	                            Ptr{Int32},
	                            Ptr{Int32},
	                            Ptr{Int64},
	                            Ptr{Int32}))

	function adddouble(uobj_::Ptr{Void}, 
	                   key_::Ptr{Int32},
	                   key_length_::Ptr{Int32},
	                   value_::Ptr{Float64})
	    uo, key = get_key(uobj_, key_, key_length_)

	    value = unsafe_load(value_)::Float64
	    set_last!(uo, value, key)
	    return nothing
	end
	const adddouble_c = cfunction(adddouble, Void, (Ptr{Void}, Ptr{Int32}, Ptr{Int32}, Ptr{Float64}))

	function addstring(uobj_::Ptr{Void}, 
	                   key_::Ptr{Int32},
	                   key_length_::Ptr{Int32},
	                   value_::Ptr{Int32},
	                   value_length_::Ptr{Int32})
	    uo, key = get_key(uobj_, key_, key_length_)
	    
	    value = get_string(value_, value_length_)
	    set_last!(uo, value, key)
	    return nothing
	end
	const addstring_c = cfunction(addstring, 
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
	#                     pointer(filename), startnew_c, exit_ob_c, addnbi_c, add_double_c, add_string_c, uo)
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
	                    utf8(str), startnew_c, exitob_c, addnbi_c, adddouble_c, addstring_c, uo)
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
