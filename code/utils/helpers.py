import pandas as pd
import re

def snake_case(CamelCaseStr: str) -> str:
    return re.sub(r'(?<!^)(?=[A-Z])', '_', CamelCaseStr).lower()

def clean_string(text: str, stopwords: dict) -> str:
    # remove non-alphabetic characters
    clean_text = " ".join(re.sub("[^a-zA-Z]+", " ", text).split())
    # remove stopwords from text
    clean_text = " ".join(
        [word for word in clean_text.split()
         if word not in stopwords]
    )
    return clean_text