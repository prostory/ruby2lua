local a = 1
  print(a)
  a = "Hello"
  _G["$a"] = 5
  print(_G["$a"])
  _TOP_B = 2
  print(_TOP_B)
  print(a)
  _TOP_A = {}
do
    local a = 1
    print(A_B)
    print(_TOP_B)
end