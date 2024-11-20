

print("(INFO): Importing packages.")
import pandas as pd
import os
import nltk
from nltk.corpus import stopwords
from collections import Counter
from joblib import Parallel, delayed

from utils.helpers import snake_case, clean_string


# define the input filepath
data_dir = "data/clean"


print("(INFO): Loading extracted data.")
# load the extracted data specifying the schema
# and values to be treated as null
data = pd.read_csv(os.path.join(data_dir, "extracted_data.tsv"),
                   sep="\t",
                   dtype={
                       "PMID": int,
                       "Year": str,
                       "Month": str,
                       "ArticleTitle": str,
                       "Abstract": str,
                       "Keywords": str
                   },
                   na_values=["[Not Available]."])

# transform the columns from CamelCase to snake_case
data.columns = [snake_case(col) if col!="PMID" 
                else col.lower()
                for col in data.columns.values.tolist()]

# specify the columns that include text data to analyse
text_columns = ["article_title", "abstract", "keywords"]

# create a date variable to track trends over time
data["date"] = data["year"] + "-" + data["month"]


print("(INFO): Loading stopwords.")
# download the stopwords from the nltk library
# create a dictionary of the english stopwords
nltk.download('stopwords', quiet=True)
stop_words = stopwords.words('english')
stopwords_dict = Counter(stop_words)


def clean_data(column: str) -> pd.DataFrame:

    df = data[["pmid", "date", column]]

    # remove rows with null values
    df = df.dropna(axis=1).reset_index(drop=True)

    # remove non-alphabetic characters
    df[column] = (
        df
        .apply(lambda row: clean_string(row[column], stopwords_dict),
               axis=1)
    )

    # save the processed data
    if column=="article_title":
        filename = "title_data.tsv"
    elif column=="abstract":
        filename = "abstract_data.tsv"
    elif column=="keywords":
        filename = "keyword_mesh_data.tsv"
    
    df.to_csv(os.path.join(data_dir, filename),
              sep='\t',
              index=False)

    return df


print(f"(INFO): Splitting data into {text_columns}, cleaning text and saving to {data_dir}.")
cleaned_data = Parallel(n_jobs=3)(delayed(clean_data)(col) for col in text_columns)
