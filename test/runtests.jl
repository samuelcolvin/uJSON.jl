using uJSON
using Base.Test

# write your own tests here
@test 1 == 1

@time result = uJSON.parse("./sample.json")
println("result:\n", result, "\n")

# println("printing test_data.json")
# @time result = parse_json("./json_profile/test_data.json")
# @profile result = parse_json("./json_profile/test_data.json")
# Profile.print()
# using ProfileView
# ProfileView.view()
# readline(STDIN)