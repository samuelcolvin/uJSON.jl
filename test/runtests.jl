using uJSON
using JSON
using Base.Test

function print_sum(a)
    print(summary(a), ": ")
    show(a)
    println()
end

print("uJSON running trivial example:")
input_str = "[1,2,\"hello\", null, 3.2123]"
uresult = uJSON.parse(input_str)
print(input_str, " >> ")
print_sum(uresult)

fn = Pkg.dir("uJSON", "test", "sample.json")
print("\nJSON running simple test:  ")
@time result = JSON.parse(open(fn, "r"))
print("uJSON running simple test: ")
@time uresult = uJSON.parse(open(fn, "r"))
@test uresult == result
println("SUCCESS: results equal")