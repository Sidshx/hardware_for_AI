import pandas as pd

input1 = [0,0,1,1]
input2 = [0,1,0,1]

data = {
        'input 1' : input1,
        'input 2' : input2,
        'result' : (input1 | input2 for input1, input2 in zip(input1,input2))} 

print(pd.DataFrame(data, index = ["A", "B", "C", "D"]) )
