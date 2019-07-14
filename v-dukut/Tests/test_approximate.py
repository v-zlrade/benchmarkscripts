import pandas as pd
import sys

train_file_name = sys.argv[1]
train_df = pd.read_csv('Analitics/' + train_file_name)
test_file_name = sys.argv[2]
test_df = pd.read_csv('Analitics/' + test_file_name)

print(train_df.columns)