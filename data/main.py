import os
import csv
import lzma
import pickle

DIRECTORY_PATH = 'WKRRaces'

def files():
    directory = DIRECTORY_PATH
    f = []
    for file in os.listdir(directory):
        if file.endswith(".csv"):
            f.append(os.path.join(directory, file))
    return f

def history_item(item, is_null_time):
    s = item.split('|')
    return (s[1], None if is_null_time else s[0])

def obj_for_file(file):
    obj = []
    with open(file, newline='') as handler:
        reader = csv.reader(handler, delimiter=',')
        next(reader, None)
        for row in reader:
            _ = row.pop(0)
            state = row.pop(0)
            _ = row.pop(0)
            history = []
            items_count = len(row)
            for index, item in enumerate(row):
                history.append(history_item(item, index == items_count - 1))
                
            obj.append({
                'State':  state,
                'History': history
            })
    return obj

def save_races():
    races = []
    for file in files():
        races.append(obj_for_file(file))

    with lzma.open("lzma_races.xz", "wb") as f:
        pickle.dump(races, f)

def load_races():
    with lzma.open('lzma_races.xz') as f:
        races = pickle.load(f)
        print(races[0])
        # ...
