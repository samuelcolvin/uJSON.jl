using uJSON
using JSON
using Base.Test

println("Running trivial example: ")
input_str = "[1,2,\"hello\", null, 3.2123, {\"a\":1}]"
uresult = uJSON.parse(input_str)
println(input_str, " >> ", uresult)

fn = Pkg.dir("uJSON", "test", "sample.json")
print("\nJSON running simple test:  ")
@time result = JSON.parse(open(fn, "r"))
print("uJSON running simple test: ")
@time uresult = uJSON.parse(open(fn, "r"))
@test uresult == result
println("SUCCESS: results equal")