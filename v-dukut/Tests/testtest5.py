import pandas as pd
from Result import Result
import plot

res = []

res.append(Result(1, 36, 131072, 100663296, "2019-06-06 10:49:37", "2019-06-06 12:49:37" , 200000, 0.52, 0, 0))
res.append(Result(1, 128, 231072, 10063296, "2019-06-06 10:49:37", "2019-06-06 12:49:37" , 200000, 0.52, 0, 1))
res.append(Result(1, 152, 46001, 1663296, "2019-06-06 10:49:37", "2019-06-06 12:49:37" , 200000, 0.52, 1, 1))
res.append(Result(1, 248, 151072, 2606996, "2019-06-06 10:49:37", "2019-06-06 12:49:37" , 5, 0.52, 0, 0))
res.append(Result(1, 12, 11072, 2606996, "2019-06-06 10:49:37", "2019-06-06 12:49:37" , 200000, 1.52, 0, 0))
res.append(Result(1, 300, 151072, 26006996, None, "2019-06-06 12:49:37" , 200000, 1.52, 0, 0))


df = pd.DataFrame([vars(result) for result in res])

#print(df)

for result in res:
    print(result.get_loss())

plot.export_results(res)



